import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
      final user = await _authStore.signInWithGoogle();
      print(
          'LoginController: Login com Google bem-sucedido. User: ${user.name}');
      // Verifica se o widget ainda está montado antes de navegar
      if (context.mounted) {
        // Navega para a home e remove todas as rotas anteriores
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    } catch (e) {
      print('LoginController: Erro no Google Sign-In - $e');
      // Verifica se o widget ainda está montado antes de mostrar SnackBar
      if (context.mounted) {
        // Mostra o erro para o usuário
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(
                  'Erro no login com Google: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = await _authStore.signInWithApple();
      print(
          'LoginController: Login com Apple bem-sucedido. User: ${user.name}');
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    } catch (e) {
      print('LoginController: Erro no Apple Sign-In - $e');
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(
                  'Erro no login com Apple: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
