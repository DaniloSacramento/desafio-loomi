// auth_controller.dart
import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:desafio_loomi/injection_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:desafio_loomi/app/features/auth/domain/validators/auth_validators.dart';
import 'package:get_it/get_it.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = await _authStore.signInWithGoogle();
      print(
          'AuthController: Login/Registro com Google bem-sucedido. User: ${user.name}');
      if (context.mounted) {
        // Navega para Home após sucesso com Google
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    } catch (e) {
      print('AuthController: Erro no Google Sign-In - $e');
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(
                  'Erro no login com Google: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  // NOVO MÉTODO para Apple Sign-In (Registro/Login)
  Future<void> signInWithApple(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = await _authStore.signInWithApple();
      print(
          'AuthController: Login/Registro com Apple bem-sucedido. User: ${user.name}');
      if (context.mounted) {
        // Navega para Home após sucesso com Apple
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    } catch (e) {
      print('AuthController: Erro no Apple Sign-In - $e');
      if (context.mounted) {
        // Não mostrar erro de 'webAuthenticationOptions' para o usuário final
        // A UI já deve prevenir a chamada no Android
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.contains('webAuthenticationOptions')) {
          errorMessage =
              'Login com Apple não suportado neste dispositivo.'; // Mensagem mais amigável
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Erro no login com Apple: $errorMessage')),
        );
      }
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}
