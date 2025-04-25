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
    final fileData =
        attributes['file']?['data']?['attributes'] as Map<String, dynamic>? ??
            {};

    return SubtitleModel(
      id: json['id'] as int? ?? 0,
      language: attributes['language'] as String? ?? 'und',
      format: fileData['ext'] as String? ?? '.vtt',
      fileUrl: fileData['url'] as String? ?? '',
    );
  }
}
