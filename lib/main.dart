import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/routes/route_generator.dart';
import 'package:desafio_loomi/app/core/themes/app_themes.dart';
import 'package:desafio_loomi/app/features/splash/presentation/pages/splash_page.dart';
import 'package:desafio_loomi/firebase_options.dart';
import 'package:desafio_loomi/injection_container.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
      );

  await configureDependencies();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // localizationsDelegates: const [
      //   AppLocalizations.delegate,
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en', 'US'),
      //   Locale('pt', 'BR'),
      // ],
      title: 'Desafio Loomi',
      theme: AppThemes.mainTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
