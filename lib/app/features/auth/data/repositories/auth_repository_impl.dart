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
    UserCredential? userCredential; // Use nullable type initially

    // 1. Processo de Login Google + Firebase
    try {
      debugPrint("AuthRepository: Iniciando signInWithGoogle");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("AuthRepository: Google Sign In cancelado pelo usuário.");
        // Lança exceção específica para cancelamento se desejar, ou uma genérica
        throw Exception('Login com Google cancelado');
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
      userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint(
          "AuthRepository: signInWithCredential Firebase bem-sucedido. User ID: ${userCredential.user?.uid}");

      if (userCredential.user == null) {
        throw Exception(
            'Falha ao obter usuário do Firebase após login Google.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          "AuthRepository: Erro FirebaseAuthException no Google Sign In: ${e.code} - ${e.message}");
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
            'Uma conta já existe com este email, mas usando um método de login diferente.');
      }
      // Adicione outros tratamentos específicos se necessário
      throw _handleFirebaseError(e); // Use seu handler
    } on Exception catch (e) {
      // Captura a exceção de cancelamento ou outras
      debugPrint(
          "AuthRepository: Erro no fluxo Google/Firebase Sign In: ${e.toString()}");
      rethrow; // Re-lança a exceção (ex: 'Login com Google cancelado')
    } catch (e) {
      debugPrint(
          "AuthRepository: Erro genérico inesperado no fluxo Google/Firebase Sign In: ${e.toString()}");
      throw Exception('Falha no login com Google: ${e.toString()}');
    }

    // --- 2. Sincronização com o Backend (Strapi) ---
    // Só executa se o login Firebase deu certo e temos userCredential
    final firebaseUser =
        userCredential.user!; // Not null por causa das checagens anteriores
    final firebaseUID = firebaseUser.uid;
    final email = firebaseUser.email;
    final username = firebaseUser.displayName?.isNotEmpty == true
        ? firebaseUser.displayName
        : email?.split('@')[0];

    if (email == null || email.isEmpty) {
      debugPrint(
          "AuthRepository: Email não obtido do Google/Firebase. Não é possível sincronizar com o backend.");
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após email nulo do Google."));
      throw Exception(
          'Email não fornecido pelo Google. Não é possível completar o login/registro.');
    }

    if (username == null || username.isEmpty) {
      debugPrint(
          "AuthRepository: Não foi possível determinar um username válido.");
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após username inválido."));
      throw Exception('Nome de usuário não pôde ser determinado.');
    }

    // Prepara dados para o Strapi
    // !!! VERIFICAÇÃO IMPORTANTE !!!
    // Seu backend Strapi REALMENTE precisa/aceita o campo "password" ao registrar/sincronizar
    // um usuário via Firebase UID? Se ele ignora ou se baseia apenas no firebase_UID,
    // enviar um placeholder pode ser desnecessário ou até causar erro 400.
    // CONFIRME A LÓGICA DO SEU ENDPOINT `/api/auth/local/register` NO STRAPI.
    final backendRegisterData = {
      "username": username,
      "email": email,
      "password":
          "GOOGLE_SIGN_IN_PLACEHOLDER_${DateTime.now().millisecondsSinceEpoch}", // <-- CONFIRMAR SE NECESSÁRIO/ACEITO
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
          'AuthRepository: Sincronização/Registro no backend bem-sucedida (Status 2xx).');
      return AppUser.fromFirebase(firebaseUser); // Retorna sucesso
    } on DioException catch (dioError) {
      // Verifica se o erro é 400 (provável usuário existente OU erro de validação no Strapi)
      if (dioError.response?.statusCode == 400) {
        // LOG DETALHADO para entender o erro 400
        debugPrint(
            'AuthRepository: Backend Strapi retornou 400. Resposta: ${dioError.response?.data}');
        // Verifica se a mensagem de erro INDICA que o usuário já existe (adapte conforme a resposta do seu Strapi)
        // Exemplo: if (dioError.response?.data['error']?['message']?.contains('already taken')) { ... }
        // POR ENQUANTO, vamos manter a lógica original de assumir que 400 é "usuário existe"
        debugPrint(
            'AuthRepository: Assumindo erro 400 como usuário existente (UID: $firebaseUID). Login/Sincronização OK.');
        return AppUser.fromFirebase(
            firebaseUser); // Retorna sucesso (login/sync ok)
      } else {
        // Outro erro do Dio (500, 401, 403, timeout, etc.) -> PROBLEMA REAL
        debugPrint(
            'AuthRepository: Erro Dio NÃO TRATADO (${dioError.response?.statusCode}) ao sincronizar com Strapi: ${dioError.response?.data ?? dioError.message}');
        await firebaseUser.delete().catchError((_) => debugPrint(
            "AuthRepository: Falha ao deletar usuário Firebase após erro Dio NÃO TRATADO do Strapi."));
        throw Exception(
            'Falha ao sincronizar com o servidor (${dioError.response?.statusCode}). Detalhes: ${dioError.response?.data?['error']?['message'] ?? dioError.message}');
      }
    } catch (e) {
      debugPrint(
          'AuthRepository: Erro inesperado ao sincronizar com Strapi: ${e.toString()}');
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após erro inesperado do Strapi."));
      throw Exception('Erro inesperado ao sincronizar com o servidor.');
    }
  }
