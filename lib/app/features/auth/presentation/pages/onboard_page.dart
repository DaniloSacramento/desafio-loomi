import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/auth/presentation/controllers/onboard_controller.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/onboard_store.dart';
import 'package:desafio_loomi/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:desafio_loomi/app/features/auth/presentation/widgets/logo_auth_widget.dart';
import 'package:desafio_loomi/app/widgets/logo_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

class OnboardPage extends StatefulWidget {
  const OnboardPage({super.key});

  @override
  State<OnboardPage> createState() => _OnboardPageState();
}

class _OnboardPageState extends State<OnboardPage> {
  final OnboardController _controller = OnboardController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late ReactionDisposer _disposer;
  @override
  void initState() {
    super.initState();
    _disposer = reaction(
      (_) => GetIt.I.get<OnboardStore>().isLoading,
      (isLoading) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _disposer();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.buttonPrimary),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _controller.pickImageFromCamera();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.photo_library, color: AppColors.buttonPrimary),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _controller.pickImageFromGallery();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardStore = GetIt.I.get<OnboardStore>();
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const HalfCircleWithLine(
                        size: 50,
                        lineThicknessRatio: 0.1,
                        innerCircleRatio: 0.4,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.04),
                      const Text(
                        'Tell us more!',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      const Text(
                        'Complete your profile',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      CustomTextFormField(
                        controller: _controller.nameController,
                        labelText: 'Your Name',
                        keyboardType: TextInputType.emailAddress,
                        // validator: AuthValidators.emailValidator,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      Observer(
                        builder: (_) {
                          if (onboardStore.errorMessage != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(onboardStore.errorMessage!)),
                              );
                              onboardStore.errorMessage =
                                  null; // Limpa a mensagem após exibir
                            });
                          }
                          return const SizedBox.shrink(); // Widget vazio
                        },
                      ),
                      Observer(
                        builder: (_) {
                          final onboardStore = GetIt.I.get<OnboardStore>();
                          return ElevatedButton(
                            onPressed: onboardStore.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      // ADICIONE ESTE LOG:
                                      debugPrint(
                                          'OnboardPage: Checking user before calling completeOnboarding: ${FirebaseAuth.instance.currentUser?.uid}');
                                      if (FirebaseAuth.instance.currentUser ==
                                          null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Erro: Usuário não autenticado! Saindo...')),
                                        );

                                        return;
                                      }
                                      // FIM DO LOG

                                      await _controller.completeOnboarding();
                                      Navigator.pushNamed(
                                          context, AppRoutes.home);
                                    }
                                  },
                            child: onboardStore.isLoading
                                ? CircularProgressIndicator()
                                : Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.transparent,
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.buttonText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
