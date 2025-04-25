// lib/features/movies/data/datasources/video_player_remote_data_source_impl.dart
import 'package:desafio_loomi/app/core/network/api_client.dart';
import 'package:desafio_loomi/app/core/error/exception.dart';
import 'package:dio/dio.dart';
import '../models/subtitle_model.dart';
import 'video_player_remote_data_source.dart';

class VideoPlayerRemoteDataSourceImpl implements VideoPlayerRemoteDataSource {
  final ApiClient apiClient;

  VideoPlayerRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<SubtitleModel>> getSubtitles(int movieId) async {
    final path =
        '/api/subtitles?populate=file&filters[movie_id][\$eq]=$movieId';
    print("[DATASOURCE] Buscando legendas: $path"); // Log

    try {
      final response = await apiClient.get(path);
      final List<dynamic> data = response.data['data'] as List<dynamic>? ?? [];
      print("[DATASOURCE] Legendas recebidas: ${data.length}"); // Log
      return data.map((json) => SubtitleModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print(
          "[DATASOURCE] Erro Dio buscando legendas: ${e.response?.statusCode} - ${e.message}");
      throw ServerException(
          message:
              'Falha ao buscar legendas: ${e.response?.statusMessage ?? e.message}');
    } catch (e) {
      print("[DATASOURCE] Erro inesperado buscando legendas: $e");
      throw ServerException(message: 'Erro inesperado ao buscar legendas.');
    }
  }
}
