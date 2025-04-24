import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desafio_loomi/app/core/network/api_client.dart';
import 'package:desafio_loomi/app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:desafio_loomi/app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:desafio_loomi/app/features/auth/data/repositories/onboard_repository_impl.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:desafio_loomi/app/features/auth/domain/repositories/onboard_repository.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/onboard_store.dart';
import 'package:desafio_loomi/app/features/movies/data/datasources/comments_firestore_data_source.dart';

import 'package:desafio_loomi/app/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:desafio_loomi/app/features/movies/data/datasources/movie_remote_data_source_impl.dart';
import 'package:desafio_loomi/app/features/movies/data/datasources/video_player_remote_data_source.dart'; // <-- Import VideoPlayer DataSource
import 'package:desafio_loomi/app/features/movies/data/datasources/video_player_remote_data_source_impl.dart'; // <-- Import VideoPlayer DataSource Impl
import 'package:desafio_loomi/app/features/movies/data/repositories/comments_repository_impl.dart';
import 'package:desafio_loomi/app/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:desafio_loomi/app/features/movies/data/repositories/video_player_repository_impl.dart'; // <-- Import VideoPlayer Repo Impl
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart';
import 'package:desafio_loomi/app/features/movies/domain/repositories/movie_repository.dart';
import 'package:desafio_loomi/app/features/movies/domain/repositories/video_player_repository.dart'; // <-- Import VideoPlayer Repo
import 'package:desafio_loomi/app/features/movies/domain/usecases/add_comment_usecase.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/delete_comment_usecase.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_comments_stream_usecase.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_likes_usecase.dart.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_movies.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_subtitles_usecase.dart'; // <-- Import GetSubtitles UseCase
import 'package:desafio_loomi/app/features/movies/domain/usecases/like_movie_usecase.dart.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/unlike_movie.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/update_comment_usecase.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/comments_store.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/movie_store.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/video_player_store.dart'; // <-- Import VideoPlayer Store
import 'package:desafio_loomi/app/features/user/domain/usecases/change_password_usecase.dart';
import 'package:desafio_loomi/app/features/user/domain/usecases/update_user_profile_usecase.dart';
import 'package:desafio_loomi/app/features/user/presentation/store/change_password_store.dart';
import 'package:desafio_loomi/app/features/user/presentation/store/edit_user_profile_store.dart';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Use um nome consistente para a instância do GetIt
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance);
  getIt.registerLazySingleton<Dio>(() => Dio()); // Dio básico
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.standard());

  // ApiClient (depende de Dio e FirebaseAuth)
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(
        dio: getIt<Dio>(),
        firebaseAuth: getIt<FirebaseAuth>(),
        baseUrl: 'https://untold-strapi.api.prod.loomi.com.br', // Sua Base URL
      ));
  getIt.registerLazySingleton<CommentsFirestoreDataSource>(
    () => CommentsFirestoreDataSourceImpl(),
  );
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

  getIt.registerLazySingleton<CommentsRepository>(
    () => CommentsRepositoryImpl(
        firestoreDataSource: getIt<CommentsFirestoreDataSource>()),
  );
  getIt.registerLazySingleton(
      () => DeleteCommentUseCase(repository: getIt<CommentsRepository>()));
  getIt.registerLazySingleton(
      () => GetCommentsStreamUseCase(repository: getIt<CommentsRepository>()));
  getIt.registerLazySingleton(
      () => AddCommentUseCase(repository: getIt<CommentsRepository>()));
  getIt.registerLazySingleton(
      () => UpdateCommentUseCase(repository: getIt<CommentsRepository>()));
  getIt.registerFactory(() => CommentsStore(
        getIt<GetCommentsStreamUseCase>(), // OK (1º)
        getIt<AddCommentUseCase>(), // OK (2º)
        getIt<AuthStore>(), // ERRADO (passando AuthStore como 3º)
        getIt<DeleteCommentUseCase>(),
        getIt<UpdateCommentUseCase>(),
      ));

  // --- Use Cases ---
  // Auth UseCases (se você os tiver, registre aqui)

  // Movie UseCases
  // Added Delete UseCase
  getIt.registerLazySingleton(
      () => ChangePasswordUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetMoviesUseCase(getIt<MovieRepository>()));
  getIt.registerLazySingleton(() => GetLikesUseCase(getIt<MovieRepository>()));
  getIt.registerLazySingleton(() => LikeMovieUseCase(getIt<MovieRepository>()));
  getIt.registerLazySingleton(
      () => UnlikeMovieUseCase(getIt<MovieRepository>()));
  // NOVO: Video Player UseCase
  getIt.registerLazySingleton(
      () => GetSubtitlesUseCase(getIt<VideoPlayerRepository>()));
  getIt.registerLazySingleton(
      () => UpdateUserProfileUseCase(getIt<AuthRepository>()));
  getIt.registerFactory(() => EditUserProfileStore(
        getIt<UpdateUserProfileUseCase>(),
        getIt<AuthStore>(), // Passa o AuthStore singleton
      ));
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
  getIt.registerFactory(
      () => ChangePasswordStore(getIt<ChangePasswordUseCase>()));
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
