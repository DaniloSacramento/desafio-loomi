import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Interface (opcional, mas boa prática)
abstract class IAuthRemoteDataSource {
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password);
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password);
  Future<UserCredential> signInWithGoogle();
  // Future<UserCredential> signInWithApple(); // Adicionar se necessário
  Future<void> signOut();
  Stream<User?> get authStateChanges; // Renomeado para clareza
  User? get currentUser; // Helper para pegar usuário atual
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  // final AppleSignIn _appleSignIn; // Adicionar se usar Apple Sign In

  AuthRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    // AppleSignIn? appleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();
  // _appleSignIn = appleSignIn ?? AppleSignIn(); // Ajustar conforme lib Apple

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    // A lógica de try/catch geralmente fica no repositório
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    // A lógica de try/catch geralmente fica no repositório
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    // A lógica de try/catch e validação de null fica no repositório
    final googleUser = await _googleSignIn.signIn();
    // A verificação de googleUser == null deve ser feita no repositório

    final googleAuth = await googleUser?.authentication;
    // A verificação de googleAuth == null deve ser feita no repositório

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken, // Importante para Firebase
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  /* // Exemplo Apple Sign In (precisa da lib 'sign_in_with_apple')
  @override
  Future<UserCredential> signInWithApple() async {
     final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken, // Essencial
         rawNonce: null, // pode precisar gerar um nonce dependendo da config
         accessToken: appleCredential.authorizationCode, // ou accessToken se disponível
      );

     return await _firebaseAuth.signInWithCredential(credential);
     // Atualizar nome/email no Firebase pode ser feito no repositório
  }
  */

  @override
  Future<void> signOut() async {
    // O signOut de múltiplos providers é melhor coordenado no repositório
    await _googleSignIn.signOut();
    // await _appleSignIn.signOut(); // Se usar Apple
    await _firebaseAuth.signOut();
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  @override
  User? get currentUser {
    return _firebaseAuth.currentUser;
  }
}
