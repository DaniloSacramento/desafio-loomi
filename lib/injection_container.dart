import 'package:desafio_loomi/app/core/network/api_client.dart';
import 'package:desafio_loomi/app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:desafio_loomi/app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:desafio_loomi/app/features/auth/data/repositories/onboard_repository_impl.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/onboard_repository.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/onboard_store.dart';

import 'package:desafio_loomi/app/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:desafio_loomi/app/features/movies/data/datasources/movie_remote_data_source_impl.dart';
import 'package:desafio_loomi/app/features/movies/data/datasources/video_player_remote_data_source.dart'; // <-- Import VideoPlayer DataSource
import 'package:desafio_loomi/app/features/movies/data/datasources/video_player_remote_data_source_impl.dart'; // <-- Import VideoPlayer DataSource Impl
import 'package:desafio_loomi/app/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:desafio_loomi/app/features/movies/data/repositories/video_player_repository_impl.dart'; // <-- Import VideoPlayer Repo Impl
import 'package:desafio_loomi/app/features/movies/domain/repositories/movie_repository.dart';
import 'package:desafio_loomi/app/features/movies/domain/repositories/video_player_repository.dart'; // <-- Import VideoPlayer Repo
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_likes_usecase.dart.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_movies.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_subtitles_usecase.dart'; // <-- Import GetSubtitles UseCase
import 'package:desafio_loomi/app/features/movies/domain/usecases/like_movie_usecase.dart.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/unlike_movie.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/movie_store.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/video_player_store.dart'; // <-- Import VideoPlayer Store

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Use um nome consistente para a instância do GetIt
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // --- External Packages & Core ---
  // SharedPreferences precisa ser aguardado ANTES de registrar quem depende dele
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  getIt.registerLazySingleton<Dio>(() => Dio()); // Dio básico
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.standard());

  // ApiClient (depende de Dio e FirebaseAuth)
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(
        dio: getIt<Dio>(),
        firebaseAuth: getIt<FirebaseAuth>(),
        baseUrl: 'https://untold-strapi.api.prod.loomi.com.br', // Sua Base URL
      ));

  // --- Data Sources ---
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(
        getIt<SharedPreferences>()), // Depende de SharedPreferences
  );
  getIt.registerLazySingleton<MovieRemoteDataSource>(
    () => MovieRemoteDataSourceImpl(
        apiClient: getIt<ApiClient>()), // Depende de ApiClient
  );
  // NOVO: Video Player DataSource
  getIt.registerLazySingleton<VideoPlayerRemoteDataSource>(
    () => VideoPlayerRemoteDataSourceImpl(
        apiClient: getIt<ApiClient>()), // Depende de ApiClient
  );

  // --- Repositories ---
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      firebaseAuth: getIt<FirebaseAuth>(),
      googleSignIn: getIt<GoogleSignIn>(),
      // localDataSource: getIt<AuthLocalDataSource>(), // Adicione se AuthRepositoryImpl precisar
    ),
  );
  getIt.registerLazySingleton<OnboardRepository>(
    () => OnboardRepositoryImpl(
        apiClient: getIt<ApiClient>()), // Depende de ApiClient
  );
  getIt.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(
      remoteDataSource:
          getIt<MovieRemoteDataSource>(), // Depende de MovieRemoteDataSource
      // networkInfo: getIt<NetworkInfo>(), // Opcional
    ),
  );
  // NOVO: Video Player Repository
  getIt.registerLazySingleton<VideoPlayerRepository>(
    () => VideoPlayerRepositoryImpl(
      remoteDataSource: getIt<
          VideoPlayerRemoteDataSource>(), // Depende de VideoPlayerRemoteDataSource
    ),
  );

  // --- Use Cases ---
  // Auth UseCases (se você os tiver, registre aqui)

  // Movie UseCases
  getIt.registerLazySingleton(() => GetMoviesUseCase(getIt<MovieRepository>()));
  getIt.registerLazySingleton(() => GetLikesUseCase(getIt<MovieRepository>()));
  getIt.registerLazySingleton(() => LikeMovieUseCase(getIt<MovieRepository>()));
  getIt.registerLazySingleton(
      () => UnlikeMovieUseCase(getIt<MovieRepository>()));
  // NOVO: Video Player UseCase
  getIt.registerLazySingleton(() => GetSubtitlesUseCase(
      getIt<VideoPlayerRepository>())); // Depende de VideoPlayerRepository

  // --- Stores (State Management) ---
  // Registre AuthStore ANTES dos stores que dependem dele
  getIt.registerLazySingleton<AuthStore>(
    () => AuthStore(
      authRepository: getIt<AuthRepository>(),
      apiClient: getIt<ApiClient>(), // Necessário para buscar ID Strapi
    ),
  );
  getIt.registerLazySingleton<OnboardStore>(
    () => OnboardStore(getIt<OnboardRepository>()),
  );
  // Registre MovieStore (depende de AuthStore)
  getIt.registerLazySingleton(() => MovieStore(
        getMoviesUseCase: getIt<GetMoviesUseCase>(),
        getLikesUseCase: getIt<GetLikesUseCase>(),
        likeMovieUseCase: getIt<LikeMovieUseCase>(),
        unlikeMovieUseCase: getIt<UnlikeMovieUseCase>(),
        authStore: getIt<AuthStore>(), // Depende de AuthStore
      ));
  // NOVO: Video Player Store (Use registerFactory se precisar de novas instâncias por página)
  getIt.registerFactory(() => VideoPlayerStore(
        // Depende de GetSubtitlesUseCase
        getSubtitlesUseCase: getIt<GetSubtitlesUseCase>(),
      ));
}
