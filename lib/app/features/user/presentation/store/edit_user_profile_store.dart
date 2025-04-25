import 'dart:io';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart'; // Para pegar dados iniciais
import 'package:desafio_loomi/app/features/movies/domain/usecases/update_comment_usecase.dart';
import 'package:desafio_loomi/app/features/user/domain/usecases/update_user_profile_usecase.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobx/mobx.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
part 'edit_user_profile_store.g.dart';

class EditUserProfileStore = _EditUserProfileStoreBase
    with _$EditUserProfileStore;

abstract class _EditUserProfileStoreBase with Store {
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final AuthStore _authStore;

  _EditUserProfileStoreBase(this._updateUserProfileUseCase, this._authStore) {
    _loadInitialData();
  }

  final TextEditingController usernameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @observable
  String? currentPhotoUrl;

  @observable
  File? selectedImageFile;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  bool updateSuccess = false;

  // --- Actions ---

  @action
  void _loadInitialData() {
    usernameController.text = _authStore.user.name ?? '';
    currentPhotoUrl = _authStore.user.photoUrl;
    print(
        "EditUserProfileStore Initialized: Name='${usernameController.text}', PhotoUrl='$currentPhotoUrl'");
  }

  @action
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    errorMessage = null; // Limpa erro anterior
    try {
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        selectedImageFile = File(pickedFile.path);
        print("Image picked: ${selectedImageFile?.path}");
      } else {
        print("Image picking cancelled.");
      }
    } catch (e) {
      print("Error picking image: $e");
      errorMessage = "Failed to pick image: ${e.toString()}";
    }
  }

  @action
  Future<void> submitUpdateProfile() async {
    errorMessage = null;
    updateSuccess = false;

    if (formKey.currentState?.validate() ?? false) {
      isLoading = true;

      final params = UpdateUserProfileParams(
        username: usernameController.text,
      );

      final result = await _updateUserProfileUseCase(params);

      result.fold(
        (failure) {
          print("EditUserProfileStore Error: ${failure.toString()}");
          errorMessage = _mapFailureToMessage(failure);
        },
        (updatedUser) {
          print("EditUserProfileStore Success: Profile updated.");
          _authStore.user = updatedUser;
          updateSuccess = true; // Sinaliza sucesso para a UI
        },
      );

      isLoading = false;
    } else {
      print("EditUserProfileStore: Form validation failed.");
      errorMessage = "Please correct the errors in the form.";
    }
  }

  // --- Helper Methods ---
  String? _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred.';
  }

  void dispose() {
    print("Disposing EditUserProfileStore controllers...");
    usernameController.dispose();
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your username';
    }
    return null;
  }
}
