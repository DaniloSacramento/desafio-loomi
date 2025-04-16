class User {
  final String id;
  final String? email;
  final String? name;
  final String? photoUrl;

  const User({
    required this.id,
    this.email,
    this.name,
    this.photoUrl,
  });

  static const User empty = User(id: '');

  // Método para verificar se o usuário está vazio
  bool get isEmpty => this == User.empty;
}
