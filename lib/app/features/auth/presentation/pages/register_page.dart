import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/auth/domain/validators/auth_validators.dart';

import 'package:desafio_loomi/app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:desafio_loomi/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:desafio_loomi/app/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late final AuthController _authController;
  final AuthStore _authStore = GetIt.instance<AuthStore>();
  @override
  void initState() {
    super.initState();
    _authController = AuthController();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.030),
                  const LogoWidget(
                    size: 130,
                    lineThickness: 10,
                    innerCircleSize: 60,
                    text: 'PQ NAO TA PEGANDO PORRA',
                    textStyle: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                        child: const Text(
                          'Sing in!',
                          style: TextStyle(
                            color: AppColors.buttonPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  const Text(
                    'Create an account',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                            text: 'To get started, please complete your\n'),
                        TextSpan(text: 'account registration.'),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _authController.signInWithGoogle(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          elevation: 2,
                        ),
                        child: Image.asset(
                          'assets/logogoogle.png',
                          height: 50,
                          width: 50,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          _authController.signInWithApple(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appleButton,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          elevation: 2,
                        ),
                        child: Image.asset(
                          'assets/logoapple.png',
                          height: 50,
                          width: 50,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  const Text(
                    'Or Sing up With',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  CustomTextFormField(
                    controller: _authController.emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthValidators.emailValidator,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    controller: _authController.passwordController,
                    labelText: 'Password',
                    obscureText: _authController.obscurePassword,
                    validator: AuthValidators.passwordValidator,
                    showVisibilityToggle: true,
                    onToggleVisibility: () {
                      setState(() {
                        _authController.togglePasswordVisibility();
                      });
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    controller: _authController.confirmPasswordController,
                    labelText: 'Confirm Your Password',
                    obscureText: _authController.obscureConfirmPassword,
                    validator: (value) =>
                        AuthValidators.confirmPasswordValidator(
                      value,
                      _authController.passwordController.text,
                    ),
                    showVisibilityToggle: true,
                    onToggleVisibility: () {
                      setState(() {
                        _authController.toggleConfirmPasswordVisibility();
                      });
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  Observer(
                    builder: (_) {
                      // Builder que reconstrói quando o estado do store muda
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.buttonPrimary, // Cor de fundo
                          foregroundColor:
                              AppColors.buttonText, // Cor do texto/ícone
                          minimumSize: const Size(double.infinity,
                              50), // Faz o botão esticar na largura
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          // Cor quando desabilitado (carregando)
                          disabledBackgroundColor:
                              AppColors.buttonPrimary.withOpacity(0.6),
                          disabledForegroundColor:
                              AppColors.buttonText.withOpacity(0.7),
                        ),
                        // Desabilita o botão se authStore.isLoading for true
                        onPressed: _authStore.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  // Chama o método do controller que chama a action do store
                                  _authController
                                      .registerWithEmailAndPassword(context);
                                }
                              },
                        // Define o filho do botão baseado em authStore.isLoading
                        child: _authStore.isLoading
                            ? const SizedBox(
                                // Mostra o indicador de loading
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                // Mostra o texto normal
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  // color: AppColors.buttonText, // Já definido no foregroundColor do styleFrom
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
