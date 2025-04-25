import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/exception.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart'; // Import AppUser
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';

// Parâmetros para o use case
class UpdateUserProfileParams {
  final String username;

  UpdateUserProfileParams({required this.username /*, this.imageFile*/});
}

class UpdateUserProfileUseCase {
  final AuthRepository repository;

  UpdateUserProfileUseCase(this.repository);

  Future<Either<Failure, AppUser>> call(UpdateUserProfileParams params) async {
    if (params.username.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Username cannot be empty.'));
    }

    try {
      final updatedUser =
          await repository.updateUserProfile(username: params.username);
      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print("UpdateUserProfileUseCase unexpected error: $e");
      return Left(ServerFailure(
          message: 'An unexpected error occurred while updating profile.'));
    }
  }
}
