// lib/features/movies/domain/usecases/get_subtitles_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import '../entities/subtitle_entity.dart';
import '../repositories/video_player_repository.dart';

class GetSubtitlesUseCase {
  final VideoPlayerRepository repository;

  GetSubtitlesUseCase(this.repository);

  Future<Either<Failure, List<Subtitle>>> call(int movieId) async {
    return await repository.getSubtitles(movieId);
  }
}
