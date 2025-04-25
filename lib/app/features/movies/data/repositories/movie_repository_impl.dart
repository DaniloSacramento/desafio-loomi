import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/exception.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:desafio_loomi/app/features/movies/data/models/like_request_model.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import '../../domain/repositories/movie_repository.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;

  MovieRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Movie>>> getMovies() async {
    try {
      final remoteMovies = await remoteDataSource.getMovies();
      return Right(remoteMovies);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print("Repo getMovies unexpected error: $e");
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<Like>>> getLikes(int userId) async {
    try {
      final allRemoteLikes = await remoteDataSource.getLikes();

      final userLikes =
          allRemoteLikes.where((like) => like.userId == userId).toList();
      return Right(userLikes);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print("Repo getLikes unexpected error: $e");
      return Left(
          ServerFailure(message: 'An unexpected error occurred getting likes'));
    }
  }

  @override
  Future<Either<Failure, Like>> likeMovie(int movieId, int userId) async {
    print(
        "--- [REPO LOG] likeMovie chamado - Movie ID: $movieId, User ID: $userId");
    try {
      final requestModel = LikeRequestModel(movieId: movieId, userId: userId);
      final remoteLike = await remoteDataSource.likeMovie(requestModel);
      return Right(remoteLike);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado ao dar like'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikeMovie(int likeId) async {
    try {
      await remoteDataSource.unlikeMovie(likeId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado ao remover like'));
    }
  }
}
