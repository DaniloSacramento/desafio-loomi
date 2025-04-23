import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart'; // Ajuste o path

// Interface Abstrata do Repositório de Autenticação
abstract class AuthRepository {
  // Stream para observar mudanças no estado de autenticação (logado/deslogado)
  // Retorna o AppUser customizado ou AppUser.empty
  Stream<AppUser> get user;

  // Métodos para diferentes formas de login/cadastro
  Future<AppUser> signInWithEmailAndPassword(String email, String password);
  Future<AppUser> signUpWithEmailAndPassword(String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple(); // Se implementado

  // Método para logout
  Future<void> signOut();

  // Helper para obter o usuário atual de forma síncrona (pode ser null)
  // AppUser? get currentUser; // Poderia adicionar isso se útil
}
