import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';
import '../repositories/movie_repository.dart';

class GetLikesUseCase {
  final MovieRepository repository;

  GetLikesUseCase(this.repository);

  Future<Either<Failure, List<Like>>> call(int userId) async {
    return await repository.getLikes(userId);
  }
}
