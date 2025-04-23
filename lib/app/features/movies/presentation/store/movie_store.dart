// --- presentation/store/movie_store.dart ---
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:desafio_loomi/app/features/movies/data/models/like_model.dart';
import 'package:desafio_loomi/app/features/movies/data/models/like_request_model.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_likes_usecase.dart.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_movies.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/like_movie_usecase.dart.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/unlike_movie.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:share_plus/share_plus.dart'; // Import Share Plus
import 'package:collection/collection.dart'; // Import collection package

part 'movie_store.g.dart';

enum RatingAction { like, dislike, loveIt }

class MovieStore = _MovieStoreBase with _$MovieStore;

abstract class _MovieStoreBase with Store {
  final GetMoviesUseCase getMoviesUseCase;
  final GetLikesUseCase getLikesUseCase;
  final LikeMovieUseCase likeMovieUseCase;
  final UnlikeMovieUseCase unlikeMovieUseCase; // Add UnlikeUseCase
  final AuthStore authStore;

  _MovieStoreBase({
    required this.getMoviesUseCase,
    required this.getLikesUseCase,
    required this.likeMovieUseCase,
    required this.unlikeMovieUseCase, // Inject UnlikeUseCase
    required this.authStore,
  }) {
    _initialize();
  }

  // --- Observables ---
  @observable
  ObservableList<Movie> movies = ObservableList<Movie>();

  @observable
  ObservableList<Like> userLikes =
      ObservableList<Like>(); // Holds likes for the logged-in user

  @observable
  bool isLoadingMovies = false;

  @observable
  bool isLoadingLikes = false;

  @observable
  ObservableSet<int> likingInProgress =
      ObservableSet<int>(); // Tracks movie IDs being liked/unliked

  @observable
  String? errorMessage;

  @observable
  int currentPage = 0;

  @observable
  Color gradientColor1 = Colors.blueGrey[900]!;

  @observable
  Color gradientColor2 = Colors.black;

  @observable
  bool isGeneratingPalette = false;

  // --- Computed ---
  @computed
  Set<int> get likedMovieIds => userLikes.map((like) => like.movieId).toSet();

  // --- Actions ---

  Future<void> _initialize() async {
    // Don't await fetchLikes if background loading is okay
    await fetchMovies();
    if (authStore.isLoggedIn && authStore.strapiUserId != null) {
      fetchLikes(); // Fetch likes in background
    }
  }

  @action
  Future<void> fetchMovies() async {
    // (Implementation remains the same as before)
    isLoadingMovies = true;
    errorMessage = null;
    final result = await getMoviesUseCase();
    result.fold(
      (failure) {
        errorMessage = _mapFailureToMessage(failure);
        movies = ObservableList<Movie>();
      },
      (movieList) {
        movies = ObservableList.of(movieList);
        if (movies.isNotEmpty && currentPage == 0) {
          updateBackgroundGradient(forceUpdate: true);
        } else if (movies.isEmpty) {
          _resetGradientColors();
        }
      },
    );
    isLoadingMovies = false;
  }

  @action
  Future<void> fetchLikes() async {
    final userId = authStore.strapiUserId;
    if (userId == null) {
      print("User ID not available, clearing local likes.");
      userLikes = ObservableList<Like>(); // Clear likes if user logs out
      return;
    }

    isLoadingLikes = true;
    // Fetch likes specifically for the user (filtering done in repository)
    final result = await getLikesUseCase(userId);
    isLoadingLikes = false; // Set loading false regardless of outcome here

    result.fold(
      (failure) {
        // Handle error - maybe show a snackbar or log it
        print("Error fetching likes: ${_mapFailureToMessage(failure)}");
        // Optionally set a specific likesError observable
        errorMessage =
            "Could not update liked status."; // Example error feedback
      },
      (likesList) {
        // This list should *only* contain likes for the current user
        userLikes = ObservableList.of(likesList);
        // Clear general error if likes loaded successfully
        if (errorMessage == "Could not update liked status.") {
          errorMessage = null;
        }
      },
    );
  }

