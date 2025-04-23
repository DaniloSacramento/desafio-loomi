import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';

abstract class MovieRepository {
  Future<Either<Failure, List<Movie>>> getMovies();
  Future<Either<Failure, List<Like>>> getLikes(
      int userId); // Precisa do ID do usuário para filtrar
  Future<Either<Failure, Like>> likeMovie(
      int movieId, int userId); // Precisa dos IDs
  Future<Either<Failure, void>> unlikeMovie(int likeId);
}
