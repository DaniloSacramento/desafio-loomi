import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';

class LikeModel extends Like {
  // Você pode adicionar outros campos que vêm da API, se precisar
  // Ex: final DateTime createdAt;

  LikeModel({
    required super.id,
    required super.movieId,
    required super.userId,
    // required this.createdAt, // Exemplo
  });

  /// Factory constructor para criar uma instância de LikeModel a partir de um JSON.
  /// Adapte os caminhos ['...'] conforme a estrutura exata da resposta da sua API Strapi.
  factory LikeModel.fromJson(Map<String, dynamic> json) {
    // A estrutura exata da resposta do Strapi pode variar,
    // especialmente com 'populate=*'. Ajuste conforme necessário.
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    // Tenta extrair o ID do filme. Pode estar em uma relação populada.
    final movieData = attributes['movie']?['data'] as Map<String, dynamic>?;
    final movieIdFromJson =
        movieData?['id'] as int? ?? 0; // Assume 0 se não encontrar

    // Tenta extrair o ID do usuário. Pode estar em uma relação populada.
    final userData = attributes['user']?['data'] as Map<String, dynamic>?;
    final userIdFromJson =
        userData?['id'] as int? ?? 0; // Assume 0 se não encontrar

    // Alternativa: Se os IDs forem campos diretos nos atributos (menos provável com populate=*)
    // final movieIdFromJson = attributes['movie_id'] as int? ?? 0;
    // final userIdFromJson = attributes['user_id'] as int? ?? 0;

    // Extrai o ID do próprio like
    final likeId = json['id'] as int? ?? 0;

    // Extrai outras informações se necessário (ex: datas)
    // final createdAtFromJson = DateTime.tryParse(attributes['createdAt'] ?? '') ?? DateTime.now();

    return LikeModel(
      id: likeId,
      movieId: movieIdFromJson,
      userId: userIdFromJson,
      // createdAt: createdAtFromJson, // Exemplo
    );
  }

  /// (Opcional) Método para converter LikeModel de volta para JSON,
  /// útil se você precisar enviar o objeto completo em alguma requisição.
  /// Geralmente não é necessário se você já tem o LikeRequestModel para o POST.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attributes': {
        'movie': {
          // Estrutura de exemplo, pode não ser necessária para envio
          'data': {'id': movieId}
        },
        'user': {
          // Estrutura de exemplo
          'data': {'id': userId}
        },
        // Adicione outros atributos se necessário
      }
    };
  }
}
