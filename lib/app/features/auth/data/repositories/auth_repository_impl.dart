import 'package:desafio_loomi/app/core/network/api_client.dart';
import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    required ApiClient apiClient,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard(),
        _apiClient = apiClient;

  @override
  Stream<AppUser> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser == null
          ? AppUser.empty()
          : AppUser.fromFirebase(firebaseUser);
    });
  }

  @override
  Future<AppUser> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AppUser.fromFirebase(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword(
      String email, String password) async {
    UserCredential userCredential;
    try {
      // 1. Cadastra no Firebase
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Falha ao criar usuário no Firebase.');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      throw Exception(
          'Erro desconhecido no cadastro Firebase: ${e.toString()}');
    }

    // 2. Tenta registrar no Backend (Strapi) APÓS sucesso no Firebase
    try {
      final firebaseUser = userCredential.user!;
      final username = firebaseUser.displayName ??
          email.split(
              '@')[0]; // Use o nome do display OU parte do email como default
      final firebaseUID = firebaseUser.uid;

      // Monta o body para a API Strapi
      final backendRegisterData = {
        "username":
            username, // Considere pegar um nome de usuário inicial de outra forma se necessário
        "email": email,
        "password":
            password, // IMPORTANTE: Verifique se sua API *realmente* precisa da senha aqui. Se a auth é só Firebase, isso pode ser inseguro ou desnecessário. Talvez um placeholder? CONFIRME ISSO.
        "firebase_UID": firebaseUID
      };

      // Faz a chamada POST para /api/auth/local/register
      // O ApiClient já deve injetar o token Firebase automaticamente via AuthInterceptor
      await _apiClient.post(
        '/api/auth/local/register', // Endpoint de registro do backend
        data: backendRegisterData,
      );

      // 3. Retorna o AppUser se ambos os passos tiveram sucesso
      return AppUser.fromFirebase(firebaseUser);
    } on DioException catch (dioError) {
      // Se falhar ao registrar no backend, delete o usuário recém-criado no Firebase para consistência
      await userCredential.user?.delete();
      // Log detalhado do erro Dio
      print(
          'Erro Dio ao registrar no backend: ${dioError.response?.statusCode} - ${dioError.response?.data}');
      throw Exception(
          'Falha ao registrar usuário no servidor backend após cadastro no Firebase. Detalhes: ${dioError.response?.data ?? dioError.message}');
    } catch (e) {
      // Outro erro durante registro no backend
      await userCredential.user?.delete(); // Tenta deletar do Firebase
      print('Erro inesperado ao registrar no backend: ${e.toString()}');
      throw Exception(
          'Erro inesperado ao sincronizar usuário com servidor backend.');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    UserCredential userCredential;

    // 1. Processo de Login Google + Firebase
    try {
      debugPrint("AuthRepository: Iniciando signInWithGoogle");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Usuário cancelou o fluxo do Google
      if (googleUser == null) {
        debugPrint("AuthRepository: Google Sign In cancelado pelo usuário.");
        throw Exception('Login com Google cancelado pelo usuário');
      }
      debugPrint("AuthRepository: Google User obtido: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint("AuthRepository: Google Authentication obtida.");

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken, // O ID Token do Google é usado aqui
      );

      debugPrint(
          "AuthRepository: Credencial Firebase criada. Tentando signInWithCredential...");
      userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint(
          "AuthRepository: signInWithCredential bem-sucedido. User ID: ${userCredential.user?.uid}");

      if (userCredential.user == null) {
        throw Exception(
            'Falha ao autenticar com Google no Firebase (User null).');
      }
    } catch (e) {
      // Trata erros específicos do Firebase Auth ou Google Sign In
      if (e is FirebaseAuthException) {
        debugPrint(
            "AuthRepository: Erro FirebaseAuthException no Google Sign In: ${e.code} - ${e.message}");
        throw _handleFirebaseError(e);
      }
      debugPrint(
          "AuthRepository: Erro genérico no fluxo Google/Firebase Sign In: ${e.toString()}");
      // Pode ser um erro de rede, conta desativada, etc.
      throw Exception('Falha no login com Google: ${e.toString()}');
    }

    // 2. Sincronização com o Backend (Strapi) via /api/auth/local/register
    final firebaseUser = userCredential.user!;
    final firebaseUID = firebaseUser.uid;
    final email = firebaseUser.email;
    final username = firebaseUser.displayName ??
        email?.split('@')[0]; // Usa nome do Google ou parte do email

    // Verifica se o email foi obtido (essencial para o backend)
    if (email == null) {
      debugPrint(
          "AuthRepository: Email não obtido do Google. Não é possível sincronizar com o backend.");
      // Considere deletar o usuário do Firebase se o email for obrigatório? Ou apenas falhar o login?
      // Por enquanto, vamos falhar o login completo.
      // await firebaseUser.delete(); // Opcional: limpar o usuário Firebase se o email é crítico
      throw Exception(
          'Email não fornecido pelo Google. Não é possível completar o login/registro no sistema.');
    }

    if (username == null) {
      // Deveria ser raro se o email existe, mas por segurança
      debugPrint("AuthRepository: Não foi possível determinar um username.");
      throw Exception('Nome de usuário não pôde ser determinado.');
    }

    // Prepara dados para o backend
    final backendRegisterData = {
      "username": username,
      "email": email,
      // IMPORTANTE: Verifique se o backend aceita NULL, string vazia, ou se ignora 'password'
      // quando 'firebase_UID' está presente. Usar um placeholder é uma opção.
      "password":
          "GOOGLE_SIGN_IN_PLACEHOLDER_PASSWORD_${DateTime.now().millisecondsSinceEpoch}", // Placeholder único/aleatório se necessário
      "firebase_UID": firebaseUID
    };

    // 3. Tenta chamar o backend
    try {
      debugPrint(
          'AuthRepository: Tentando sincronizar com backend (Strapi) via /auth/local/register para UID: $firebaseUID');
      await _apiClient.post(
        '/api/auth/local/register',
        data: backendRegisterData,
      );
      debugPrint(
          'AuthRepository: Sincronização (ou criação) no backend bem-sucedida.');
    } on DioException catch (dioError) {
      // TRATAMENTO ESPECIAL PARA LOGIN: Erro 400 pode significar que usuário já existe
      if (dioError.response?.statusCode == 400) {
        // Verifique a mensagem de erro específica do seu backend para ter certeza
        // Exemplo: if (dioError.response?.data['error']?['message']?.contains('Email or Username are already taken'))
        debugPrint(
            'AuthRepository: Backend retornou ${dioError.response?.statusCode}. Provavelmente usuário já existe (UID: $firebaseUID). Login continua.');
        // NÃO lançamos exceção aqui, pois para LOGIN, isso é esperado/aceitável.
      } else {
        // Outros erros do backend (500, 401, 403, etc.) são problemas reais.
        debugPrint(
            'AuthRepository: Erro Dio NÃO TRATADO ao sincronizar com backend: ${dioError.response?.statusCode} - ${dioError.response?.data}');
        // Decisão: Falhar o login inteiro ou permitir login Firebase mas logar o erro de sync?
        // Opção: Logar e continuar (usuário logado no Firebase, mas backend não syncado)
        // logger.error('Falha ao sincronizar usuário $firebaseUID com backend: ${dioError.message}');
        // Opção B: Falhar o login (mais seguro se o backend for crítico)
        throw Exception(
            'Falha ao sincronizar usuário com o servidor após login Google. Status: ${dioError.response?.statusCode}. Detalhes: ${dioError.response?.data['error']?['message'] ?? dioError.message}');
      }
    } catch (e) {
      // Erros inesperados durante a chamada ao backend
      debugPrint(
          'AuthRepository: Erro inesperado ao sincronizar com backend: ${e.toString()}');
      // Decisão similar à de cima: falhar ou logar e continuar?
      throw Exception('Erro inesperado ao sincronizar usuário com o servidor.');
    }

    // 4. Retorna o AppUser se o login Firebase funcionou e a sincronização foi tratada
    debugPrint(
        "AuthRepository: signInWithGoogle concluído com sucesso para ${firebaseUser.email}.");
    return AppUser.fromFirebase(firebaseUser);
  }

  @override
  Future<AppUser> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (appleCredential.givenName != null) {
        await userCredential.user?.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
              .trim(),
        );
      }

      return AppUser.fromFirebase(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      throw Exception('Falha no login com Apple: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
      ]);
    } catch (e) {
      throw Exception('Falha ao fazer logout: ${e.toString()}');
    }
  }

  Exception _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('Email inválido');
      case 'user-disabled':
        return Exception('Usuário desativado');
      case 'user-not-found':
        return Exception('Usuário não encontrado');
      case 'wrong-password':
        return Exception('Senha incorreta');
      case 'email-already-in-use':
        return Exception('Email já está em uso');
      case 'operation-not-allowed':
        return Exception('Operação não permitida');
      case 'weak-password':
        return Exception('Senha muito fraca');
      default:
        return Exception('Erro de autenticação: ${e.message}');
    }
  }
}
