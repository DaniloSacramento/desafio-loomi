import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';

class LoginController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthStore _authStore = GetIt.I.get<AuthStore>();

  bool obscurePassword = true;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

  Future<void> loginWithEmailAndPassword(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _authStore.signInWithEmailAndPassword(
        emailController.text,
        passwordController.text,
      );

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _authStore.signInWithGoogle();
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro no login com Google: ${e.toString()}')),
      );
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
