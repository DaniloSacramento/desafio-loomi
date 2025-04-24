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
    UserCredential? userCredential; // Use nullable type initially

    // 1. Processo de Login Google + Firebase
    try {
      debugPrint("AuthRepository: Iniciando signInWithGoogle");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint(
            "AuthRepository: Google Sign In cancelado pelo usu\u00E1rio.");
        throw Exception('Login com Google cancelado'); // Throw early
      }
      debugPrint("AuthRepository: Google User obtido: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint("AuthRepository: Google Authentication obtida.");

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint(
          "AuthRepository: Tentando signInWithCredential no Firebase...");
      userCredential =
          await _firebaseAuth.signInWithCredential(credential); // Assign here
      debugPrint(
          "AuthRepository: signInWithCredential Firebase bem-sucedido. User ID: ${userCredential.user?.uid}");

      if (userCredential.user == null) {
        // Should not happen if signInWithCredential succeeded, but check anyway
        throw Exception(
            'Falha ao obter usuário do Firebase após login Google.');
      }
    } on FirebaseAuthException catch (e) {
      // Catch Firebase specific errors
      debugPrint(
          "AuthRepository: Erro FirebaseAuthException no Google Sign In: ${e.code} - ${e.message}");
      throw _handleFirebaseError(e); // Use your handler
    } catch (e) {
      // Catch other errors during Google/Firebase flow
      debugPrint(
          "AuthRepository: Erro gen\u00E9rico no fluxo Google/Firebase Sign In: ${e.toString()}");
      throw Exception('Falha no login com Google: ${e.toString()}');
    }

    // --- 2. Sincronização com o Backend (Strapi) ---
    // Só executa se o login Firebase deu certo e temos userCredential
    final firebaseUser =
        userCredential.user!; // Not null because of checks above
    final firebaseUID = firebaseUser.uid;
    final email = firebaseUser.email;
    // Usa o nome vindo do Google (já sincronizado com Firebase) ou deriva do email
    final username = firebaseUser.displayName?.isNotEmpty == true
        ? firebaseUser.displayName
        : email?.split('@')[0];

    // Validação Crítica: Email é necessário para o registro no Strapi
    if (email == null || email.isEmpty) {
      debugPrint(
          "AuthRepository: Email n\u00E3o obtido do Google/Firebase. N\u00E3o \u00E9 poss\u00EDvel sincronizar com o backend.");
      // Deleta o usuário do Firebase criado/logado via Google, pois não podemos registrar no Strapi
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após email nulo do Google.")); // Tenta deletar
      throw Exception(
          'Email n\u00E3o fornecido pelo Google. N\u00E3o \u00E9 poss\u00EDvel completar o login/registro.');
    }

    // Validação do Username (caso o email não tenha '@')
    if (username == null || username.isEmpty) {
      debugPrint(
          "AuthRepository: N\u00E3o foi poss\u00EDvel determinar um username v\u00E1lido.");
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após username inv\u00E1lido.")); // Tenta deletar
      throw Exception(
          'Nome de usu\u00E1rio n\u00E3o p\u00F4de ser determinado.');
    }

    // Prepara dados para o Strapi
    final backendRegisterData = {
      "username": username,
      "email": email,
      // Senha placeholder - confirme se Strapi ignora isso com firebase_UID
      "password":
          "GOOGLE_SIGN_IN_PLACEHOLDER_${DateTime.now().millisecondsSinceEpoch}",
      "firebase_UID": firebaseUID
    };

    // 3. Tenta chamar o backend Strapi POST /api/auth/local/register
    try {
      debugPrint(
          'AuthRepository: Tentando sincronizar/registrar no backend (Strapi) via /auth/local/register para UID: $firebaseUID');
      await _apiClient.post(
        '/api/auth/local/register',
        data: backendRegisterData,
      );
      debugPrint(
          'AuthRepository: Sincroniza\u00E7\u00E3o/Registro no backend bem-sucedida (Status 2xx).');
      // Se chegou aqui, tudo certo (ou era um usuário novo ou um existente que foi apenas "sincronizado")
      return AppUser.fromFirebase(firebaseUser); // Retorna sucesso
    } on DioException catch (dioError) {
      // Verifica se o erro é 400 (provável usuário existente)
      // Idealmente, verificar a mensagem de erro específica do Strapi se possível
      if (dioError.response?.statusCode ==
          400 /* && dioError.response?.data['error']?['message']?.contains('already taken') */) {
        debugPrint(
            'AuthRepository: Backend Strapi retornou ${dioError.response?.statusCode}. Usu\u00E1rio provavelmente j\u00E1 existe (UID: $firebaseUID). Login/Sincroniza\u00E7\u00E3o OK.');
        // IGNORA O ERRO 400 - Consideramos sucesso, pois o usuário existe e está logado no Firebase
        return AppUser.fromFirebase(firebaseUser); // Retorna sucesso
      } else {
        // Outro erro do Dio (500, 401, 403, timeout, etc.) -> PROBLEMA REAL
        debugPrint(
            'AuthRepository: Erro Dio N\u00C3O TRATADO (${dioError.response?.statusCode}) ao sincronizar com Strapi: ${dioError.response?.data ?? dioError.message}');
        // DELETA o usuário do Firebase para consistência
        await firebaseUser.delete().catchError((_) => debugPrint(
            "AuthRepository: Falha ao deletar usuário Firebase após erro Dio N\u00C3O TRATADO do Strapi."));
        throw Exception(
            'Falha ao sincronizar com o servidor (${dioError.response?.statusCode}). Detalhes: ${dioError.response?.data?['error']?['message'] ?? dioError.message}');
      }
    } catch (e) {
      // Outro erro inesperado durante a chamada ao Strapi
      debugPrint(
          'AuthRepository: Erro inesperado ao sincronizar com Strapi: ${e.toString()}');
      // DELETA o usuário do Firebase para consistência
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após erro inesperado do Strapi."));
      throw Exception('Erro inesperado ao sincronizar com o servidor.');
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    UserCredential? userCredential; // Nullable inicial

    // 1. Processo de Login Apple + Firebase
    try {
      debugPrint("AuthRepository: Iniciando signInWithApple");
      // Solicita credenciais da Apple (incluindo email e nome completo)
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      debugPrint("AuthRepository: Credencial Apple obtida.");

      // Cria credencial OAuth para Firebase
      final oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken, // Essencial
        // rawNonce: appleCredential.nonce, // Adicione se você gerar e usar nonces
        accessToken:
            appleCredential.authorizationCode, // Ou accessToken se aplicável
      );

      debugPrint(
          "AuthRepository: Tentando signInWithCredential no Firebase...");
      userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint(
          "AuthRepository: signInWithCredential Firebase bem-sucedido. User ID: ${userCredential.user?.uid}");

      if (userCredential.user == null) {
        throw Exception('Falha ao obter usuário do Firebase após login Apple.');
      }

      // Tenta atualizar nome/email no Firebase com dados da Apple (só vem na primeira vez geralmente)
      final firebaseUser = userCredential.user!;
      bool profileUpdated = false;
      String? appleName;
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        appleName =
            ('${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}')
                .trim();
        if (appleName.isNotEmpty && firebaseUser.displayName != appleName) {
          debugPrint(
              "AuthRepository: Atualizando displayName no Firebase com nome da Apple: $appleName");
          await firebaseUser.updateDisplayName(appleName);
          profileUpdated = true;
        }
      }
      // Email da Apple (pode ser nulo ou o relay privado)
      final appleEmail = appleCredential.email;
      if (appleEmail != null &&
          appleEmail.isNotEmpty &&
          firebaseUser.email != appleEmail) {
        // Cuidado: Atualizar email pode exigir verificação
        // Por segurança, vamos apenas logar por enquanto se for diferente
        debugPrint(
            "AuthRepository: Email da Apple ($appleEmail) diferente do Firebase (${firebaseUser.email}). Atualização manual pode ser necessária se desejado.");
        // await firebaseUser.updateEmail(appleEmail); // NÃO FAZER SEM REAUTENTICAÇÃO/VERIFICAÇÃO
        // profileUpdated = true;
      }

      // Recarrega o usuário se o perfil foi atualizado para pegar os dados mais recentes
      if (profileUpdated) {
        await firebaseUser.reload();
        userCredential = await _firebaseAuth
            .signInWithCredential(credential); // Re-obtém credencial atualizada
        debugPrint(
            "AuthRepository: Usuário Firebase recarregado após atualização do perfil.");
        if (userCredential.user == null)
          throw Exception(
              'Falha ao recarregar usuário Firebase.'); // Check de novo
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          "AuthRepository: Erro FirebaseAuthException no Apple Sign In: ${e.code} - ${e.message}");
      throw _handleFirebaseError(e);
    } catch (e) {
      debugPrint(
          "AuthRepository: Erro gen\u00E9rico no fluxo Apple/Firebase Sign In: ${e.toString()}");
      // Pode ser erro de configuração nativa, usuário cancelou, etc.
      throw Exception('Falha no login com Apple: ${e.toString()}');
    }

    // --- 2. Sincronização com o Backend (Strapi) ---
    final firebaseUser = userCredential.user!; // Not null
    final firebaseUID = firebaseUser.uid;
    final email =
        firebaseUser.email; // Pode ser nulo se a Apple não fornecer/esconder
    // Usa o nome do Firebase (que tentamos atualizar com o da Apple) ou deriva do email
    final username = firebaseUser.displayName?.isNotEmpty == true
        ? firebaseUser.displayName
        : email?.split('@')[0];

    // Validação Crítica: Email
    if (email == null || email.isEmpty) {
      debugPrint(
          "AuthRepository: Email n\u00E3o obtido da Apple/Firebase. N\u00E3o \u00E9 poss\u00EDvel sincronizar com o backend Strapi.");
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após email nulo da Apple."));
      throw Exception(
          'Email n\u00E3o fornecido pela Apple. N\u00E3o \u00E9 poss\u00EDvel completar o login/registro.');
    }

    // Validação Username
    if (username == null || username.isEmpty) {
      debugPrint(
          "AuthRepository: N\u00E3o foi poss\u00EDvel determinar um username v\u00E1lido para Apple Sign In.");
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após username inv\u00E1lido da Apple."));
      throw Exception(
          'Nome de usu\u00E1rio n\u00E3o p\u00F4de ser determinado.');
    }

    // Prepara dados para Strapi
    final backendRegisterData = {
      "username": username,
      "email": email,
      "password":
          "APPLE_SIGN_IN_PLACEHOLDER_${DateTime.now().millisecondsSinceEpoch}",
      "firebase_UID": firebaseUID
    };

    // 3. Tenta chamar o backend Strapi POST /api/auth/local/register
    try {
      debugPrint(
          'AuthRepository: Tentando sincronizar/registrar Apple User no Strapi via /auth/local/register para UID: $firebaseUID');
      await _apiClient.post(
        '/api/auth/local/register',
        data: backendRegisterData,
      );
      debugPrint(
          'AuthRepository: Sincroniza\u00E7\u00E3o/Registro Strapi (Apple) bem-sucedida (Status 2xx).');
      return AppUser.fromFirebase(firebaseUser); // Sucesso
    } on DioException catch (dioError) {
      // Trata erro 400 como usuário existente (sucesso para login/sync)
      if (dioError.response?.statusCode == 400) {
        debugPrint(
            'AuthRepository: Backend Strapi retornou ${dioError.response?.statusCode} (Apple). Usu\u00E1rio provavelmente j\u00E1 existe. Login/Sincroniza\u00E7\u00E3o OK.');
        return AppUser.fromFirebase(firebaseUser); // Sucesso
      } else {
        // Outro erro Dio
        debugPrint(
            'AuthRepository: Erro Dio N\u00C3O TRATADO (${dioError.response?.statusCode}) ao sincronizar Apple User com Strapi: ${dioError.response?.data ?? dioError.message}');
        await firebaseUser.delete().catchError((_) => debugPrint(
            "AuthRepository: Falha ao deletar usuário Firebase após erro Dio N\u00C3O TRATADO do Strapi (Apple)."));
        throw Exception(
            'Falha ao sincronizar Apple User com o servidor (${dioError.response?.statusCode}). Detalhes: ${dioError.response?.data?['error']?['message'] ?? dioError.message}');
      }
    } catch (e) {
      // Outro erro inesperado
      debugPrint(
          'AuthRepository: Erro inesperado ao sincronizar Apple User com Strapi: ${e.toString()}');
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após erro inesperado do Strapi (Apple)."));
      throw Exception(
          'Erro inesperado ao sincronizar Apple User com o servidor.');
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
