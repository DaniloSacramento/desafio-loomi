import '../../domain/entities/poster.dart';

class PosterModel extends Poster {
  PosterModel({
    required super.id,
    required super.name,
    required super.url,
    super.thumbnailUrl,
    super.smallUrl,
    super.mediumUrl,
    super.largeUrl,
  });

  factory PosterModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    final formats = attributes['formats'] as Map<String, dynamic>? ?? {};
    final thumbnail = formats['thumbnail'] as Map<String, dynamic>?;
    final small = formats['small'] as Map<String, dynamic>?;
    final medium = formats['medium'] as Map<String, dynamic>?;
    final large = formats['large'] as Map<String, dynamic>?;

    return PosterModel(
      id: json['id'] ?? 0,
      name: attributes['name'] ?? '',
      url: attributes['url'] ?? '',
      thumbnailUrl: thumbnail?['url'],
      smallUrl: small?['url'],
      mediumUrl: medium?['url'],
      largeUrl: large?['url'],
    );
  }
}
