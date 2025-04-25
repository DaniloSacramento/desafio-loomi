import 'package:dartz/dartz.dart'; // Para o Either
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/comments_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart'; // A interface do Repository

class GetCommentsStreamUseCase {
  final CommentsRepository repository; // Depende da interface do repositório

  GetCommentsStreamUseCase({required this.repository});

  Stream<Either<Failure, List<CommentEntity>>> call(String movieId) {
    return repository.getCommentsStream(movieId);
  }
}
