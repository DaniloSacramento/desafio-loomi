import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/features/auth/presentation/pages/login_page.dart';
import 'package:desafio_loomi/app/features/auth/presentation/pages/onboard_page.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import 'package:desafio_loomi/app/features/movies/presentation/pages/home_page.dart';
import 'package:desafio_loomi/app/features/movies/presentation/pages/video_player_page.dart';

import 'package:desafio_loomi/app/features/user/presentation/pages/change_password_page.dart';
import 'package:desafio_loomi/app/features/user/presentation/pages/update_user_profile_page.dart';
import 'package:desafio_loomi/app/features/user/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:desafio_loomi/app/features/auth/presentation/pages/register_page.dart';
import 'package:desafio_loomi/app/features/splash/presentation/pages/splash_page.dart';
import 'package:video_player/video_player.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case AppRoutes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditUserProfilePage());
      case AppRoutes.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordPage());
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.onboard:
        return MaterialPageRoute(builder: (_) => const OnboardPage());
      case AppRoutes.videoPlayer:
        if (args is Movie) {
          return MaterialPageRoute(
            builder: (_) => VideoPlayerPage(movie: args),
          );
        }
        return _errorRoute();
      // case AppRoutes.forgotPassword:
      //   return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found!')),
      );
    });
  }
}
