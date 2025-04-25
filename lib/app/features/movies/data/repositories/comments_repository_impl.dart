// lib/features/movies/data/repositories/comments_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/comments_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart';
import '../datasources/comments_firestore_data_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para FirebaseException

class CommentsRepositoryImpl implements CommentsRepository {
  final CommentsFirestoreDataSource firestoreDataSource;

  CommentsRepositoryImpl({required this.firestoreDataSource});

  @override
  Stream<Either<Failure, List<CommentEntity>>> getCommentsStream(
      String movieId) {
    return firestoreDataSource.getCommentsStream(movieId).map((comments) {
      return Right<Failure, List<CommentEntity>>(comments);
    }).handleError((error) {
      print("[Repo-Firestore] Erro no stream de comentários: $error");
      if (error is FirebaseException) {
        return Left<Failure, List<CommentEntity>>(
            ServerFailure(message: "Erro Firestore: ${error.message}"));
      }
      return Left<Failure, List<CommentEntity>>(
          ServerFailure(message: "Erro ao carregar comentários."));
    });
  }

  @override
  Future<Either<Failure, void>> deleteComment(String commentId) async {
    try {
      await firestoreDataSource.deleteComment(commentId);
      return const Right(null); // Success
    } on FirebaseException catch (e) {
      print(
          "[Repo-Firestore] Erro Firebase ao deletar comentário: ${e.code} - ${e.message}");
      return Left(
          ServerFailure(message: "Falha ao excluir comentário: ${e.message}"));
    } catch (e) {
      print("[Repo-Firestore] Erro inesperado ao deletar comentário: $e");
      return Left(
          ServerFailure(message: "Erro inesperado ao excluir comentário."));
    }
  }

  @override
  Future<Either<Failure, void>> updateComment(
      String commentId, String newText) async {
    if (newText.trim().isEmpty) {
      return Left(ServerFailure(
          message:
              "O comentário não pode ficar vazio.")); // Ou um tipo de Failure diferente
    }
    try {
      await firestoreDataSource.updateComment(commentId, newText.trim());
      return const Right(null); // Sucesso
    } on FirebaseException catch (e) {
      print(
          "[Repo-Firestore] Erro Firebase ao atualizar comentário: ${e.code} - ${e.message}");
      return Left(ServerFailure(
          message: "Falha ao atualizar comentário: ${e.message}"));
    } catch (e) {
      print("[Repo-Firestore] Erro inesperado ao atualizar comentário: $e");
      return Left(
          ServerFailure(message: "Erro inesperado ao atualizar comentário."));
    }
  }

  @override
  Future<Either<Failure, void>> addComment(
      String movieId, String userId, String userName, String text) async {
    try {
      final commentData = {
        'movieId': movieId,
        'userId': userId,
        'userName': userName,
        'text': text,
      };
      await firestoreDataSource.addComment(commentData);
      return const Right(null); // Sucesso
    } on FirebaseException catch (e) {
      print(
          "[Repo-Firestore] Erro Firebase ao adicionar comentário: ${e.code} - ${e.message}");
      return Left(
          ServerFailure(message: "Falha ao enviar comentário: ${e.message}"));
    } catch (e) {
      print("[Repo-Firestore] Erro inesperado ao adicionar comentário: $e");
      return Left(
          ServerFailure(message: "Erro inesperado ao enviar comentário."));
    }
  }
}
