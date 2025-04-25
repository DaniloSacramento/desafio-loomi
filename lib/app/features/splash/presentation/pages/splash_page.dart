import 'dart:async'; // Necessário para Future.delayed

import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/splash/presentation/widgets/custom_circle_widget.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';
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

  @override
  void initState() {
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
  }

  Future<void> _checkAuthAndNavigate() async {
    const splashDisplayDuration = Duration(seconds: 3);

    await Future.delayed(splashDisplayDuration);

    final bool isLoggedIn = _authStore.isLoggedIn;

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.register);
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
