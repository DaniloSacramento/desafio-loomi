class Like {
  final int id;
  final int movieId;
  final int userId;
  // Adicione outros campos que a API /likes retorna, se necessário

  Like({
    required this.id,
    required this.movieId,
    required this.userId,
  });
}
