// lib/features/splash/presentation/pages/splash_page.dart

import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/splash/presentation/widgets/custom_circle_widget.dart'; // Seu widget de logo
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart'; // Import AuthStore
import 'package:desafio_loomi/app/features/movies/presentation/store/movie_store.dart'; // Import MovieStore
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart'; // Import GetIt

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final AuthStore _authStore = GetIt.I.get<AuthStore>();
  final MovieStore _movieStore = GetIt.I.get<MovieStore>();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward(); // Inicia a animação

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(
        const Duration(seconds: 3)); // Ajuste o tempo se necessário

    final bool isLoggedIn = _authStore.isLoggedIn;

    if (isLoggedIn) {
      try {
        await _movieStore.fetchMovies();

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } catch (e) {
        print("SplashPage: Erro ao buscar filmes iniciais: $e");
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    } else {
      print("SplashPage: Usuário não logado. Navegando para Login.");
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomCircleWidget(
                circleSize: 130,
                lineThickness: 10,
                innerCircleSize: 60,
              ),
              SizedBox(height: 40), // Espaço
            ],
          ),
        ),
      ),
    );
  }
}
