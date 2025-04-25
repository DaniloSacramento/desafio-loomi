class ApiConstants {
  static const String baseUrl =
      'https://untold-strapi.api.prod.loomi.com.br/api';

  static const String register = '$baseUrl/auth/local/register';
  static const String userMe = '$baseUrl/users/me';
  static const String updateUser = '$baseUrl/users/updateMe';
  static String deleteUser(String userId) => '$baseUrl/users/$userId';

  static const String movies = '$baseUrl/movies';
  static const String likes = '$baseUrl/likes';
  static String deleteLike(String likeId) => '$baseUrl/likes/$likeId';
  static const String subtitles = '$baseUrl/subtitles';

  static String moviesWithPoster = '$movies?populate=poster';
  static String likesPopulated = '$likes?populate=*';
  static String subtitlesForMovie(int movieId) =>
      '$subtitles?populate=file&filters%5Bmovie_id%5D=$movieId';
}
