// lib/features/movies/data/datasources/video_player_remote_data_source.dart
import '../models/subtitle_model.dart';

abstract class VideoPlayerRemoteDataSource {
  Future<List<SubtitleModel>> getSubtitles(int movieId);
}
