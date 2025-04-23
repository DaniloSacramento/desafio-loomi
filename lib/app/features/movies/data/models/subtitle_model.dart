// lib/features/movies/data/models/subtitle_model.dart
import 'package:desafio_loomi/app/features/movies/domain/entities/subtitle_entity.dart';

class SubtitleModel extends Subtitle {
  SubtitleModel({
    required super.id,
    required super.language,
    required super.format,
    required super.fileUrl,
  });

  factory SubtitleModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    // O populate=file provavelmente aninha os dados do arquivo
    final fileData =
        attributes['file']?['data']?['attributes'] as Map<String, dynamic>? ??
            {};

    return SubtitleModel(
      id: json['id'] as int? ?? 0,
      // Adapte os nomes dos campos conforme sua API Strapi retorna
      language:
          attributes['language'] as String? ?? 'und', // Idioma (ex: 'pt-BR')
      format: fileData['ext'] as String? ??
          '.vtt', // Formato (ex: '.vtt') - pegando da extensão do arquivo
      fileUrl: fileData['url'] as String? ??
          '', // URL completa do arquivo de legenda
    );
  }
}
