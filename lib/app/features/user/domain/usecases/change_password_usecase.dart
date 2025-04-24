// File: lib/app/features/auth/domain/usecases/change_password_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/exception.dart'; // Import ServerException if your repo throws it
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import if catching FirebaseAuthException directly

// Use case parameters (mantido)
class ChangePasswordParams {
  final String currentPassword;
  final String newPassword;

  ChangePasswordParams(
      {required this.currentPassword, required this.newPassword});
}

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  // --- MÉTODO CALL CORRIGIDO ---
  Future<Either<Failure, void>> call(ChangePasswordParams params) async {
    try {
      await repository.changePassword(
          params.currentPassword, params.newPassword);

      return const Right(null);
    } on ServerException catch (e) {
      print("ChangePasswordUseCase caught ServerException: ${e.message}");
      return Left(
          ServerFailure(message: e.message)); // Retorna Left com ServerFailure
    } on FirebaseAuthException catch (e) {
      print("ChangePasswordUseCase caught FirebaseAuthException: ${e.code}");

      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Senha atual incorreta.';
          break;
        case 'weak-password':
          message = 'Nova senha muito fraca.';
          break;
        case 'requires-recent-login':
          message = 'Requer login recente. Saia e entre novamente.';
          break;
        default:
          message = 'Erro de autenticação: ${e.code}';
      }
      return Left(ServerFailure(message: message));
    } catch (e) {
      print("ChangePasswordUseCase caught unexpected error: ${e.toString()}");
      return Left(
          ServerFailure(message: 'Erro inesperado ao tentar alterar a senha.'));
    }
  }
}
