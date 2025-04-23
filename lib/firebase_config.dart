import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class FirebaseConfig {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      try {
        await Firebase.initializeApp(
          name: 'DefaultApp', // Nome explícito para evitar duplicação
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _initialized = true;
      } catch (e) {
        if (e.toString().contains('[core/duplicate-app]')) {
          // Ignora erro de app já inicializado
          _initialized = true;
        } else {
          rethrow;
        }
      }
    }
  }
}