  @action
  Future<void> rateMovie(int movieId, RatingAction action) async {
    final userId = authStore.strapiUserId;
    if (userId == null) {
      errorMessage = "Please log in to rate movies.";
      print("[STORE] RateMovie ERRO: User ID nulo!");
      return;
    }
    if (likingInProgress.contains(movieId)) {
      print("[STORE] RateMovie: Ação já em progresso para Movie ID $movieId.");
      return;
    }

    likingInProgress.add(movieId);
    errorMessage = null;
    print(
        "[STORE] Iniciando rateMovie - Movie ID: $movieId, Ação: $action, User ID: $userId");

    // Verifica o estado ATUAL do like para este filme
    final existingLike = userLikes.firstWhereOrNull(
      (like) => like.movieId == movieId && like.userId == userId,
    );
    final bool isCurrentlyLiked = existingLike != null;
    print(
        "[STORE] RateMovie: Filme atualmente curtido? $isCurrentlyLiked ${isCurrentlyLiked ? '(Like ID: ${existingLike?.id})' : ''}");

    Either<Failure, dynamic> result; // Para armazenar resultado dos use cases

    try {
      switch (action) {
        case RatingAction.like:
        case RatingAction.loveIt: // Tratando Love It como Like por enquanto
          if (!isCurrentlyLiked) {
            // Só chama API se NÃO estiver curtido
            print("[STORE] Tentando LIKE API...");
            result = await likeMovieUseCase(movieId: movieId, userId: userId);
            result.fold(
              (failure) {
                errorMessage = _mapFailureToMessage(failure);
                print("[STORE] FALHA LIKE API: $errorMessage");
              },
              (newLikeResponse) {
                // newLikeResponse é o Like retornado pela API (geralmente só com ID)
                print(
                    "[STORE] SUCESSO LIKE API - Resposta Like ID: ${newLikeResponse.id}");

                // *** CORREÇÃO APLICADA ***
                // Cria o LikeModel localmente com os IDs corretos
                final likeToAdd = LikeModel(
                  id: newLikeResponse.id, // ID retornado pela API
                  movieId: movieId, // ID do filme da ação
                  userId: userId, // ID do usuário logado
                );
                // Adiciona o modelo CORRETO à lista observável
                userLikes.add(likeToAdd);
                print(
                    "[STORE] LikeModel CORRIGIDO adicionado localmente: (ID: ${likeToAdd.id}, MovieID: ${likeToAdd.movieId}, UserID: ${likeToAdd.userId})");
                // --------------------------

                // TODO: Lógica adicional para 'Love It' se necessário (ex: guardar em outro mapa local)
              },
            );
          } else {
            print("[STORE] Filme já curtido. Nenhuma API 'Like' chamada.");
            // TODO: Lógica para 'Love It' em filme já curtido (ex: atualizar estado local)
          }
          break;

        case RatingAction.dislike:
          if (isCurrentlyLiked) {
            // Só chama API se ESTIVER curtido
            print(
                "[STORE] Tentando UNLIKE API (Like ID: ${existingLike!.id})..."); // existingLike não será nulo aqui
            result = await unlikeMovieUseCase(
                existingLike.id); // Chama use case de unlike
            result.fold(
              (failure) {
                errorMessage = _mapFailureToMessage(failure);
                print("[STORE] FALHA UNLIKE API: $errorMessage");
              },
              (_) {
                // Sucesso no unlike da API
                // Remove o like da lista local pelo ID
                final removed =
                    userLikes.removeWhere((like) => like.id == existingLike.id);
              },
            );
          } else {
            print(
                "[STORE] Filme não está curtido. Nenhuma API 'Unlike' chamada.");
            // TODO: Lógica para estado 'Disliked' se necessário (guardar localmente)
          }
          break;
      }
    } catch (e) {
      errorMessage = "An unexpected error occurred during rating.";
      print("[STORE] ERRO INESPERADO no rateMovie: $e");
    } finally {
      likingInProgress
          .remove(movieId); // Garante que remove o ID do processamento
      print(
          "[STORE] Finalizado rateMovie - Removido $movieId de likingInProgress.");
    }
  }

