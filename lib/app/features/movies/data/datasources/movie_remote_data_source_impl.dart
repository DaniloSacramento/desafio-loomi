import 'package:desafio_loomi/app/core/network/api_client.dart';
import 'package:dio/dio.dart'; // Import DioException for error handling
import '../models/like_model.dart';
import '../models/like_request_model.dart';
import '../models/movie_model.dart';
import 'movie_remote_data_source.dart'; // Import the interface
import 'package:desafio_loomi/app/core/error/exception.dart';

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final ApiClient apiClient;

  MovieRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MovieModel>> getMovies() async {
    try {
      final response = await apiClient.get('/api/movies?populate=poster');

      if (response.data != null && response.data['data'] is List) {
        final List<dynamic> data = response.data['data'];
        if (data.isNotEmpty) {
        } else {}
        return data.map((json) => MovieModel.fromJson(json)).toList();
      } else {
        throw ServerException(
            message:
                'Formato de resposta inválido do servidor ao buscar filmes.');
      }
    } on DioException catch (e) {
      String detailedMessage = 'Failed to load movies.';
      if (e.response?.statusCode != null) {
        detailedMessage += ' Status: ${e.response?.statusCode}';
      }
      if (e.response?.data is Map &&
          e.response?.data['error']?['message'] != null) {
        detailedMessage += ' Details: ${e.response?.data['error']['message']}';
      } else if (e.message != null) {
        detailedMessage += ' - ${e.message}'; // Fallback para msg do Dio
      }

      throw ServerException(message: detailedMessage);
    } catch (e, stackTrace) {
      print(
          '--- [DataSource] Erro inesperado (não DioException) ao buscar /api/movies: $e ---');
      print('Stack Trace: $stackTrace'); // Loga o stack trace
      throw ServerException(
          message: 'An unexpected error occurred while loading movies: $e');
    }
  }

  @override
  Future<List<LikeModel>> getLikes() async {
    try {
      final response = await apiClient.get('/api/likes?populate=*');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => LikeModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioError getting likes: ${e.response?.statusCode} - ${e.message}');
      throw ServerException(
          message:
              'Failed to load like status. ${e.response?.statusMessage ?? e.message}');
    } catch (e) {
      print('Unexpected error getting likes: $e');
      throw ServerException(
          message: 'An unexpected error occurred while loading likes.');
    }
  }

  @override
  Future<LikeModel> likeMovie(LikeRequestModel likeRequest) async {
    print("--- [DATASOURCE LOG] likeMovie chamado.");
    try {
      print(
          "--- [DATASOURCE LOG] Chamando apiClient.post('/api/likes') com dados: ${likeRequest.toJson()}");
      final response = await apiClient.post(
        '/api/likes',
        data: likeRequest.toJson(),
      );
      print(
          "--- [DATASOURCE LOG] apiClient.post SUCESSO - Status: ${response.statusCode}");
      print(
          "--- [DATASOURCE LOG] Resposta data: ${response.data}"); // LOG IMPORTANTE
      return LikeModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      print(
          "--- [DATASOURCE LOG] DioException em likeMovie - Status: ${e.response?.statusCode}, Mensagem: ${e.message}");
      print(
          "--- [DATASOURCE LOG] Resposta de ERRO data: ${e.response?.data}"); // LOG IMPORTANTE
      throw ServerException(
          message: 'Falha ao dar like: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      throw ServerException(message: 'Erro inesperado ao dar like.');
    }
  }

  @override
  Future<void> unlikeMovie(int likeId) async {
    try {
      final response = await apiClient.delete(
          '/api/likes/$likeId'); // Capturar response se quiser logar status
      print(
          "--- [DATASOURCE LOG] apiClient.delete SUCESSO - Status: ${response.statusCode}");
    } on DioException catch (e) {
      print(
          "--- [DATASOURCE LOG] DioException em unlikeMovie - Status: ${e.response?.statusCode}, Mensagem: ${e.message}");
      print(
          "--- [DATASOURCE LOG] Resposta de ERRO data: ${e.response?.data}"); // LOG IMPORTANTE
      // ... (resto do tratamento de erro ServerException) ...
      throw ServerException(
          message:
              'Falha ao remover like: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      print("--- [DATASOURCE LOG] Erro inesperado em unlikeMovie: $e");
      throw ServerException(message: 'Erro inesperado ao remover like.');
    }
  }
}
