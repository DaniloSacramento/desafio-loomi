import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/comments_entity.dart';

abstract class CommentsRepository {
  Stream<Either<Failure, List<CommentEntity>>> getCommentsStream(
      String movieId);
  Future<Either<Failure, void>> addComment(
      String movieId, String userId, String userName, String text);
  Future<Either<Failure, void>> deleteComment(String commentId);
  Future<Either<Failure, void>> updateComment(String commentId, String newText);
}
