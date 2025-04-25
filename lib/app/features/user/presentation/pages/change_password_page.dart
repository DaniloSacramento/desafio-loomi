import 'package:desafio_loomi/app/core/routes/app_routes.dart'; // Keep for navigation
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/auth/domain/validators/auth_validators.dart'; // Keep for direct validator use
import 'package:desafio_loomi/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:desafio_loomi/app/features/user/presentation/store/change_password_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart'; // Import Observer
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart'; // Import ReactionDisposer

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final ChangePasswordStore _store = GetIt.instance<ChangePasswordStore>();

  late List<ReactionDisposer> _disposers;

  @override
  void initState() {
    super.initState();
    _disposers = [
      reaction(
        (_) => _store.errorMessage,
        (String? message) {
          if (message != null && message.isNotEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
      reaction(
        (_) => _store.changePasswordSuccess, // Observa a flag de sucesso
        (bool success) {
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Senha atualizada com sucesso!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2), // Duração da SnackBar
              ),
            );

            Future.delayed(const Duration(milliseconds: 800), () {
              // Pequeno delay
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.profile);
              }
            });
          }
        },
      ),
    ];
  }

  @override
  void dispose() {
    // Dispose reactions
    for (var d in _disposers) {
      d();
    }
    // Dispose store controllers
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Use Observer to react to store changes in the UI
          child: Observer(builder: (_) {
            // Use Observer builder
            return Form(
              key: _store.formKey, // Use formKey from the store
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 20),
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: AppColors.buttonText,
                            size: 30,
                          ),
                          // Disable button when loading
                          onPressed: _store.isLoading
                              ? null
                              : () => Navigator.pushNamed(
                                  context, AppRoutes.profile)),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(text: 'Change\n'),
                            TextSpan(text: 'Password'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                  // --- Current Password Field ---
                  CustomTextFormField(
                    controller: _store
                        .currentPasswordController, // Use store controller
                    labelText: 'Current Password',
                    obscureText:
                        _store.obscureCurrentPassword, // Use store state
                    validator: _store
                        .validateCurrentPassword, // Use store validator method
                    showVisibilityToggle: true,
                    onToggleVisibility: _store
                        .toggleCurrentPasswordVisibility, // Use store action
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  const Divider(color: Colors.grey),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                  // --- New Password Field ---
                  CustomTextFormField(
                    controller:
                        _store.newPasswordController, // Use store controller
                    labelText: 'New Password',
                    obscureText: _store.obscureNewPassword, // Use store state
                    validator: _store
                        .validateNewPassword, // Use store validator method
                    showVisibilityToggle: true,
                    onToggleVisibility:
                        _store.toggleNewPasswordVisibility, // Use store action
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                  // --- Confirm New Password Field ---
                  CustomTextFormField(
                    controller: _store
                        .confirmNewPasswordController, // Use store controller
                    labelText: 'Confirm New Password',
                    obscureText:
                        _store.obscureConfirmPassword, // Use store state
                    validator: _store
                        .validateConfirmPassword, // Use store validator method
                    showVisibilityToggle: true,
                    onToggleVisibility: _store
                        .toggleConfirmPasswordVisibility, // Use store action
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),

                  // --- Update Button ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // Disable based on store's loading state
                      disabledBackgroundColor:
                          AppColors.buttonPrimary.withOpacity(0.5),
                    ),
                    onPressed:
                        _store.isLoading ? null : _store.submitChangePassword,
                    child: _store.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
