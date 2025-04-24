// lib/features/movies/domain/usecases/delete_comment_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart'; // Adjust import
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart'; // Adjust import

class DeleteCommentUseCase {
  final CommentsRepository repository;

  DeleteCommentUseCase({required this.repository});

  Future<Either<Failure, void>> call(String commentId) async {
    // Add any specific business logic/validation here if needed
    return await repository.deleteComment(commentId);
  }
}
