class LikeRequestModel {
  final int movieId;
  final int userId;

  LikeRequestModel({required this.movieId, required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'movie_id': movieId, // Atenção aos nomes exatos dos campos da API!
        'user_id': userId,
      }
    };
  }
}
