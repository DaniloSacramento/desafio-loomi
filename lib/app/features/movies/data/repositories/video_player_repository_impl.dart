// lib/features/movies/data/repositories/video_player_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/exception.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/subtitle_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/repositories/video_player_repository.dart';
import '../datasources/video_player_remote_data_source.dart';

class VideoPlayerRepositoryImpl implements VideoPlayerRepository {
  final VideoPlayerRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Opcional

  VideoPlayerRepositoryImpl(
      {required this.remoteDataSource /*, this.networkInfo*/});

  @override
  Future<Either<Failure, List<Subtitle>>> getSubtitles(int movieId) async {
    // if (await networkInfo.isConnected) { // Opcional
    try {
      final remoteSubtitles = await remoteDataSource.getSubtitles(movieId);
      // SubtitleModel estende Subtitle, então a conversão é direta
      return Right(remoteSubtitles);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print("[REPO] Erro inesperado getSubtitles: $e");
      return Left(
          ServerFailure(message: 'Erro inesperado ao buscar legendas.'));
    }
    // } else {
    //   return Left(NetworkFailure());
    // }
  }
}
