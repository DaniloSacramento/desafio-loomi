import 'dart:io';
import 'package:desafio_loomi/app/core/routes/app_routes.dart'; // Para navegação
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:desafio_loomi/app/features/user/presentation/store/edit_user_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart'; // Import Observer
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart'; // Import ReactionDisposer

class EditUserProfilePage extends StatefulWidget {
  const EditUserProfilePage({super.key});

  @override
  State<EditUserProfilePage> createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends State<EditUserProfilePage> {
  // Instância do Store via GetIt
  final EditUserProfileStore _store = GetIt.instance<EditUserProfileStore>();
  late List<ReactionDisposer> _disposers;

  @override
  void initState() {
    super.initState();
    // Configura reações para feedback (erro/sucesso)
    _disposers = [
      reaction(
        (_) => _store.errorMessage,
        (String? message) {
          if (message != null && message.isNotEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
            // _store.errorMessage = null; // Opcional: limpar após mostrar
          }
        },
      ),
      reaction(
        (_) => _store.updateSuccess,
        (bool success) {
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil atualizado com sucesso!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Volta para a tela anterior (provavelmente ProfilePage)
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.profile);
              }
              ;
            });
          }
        },
      ),
    ];
  }

  @override
  void dispose() {
    for (var d in _disposers) {
      d();
    }
    _store.dispose(); // Chama dispose do store para limpar controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Observer para reagir às mudanças no store
          child: Observer(builder: (_) {
            return Form(
              key: _store.formKey, // Usa a key do store
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 10),
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: AppColors.buttonText, size: 30),
                          onPressed: _store.isLoading
                              ? null
                              : () => Navigator.pushReplacementNamed(
                                  context, AppRoutes.profile)),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 24,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: 'Edit\n'),
                            TextSpan(text: 'Profile'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                  // --- Seção da Imagem ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey.shade700,
                            backgroundImage: _store.selectedImageFile != null
                                ? FileImage(_store
                                    .selectedImageFile!) // Usa imagem selecionada do store
                                : (_store.currentPhotoUrl != null &&
                                        _store.currentPhotoUrl!.isNotEmpty)
                                    ? NetworkImage(_store
                                        .currentPhotoUrl!) // Usa URL atual do store
                                    : null,
                            child: (_store.selectedImageFile == null &&
                                    (_store.currentPhotoUrl == null ||
                                        _store.currentPhotoUrl!.isEmpty))
                                ? Icon(Icons.person,
                                    size: 45, color: Colors.grey.shade400)
                                : null,
                          ),
                          // Ícone de câmera
                          Container(
                            decoration: BoxDecoration(
                                color: AppColors.buttonPrimary.withOpacity(0.8),
                                shape: BoxShape.circle),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.camera_alt,
                                  color: Colors.white, size: 18),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: _store.isLoading
                                  ? null
                                  : _store.pickImage, // Chama action do store
                              child: const Text('CHOOSE IMAGE',
                                  style: TextStyle(
                                      color: AppColors.buttonPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                'A square .jpg, .gif, or .png image\n200x200 or larger',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                  // --- Campo Nome de Usuário ---
                  CustomTextFormField(
                    controller:
                        _store.usernameController, // Usa controller do store
                    labelText: 'Username',
                    validator:
                        _store.validateUsername, // Usa validador do store
                    showVisibilityToggle: false,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.06),

                  // --- Botão Atualizar Perfil ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      disabledBackgroundColor:
                          AppColors.buttonPrimary.withOpacity(0.5),
                    ),
                    // Observa isLoading e chama action do store
                    onPressed:
                        _store.isLoading ? null : _store.submitUpdateProfile,
                    child: _store.isLoading // Observa isLoading do store
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)),
                          )
                        : const Text('Update profile',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.buttonText)),
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
