import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/exception.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:desafio_loomi/app/features/movies/data/models/like_request_model.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import '../../domain/repositories/movie_repository.dart';
// Optional: Import NetworkInfo if you use it
// import 'package:desafio_loomi/app/core/platform/network_info.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Optional

  MovieRepositoryImpl({
    required this.remoteDataSource,
    // required this.networkInfo, // Optional
  });

  @override
  Future<Either<Failure, List<Movie>>> getMovies() async {
    // Optional: Check network connection
    // if (!await networkInfo.isConnected) {
    //   return Left(NetworkFailure());
    // }
    try {
      final remoteMovies = await remoteDataSource.getMovies();
      // Assuming MovieModel extends Movie (Entity)
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
    // if (!await networkInfo.isConnected) {
    //   return Left(NetworkFailure());
    // }
    try {
      // Fetches ALL likes from the source
      final allRemoteLikes = await remoteDataSource.getLikes();
      // Filter likes for the specific user *here* in the repository
      // This is crucial because the data source might return likes for all users
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
      print("--- [REPO LOG] Chamando remoteDataSource.likeMovie...");
      final remoteLike = await remoteDataSource.likeMovie(requestModel);
      print("--- [REPO LOG] remoteDataSource.likeMovie SUCESSO.");
      return Right(remoteLike);
    } on ServerException catch (e) {
      print("--- [REPO LOG] ServerException em likeMovie: ${e.message}");
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print("--- [REPO LOG] Erro inesperado em likeMovie: $e");
      return Left(ServerFailure(message: 'Erro inesperado ao dar like'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikeMovie(int likeId) async {
    print("--- [REPO LOG] unlikeMovie chamado - Like ID: $likeId");
    try {
      print("--- [REPO LOG] Chamando remoteDataSource.unlikeMovie...");
      await remoteDataSource.unlikeMovie(likeId);
      print("--- [REPO LOG] remoteDataSource.unlikeMovie SUCESSO.");
      return const Right(null);
    } on ServerException catch (e) {
      print("--- [REPO LOG] ServerException em unlikeMovie: ${e.message}");
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print("--- [REPO LOG] Erro inesperado em unlikeMovie: $e");
      return Left(ServerFailure(message: 'Erro inesperado ao remover like'));
    }
  }
}
