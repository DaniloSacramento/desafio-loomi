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

// Removed MobX import as we only use flutter_mobx here
// Removed Palette Generator import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _handleMovieRateRequest(Movie movie) {
    print("HomePage: Handling rate request for movie ID: ${movie.id}");
    // A chamada a displayRatingSheet será corrigida no próximo erro
    displayRatingSheet(
        context: context,
        movie: movie,
        movieStore: movieStore); // << CORREÇÃO DO PRÓXIMO ERRO APLICADA AQUI
  }

  // Get the store instance
  final MovieStore movieStore = GetIt.I.get<MovieStore>();
  // PageController remains managed here as it's purely UI control
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    // Initialize PageController with viewportFraction
    // Use the store's currentPage if needed for initialPage, though 0 is typical
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: movieStore.currentPage, // Start at the stored page index
    );

    // Add listener to notify the store about page changes
    _pageController.addListener(_onPageChanged);

    // Set System UI styles
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark, // For iOS notch area
    ));
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge); // Make app fullscreen

    // Initial data fetching is handled within the store's constructor or an init method
    // No need for reaction here to trigger gradient, store handles it internally.
  }

  @override
  void dispose() {
    // Clean up listener and controller
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  // Notifies the store when the page controller settles on a new page
  void _onPageChanged() {
    if (_pageController.page == null || !_pageController.hasClients) return;
    // Round the page value to get the nearest integer index
    int newPage = _pageController.page!.round();
    // Call the store's action to update the current page and potentially the gradient
    movieStore.setCurrentPage(newPage);
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safePadding = MediaQuery.of(context).padding;

    // Observer listens to changes in the MovieStore
    return Observer(
      builder: (_) {
        // Use the gradient colors directly from the store
        final Color gradColor1 = movieStore.gradientColor1;
        final Color gradColor2 = movieStore.gradientColor2;

        return Scaffold(
          backgroundColor: gradColor2, // Base color from store
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor:
                  Colors.transparent, // Ensure status bar is transparent
            ),
            child: Stack(
              children: [
                // --- Background Gradient Layer ---
                // AnimatedContainer reacts smoothly to color changes from the store
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 700), // Animation duration
                  curve: Curves.easeOut, // Animation curve
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [gradColor1, gradColor2],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.85] // Gradient stops
                        ),
                  ),
                ),

                // --- Content Layer (Top Bar + PageView) ---
                Column(
                  children: [
                    // --- Top Bar ---
                    _buildTopBar(safePadding, context),

                    // --- "Now Showing" Title ---
                    _buildNowShowingTitle(),

                    // --- PageView Section ---
                    _buildMoviesPageView(),
                  ],
                ),

                // --- Optional: Loading Indicator for Palette Generation ---
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

  // --- Helper Widgets for Build Method ---

  Widget _buildTopBar(EdgeInsets safePadding, BuildContext context) {
    final authStore = GetIt.I.get<AuthStore>();
    return Padding(
      padding: EdgeInsets.only(
        top: safePadding.top + 10.0, // Respect safe area + add margin
        left: 20.0,
        right: 20.0,
        bottom: 10.0, // Space before "Now Showing"
      ),
      child: SizedBox(
        height: kToolbarHeight * 0.8, // Define height for the bar
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70, size: 24),
                tooltip: 'Logout',
                onPressed: () async {
                  // --- Ação de Logout ---
                  print("HomePage: Logout button pressed.");
                  try {
                    await authStore.signOut();
                    print("HomePage: signOut successful.");
                    // Navega para a tela de login e remove todas as rotas anteriores
                    // Verifica se o widget ainda está montado antes de navegar
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes
                            .login, // Ou AppRoutes.register, dependendo do seu fluxo
                        (route) => false, // Remove todas as rotas anteriores
                      );
                    }
                  } catch (e) {
                    print("HomePage: Error during signOut: $e");
                    // Mostra erro para o usuário (opcional)
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Erro ao sair: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: const HalfCircleWithLine(
                // Your custom logo widget
                size: 30,
                lineThicknessRatio: 0.1,
                innerCircleRatio: 0.4,
              ),
            ),
            // Right Profile Icon
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  // TODO: Implement profile navigation
                  print("Navigate to Profile");
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile action (TODO)')));
                  // Example: Navigator.pushNamed(context, '/profile');
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
      padding:
          EdgeInsets.only(left: 33.0, bottom: 10.0), // Adjust padding as needed
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
          // --- ESTADO DE LOADING ---
          // Verifica se está carregando E se a lista de filmes está vazia
          if (movieStore.isLoadingMovies && movieStore.movies.isEmpty) {
            // Retorna um PageView preenchido com Skeletons
            return PageView.builder(
              // Usa um PageController temporário ou o mesmo viewportFraction
              controller:
                  PageController(viewportFraction: 0.88), // Mantém a aparência
              itemCount: 3, // Mostra alguns skeletons para preencher
              itemBuilder: (context, index) {
                return const Padding(
                  // Usa o mesmo padding do MovieCard real
                  padding:
                      EdgeInsets.only(top: 0, bottom: 55, left: 8, right: 8),
                  child: MovieCardSkeleton(), // <<< USA O WIDGET SKELETON
                );
              },
            );
          }

          // --- ESTADO DE ERRO ---
          if (movieStore.errorMessage != null && movieStore.movies.isEmpty) {
            return Center(/* ... Mensagem de Erro ... */);
          }

          // --- ESTADO VAZIO ---
          if (movieStore.movies.isEmpty && !movieStore.isLoadingMovies) {
            return const Center(
                child: Text(
              'No movies found.', /*...*/
            ));
          }

          // --- ESTADO COM CONTEÚDO (MovieCards Reais) ---
          return PageView.builder(
            controller: _pageController, // Usa o controller principal
            itemCount: movieStore.movies.length,
            itemBuilder: (context, index) {
              final movie = movieStore.movies[index];
              final isLiked = movieStore.likedMovieIds.contains(movie.id);
              final isLiking = movieStore.likingInProgress.contains(movie.id);

              // Retorna o MovieCard real quando os dados estão disponíveis
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
