// lib/features/movies/domain/repositories/video_player_repository.dart
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import '../entities/subtitle_entity.dart';

abstract class VideoPlayerRepository {
  Future<Either<Failure, List<Subtitle>>> getSubtitles(int movieId);
}
