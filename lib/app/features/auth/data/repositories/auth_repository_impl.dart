import 'package:desafio_loomi/app/core/error/exception.dart';
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
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuário não está logado.');
      }
      if (user.email == null) {
        // Reautenticação por email/senha precisa do email
        throw Exception('Email do usuário não encontrado para reautenticação.');
      }

      // 1. Criar credencial para reautenticação
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // 2. Tentar reautenticar
      print("AuthRepository: Tentando reautenticar...");
      await user.reauthenticateWithCredential(credential);
      print("AuthRepository: Reautenticação bem-sucedida.");

      // 3. Se reautenticação OK, tentar atualizar a senha
      print("AuthRepository: Tentando atualizar a senha...");
      await user.updatePassword(newPassword);
      print("AuthRepository: Senha atualizada com sucesso no Firebase.");

      // Opcional: Chamar API do Strapi se precisar atualizar algo lá também
      // Ex: await _apiClient.patch('/api/users/updateMe', data: {'data': {'password': newPassword}});
      // CUIDADO: Enviar a nova senha para o Strapi pode não ser necessário ou seguro
      // se a autenticação principal é gerenciada pelo Firebase. Verifique sua arquitetura.
    } on FirebaseAuthException catch (e) {
      // Usa o handler de erro existente para traduzir o erro do Firebase
      print("AuthRepository: Erro FirebaseAuth ao trocar senha - ${e.code}");
      throw _handleFirebaseError(e);
    } catch (e) {
      print(
          "AuthRepository: Erro inesperado ao trocar senha - ${e.toString()}");
      // Lança erro genérico se não for do Firebase
      throw Exception('Erro desconhecido ao tentar atualizar a senha.');
    }
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

  @override
  Future<AppUser> updateUserProfile({required String username}) async {
    // Pega o usuário Firebase ANTES do try para garantir que temos o ID/email base
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      // Se o usuário Firebase for nulo aqui, algo está muito errado.
      throw Exception(
          "Usuário Firebase não encontrado para atualização do perfil.");
    }

    try {
      print(
          "AuthRepository: Tentando atualizar perfil (username: $username)...");
      // Monta o body conforme especificado
      final updateData = {
        "data": {
          "username": username,
          // Adicione outros campos aqui se necessário
        }
      };

      // Chama o endpoint PATCH
      final response = await _apiClient.patch(
        '/api/users/updateMe',
        data: updateData,
      );

      // Adiciona logs para depuração
      print(
          "AuthRepository: Chamada PATCH concluída. Status: ${response.statusCode}");
      print(
          "AuthRepository: Tipo da Resposta Data: ${response.data?.runtimeType}"); // Verifica o tipo
      print(
          "AuthRepository: Conteúdo da Resposta Data: '${response.data}'"); // Verifica o conteúdo exato

      // --- INÍCIO DA LÓGICA DE TRATAMENTO DA RESPOSTA ---

      // 1. Verifica se o Status Code é 200 (OK)
      if (response.statusCode == 200) {
        // 2. Verifica se a resposta é um Map (JSON) - Cenário Ideal
        if (response.data != null && response.data is Map<String, dynamic>) {
          print(
              "AuthRepository: DETECTADO: Resposta é Map (JSON). Processando JSON.");
          final strapiData = response.data as Map<String, dynamic>;
          // Mapeia a resposta JSON para AppUser
          return AppUser(
            id: firebaseUser.uid,
            name: strapiData['username'] ??
                username, // Prioriza resposta, fallback para o enviado
            email: strapiData['email'] ??
                firebaseUser.email, // Prioriza resposta, fallback para o atual
            photoUrl:
                firebaseUser.photoURL, // Mantém foto atual (upload é separado)
          );
        }
        // 3. Verifica se a resposta é a string "OK" - SEU CASO ATUAL (Workaround)
        else if (response.data != null &&
            response.data.toString().trim().toUpperCase() == 'OK') {
          print(
              "AuthRepository: DETECTADO: Resposta é 'OK' text. Assumindo sucesso.");
          // Se a resposta é só "OK", assumimos que a atualização no backend deu certo.
          // Retornamos um AppUser com os dados ATUAIS do Firebase, mas com o NOME ATUALIZADO que enviamos.
          return AppUser(
            id: firebaseUser.uid, // ID atual do Firebase
            name: username, // <<< USA O NOME QUE FOI ENVIADO PARA ATUALIZAR
            email: firebaseUser.email, // Email atual do Firebase
            photoUrl: firebaseUser.photoURL, // Foto atual do Firebase
          );
        }
        // 4. Se status 200 mas a resposta não é JSON nem "OK"
        else {
          print(
              "AuthRepository: ERRO: Status 200, mas corpo da resposta inesperado: '${response.data}'");
          throw ServerException(
              message:
                  "Resposta inesperada (tipo/conteúdo) do servidor após atualização do perfil.");
        }
      }
      // 5. Se o Status Code NÃO for 200
      else {
        print(
            "AuthRepository: ERRO: Status ${response.statusCode}. Lançando ServerException.");
        // Tenta pegar alguma mensagem de erro do corpo, se houver
        String errorMsg =
            'Falha na atualização do perfil. Status: ${response.statusCode}';
        if (response.data != null) {
          errorMsg += ' Body: ${response.data}';
        }
        throw ServerException(message: errorMsg);
      }

      // --- FIM DA LÓGICA DE TRATAMENTO DA RESPOSTA ---
    } on DioException catch (e) {
      // Tratamento de erro de rede/comunicação (mantido como antes)
      print(
          'AuthRepository: Erro Dio ao atualizar perfil: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      String errorMessage = 'Falha ao atualizar perfil.';
      if (e.response?.data is Map &&
          e.response?.data['error']?['message'] != null) {
        errorMessage += ' Detalhes: ${e.response?.data['error']['message']}';
      } else if (e.message != null) {
        errorMessage += ' - ${e.message}';
      }
      throw ServerException(
          message: errorMessage); // Lança ServerException específica
    } catch (e) {
      // Pega outras exceções (incluindo ServerException dos casos acima)
      print(
          'AuthRepository: Erro inesperado ao atualizar perfil: ${e.toString()}');
      // 6. Bloco catch final refinado para relançar exceções específicas
      if (e is ServerException) {
        rethrow; // Re-lança a ServerException original com sua mensagem detalhada
      }
      // Não precisa checar DioException de novo aqui
      else {
        // Para qualquer outro tipo de erro não previsto
        throw Exception('Erro desconhecido ao tentar atualizar o perfil.');
      }
    }
  }

  @override
  Future<void> deleteAccount(
      {required String currentPassword, required int strapiUserId}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Usuário não está logado.');
    }
    if (user.email == null) {
      throw Exception('Email do usuário não encontrado para reautenticação.');
    }

    print(
        "AuthRepository: Iniciando processo de exclusão de conta para Strapi ID: $strapiUserId");

    // --- PASSO 1: Reautenticação no Firebase ---
    try {
      print("AuthRepository: Tentando reautenticar usuário...");
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      print("AuthRepository: Reautenticação bem-sucedida.");
    } on FirebaseAuthException catch (e) {
      print("AuthRepository: Falha na reautenticação - ${e.code}");
      // Re-lança o erro específico para ser tratado na UI/Store
      // Usar _handleFirebaseError para traduzir a mensagem
      throw _handleFirebaseError(
          e); // Garante que 'wrong-password' seja tratado
    } catch (e) {
      print(
          "AuthRepository: Erro inesperado na reautenticação: ${e.toString()}");
      throw Exception("Erro inesperado durante a reautenticação.");
    }

    // --- PASSO 2: Deletar do Backend (Strapi) ---
    // É uma escolha de design deletar backend ANTES ou DEPOIS do Firebase.
    // Deletar backend primeiro: se Firebase falhar, usuário fica órfão no backend.
    // Deletar Firebase primeiro: se backend falhar, usuário pode tentar de novo.
    // Vamos tentar deletar do Strapi primeiro.
    try {
      print(
          "AuthRepository: Tentando deletar usuário do Strapi (ID: $strapiUserId)...");
      await _apiClient.delete('/api/users/$strapiUserId'); // Usa o ID do Strapi
      print("AuthRepository: Usuário deletado com sucesso do Strapi.");
    } on DioException catch (e) {
      print(
          "AuthRepository: Falha ao deletar usuário do Strapi - ${e.response?.statusCode} - ${e.response?.data ?? e.message}");
      // Decide se quer parar aqui ou tentar deletar Firebase mesmo assim.
      // Vamos parar aqui para evitar inconsistência maior.
      String errorMessage = 'Falha ao remover dados do servidor.';
      if (e.response?.data is Map &&
          e.response?.data['error']?['message'] != null) {
        errorMessage += ' Detalhes: ${e.response?.data['error']['message']}';
      }
      throw ServerException(message: errorMessage);
    } catch (e) {
      print(
          "AuthRepository: Erro inesperado ao deletar do Strapi: ${e.toString()}");
      throw Exception("Erro inesperado ao remover dados do servidor.");
    }

    // --- PASSO 3: Deletar do Firebase Authentication ---
    // Só executa se a reautenticação e a exclusão do Strapi foram bem-sucedidas
    try {
      print("AuthRepository: Tentando deletar usuário do Firebase Auth...");
      await user.delete();
      print("AuthRepository: Usuário deletado com sucesso do Firebase Auth.");
    } on FirebaseAuthException catch (e) {
      // Isso pode acontecer se a reautenticação expirou muito rápido ou outro erro
      print(
          "AuthRepository: Falha ao deletar usuário do Firebase Auth - ${e.code}");
      // O usuário foi deletado do Strapi mas não do Firebase - situação ruim.
      // Pode logar isso de forma crítica.
      // Lança um erro claro para a UI.
      throw Exception(
          "Falha ao finalizar a exclusão da conta (${e.code}). Contacte o suporte.");
    } catch (e) {
      print(
          "AuthRepository: Erro inesperado ao deletar do Firebase Auth: ${e.toString()}");
      throw Exception("Erro inesperado ao finalizar a exclusão da conta.");
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
