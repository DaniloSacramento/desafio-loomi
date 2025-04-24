// features/auth/presentation/store/auth_store.dart

import 'package:desafio_loomi/app/core/network/api_client.dart';
import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobx/mobx.dart';
import 'package:dio/dio.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStoreBase with _$AuthStore;

abstract class _AuthStoreBase with Store {
  final AuthRepository authRepository;
  final ApiClient apiClient;

  _AuthStoreBase({required this.authRepository, required this.apiClient}) {
    _listenToAuthState();
  }

  // Listener para estado de autenticação
  void _listenToAuthState() {
    authRepository.user.listen((appUser) {
      final wasLoggedIn =
          isLoggedIn; // Verifica se já estava logado antes da atualização
      user =
          appUser; // Atualiza o usuário vindo do stream (inicialmente com dados Firebase)

      if (isLoggedIn && !wasLoggedIn) {
        // Acabou de logar (via stream), busca perfil Strapi
        print(
            "AuthStore Listener: User logged in via stream. Fetching Strapi profile.");
        _fetchAndSyncStrapiProfile();
      } else if (isLoggedIn && strapiUserId == null) {
        // Já estava logado (ex: app reabriu), mas sem ID Strapi, busca perfil
        print(
            "AuthStore Listener: App reopened while logged in. Fetching Strapi profile.");
        _fetchAndSyncStrapiProfile();
      } else if (!isLoggedIn) {
        // Limpa o ID se deslogar
        strapiUserId = null;
        // Garante que user seja AppUser.empty() se o stream não o fizer imediatamente
        if (user != AppUser.empty()) {
          user = AppUser.empty();
        }
      }
    });
  }

  @observable
  AppUser user = AppUser.empty();

  @observable
  int? strapiUserId;
  @observable
  bool isDeletingAccount = false;
  @observable
  String? deleteAccountError;
  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  // Flag para loading específico do perfil Strapi (opcional)
  @observable
  bool isLoadingProfile = false;

  @computed
  bool get isLoggedIn => user != AppUser.empty() && user.id.isNotEmpty;

