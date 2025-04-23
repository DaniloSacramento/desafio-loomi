import 'package:desafio_loomi/app/features/movies/data/models/like_model.dart';

import '../models/like_request_model.dart';
import '../models/movie_model.dart';

abstract class MovieRemoteDataSource {
  Future<List<MovieModel>> getMovies();
  Future<List<LikeModel>> getLikes();
  Future<LikeModel> likeMovie(LikeRequestModel likeRequest);
  Future<void> unlikeMovie(int likeId);
}
