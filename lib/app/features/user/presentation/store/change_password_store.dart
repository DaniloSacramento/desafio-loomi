// File: lib/app/features/auth/presentation/store/change_password_store.dart

import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/auth/domain/validators/auth_validators.dart';
import 'package:desafio_loomi/app/features/user/domain/usecases/change_password_usecase.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'change_password_store.g.dart'; // Run build_runner after creating

class ChangePasswordStore = _ChangePasswordStoreBase with _$ChangePasswordStore;

abstract class _ChangePasswordStoreBase with Store {
  final ChangePasswordUseCase _changePasswordUseCase;

  _ChangePasswordStoreBase(this._changePasswordUseCase);

  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Form key

  @observable
  bool obscureCurrentPassword = true;

  @observable
  bool obscureNewPassword = true;

  @observable
  bool obscureConfirmPassword = true;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage; // General error message

  @observable
  bool changePasswordSuccess = false; // Flag for success state

  // --- Actions for UI Interaction ---
  @action
  void toggleCurrentPasswordVisibility() {
    obscureCurrentPassword = !obscureCurrentPassword;
  }

  @action
  void toggleNewPasswordVisibility() {
    obscureNewPassword = !obscureNewPassword;
  }

  @action
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
  }

  // --- Action for Business Logic ---
  @action
  Future<void> submitChangePassword() async {
    // Reset states
    errorMessage = null;
    changePasswordSuccess = false;

    // Validate form
    if (formKey.currentState?.validate() ?? false) {
      isLoading = true;
      final params = ChangePasswordParams(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );

      final result = await _changePasswordUseCase(params);

      result.fold(
        (failure) {
          errorMessage = _mapFailureToMessage(failure); // Set error message
        },
        (_) {
          changePasswordSuccess = true; // Set success flag
        },
      );

      isLoading = false;
    } else {
      print("ChangePasswordStore: Form validation failed.");
      errorMessage =
          "Please correct the errors in the form."; // Generic form error
    }
  }

  String? _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message; // Use message from ServerFailure
    }
    return 'An unexpected error occurred.'; // Default message
  }

  void _clearFields() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmNewPasswordController.clear();
  }

  void dispose() {
    print("Disposing ChangePasswordStore controllers...");
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
  }

  String? validateCurrentPassword(String? value) {
    return (value == null || value.isEmpty)
        ? 'Current password is required'
        : null;
  }

  String? validateNewPassword(String? value) {
    return AuthValidators.passwordValidator(value);
  }

  String? validateConfirmPassword(String? value) {
    return AuthValidators.confirmPasswordValidator(
        value, newPasswordController.text);
  }
}
