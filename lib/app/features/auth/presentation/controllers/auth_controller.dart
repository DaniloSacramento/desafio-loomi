// auth_controller.dart
import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:desafio_loomi/injection_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:desafio_loomi/app/features/auth/domain/validators/auth_validators.dart';
import 'package:get_it/get_it.dart';

class AuthController {
  final AuthStore _authStore = getIt<AuthStore>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  AuthController();

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
  }

  Future<void> registerWithEmailAndPassword(BuildContext context) async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final emailError = AuthValidators.emailValidator(emailController.text);
    final passwordError =
        AuthValidators.passwordValidator(passwordController.text);
    final confirmError = AuthValidators.confirmPasswordValidator(
      confirmPasswordController.text,
      passwordController.text,
    );

    if (emailError != null || passwordError != null || confirmError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(emailError ??
                passwordError ??
                confirmError ??
                'Erro de validação')),
      );
      return;
    }

    try {
      await _authStore.signUpWithEmailAndPassword(
        emailController.text,
        passwordController.text,
      );
      print('Firebase Current User: ${FirebaseAuth.instance.currentUser?.uid}');
      Navigator.pushReplacementNamed(context, AppRoutes.onboard);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final user = await _authStore.signInWithGoogle();
      Navigator.pushNamed(context, AppRoutes.home);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no login: ${e.toString()}')),
      );
      debugPrint('ERRO GOOGLE SIGN-IN: $e');
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}
