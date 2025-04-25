// lib/features/movies/presentation/pages/home_page.dart
import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
import 'package:desafio_loomi/app/features/auth/presentation/widgets/logo_auth_widget.dart'; // Ensure correct path
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/movie_store.dart';
import 'package:desafio_loomi/app/features/movies/presentation/widgets/movie_card.dart';
import 'package:desafio_loomi/app/features/movies/presentation/widgets/movie_card_select_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:desafio_loomi/app/features/movies/presentation/widgets/rating_bottom_sheet.dart'; // <-- AJUSTE O CAMINHO SE NECESSÁRIO

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _handleMovieRateRequest(Movie movie) {
    print("HomePage: Handling rate request for movie ID: ${movie.id}");
    displayRatingSheet(context: context, movie: movie, movieStore: movieStore);
  }

  final MovieStore movieStore = GetIt.I.get<MovieStore>();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    print("!!!!!! HomePage: initState() COMEÇOU !!!!!!");

    // **** FORÇA A ORIENTAÇÃO RETRATO AO INICIAR A TELA ****
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: movieStore.currentPage,
    );
    _pageController.addListener(_onPageChanged);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    movieStore.fetchMovies();
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_pageController.page == null || !_pageController.hasClients) return;
    int newPage = _pageController.page!.round();
    movieStore.setCurrentPage(newPage);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safePadding = MediaQuery.of(context).padding;

    return Observer(
      builder: (_) {
        final Color gradColor1 = movieStore.gradientColor1;
        final Color gradColor2 = movieStore.gradientColor2;

        return Scaffold(
          backgroundColor: gradColor2,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [gradColor1, gradColor2],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.85]),
                  ),
                ),
                Column(
                  children: [
                    _buildTopBar(safePadding, context),
                    _buildNowShowingTitle(),
                    _buildMoviesPageView(),
                  ],
                ),
                if (movieStore.isGeneratingPalette)
                  Positioned(
                      top: safePadding.top + 10,
                      left: 20,
                      child: const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(EdgeInsets safePadding, BuildContext context) {
    final authStore = GetIt.I.get<AuthStore>();
    return Padding(
      padding: EdgeInsets.only(
        top: safePadding.top + 10.0,
        left: 20.0,
        right: 20.0,
        bottom: 10.0,
      ),
      child: SizedBox(
        height: kToolbarHeight * 0.8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: const HalfCircleWithLine(
                size: 30,
                lineThicknessRatio: 0.1,
                innerCircleRatio: 0.4,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person_outline,
                      size: 20, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowShowingTitle() {
    return const Padding(
      padding: EdgeInsets.only(left: 33.0, bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Now Showing',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesPageView() {
    return Expanded(
      child: Observer(
        builder: (_) {
          print("--- Building PageView ---");
          print("isLoadingMovies: ${movieStore.isLoadingMovies}");
          print("movies.isEmpty: ${movieStore.movies.isEmpty}");
          print("errorMessage: ${movieStore.errorMessage}");

          if (movieStore.isLoadingMovies && movieStore.movies.isEmpty) {
            return PageView.builder(
              controller: PageController(viewportFraction: 0.88),
              itemCount: 3,
              itemBuilder: (context, index) {
                return const Padding(
                  padding:
                      EdgeInsets.only(top: 0, bottom: 55, left: 8, right: 8),
                  child: MovieCardSkeleton(),
                );
              },
            );
          }

          if (movieStore.errorMessage != null && movieStore.movies.isEmpty) {
            return const Center(/* ... Mensagem de Erro ... */);
          }

          if (movieStore.movies.isEmpty && !movieStore.isLoadingMovies) {
            return const Center(
                child: Text(
              'No movies found.',
            ));
          }

          return PageView.builder(
            controller: _pageController,
            itemCount: movieStore.movies.length,
            itemBuilder: (context, index) {
              final movie = movieStore.movies[index];
              final isLiked = movieStore.likedMovieIds.contains(movie.id);
              final isLiking = movieStore.likingInProgress.contains(movie.id);

              return Padding(
                padding: const EdgeInsets.only(
                    top: 0, bottom: 55, left: 8, right: 8),
                child: MovieCard(
                  key: ValueKey('movie_card_${movie.id}'),
                  movie: movie,
                  isLiked: isLiked,
                  isLoadingLike: isLiking,
                  onRatePressed: () => _handleMovieRateRequest(movie),
                  onSharePressed: () => movieStore.shareMovie(movie),
                  onWatchPressed: () {
                    Navigator.pushNamed(context, AppRoutes.videoPlayer,
                        arguments: movie);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
