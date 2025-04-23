import 'package:desafio_loomi/app/features/auth/domain/repositories/onboard_repository.dart';
import 'package:mobx/mobx.dart';

part 'onboard_store.g.dart';

class OnboardStore = _OnboardStoreBase with _$OnboardStore;

abstract class _OnboardStoreBase with Store {
  final OnboardRepository _repository;

  _OnboardStoreBase(this._repository);

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  Map<String, dynamic>? userData;

  @action
  Future<void> completeOnboarding() async {
    try {
      isLoading = true;
      errorMessage = null;
      await _repository.completeOnboarding();
      isLoading = false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      rethrow;
    }
  }

  @action
  Future<void> fetchUserData() async {
    try {
      isLoading = true;
      userData = await _repository.getUserData();
      isLoading = false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      rethrow;
    }
  }

  @action
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      isLoading = true;
      await _repository.updateUserData(data);
      await fetchUserData();
      isLoading = false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      rethrow;
    }
  }

  @action
  Future<void> deleteAccount() async {
    try {
      isLoading = true;
      await _repository.deleteUser();
      isLoading = false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      rethrow;
    }
  }
}
