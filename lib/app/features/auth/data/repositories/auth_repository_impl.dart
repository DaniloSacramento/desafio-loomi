import 'package:desafio_loomi/app/core/error/exception.dart';
import 'package:desafio_loomi/app/core/network/api_client.dart';
import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  Future<AppUser> signInWithGoogle() async {
    UserCredential? userCredential;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Login com Google cancelado');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception(
            'Falha ao obter usuário do Firebase após login Google.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
            'Uma conta já existe com este email, mas usando um método de login diferente.');
      }

      throw _handleFirebaseError(e);
    } on Exception catch (e) {
      debugPrint(
          "AuthRepository: Erro no fluxo Google/Firebase Sign In: ${e.toString()}");
      rethrow; // Re-lança a exceção (ex: 'Login com Google cancelado')
    } catch (e) {
      throw Exception('Falha no login com Google: ${e.toString()}');
    }

    final firebaseUser = userCredential.user!;
    final firebaseUID = firebaseUser.uid;
    final email = firebaseUser.email;
    final username = firebaseUser.displayName?.isNotEmpty == true
        ? firebaseUser.displayName
        : email?.split('@')[0];

    if (email == null || email.isEmpty) {
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após email nulo do Google."));
      throw Exception(
          'Email não fornecido pelo Google. Não é possível completar o login/registro.');
    }

    if (username == null || username.isEmpty) {
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após username inválido."));
      throw Exception('Nome de usuário não pôde ser determinado.');
    }

    final backendRegisterData = {
      "username": username,
      "email": email,
      "password":
          "GOOGLE_SIGN_IN_PLACEHOLDER_${DateTime.now().millisecondsSinceEpoch}", // <-- CONFIRMAR SE NECESSÁRIO/ACEITO
      "firebase_UID": firebaseUID
    };

    try {
      await _apiClient.post(
        '/api/auth/local/register',
        data: backendRegisterData,
      );
      return AppUser.fromFirebase(firebaseUser); // Retorna sucesso
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 400) {
        return AppUser.fromFirebase(
            firebaseUser); // Retorna sucesso (login/sync ok)
      } else {
        await firebaseUser.delete().catchError((_) => debugPrint(
            "AuthRepository: Falha ao deletar usuário Firebase após erro Dio NÃO TRATADO do Strapi."));
        throw Exception(
            'Falha ao sincronizar com o servidor (${dioError.response?.statusCode}). Detalhes: ${dioError.response?.data?['error']?['message'] ?? dioError.message}');
      }
    } catch (e) {
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após erro inesperado do Strapi."));
      throw Exception('Erro inesperado ao sincronizar com o servidor.');
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      throw UnsupportedError(
          'Sign in with Apple não é suportado nativamente nesta plataforma.');
    }

    User? firebaseUser;
    late final AuthorizationCredentialAppleID appleCredential;

    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception(
            'Login com Apple não está disponível neste dispositivo.');
      }

      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken, // Essencial
        accessToken: appleCredential.authorizationCode, // Pode ser usado também
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Falha ao obter usuário do Firebase após login Apple.');
      }
      firebaseUser = userCredential.user!;

      bool profileUpdated = false;
      String? appleName;
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        appleName =
            ('${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}')
                .trim();
        if (appleName.isNotEmpty && firebaseUser.displayName != appleName) {
          await firebaseUser.updateDisplayName(appleName).catchError((e) {});
          profileUpdated = true; // Marca que tentamos atualizar
        }
      }
      final appleEmail = appleCredential.email;
      if (appleEmail != null &&
          appleEmail.isNotEmpty &&
          firebaseUser.email != appleEmail) {}

      if (profileUpdated) {
        try {
          debugPrint("AuthRepository: Recarregando usuário Firebase...");
          await firebaseUser.reload();
          final updatedFirebaseUser = _firebaseAuth.currentUser;
          if (updatedFirebaseUser == null) {
            throw Exception(
                'Falha ao obter usuário atualizado do Firebase após reload.');
          }
          firebaseUser = updatedFirebaseUser;
        } catch (e) {
          debugPrint(
              "AuthRepository: Erro ao recarregar usuário Firebase: $e. Continuando com dados anteriores.");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
            'Uma conta já existe com este email, mas usando um método de login diferente.');
      }
      throw _handleFirebaseError(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      // Captura erros específicos da autorização da Apple (ex: cancelado pelo usuário)
      debugPrint(
          "AuthRepository: Erro de autorização Apple Sign In: ${e.code} - ${e.message}");
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Login com Apple cancelado');
      } else if (e.code == AuthorizationErrorCode.notInteractive) {
        throw Exception(
            'Login com Apple requer interação do usuário.'); // Pode acontecer em contextos específicos
      }
      throw Exception(
          'Falha na autorização com Apple: ${e.message}'); // Outros erros de autorização
    } catch (e) {
      // Captura outros erros durante o fluxo Apple/Firebase (ex: disponibilidade, credencial inválida antes do Firebase)
      debugPrint(
          "AuthRepository: Erro genérico no fluxo Apple/Firebase Sign In: ${e.toString()}");
      // Não deletar usuário aqui, pois pode não ter sido criado/logado ainda
      throw Exception('Falha no login com Apple: ${e.toString()}');
    }

    if (firebaseUser == null) {
      throw Exception(
          "Erro inesperado: Usuário Firebase nulo após fluxo de login bem-sucedido.");
    }

    final firebaseUID = firebaseUser.uid;
    final email = (appleCredential.email != null &&
            appleCredential.email!.isNotEmpty &&
            appleCredential.email != firebaseUser.email)
        ? appleCredential.email
        : firebaseUser.email; // Usa o email associado à conta Firebase
    final username = firebaseUser.displayName?.isNotEmpty == true
        ? firebaseUser.displayName
        : email?.split('@')[0];

    if (email == null || email.isEmpty) {
      debugPrint(
          "AuthRepository: Email não obtido da Apple/Firebase. Não é possível sincronizar com o backend Strapi.");
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após email nulo da Apple."));
      throw Exception(
          'Não foi possível obter seu email da Apple ou Firebase. Tente outro método de login.');
    }

    if (username == null || username.isEmpty) {
      debugPrint(
          "AuthRepository: Não foi possível determinar um username válido para Apple Sign In.");
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após username inválido da Apple."));
      throw Exception('Nome de usuário não pôde ser determinado.');
    }

    final backendRegisterData = {
      "username": username,
      "email":
          email, // Usa o email que determinamos (pode ser o da Apple ou Firebase)
      "password":
          "APPLE_SIGN_IN_PLACEHOLDER_${DateTime.now().millisecondsSinceEpoch}", // <-- CONFIRMAR SE NECESSÁRIO/ACEITO
      "firebase_UID": firebaseUID
    };

    try {
      debugPrint(
          'AuthRepository: Tentando sincronizar/registrar Apple User no Strapi via /auth/local/register para UID: $firebaseUID');
      await _apiClient.post(
        '/api/auth/local/register', // VERIFIQUE SE ESTE É O ENDPOINT CORRETO NO STRAPI
        data: backendRegisterData,
      );
      debugPrint(
          'AuthRepository: Sincronização/Registro Strapi (Apple) bem-sucedida (Status 2xx).');
      return AppUser.fromFirebase(
          firebaseUser); // Retorna AppUser com base no firebaseUser final
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 400) {
        debugPrint(
            'AuthRepository: Backend Strapi retornou 400 (Apple). Resposta: ${dioError.response?.data}');
        debugPrint(
            'AuthRepository: Assumindo erro 400 como usuário existente (Apple). Login/Sincronização OK.');
        return AppUser.fromFirebase(firebaseUser); // Sucesso (login/sync ok)
      } else {
        debugPrint(
            'AuthRepository: Erro Dio NÃO TRATADO (${dioError.response?.statusCode}) ao sincronizar Apple User com Strapi: ${dioError.response?.data ?? dioError.message}');
        await firebaseUser.delete().catchError((_) => debugPrint(
            "AuthRepository: Falha ao deletar usuário Firebase após erro Dio NÃO TRATADO do Strapi (Apple)."));
        throw Exception(
            'Falha ao sincronizar Apple User com o servidor (${dioError.response?.statusCode}). Detalhes: ${dioError.response?.data?['error']?['message'] ?? dioError.message}');
      }
    } catch (e) {
      debugPrint(
          'AuthRepository: Erro inesperado ao sincronizar Apple User com Strapi: ${e.toString()}');
      // DELETA o usuário do Firebase para consistência
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após erro inesperado do Strapi (Apple)."));
      throw Exception(
          'Erro inesperado ao sincronizar Apple User com o servidor.');
    }
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
        throw Exception('Email do usuário não encontrado para reautenticação.');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
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

    try {
      final firebaseUser = userCredential.user!;
      final username = firebaseUser.displayName ??
          email.split(
              '@')[0]; // Use o nome do display OU parte do email como default
      final firebaseUID = firebaseUser.uid;

      final backendRegisterData = {
        "username":
            username, // Considere pegar um nome de usuário inicial de outra forma se necessário
        "email": email,
        "password":
            password, // IMPORTANTE: Verifique se sua API *realmente* precisa da senha aqui. Se a auth é só Firebase, isso pode ser inseguro ou desnecessário. Talvez um placeholder? CONFIRME ISSO.
        "firebase_UID": firebaseUID
      };

      await _apiClient.post(
        '/api/auth/local/register', // Endpoint de registro do backend
        data: backendRegisterData,
      );

      return AppUser.fromFirebase(firebaseUser);
    } on DioException catch (dioError) {
      await userCredential.user?.delete();
      throw Exception(
          'Falha ao registrar usuário no servidor backend após cadastro no Firebase. Detalhes: ${dioError.response?.data ?? dioError.message}');
    } catch (e) {
      await userCredential.user?.delete(); // Tenta deletar do Firebase
      throw Exception(
          'Erro inesperado ao sincronizar usuário com servidor backend.');
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
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception(
          "Usuário Firebase não encontrado para atualização do perfil.");
    }
    try {
      final updateData = {
        "data": {
          "username": username,
        }
      };

      final response = await _apiClient.patch(
        '/api/users/updateMe',
        data: updateData,
      );
      if (response.statusCode == 200) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final strapiData = response.data as Map<String, dynamic>;
          return AppUser(
            id: firebaseUser.uid,
            name: strapiData['username'] ?? username,
            email: strapiData['email'] ?? firebaseUser.email,
            photoUrl: firebaseUser.photoURL,
          );
        } else if (response.data != null &&
            response.data.toString().trim().toUpperCase() == 'OK') {
          return AppUser(
            id: firebaseUser.uid,
            name: username,
            email: firebaseUser.email,
            photoUrl: firebaseUser.photoURL,
          );
        } else {
          print(
              "AuthRepository: ERRO: Status 200, mas corpo da resposta inesperado: '${response.data}'");
          throw ServerException(
              message:
                  "Resposta inesperada (tipo/conteúdo) do servidor após atualização do perfil.");
        }
      } else {
        String errorMsg =
            'Falha na atualização do perfil. Status: ${response.statusCode}';
        if (response.data != null) {
          errorMsg += ' Body: ${response.data}';
        }
        throw ServerException(message: errorMsg);
      }
    } on DioException catch (e) {
      String errorMessage = 'Falha ao atualizar perfil.';
      if (e.response?.data is Map &&
          e.response?.data['error']?['message'] != null) {
        errorMessage += ' Detalhes: ${e.response?.data['error']['message']}';
      } else if (e.message != null) {
        errorMessage += ' - ${e.message}';
      }
      throw ServerException(message: errorMessage);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      } else {
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

    try {
      print("AuthRepository: Tentando reautenticar usuário...");
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(
          e); // Garante que 'wrong-password' seja tratado
    } catch (e) {
      throw Exception("Erro inesperado durante a reautenticação.");
    }

    try {
      await _apiClient.delete('/api/users/$strapiUserId'); // Usa o ID do Strapi
    } on DioException catch (e) {
      String errorMessage = 'Falha ao remover dados do servidor.';
      if (e.response?.data is Map &&
          e.response?.data['error']?['message'] != null) {
        errorMessage += ' Detalhes: ${e.response?.data['error']['message']}';
      }
      throw ServerException(message: errorMessage);
    } catch (e) {
      throw Exception("Erro inesperado ao remover dados do servidor.");
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(
          "Falha ao finalizar a exclusão da conta (${e.code}). Contacte o suporte.");
    } catch (e) {
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