  // Dentro de MovieStore
  @action
  Future<void> toggleLike(int movieId) async {
    print("--- [STORE LOG] Iniciando toggleLike - Movie ID: $movieId");
    final userId = authStore.strapiUserId;

    if (userId == null) {
      print("--- [STORE LOG] ERRO: User ID nulo! Usuário não logado?");
      errorMessage = "Please log in to like movies.";
      return;
    }
    print("--- [STORE LOG] User ID: $userId");

    if (likingInProgress.contains(movieId)) {
      print(
          "--- [STORE LOG] Ação já em progresso para Movie ID: $movieId. Abortando.");
      return;
    }

    likingInProgress.add(movieId);
    errorMessage = null;
    print("--- [STORE LOG] Adicionado $movieId a likingInProgress.");

    // Encontra like existente (CRUCIAL!)
    final existingLike = userLikes.firstWhereOrNull(
      (like) => like.movieId == movieId && like.userId == userId,
    );
    print(
        "--- [STORE LOG] Like existente para Movie ID $movieId e User ID $userId: ${existingLike != null ? 'SIM (ID: ${existingLike.id})' : 'NÃO'}");

    Either<Failure, dynamic> result;

    try {
      // Adiciona try/finally para garantir a remoção do likingInProgress
      if (existingLike != null) {
        // --- UNLIKE ---
        print("--- [STORE LOG] Tentando UNLIKE - Like ID: ${existingLike.id}");
        result = await unlikeMovieUseCase(existingLike.id);
        print(
            "--- [STORE LOG] Resultado UNLIKE: ${result.isRight() ? 'SUCESSO' : 'FALHA (${result.fold((l) => l.runtimeType, (r) => '')})'}");
        result.fold(
          (failure) {
            errorMessage = _mapFailureToMessage(failure);
            print("--- [STORE LOG] FALHA UNLIKE: $errorMessage");
          },
          (_) {
            userLikes.removeWhere((like) => like.id == existingLike.id);
            print(
                "--- [STORE LOG] SUCESSO UNLIKE - Removido Like ID: ${existingLike.id} da lista local.");
          },
        );
      } else {
        // --- LIKE ---
        print(
            "--- [STORE LOG] Tentando LIKE - Movie ID: $movieId, User ID: $userId");
        // *** VERIFIQUE AQUI O CORPO DA REQUISIÇÃO ***
        final requestModel = LikeRequestModel(movieId: movieId, userId: userId);
        print(
            "--- [STORE LOG] Corpo da requisição (teórico): ${requestModel.toJson()}");
        result = await likeMovieUseCase(movieId: movieId, userId: userId);
        print(
            "--- [STORE LOG] Resultado LIKE: ${result.isRight() ? 'SUCESSO' : 'FALHA (${result.fold((l) => l.runtimeType, (r) => '')})'}");
        result.fold(
          (failure) {
            errorMessage = _mapFailureToMessage(failure);
            print("--- [STORE LOG] FALHA LIKE: $errorMessage");
          },
          (newLike) {
            userLikes.add(newLike);
            print(
                "--- [STORE LOG] SUCESSO LIKE - Adicionado Novo Like ID: ${newLike.id} à lista local.");
          },
        );
      }
    } catch (e) {
      print("--- [STORE LOG] ERRO INESPERADO no toggleLike: $e");
      errorMessage = "An unexpected error occurred.";
    } finally {
      likingInProgress.remove(movieId);
      print("--- [STORE LOG] Removido $movieId de likingInProgress.");
    }
  }

  @action
  Future<void> shareMovie(Movie movie) async {
    // Basic share functionality using share_plus
    try {
      // Customize the shared text
      final String shareText =
          "Check out this movie: ${movie.name}!\n${movie.synopsis}\nWatch here: ${movie.streamLink}";
      // You might want to share the poster URL too if possible/desired

      await Share.share(shareText,
          subject: 'Movie Recommendation: ${movie.name}');
    } catch (e) {
      print("Error sharing movie: $e");
      errorMessage = "Could not share movie.";
      // Optionally show a snackbar/message to the user
    }
  }

  @action
  void setCurrentPage(int newPage) {
    // (Implementation remains the same as before)
    if (newPage != currentPage && newPage >= 0 && newPage < movies.length) {
      currentPage = newPage;
      updateBackgroundGradient();
    }
  }

  @action
  Future<void> updateBackgroundGradient({bool forceUpdate = false}) async {
    // (Implementation remains the same as before)
    if (currentPage < 0 || currentPage >= movies.length) {
      _resetGradientColors();
      return;
    }
    if (isGeneratingPalette && !forceUpdate) return;

    isGeneratingPalette = true;

    final Movie currentMovie = movies[currentPage];
    final String? imageUrl =
        currentMovie.poster?.largeUrl ?? currentMovie.poster?.url;

    Color color1 = Colors.blueGrey[900]!;
    Color color2 = Colors.black;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final PaletteGenerator pg = await PaletteGenerator.fromImageProvider(
          NetworkImage(imageUrl),
          size: const Size(100, 150),
          maximumColorCount: 20,
        );
        color1 = pg.darkMutedColor?.color ??
            pg.darkVibrantColor?.color ??
            pg.dominantColor?.color ??
            color1;
        color2 = pg.dominantColor?.color?.withOpacity(0.85) ??
            pg.mutedColor?.color ??
            Colors.black;
        if (color1.computeLuminance() < 0.05 &&
            color2.computeLuminance() < 0.05) {
          color2 = Colors.grey[850]!;
        } else if (color1 == color2) {
          color2 = color1.withRed((color1.red + 30).clamp(0, 255));
        }
      } catch (e) {
        print("Error generating palette for ${currentMovie.name}: $e");
        _resetGradientColors();
      }
    } else {
      _resetGradientColors();
    }

    gradientColor1 = color1;
    gradientColor2 = color2;
    isGeneratingPalette = false;
  }

  @action
  void _resetGradientColors() {
    // (Implementation remains the same as before)
    gradientColor1 = Colors.blueGrey[900]!;
    gradientColor2 = Colors.black;
  }

  String _mapFailureToMessage(Failure failure) {
    // (Implementation remains the same as before)
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message ??
            'An unknown server error occurred.';
      case NetworkFailure:
        return 'Please check your internet connection.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
