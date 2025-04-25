class Poster {
  final int id;
  final String name;
  final String url;
  final String? thumbnailUrl;
  final String? smallUrl;
  final String? mediumUrl;
  final String? largeUrl;

  Poster({
    required this.id,
    required this.name,
    required this.url,
    this.thumbnailUrl,
    this.smallUrl,
    this.mediumUrl,
    this.largeUrl,
  });
}
