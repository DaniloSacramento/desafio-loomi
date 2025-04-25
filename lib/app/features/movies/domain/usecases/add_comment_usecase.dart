import 'package:dartz/dartz.dart'; // Para o Either
import 'package:desafio_loomi/app/core/error/failures.dart'; // Suas classes de Failure
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart'; // A interface do Repository

class AddCommentUseCase {
  final CommentsRepository repository;

  AddCommentUseCase({required this.repository});

  Future<Either<Failure, void>> call({
    required String movieId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    return await repository.addComment(movieId, userId, userName, text);
  }
}
