import 'poster.dart';

class Movie {
  final int id;
  final String name;
  final String synopsis;
  final String streamLink;
  final String genre;
  final Poster? poster; // Pode ser nulo se o populate falhar

  Movie({
    required this.id,
    required this.name,
    required this.synopsis,
    required this.streamLink,
    required this.genre,
    this.poster,
  });
}
