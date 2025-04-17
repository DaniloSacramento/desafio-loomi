import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<AppUser> signInWithEmailAndPassword(String email, String password);
  Future<AppUser> signUpWithEmailAndPassword(String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<void> signOut();
  Stream<AppUser> get user;
}
