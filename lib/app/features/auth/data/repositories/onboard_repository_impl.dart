import 'package:desafio_loomi/app/core/network/api_client.dart'; // Ajuste o path
import 'package:desafio_loomi/app/features/auth/domain/repositories/onboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class OnboardRepositoryImpl implements OnboardRepository {
  final ApiClient _apiClient;

  OnboardRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<void> completeOnboarding() async {
    try {
      debugPrint(
          'OnboardRepository: Enviando PATCH (completeOnboarding) para /api/users/updateMe');
      final response = await _apiClient.patch(
        '/api/users/updateMe',
        data: {
          'data': {
            // Wrapper 'data' comum no Strapi
            'finished_onboarding': true,
          },
        },
      );
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        debugPrint(
            'OnboardRepository: Falha ao completar onboarding. Status: ${response.statusCode}, Data: ${response.data}');
        throw Exception(
            'Falha ao marcar onboarding como completo. Status: ${response.statusCode}');
      }
      debugPrint('OnboardRepository: completeOnboarding bem-sucedido.');
    } on DioException catch (e) {
      debugPrint(
          'OnboardRepository: Erro Dio em completeOnboarding: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      throw Exception('Erro de rede ao completar onboarding: ${e.message}');
    } catch (e) {
      debugPrint(
          'OnboardRepository: Erro inesperado em completeOnboarding: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserData() async {
    try {
      debugPrint(
          'OnboardRepository: Buscando dados do usuário (GET /api/users/me)');
      final response = await _apiClient.get('/api/users/me');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint(
            'OnboardRepository: Falha ao buscar dados do usuário. Status: ${response.statusCode}, Data: ${response.data}');
        throw Exception(
            'Falha ao buscar dados do usuário. Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint(
          'OnboardRepository: Erro Dio em getUserData: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      // Tratar 401/403 - pode significar que o token expirou
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Sessão expirada ou inválida. Faça login novamente.');
      }
      throw Exception('Erro de rede ao buscar dados do usuário: ${e.message}');
    } catch (e) {
      debugPrint('OnboardRepository: Erro inesperado em getUserData: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final payload = {
        'data': {
          ...data,
          'finished_onboarding': true,
        }
      };
      debugPrint(
          'OnboardRepository: Enviando PATCH (updateUserData) para /api/users/updateMe com payload: $payload');
      final response = await _apiClient.patch(
        '/api/users/updateMe',
        data: payload,
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        debugPrint(
            'OnboardRepository: Falha ao atualizar dados do usuário. Status: ${response.statusCode}, Data: ${response.data}');
        throw Exception(
            'Falha ao atualizar dados do usuário. Status: ${response.statusCode}');
      }
      debugPrint('OnboardRepository: updateUserData bem-sucedido.');
    } on DioException catch (e) {
      debugPrint(
          'OnboardRepository: Erro Dio em updateUserData: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 403) {
        throw Exception(
            'Permissão negada para atualizar dados. Verifique as permissões no backend.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Sessão expirada ou inválida. Faça login novamente.');
      }
      throw Exception(
          'Erro de rede ao atualizar dados: ${e.response?.data['error']?['message'] ?? e.message}');
    } catch (e) {
      debugPrint('OnboardRepository: Erro inesperado em updateUserData: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      final userData = await getUserData(); // Reusa o método existente
      final userId = userData['id']; // Assumindo que o ID está no campo 'id'

      if (userId == null) {
        throw Exception(
            'Não foi possível obter o ID do usuário do backend para deleção.');
      }
      debugPrint(
          'OnboardRepository: ID do usuário Strapi obtido: $userId. Deletando...');

      final response =
          await _apiClient.delete('/api/users/$userId'); // Usa o ID na URL

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        debugPrint(
            'OnboardRepository: Falha ao deletar usuário no backend. Status: ${response.statusCode}, Data: ${response.data}');
        throw Exception(
            'Falha ao deletar usuário no backend. Status: ${response.statusCode}');
      }
      debugPrint(
          'OnboardRepository: Usuário deletado com sucesso no backend Strapi.');
    } on DioException catch (e) {
      debugPrint(
          'OnboardRepository: Erro Dio em deleteUser: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      throw Exception('Erro de rede ao deletar usuário: ${e.message}');
    } catch (e) {
      debugPrint('OnboardRepository: Erro inesperado em deleteUser: $e');
      rethrow;
    }
  }
}
