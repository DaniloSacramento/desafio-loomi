// features/auth/presentation/store/auth_store.dart

import 'package:desafio_loomi/app/core/error/failures.dart'; // Certifique-se que está importado
import 'package:desafio_loomi/app/core/network/api_client.dart'; // Importar ApiClient
import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobx/mobx.dart';
import 'package:dio/dio.dart'; // Importar para DioException

part 'auth_store.g.dart';

class AuthStore = _AuthStoreBase with _$AuthStore;

abstract class _AuthStoreBase with Store {
  final AuthRepository authRepository;
  final ApiClient apiClient; // Adicionar ApiClient como dependência

  _AuthStoreBase({required this.authRepository, required this.apiClient}) {
    // Opcional: Adicionar listener para pegar usuário já logado na inicialização
    _listenToAuthState();
  }

  // Listener para estado de autenticação (exemplo básico)
  void _listenToAuthState() {
    authRepository.user.listen((appUser) {
      user = appUser; // Atualiza o usuário vindo do stream do Firebase
      if (isLoggedIn && strapiUserId == null) {
        // Se logado via stream E AINDA não tem ID Strapi, tenta buscar
        _fetchAndSetStrapiUserId();
      } else if (!isLoggedIn) {
        // Limpa o ID se deslogar
        strapiUserId = null;
      }
    });
  }

  @observable
  AppUser user = AppUser.empty();

  @observable
  int? strapiUserId; // Adicionar observable para o ID do Strapi

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  /// Getter computado para verificar se o usuário está logado
  @computed
  bool get isLoggedIn => user != AppUser.empty() && user.id.isNotEmpty;

  /// Função privada para buscar e definir o ID do Strapi
  @action
  Future<void> _fetchAndSetStrapiUserId() async {
    // Só executa se estiver logado no Firebase e ainda não tiver o ID
    if (!isLoggedIn || strapiUserId != null) return;

    print('AuthStore: Attempting to fetch Strapi User ID...');
    // Não seta isLoading aqui para não conflitar com o loading de login/signup
    try {
      final response = await apiClient.get('/api/users/me');
      // A resposta de /api/users/me geralmente tem o ID no corpo principal
      if (response.data != null && response.data['id'] != null) {
        strapiUserId = response.data['id'] as int?;
        print('AuthStore: Strapi User ID fetched: $strapiUserId');
      } else {
        print(
            'AuthStore: Failed to get Strapi User ID from /api/users/me response.');
        // Poderia setar um erro específico aqui se necessário
      }
    } on DioException catch (e) {
      print(
          'AuthStore: Error fetching Strapi User ID: ${e.response?.data ?? e.message}');
      // Define um erro ou loga, mas não necessariamente impede o login no Firebase
      // errorMessage = 'Failed to fetch user profile data.'; // Cuidado para não sobrescrever erros de login
    } catch (e) {
      print('AuthStore: Unexpected error fetching Strapi User ID: $e');
    }
  }

  @action
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      strapiUserId = null; // Limpa ID antigo ao tentar novo login
      user = await authRepository.signInWithEmailAndPassword(email, password);
      // Após login com sucesso no Firebase, busca o ID do Strapi
      if (isLoggedIn) {
        await _fetchAndSetStrapiUserId();
      }
    } catch (e) {
      errorMessage = e.toString();
      user = AppUser.empty(); // Garante estado de logout em caso de erro
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
      user = await authRepository.signUpWithEmailAndPassword(email, password);
      // Após signup com sucesso no Firebase, busca o ID do Strapi
      if (isLoggedIn) {
        await _fetchAndSetStrapiUserId();
      }
    } catch (e) {
      errorMessage = e.toString();
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
      user = await authRepository.signInWithGoogle();
      // Após login com Google sucesso no Firebase, busca o ID do Strapi
      if (isLoggedIn) {
        await _fetchAndSetStrapiUserId();
      }
    } catch (e) {
      errorMessage = e.toString();
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
      isLoading = true; // Opcional: mostrar loading no logout
      await authRepository.signOut();
      user = AppUser.empty();
      strapiUserId = null; // Limpa o ID do Strapi no logout
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      // Mesmo com erro no logout, força o estado local para deslogado
      user = AppUser.empty();
      strapiUserId = null;
      rethrow;
    } finally {
      isLoading = false;
    }
  }
}
