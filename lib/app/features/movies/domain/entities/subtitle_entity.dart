// lib/features/movies/domain/entities/subtitle_entity.dart
class Subtitle {
  final int id;
  final String language; // Ex: 'en', 'pt-BR'
  final String format; // Ex: 'vtt', 'srt'
  final String fileUrl; // URL para baixar/usar o arquivo .vtt/.srt

  Subtitle({
    required this.id,
    required this.language,
    required this.format,
    required this.fileUrl,
  });
}
