import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart'; // Adjust import
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart'; // Adjust import

class DeleteCommentUseCase {
  final CommentsRepository repository;

  DeleteCommentUseCase({required this.repository});

  Future<Either<Failure, void>> call(String commentId) async {
    return await repository.deleteComment(commentId);
  }
}
