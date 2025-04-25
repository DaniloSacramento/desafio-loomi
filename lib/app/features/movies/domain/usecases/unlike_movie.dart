import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import '../repositories/movie_repository.dart';

class UnlikeMovieUseCase {
  final MovieRepository repository;

  UnlikeMovieUseCase(this.repository);

  Future<Either<Failure, void>> call(int likeId) async {
    return await repository.unlikeMovie(likeId);
  }
}
