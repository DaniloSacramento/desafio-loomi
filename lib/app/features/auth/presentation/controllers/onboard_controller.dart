import 'dart:async';
import 'dart:io';
import 'package:desafio_loomi/app/features/auth/presentation/store/onboard_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

class OnboardController {
  final TextEditingController nameController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  final OnboardStore _onboardStore = GetIt.I.get<OnboardStore>();
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker
          .pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.rear,
            imageQuality: 85,
          )
          .timeout(const Duration(seconds: 15));

      if (image != null) {
        // _onboardStore.setProfileImage(File(image.path));
      }
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw Exception('Permissão da câmera negada');
      } else {
        throw Exception('Erro na câmera: ${e.message}');
      }
    } on TimeoutException {
      throw Exception('Tempo limite excedido ao acessar a câmera');
    } catch (e) {
      throw Exception('Erro desconhecido: $e');
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker
          .pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          )
          .timeout(const Duration(seconds: 15));

      if (image != null) {
        //_onboardStore.setProfileImage(File(image.path));
      }
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw Exception('Permissão da galeria negada');
      } else {
        throw Exception('Erro na galeria: ${e.message}');
      }
    } on TimeoutException {
      throw Exception('Tempo limite excedido ao acessar a galeria');
    } catch (e) {
      throw Exception('Erro desconhecido: $e');
    }
  }

  Future<void> updateProfile({
    required String name,
    //File? profileImage,
  }) async {
    try {
      final data = {
        'username': name,
        'finished_onboarding': true, // Adicione isso se necessário
      };
      await _onboardStore.updateProfile(data);
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  Future<void> completeOnboarding() async {
    try {
      if (nameController.text.isEmpty) {
        throw Exception('Por favor, insira seu nome');
      }

      await updateProfile(name: nameController.text);

      await _onboardStore.completeOnboarding();
    } catch (e) {
      debugPrint('Erro no onboarding: $e');
      rethrow;
    }
  }

  Future<void> fetchUserData() async {
    await _onboardStore.fetchUserData();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
  }

  void dispose() {
    nameController.dispose();
  }
}
