import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';
import '../repositories/movie_repository.dart';

class LikeMovieUseCase {
  final MovieRepository repository;

  LikeMovieUseCase(this.repository);

  Future<Either<Failure, Like>> call(
      {required int movieId, required int userId}) async {
    return await repository.likeMovie(movieId, userId);
  }
}
