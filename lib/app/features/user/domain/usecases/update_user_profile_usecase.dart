// File: lib/app/features/auth/domain/usecases/update_user_profile_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/exception.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart'; // Import AppUser
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';

// Parâmetros para o use case
class UpdateUserProfileParams {
  final String username;
  // Adicionar File imageFile aqui se for implementar upload de imagem
  // final File? imageFile;

  UpdateUserProfileParams({required this.username /*, this.imageFile*/});
}

class UpdateUserProfileUseCase {
  final AuthRepository repository;

  UpdateUserProfileUseCase(this.repository);

  Future<Either<Failure, AppUser>> call(UpdateUserProfileParams params) async {
    // Validação básica pode ocorrer aqui ou no Store
    if (params.username.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Username cannot be empty.'));
    }

    // Lógica de upload de imagem iria aqui ANTES de chamar o repo para atualizar o user
    // 1. Fazer upload da imagem (params.imageFile) para obter a URL ou ID
    // 2. Chamar o repositório passando o username e a URL/ID da imagem

    // Chamada atual (apenas username)
    try {
      // O repositório já retorna Either<Failure, AppUser> ou lança exceção
      // Se o repo lançar exceção, o catch abaixo trata. Se retornar Either, repassamos.
      // A versão atual do seu repo lança exceção em caso de erro.
      final updatedUser =
          await repository.updateUserProfile(username: params.username);
      return Right(
          updatedUser); // Retorna o usuário atualizado em caso de sucesso
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print("UpdateUserProfileUseCase unexpected error: $e");
      return Left(ServerFailure(
          message: 'An unexpected error occurred while updating profile.'));
    }
  }
}

// Definição simples de ValidationFailure (pode ir para core/error/failures.dart)