  @action
  Future<void> _fetchAndSyncStrapiProfile() async {
    // Só executa se estiver logado no Firebase
    if (!isLoggedIn) {
      print("AuthStore: Cannot fetch Strapi profile, user not logged in.");
      return;
    }

    print('AuthStore: Attempting to fetch Strapi User Profile...');
    isLoadingProfile = true; // Indica que o perfil está sendo carregado
    try {
      final response = await apiClient.get('/api/users/me'); // Chama o endpoint

      if (response.data != null && response.data is Map<String, dynamic>) {
        final strapiData = response.data as Map<String, dynamic>;

        // Extrai os dados do Strapi
        final int? fetchedStrapiId = strapiData['id'] as int?;
        // IMPORTANTE: Verifique o nome exato do campo no Strapi (pode ser 'username', 'name', etc.)
        final String? fetchedUsername = strapiData['username'] as String?;
        final String? fetchedEmail = strapiData['email'] as String?;
        // Adicione outros campos que você precise, ex:
        // final String? fetchedStrapiPhoto = strapiData['profilePicture']?['url'];

        print(
            'AuthStore: Strapi data received: ID=$fetchedStrapiId, Username=$fetchedUsername, Email=$fetchedEmail');

        // Atualiza o 'user' observável, priorizando dados do Strapi
        // Mantém o ID do Firebase (user.id)
        user = AppUser(
          id: user.id, // Mantém o ID do Firebase que identifica a sessão
          email: fetchedEmail ??
              user.email, // Usa email do Strapi, senão mantém o do Firebase
          name: fetchedUsername ??
              user.name, // Usa nome do Strapi, senão mantém o do Firebase
          photoUrl: user
              .photoUrl, // Mantém a foto do Firebase por enquanto (a menos que Strapi a forneça)
          // Se Strapi fornecer foto: photoUrl: fetchedStrapiPhoto ?? user.photoUrl,
        );

        strapiUserId = fetchedStrapiId; // Atualiza o ID do Strapi

        print(
            'AuthStore: User observable updated: Name=${user.name}, Email=${user.email}');
      } else {
        print(
            'AuthStore: Failed to parse Strapi User Profile from /api/users/me. Response data was not a valid map.');
        // Opcional: definir uma mensagem de erro específica para falha no perfil
        // errorMessage = 'Não foi possível carregar os detalhes do perfil.';
      }
    } on DioException catch (e) {
      // Erro comum é 401 (Não autorizado) se o token não for enviado ou for inválido
      // ou 403 (Proibido) se o token for válido mas não tiver permissão para /users/me
      print(
          'AuthStore: DioError fetching Strapi User Profile: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      errorMessage =
          'Falha ao buscar dados do perfil (${e.response?.statusCode}). Tente novamente.';
      // Em caso de erro, mantemos os dados do Firebase que já estavam no 'user'
    } catch (e) {
      print('AuthStore: Unexpected error fetching Strapi User Profile: $e');
      errorMessage = 'Erro inesperado ao buscar dados do perfil.';
      // Mantemos os dados do Firebase
    } finally {
      isLoadingProfile = false; // Finaliza o loading do perfil
    }
  }

  @action
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      strapiUserId = null;
      // Chama o repositório (que autentica no Firebase)
      final loggedInUser =
          await authRepository.signInWithEmailAndPassword(email, password);
      // user = loggedInUser; // O listener do stream geralmente já faz isso, mas pode ser redundante aqui
      print(
          "AuthStore: Email/Pass Sign In successful in Repo. User ID: ${loggedInUser.id}");

      // **Busca o perfil Strapi APÓS login Firebase bem-sucedido**
      // O listener pode demorar um pouco, então chamar diretamente garante a busca
      if (isLoggedIn) {
        // Garante que o user foi atualizado pelo stream ou pela linha acima
        await _fetchAndSyncStrapiProfile();
      } else {
        print(
            "AuthStore Warning: isLoggedIn is false immediately after successful repo call in signInWithEmailAndPassword.");
        // Isso pode indicar um problema de timing com o stream, mas vamos tentar buscar mesmo assim
        // se loggedInUser.id for válido
        if (loggedInUser.id.isNotEmpty) {
          user =
              loggedInUser; // Força a atualização se o stream ainda não o fez
          await _fetchAndSyncStrapiProfile();
        }
      }
    } catch (e) {
      print("AuthStore: Error during Email/Pass Sign In: ${e.toString()}");
      errorMessage =
          e.toString().replaceFirst('Exception: ', ''); // Remove 'Exception: '
      user = AppUser.empty();
      strapiUserId = null;
      rethrow; // Propaga o erro para a UI mostrar
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      strapiUserId = null;
      // Chama o repositório (que cadastra no Firebase E no Strapi)
      final newUser =
          await authRepository.signUpWithEmailAndPassword(email, password);
      // user = newUser; // Deixe o listener cuidar disso ou force como no login
      print(
          "AuthStore: Email/Pass Sign Up successful in Repo. User ID: ${newUser.id}");

      // **Busca o perfil Strapi APÓS cadastro bem-sucedido**
      if (isLoggedIn) {
        await _fetchAndSyncStrapiProfile();
      } else {
        print(
            "AuthStore Warning: isLoggedIn is false immediately after successful repo call in signUpWithEmailAndPassword.");
        if (newUser.id.isNotEmpty) {
          user = newUser;
          await _fetchAndSyncStrapiProfile();
        }
      }
    } catch (e) {
      print("AuthStore: Error during Email/Pass Sign Up: ${e.toString()}");
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      user = AppUser.empty();
      strapiUserId = null;
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> signInWithGoogle() async {
    try {
      isLoading = true;
      errorMessage = null;
      strapiUserId = null;
      // Chama o repositório (que faz login Google, Firebase e sincroniza/registra Strapi)
      final googleUser = await authRepository.signInWithGoogle();
      // user = googleUser; // Deixe o listener ou force
      print(
          "AuthStore: Google Sign In successful in Repo. User ID: ${googleUser.id}");

      // **Busca o perfil Strapi APÓS login Google bem-sucedido**
      if (isLoggedIn) {
        await _fetchAndSyncStrapiProfile();
      } else {
        print(
            "AuthStore Warning: isLoggedIn is false immediately after successful repo call in signInWithGoogle.");
        if (googleUser.id.isNotEmpty) {
          user = googleUser;
          await _fetchAndSyncStrapiProfile();
        }
      }
    } catch (e) {
      print("AuthStore: Error during Google Sign In: ${e.toString()}");
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      user = AppUser.empty();
      strapiUserId = null;
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  //signInWithApple (se implementado, fazer o mesmo)

  @action
  Future<void> signOut() async {
    // Não precisa buscar perfil aqui
    try {
      isLoading = true;
      await authRepository.signOut();
      // O listener (_listenToAuthState) deve limpar o user e strapiUserId
      errorMessage = null;
      // Forçar limpeza caso o listener demore
      user = AppUser.empty();
      strapiUserId = null;
    } catch (e) {
      print("AuthStore: Error during Sign Out: ${e.toString()}");
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      // Mesmo com erro, força o estado local para deslogado
      user = AppUser.empty();
      strapiUserId = null;
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> updateUserProfile({required String username}) async {
    // Pode usar isLoading geral ou um específico (ex: isLoadingProfileUpdate)
    isLoading = true;
    errorMessage = null;
    try {
      // Chama o repositório para atualizar no backend
      final updatedUser =
          await authRepository.updateUserProfile(username: username);

      // Atualiza o 'user' observável localmente com os dados retornados
      // Isso garante que a UI reflita a mudança imediatamente
      user = updatedUser;
      // OU, se o repo não retornar o usuário atualizado, atualize manualmente:
      // user = AppUser(id: user.id, email: user.email, name: username, photoUrl: user.photoUrl);

      // Opcional: Atualizar também o strapiUserId se ele for retornado na resposta
      // if (updatedUser.strapiId != null) strapiUserId = updatedUser.strapiId;

      print(
          "AuthStore: Perfil atualizado com sucesso no repositório e no estado local.");
    } catch (e) {
      print(
          "AuthStore: Erro ao chamar updateUserProfile do repositório - ${e.toString()}");
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow; // Propaga para a UI
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> deleteUserAccount(String currentPassword) async {
    if (strapiUserId == null) {
      errorMessage = "ID do usuário não encontrado para exclusão.";
      throw Exception(errorMessage);
    }

    isDeletingAccount = true;
    deleteAccountError = null; // Limpa erro anterior
    errorMessage = null; // Limpa erro geral também

    try {
      print(
          "AuthStore: Chamando repositório para deletar conta (Strapi ID: $strapiUserId)");
      await authRepository.deleteAccount(
        currentPassword: currentPassword,
        strapiUserId: strapiUserId!, // Usa o ID do Strapi armazenado no store
      );
      print("AuthStore: Exclusão de conta bem-sucedida no repositório.");
      // O sucesso aqui significa que o usuário foi removido do Firebase também.
      // O listener `_listenToAuthState` deve detectar a mudança para user=null
      // e limpar o `strapiUserId` localmente.
      // A navegação para login será feita na UI após detectar o sucesso.
    } catch (e) {
      print("AuthStore: Erro durante a exclusão da conta - ${e.toString()}");
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      deleteAccountError = errorMsg; // Define erro específico
      errorMessage = errorMsg; // Define erro geral também
      rethrow; // Re-lança para a UI (dialog) saber que falhou
    } finally {
      isDeletingAccount = false;
    }
  }

  @action
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    isLoading =
        true; // Usa o loading geral ou crie um específico (ex: isLoadingPasswordChange)
    errorMessage = null;
    try {
      await authRepository.changePassword(currentPassword, newPassword);
      print("AuthStore: Senha trocada com sucesso no repositório.");
      // Sucesso! O erro é limpo.
    } catch (e) {
      print(
          "AuthStore: Erro ao chamar changePassword do repositório - ${e.toString()}");
      errorMessage = e
          .toString()
          .replaceFirst('Exception: ', ''); // Armazena a mensagem de erro
      rethrow; // Propaga o erro para a UI poder tratá-lo (ex: SnackBar)
    } finally {
      isLoading = false;
    }
  }
}
