import 'package:desafio_loomi/app/features/auth/data/datasources/auth_remote_data_source.dart'
    show AuthRemoteDataSource;
import 'package:desafio_loomi/app/features/auth/domain/repositories/auth_repository.dart'
    show AuthRepository;
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<User> get user {
    return remoteDataSource.user.map((firebaseUser) {
      if (firebaseUser == null) return User.empty;
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        name: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
    });
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await remoteDataSource.signInWithEmailAndPassword(
      email,
      password,
    );
    return _mapFirebaseUser(userCredential.user!);
  }

  @override
  Future<User> signUpWithEmailAndPassword(String email, String password) async {
    final userCredential = await remoteDataSource.signUpWithEmailAndPassword(
      email,
      password,
    );
    return _mapFirebaseUser(userCredential.user!);
  }

  @override
  Future<User> signInWithGoogle() async {
    final userCredential = await remoteDataSource.signInWithGoogle();
    return _mapFirebaseUser(userCredential.user!);
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
  }

  User _mapFirebaseUser(FirebaseUser firebaseUser) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      name: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  }
}
