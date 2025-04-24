import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart'; // Ajuste o path

// Interface Abstrata do Repositório de Autenticação
abstract class AuthRepository {
  // Stream para observar mudanças no estado de autenticação (logado/deslogado)
  // Retorna o AppUser customizado ou AppUser.empty
  Stream<AppUser> get user;

  Future<AppUser> updateUserProfile({required String username});
  Future<AppUser> signInWithEmailAndPassword(String email, String password);
  Future<AppUser> signUpWithEmailAndPassword(String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> signOut();
  Future<void> deleteAccount(
      {required String currentPassword, required int strapiUserId});
}
