import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String? email;
  final String? name;
  final String? photoUrl;

  const AppUser({
    required this.id,
    this.email,
    this.name,
    this.photoUrl,
  });

  factory AppUser.empty() {
    return const AppUser(id: '');
  }

  factory AppUser.fromFirebase(User firebaseUser) {
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      name: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  }

  bool get isEmpty => id.isEmpty;
}
