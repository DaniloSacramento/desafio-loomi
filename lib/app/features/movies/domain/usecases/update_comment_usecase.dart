import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart'; // Ajuste o import
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart'; // Ajuste o import
import 'package:desafio_loomi/app/core/error/failures.dart';

class UpdateCommentUseCase {
  final CommentsRepository repository;

  UpdateCommentUseCase({required this.repository});

  // Parâmetros nomeados para clareza
  Future<Either<Failure, void>> call(
      {required String commentId, required String newText}) async {
    // Validação básica pode ir aqui ou no repositório
    if (newText.trim().isEmpty) {
      return Left(
          ValidationFailure(message: "O comentário não pode ficar vazio."));
    }
    if (commentId.isEmpty) {
      return Left(ValidationFailure(message: "ID do comentário inválido."));
    }
    return await repository.updateComment(commentId, newText);
  }
}