// Dentro da classe AuthRepositoryImpl

// NOVA IMPLEMENTAÇÃO signInWithApple - COMPLETA E CORRIGIDA
  @override
  Future<AppUser> signInWithApple() async {
    // IMPORTANTE: Este método só deve ser chamado em plataformas Apple (iOS/macOS)
    // A UI deve garantir isso (ex: usando Platform.isIOS ou defaultTargetPlatform).
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      // Lança um erro claro se chamado na plataforma errada
      throw UnsupportedError(
          'Sign in with Apple não é suportado nativamente nesta plataforma.');
    }

    // Variável para guardar o usuário Firebase, inicializada como nula
    User? firebaseUser;
    // Variável para guardar a credencial original da Apple
    late final AuthorizationCredentialAppleID
        appleCredential; // Usamos late final pois será inicializada no try

    // 1. Processo de Login Apple + Firebase
    try {
      debugPrint("AuthRepository: Iniciando signInWithApple");
      // Verifica disponibilidade ANTES de tentar (boa prática)
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception(
            'Login com Apple não está disponível neste dispositivo.');
      }

      // --- Obter Credencial da Apple ---
      // Solicita credenciais da Apple (incluindo email e nome completo)
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // webAuthenticationOptions: null, // Não necessário/usado em plataformas Apple nativas
        // Nonce (opcional mas recomendado): Adicionar lógica de geração e validação de nonce aqui se necessário
      );
      debugPrint("AuthRepository: Credencial Apple obtida.");

      // --- Criar Credencial Firebase ---
      final oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken, // Essencial
        accessToken: appleCredential.authorizationCode, // Pode ser usado também
        // rawNonce: rawNonce, // Se estiver usando nonce
      );

      // --- Autenticar no Firebase ---
      debugPrint(
          "AuthRepository: Tentando signInWithCredential no Firebase...");
      // Tenta autenticar ou vincular no Firebase
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      debugPrint(
          "AuthRepository: signInWithCredential Firebase bem-sucedido. User ID: ${userCredential.user?.uid}");

      // Verifica se o usuário foi retornado
      if (userCredential.user == null) {
        // Isso não deve acontecer se signInWithCredential for bem-sucedido, mas checamos
        throw Exception('Falha ao obter usuário do Firebase após login Apple.');
      }
      // Define nossa variável firebaseUser com o usuário obtido
      firebaseUser = userCredential.user!;

      // --- Tentar Atualizar Perfil Firebase (Opcional) ---
      // Tenta atualizar nome/email no Firebase com dados da Apple (só vem na primeira vez geralmente)
      bool profileUpdated = false;
      String? appleName;
      // Verifica e tenta atualizar Nome
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        appleName =
            ('${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}')
                .trim();
        // Atualiza apenas se o nome da Apple não estiver vazio e for diferente do nome atual no Firebase
        if (appleName.isNotEmpty && firebaseUser.displayName != appleName) {
          debugPrint(
              "AuthRepository: Atualizando displayName no Firebase com nome da Apple: $appleName");
          // Tenta atualizar, mas não interrompe o fluxo se falhar
          await firebaseUser.updateDisplayName(appleName).catchError((e) {
            debugPrint(
                "AuthRepository: Falha ao atualizar displayName no Firebase: $e");
          });
          profileUpdated = true; // Marca que tentamos atualizar
        }
      }
      // Apenas loga o email da Apple se diferente (não tenta atualizar sem reautenticação)
      final appleEmail = appleCredential.email;
      if (appleEmail != null &&
          appleEmail.isNotEmpty &&
          firebaseUser.email != appleEmail) {
        debugPrint(
            "AuthRepository: Email da Apple ($appleEmail) obtido. Email atual Firebase: (${firebaseUser.email}).");
        // Poderíamos considerar usar o appleEmail na sincronização Strapi se o firebaseUser.email for nulo ou um relay.
      }

      // --- Recarregar Usuário Firebase se Perfil foi Atualizado ---
      // Se tentamos atualizar o perfil (nome), recarregamos para garantir que temos os dados mais recentes
      if (profileUpdated) {
        try {
          debugPrint("AuthRepository: Recarregando usuário Firebase...");
          await firebaseUser.reload();
          // Pega a instância do usuário MAIS ATUALIZADA diretamente do FirebaseAuth
          final updatedFirebaseUser = _firebaseAuth.currentUser;
          if (updatedFirebaseUser == null) {
            // Se o reload funcionou, currentUser não deveria ser nulo
            throw Exception(
                'Falha ao obter usuário atualizado do Firebase após reload.');
          }
          // ATUALIZA a variável local 'firebaseUser' para a versão mais recente
          firebaseUser = updatedFirebaseUser;
          debugPrint(
              "AuthRepository: Usuário Firebase recarregado. Novo nome: ${firebaseUser.displayName}");
        } catch (e) {
          // Se o reload falhar, logamos o erro mas continuamos com o 'firebaseUser' que tínhamos antes
          debugPrint(
              "AuthRepository: Erro ao recarregar usuário Firebase: $e. Continuando com dados anteriores.");
        }
      }
      // Neste ponto, 'firebaseUser' contém a instância mais atualizada possível do usuário Firebase

      // --- Tratamento de Erros Específicos ---
      // Captura erros durante o fluxo Apple/Firebase
    } on FirebaseAuthException catch (e) {
      debugPrint(
          "AuthRepository: Erro FirebaseAuthException no Apple Sign In: ${e.code} - ${e.message}");
      if (e.code == 'account-exists-with-different-credential') {
        // Erro comum se o usuário já se cadastrou com Google ou Email/Senha usando o mesmo email
        throw Exception(
            'Uma conta já existe com este email, mas usando um método de login diferente.');
      }
      // Se o erro ocorreu aqui, firebaseUser pode não ter sido definido.
      // Não tentamos deletar, pois o login/criação não foi completado no Firebase.
      throw _handleFirebaseError(
          e); // Usa o handler customizado para traduzir o erro
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

    // --- 2. Sincronização com o Backend (Strapi) ---
    // Só chegamos aqui se o login/criação no Firebase foi BEM SUCEDIDO e temos um 'firebaseUser' válido.

    // Se firebaseUser ainda for nulo (verificação extra de segurança, não deveria acontecer)
    if (firebaseUser == null) {
      throw Exception(
          "Erro inesperado: Usuário Firebase nulo após fluxo de login bem-sucedido.");
    }

    // Prepara dados para enviar ao Strapi
    final firebaseUID = firebaseUser.uid;
    // Prioriza email vindo diretamente da Apple se disponível e diferente do Firebase, senão usa o do Firebase
    // Isso pode ajudar se o usuário usou o relay da Apple e temos o email real aqui.
    final email = (appleCredential.email != null &&
            appleCredential.email!.isNotEmpty &&
            appleCredential.email != firebaseUser.email)
        ? appleCredential.email
        : firebaseUser.email; // Usa o email associado à conta Firebase
    // Usa o nome do Firebase (que tentamos atualizar com o da Apple)
    final username = firebaseUser.displayName?.isNotEmpty == true
        ? firebaseUser.displayName
        : email?.split(
            '@')[0]; // Fallback para parte do email se nome não disponível

    // Validação Crítica: Email é necessário para o Strapi (conforme sua lógica)
    if (email == null || email.isEmpty) {
      debugPrint(
          "AuthRepository: Email não obtido da Apple/Firebase. Não é possível sincronizar com o backend Strapi.");
      // Deleta o usuário recém-criado/logado no Firebase, pois não podemos prosseguir sem email para Strapi
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após email nulo da Apple."));
      // Informa o usuário sobre o problema
      throw Exception(
          'Não foi possível obter seu email da Apple ou Firebase. Tente outro método de login.');
    }

    // Validação Username (se necessário para Strapi)
    if (username == null || username.isEmpty) {
      debugPrint(
          "AuthRepository: Não foi possível determinar um username válido para Apple Sign In.");
      // Deleta o usuário Firebase se username for obrigatório no Strapi e não puder ser determinado
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após username inválido da Apple."));
      throw Exception('Nome de usuário não pôde ser determinado.');
    }

    // Prepara dados para Strapi
    // !!! VERIFICAÇÃO IMPORTANTE !!!
    // Seu backend Strapi REALMENTE precisa/aceita o campo "password" ao registrar/sincronizar
    // um usuário via Firebase UID? Se ele ignora ou se baseia apenas no firebase_UID,
    // enviar um placeholder pode ser desnecessário ou até causar erro 400.
    // CONFIRME A LÓGICA DO SEU ENDPOINT `/api/auth/local/register` NO STRAPI.
    final backendRegisterData = {
      "username": username,
      "email":
          email, // Usa o email que determinamos (pode ser o da Apple ou Firebase)
      "password":
          "APPLE_SIGN_IN_PLACEHOLDER_${DateTime.now().millisecondsSinceEpoch}", // <-- CONFIRMAR SE NECESSÁRIO/ACEITO
      "firebase_UID": firebaseUID
    };

    // 3. Tenta chamar o backend Strapi POST /api/auth/local/register
    try {
      debugPrint(
          'AuthRepository: Tentando sincronizar/registrar Apple User no Strapi via /auth/local/register para UID: $firebaseUID');
      // Assumindo que seu ApiClient injeta o token Firebase via interceptor
      await _apiClient.post(
        '/api/auth/local/register', // VERIFIQUE SE ESTE É O ENDPOINT CORRETO NO STRAPI
        data: backendRegisterData,
      );
      debugPrint(
          'AuthRepository: Sincronização/Registro Strapi (Apple) bem-sucedida (Status 2xx).');
      // Se chegou aqui, Firebase e Strapi (ou sync) OK.
      return AppUser.fromFirebase(
          firebaseUser); // Retorna AppUser com base no firebaseUser final
    } on DioException catch (dioError) {
      // Trata erro 400 como usuário existente (sucesso para login/sync) - ADAPTE CONFORME SUA API
      if (dioError.response?.statusCode == 400) {
        // Log detalhado para entender o 400
        debugPrint(
            'AuthRepository: Backend Strapi retornou 400 (Apple). Resposta: ${dioError.response?.data}');
        // Idealmente, verificar a mensagem específica de erro 400 do Strapi aqui
        // Ex: if (dioError.response?.data['error']?['message']?.contains('already taken'))
        debugPrint(
            'AuthRepository: Assumindo erro 400 como usuário existente (Apple). Login/Sincronização OK.');
        // Considera sucesso, pois o usuário existe no Strapi e está logado no Firebase
        return AppUser.fromFirebase(firebaseUser); // Sucesso (login/sync ok)
      } else {
        // Outro erro Dio -> PROBLEMA REAL
        debugPrint(
            'AuthRepository: Erro Dio NÃO TRATADO (${dioError.response?.statusCode}) ao sincronizar Apple User com Strapi: ${dioError.response?.data ?? dioError.message}');
        // DELETA o usuário do Firebase para consistência, pois Strapi falhou
        await firebaseUser.delete().catchError((_) => debugPrint(
            "AuthRepository: Falha ao deletar usuário Firebase após erro Dio NÃO TRATADO do Strapi (Apple)."));
        // Lança uma exceção clara
        throw Exception(
            'Falha ao sincronizar Apple User com o servidor (${dioError.response?.statusCode}). Detalhes: ${dioError.response?.data?['error']?['message'] ?? dioError.message}');
      }
    } catch (e) {
      // Outro erro inesperado durante a chamada ao Strapi
      debugPrint(
          'AuthRepository: Erro inesperado ao sincronizar Apple User com Strapi: ${e.toString()}');
      // DELETA o usuário do Firebase para consistência
      await firebaseUser.delete().catchError((_) => debugPrint(
          "AuthRepository: Falha ao deletar usuário Firebase após erro inesperado do Strapi (Apple)."));
      throw Exception(
          'Erro inesperado ao sincronizar Apple User com o servidor.');
    }
  } // Fim do método signInWithApple

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
