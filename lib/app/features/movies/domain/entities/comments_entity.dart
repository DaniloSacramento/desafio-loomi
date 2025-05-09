// lib/features/movies/domain/entities/comment_entity.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp

class CommentEntity {
  final String id;
  final String movieId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String text;
  final Timestamp timestamp; // Para ordenação

  CommentEntity({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.text,
    required this.timestamp,
  });

  factory CommentEntity.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return CommentEntity(
      id: snap.id,
      movieId: data['movieId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuário Anônimo',
      userAvatarUrl: data['userAvatarUrl'], // Pode ser null
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(), // Fallback
    );
  }
}
