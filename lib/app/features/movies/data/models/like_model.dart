import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';

class LikeModel extends Like {
  LikeModel({
    required super.id,
    required super.movieId,
    required super.userId,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    final movieData = attributes['movie']?['data'] as Map<String, dynamic>?;
    final movieIdFromJson =
        movieData?['id'] as int? ?? 0; // Assume 0 se não encontrar

    final userData = attributes['user']?['data'] as Map<String, dynamic>?;
    final userIdFromJson =
        userData?['id'] as int? ?? 0; // Assume 0 se não encontrar

    final likeId = json['id'] as int? ?? 0;

    return LikeModel(
      id: likeId,
      movieId: movieIdFromJson,
      userId: userIdFromJson,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attributes': {
        'movie': {
          'data': {'id': movieId}
        },
        'user': {
          'data': {'id': userId}
        },
      }
    };
  }
}
