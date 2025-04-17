import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobx/mobx.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStoreBase with _$AuthStore;

abstract class _AuthStoreBase with Store {
  final AuthRepository authRepository;

  _AuthStoreBase(this.authRepository);

  @observable
  AppUser user = AppUser.empty();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @action
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      user = await authRepository.signInWithEmailAndPassword(email, password);
    } catch (e) {
      errorMessage = e.toString();
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
      user = await authRepository.signUpWithEmailAndPassword(email, password);
    } catch (e) {
      errorMessage = e.toString();
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
      user = await authRepository.signInWithGoogle();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> signOut() async {
    try {
      await authRepository.signOut();
      user = AppUser.empty();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    }
  }
}
