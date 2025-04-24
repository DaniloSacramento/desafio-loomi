import 'dart:async'; // Necessário para Future.delayed

import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/splash/presentation/widgets/custom_circle_widget.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
// Não precisamos mais do MovieStore aqui se a busca de filmes foi movida para HomePage
// import 'package:desafio_loomi/app/features/movies/presentation/store/movie_store.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
  // final MovieStore _movieStore = GetIt.I.get<MovieStore>(); // Removido se não usado aqui

  @override
  void initState() {
    print("!!!!!! SplashPage: initState() COMEÇOU !!!!!!");
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _checkAuthAndNavigate();
    print("!!!!!! SplashPage: initState() FINALIZOU !!!!!!");
  }

  Future<void> _checkAuthAndNavigate() async {
    print("!!!!!! SplashPage: _checkAuthAndNavigate() COMEÇOU !!!!!!");
    const splashDisplayDuration = Duration(seconds: 3);

    // Espera apenas o tempo da splash
    await Future.delayed(splashDisplayDuration);
    print("[SplashPage] CheckAuth - Delay concluído.");

    // Verifica o estado de login ATUAL no AuthStore
    // (Assume que o listener interno do AuthStore já atualizou o estado)
    final bool isLoggedIn = _authStore.isLoggedIn;
    print("[SplashPage] CheckAuth - Estado isLoggedIn: $isLoggedIn");

    if (!mounted) return;

    // Navega baseado no estado de login
    if (isLoggedIn) {
      print("[SplashPage] CheckAuth - Navegando para Home.");
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      print("[SplashPage] CheckAuth - Navegando para Register.");
      Navigator.pushReplacementNamed(context, AppRoutes.register);
    }
  }

  @override
  void dispose() {
    print("!!!!!! SplashPage: dispose() CHAMADO !!!!!!");
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("!!!!!! SplashPage: build() CHAMADO !!!!!!");
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const CustomCircleWidget(
            circleSize: 130,
            lineThickness: 10,
            innerCircleSize: 60,
          ),
        ),
      ),
    );
  }
}
