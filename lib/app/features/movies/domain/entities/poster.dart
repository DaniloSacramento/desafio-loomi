class Poster {
  final int id;
  final String name;
  final String url; // URL principal da imagem
  final String? thumbnailUrl; // URL da miniatura (opcional)
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
