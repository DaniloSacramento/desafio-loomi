import 'package:desafio_loomi/app/core/network/api_client.dart';
import 'package:dio/dio.dart'; // Import DioException for error handling
import '../models/like_model.dart';
import '../models/like_request_model.dart';
import '../models/movie_model.dart';
import 'movie_remote_data_source.dart'; // Import the interface
// Assuming you have a custom ServerException or similar
import 'package:desafio_loomi/app/core/error/exception.dart';

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final ApiClient apiClient;
  // Base URL should ideally be configured within ApiClient, but using directly for clarity if not
  // final String baseUrl = "https://untold-strapi.api.prod.loomi.com.br"; // Example

  MovieRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MovieModel>> getMovies() async {
    print(
        "--- [DataSource] Tentando buscar /api/movies?populate=poster ---"); // Log de início
    try {
      final response = await apiClient.get('/api/movies?populate=poster');
      print(
          "--- [DataSource] Sucesso ao buscar /api/movies - Status: ${response.statusCode} ---"); // Log de sucesso

      // Verifica se a resposta contém a chave 'data' e se é uma lista
      if (response.data != null && response.data['data'] is List) {
        final List<dynamic> data = response.data['data'];
        // Verifica se a lista não está vazia antes de mapear
        if (data.isNotEmpty) {
          print(
              "--- [DataSource] Mapeando ${data.length} filmes recebidos ---");
        } else {
          print(
              "--- [DataSource] Recebida lista de filmes vazia do backend ---");
        }
        return data.map((json) => MovieModel.fromJson(json)).toList();
      } else {
        // Se 'data' não existir ou não for uma lista, lança um erro
        print(
            "--- [DataSource] ERRO: Resposta inesperada do backend ao buscar filmes. 'data' não é uma lista ou é nulo. Resposta: ${response.data} ---");
        throw ServerException(
            message:
                'Formato de resposta inválido do servidor ao buscar filmes.');
      }
    } on DioException catch (e) {
      // **** LOGS DETALHADOS ADICIONADOS AQUI ****
      print('--- [DataSource] ERRO DioException ao buscar /api/movies ---');
      print('Tipo do Erro: ${e.type}');
      print('URL da Requisição: ${e.requestOptions.uri}');
      print('Status Code: ${e.response?.statusCode}'); // Ex: 403, 404, 500?
      print('Mensagem Status: ${e.response?.statusMessage}');
      print('Mensagem Dio: ${e.message}');
      print(
          'Dados da Resposta (Erro): ${e.response?.data}'); // MUITO IMPORTANTE!
      // **** FIM DOS LOGS DETALHADOS ****

      // Crie uma mensagem mais útil
      String detailedMessage = 'Failed to load movies.';
      if (e.response?.statusCode != null) {
        detailedMessage += ' Status: ${e.response?.statusCode}';
      }
      // Tenta pegar a mensagem de erro específica do Strapi, se houver
      // Adiciona verificação se response.data é um Map antes de acessar
      if (e.response?.data is Map &&
          e.response?.data['error']?['message'] != null) {
        detailedMessage += ' Details: ${e.response?.data['error']['message']}';
      } else if (e.message != null) {
        detailedMessage += ' - ${e.message}'; // Fallback para msg do Dio
      }

      // Lança a exceção com a mensagem melhorada
      throw ServerException(message: detailedMessage);
    } catch (e, stackTrace) {
      // Adiciona stackTrace para mais detalhes
      print(
          '--- [DataSource] Erro inesperado (não DioException) ao buscar /api/movies: $e ---');
      print('Stack Trace: $stackTrace'); // Loga o stack trace
      throw ServerException(
          message: 'An unexpected error occurred while loading movies: $e');
    }
  }

  @override
  Future<List<LikeModel>> getLikes() async {
    // Warning: This fetches ALL likes. Filtering should happen in the Store/Repository.
    // Ideally, the API would support filtering like: /api/likes?populate=*&filters[user_id][$eq]=USER_ID
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
      // Log antes da chamada
      print(
          "--- [DATASOURCE LOG] Chamando apiClient.post('/api/likes') com dados: ${likeRequest.toJson()}");
      final response = await apiClient.post(
        '/api/likes',
        data: likeRequest.toJson(),
      );
      // Log da resposta SUCESSO
      print(
          "--- [DATASOURCE LOG] apiClient.post SUCESSO - Status: ${response.statusCode}");
      print(
          "--- [DATASOURCE LOG] Resposta data: ${response.data}"); // LOG IMPORTANTE
      return LikeModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      // Log da resposta ERRO
      print(
          "--- [DATASOURCE LOG] DioException em likeMovie - Status: ${e.response?.statusCode}, Mensagem: ${e.message}");
      print(
          "--- [DATASOURCE LOG] Resposta de ERRO data: ${e.response?.data}"); // LOG IMPORTANTE
      // ... (resto do tratamento de erro ServerException) ...
      throw ServerException(
          message: 'Falha ao dar like: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      print("--- [DATASOURCE LOG] Erro inesperado em likeMovie: $e");
      throw ServerException(message: 'Erro inesperado ao dar like.');
    }
  }

  @override
  Future<void> unlikeMovie(int likeId) async {
    print("--- [DATASOURCE LOG] unlikeMovie chamado - Like ID: $likeId");
    try {
      print(
          "--- [DATASOURCE LOG] Chamando apiClient.delete('/api/likes/$likeId')");
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
