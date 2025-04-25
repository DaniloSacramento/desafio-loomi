import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/auth/domain/validators/auth_validators.dart';
import 'package:desafio_loomi/app/features/auth/presentation/controllers/login_controller.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:desafio_loomi/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:desafio_loomi/app/features/auth/presentation/widgets/logo_auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController _loginController;

  @override
  void initState() {
    super.initState();

    _loginController = LoginController();

    _disposer = reaction(
      (_) => GetIt.I.get<AuthStore>().isLoading,
      (isLoading) {
        if (mounted) setState(() {});
      },
    );
  }

  late ReactionDisposer _disposer;
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    _disposer(); // Limpa a reaction do MobX
    _loginController
        .dispose(); // Isso chamará o dispose dos TextEditingControllers internos
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStore = GetIt.I.get<AuthStore>();
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(''),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  const HalfCircleWithLine(
                    size: 50,
                    lineThicknessRatio: 0.1,
                    innerCircleRatio: 0.4,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  const Text(
                    'Look who is here!',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  CustomTextFormField(
                    controller: _loginController.emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthValidators.emailValidator,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    controller: _loginController.passwordController,
                    labelText: 'Password',
                    obscureText: _loginController.obscurePassword,
                    validator: AuthValidators.passwordValidator,
                    showVisibilityToggle: true,
                    onToggleVisibility: () {
                      setState(() {
                        _loginController.togglePasswordVisibility();
                      });
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () {}, child: Text('Forgot password?'))
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  authStore.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _loginController
                                  .loginWithEmailAndPassword(context);
                            }
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    'Or Sing in With',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () {
                            _loginController.signInWithGoogle(context);
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
                      ),
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () {
                            _loginController.signInWithApple(context);
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
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Dont have an account? Sign Up! ',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text(
                          'Sing Up!',
                          style: TextStyle(
                            color: AppColors.buttonPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
