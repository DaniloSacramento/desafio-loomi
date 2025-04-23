// --- domain/usecases/unlike_movie_usecase.dart ---
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import '../repositories/movie_repository.dart';

class UnlikeMovieUseCase {
  final MovieRepository repository;

  UnlikeMovieUseCase(this.repository);

  /// Calls the repository to unlike a movie using the specific [likeId].
  Future<Either<Failure, void>> call(int likeId) async {
    return await repository.unlikeMovie(likeId);
  }
}
