import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';

import 'poster_model.dart';

class MovieModel extends Movie {
  MovieModel({
    required super.id,
    required super.name,
    required super.synopsis,
    required super.streamLink,
    required super.genre,
    super.poster,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    final posterData = attributes['poster']?['data'] as Map<String, dynamic>?;

    return MovieModel(
      id: json['id'] ?? 0,
      name: attributes['name'] ?? '',
      synopsis: attributes['synopsis'] ?? '',
      streamLink: attributes['stream_link'] ?? '',
      genre: attributes['genre'] ?? '',
      poster: posterData != null ? PosterModel.fromJson(posterData) : null,
    );
  }
}
