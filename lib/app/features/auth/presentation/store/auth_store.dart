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
      final wasLoggedIn = isLoggedIn;
      user = appUser;

      if (isLoggedIn && !wasLoggedIn) {
        print(
            "AuthStore Listener: User logged in via stream. Fetching Strapi profile.");
        _fetchAndSyncStrapiProfile();
      } else if (isLoggedIn && strapiUserId == null) {
        // Já estava logado (ex: app reabriu), mas sem ID Strapi, busca perfil
        print(
            "AuthStore Listener: App reopened while logged in. Fetching Strapi profile.");
        _fetchAndSyncStrapiProfile();
      } else if (!isLoggedIn) {
        strapiUserId = null;
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

        final int? fetchedStrapiId = strapiData['id'] as int?;
        final String? fetchedUsername = strapiData['username'] as String?;
        final String? fetchedEmail = strapiData['email'] as String?;

        print(
            'AuthStore: Strapi data received: ID=$fetchedStrapiId, Username=$fetchedUsername, Email=$fetchedEmail');

        user = AppUser(
          id: user.id,
          email: fetchedEmail ?? user.email,
          name: fetchedUsername ?? user.name,
          photoUrl: user
              .photoUrl, // Mantém a foto do Firebase por enquanto (a menos que Strapi a forneça)
        );

        strapiUserId = fetchedStrapiId; // Atualiza o ID do Strapi

        print(
            'AuthStore: User observable updated: Name=${user.name}, Email=${user.email}');
      } else {
        print(
            'AuthStore: Failed to parse Strapi User Profile from /api/users/me. Response data was not a valid map.');
      }
    } on DioException catch (e) {
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
  void _clearErrorAndLoading() {
    errorMessage = null;
    isLoading = false;
  }

  @action
  void _handleAuthError(dynamic e) {
    print("AuthStore: Error occurred - ${e.toString()}");
    errorMessage = e.toString().replaceFirst('Exception: ', '');
    user = AppUser.empty(); // Garante estado de logout no erro
    strapiUserId = null;
    isLoading = false;
  }

  @action
  Future<AppUser> signInWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    strapiUserId = null; // Limpa ID Strapi antigo
    try {
      final loggedInUser = await authRepository.signInWithGoogle();
      print(
          "AuthStore: Google Sign In successful in Repo. User: ${loggedInUser.name}");
      _clearErrorAndLoading(); // Limpa erro e loading no sucesso
      return loggedInUser; // Retorna o usuário para a UI/Controller, se necessário
    } catch (e) {
      _handleAuthError(e); // Usa handler centralizado
      throw e; // Necessário por causa do tipo de retorno Future<AppUser>
    }
  }

  // NOVA ACTION signInWithApple
  @action
  Future<AppUser> signInWithApple() async {
    isLoading = true;
    errorMessage = null;
    strapiUserId = null;
    try {
      final loggedInUser = await authRepository.signInWithApple();
      print(
          "AuthStore: Apple Sign In successful in Repo. User: ${loggedInUser.name}");
      _clearErrorAndLoading();
      return loggedInUser;
    } catch (e) {
      _handleAuthError(e);
      throw e;
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
      print(
          "AuthStore: Email/Pass Sign In successful in Repo. User ID: ${loggedInUser.id}");

      if (isLoggedIn) {
        await _fetchAndSyncStrapiProfile();
      } else {
        print(
            "AuthStore Warning: isLoggedIn is false immediately after successful repo call in signInWithEmailAndPassword.");
        if (loggedInUser.id.isNotEmpty) {
          user = loggedInUser;
          await _fetchAndSyncStrapiProfile();
        }
      }
    } catch (e) {
      print("AuthStore: Error during Email/Pass Sign In: ${e.toString()}");
      errorMessage =
          e.toString().replaceFirst('Exception: ', ''); // Remove 'Exception: '
      user = AppUser.empty();
      strapiUserId = null;
      rethrow;
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
      final newUser =
          await authRepository.signUpWithEmailAndPassword(email, password);
      print(
          "AuthStore: Email/Pass Sign Up successful in Repo. User ID: ${newUser.id}");

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
  Future<void> signOut() async {
    try {
      isLoading = true;
      await authRepository.signOut();
      errorMessage = null;
      user = AppUser.empty();
      strapiUserId = null;
    } catch (e) {
      print("AuthStore: Error during Sign Out: ${e.toString()}");
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      user = AppUser.empty();
      strapiUserId = null;
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> updateUserProfile({required String username}) async {
    isLoading = true;
    errorMessage = null;
    try {
      final updatedUser =
          await authRepository.updateUserProfile(username: username);

      user = updatedUser;

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
        strapiUserId: strapiUserId!,
      );
      print("AuthStore: Exclusão de conta bem-sucedida no repositório.");
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
