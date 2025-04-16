import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart'
    show AuthRepository;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStoreBase with _$AuthStore;

abstract class _AuthStoreBase with Store {
  final AuthRepository authRepository;

  _AuthStoreBase(this.authRepository);

  @observable
  User user = User.empty();

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
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> signOut() async {
    await authRepository.signOut();
    user = User.empty;
  }
}
