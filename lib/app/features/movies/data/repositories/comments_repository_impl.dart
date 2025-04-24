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
      // Se o stream do datasource for bem sucedido, retorna Right
      return Right<Failure, List<CommentEntity>>(comments);
    }).handleError((error) {
      // Se o stream do datasource emitir um erro
      print("[Repo-Firestore] Erro no stream de comentários: $error");
      if (error is FirebaseException) {
        return Left<Failure, List<CommentEntity>>(
            ServerFailure(message: "Erro Firestore: ${error.message}"));
      }
      return Left<Failure, List<CommentEntity>>(
          ServerFailure(message: "Erro ao carregar comentários."));
      // IMPORTANTE: Este handle Error pode não ser a forma ideal de transformar
      // o erro do stream em Either. Uma abordagem mais robusta pode ser necessária
      // dependendo de como você gerencia erros em Streams na sua arquitetura.
      // Por simplicidade, estamos mapeando o erro aqui.
    });
    // Nota: Uma forma mais garantida seria o DataSource retornar o Either diretamente no stream.
  }

  @override
  Future<Either<Failure, void>> deleteComment(String commentId) async {
    try {
      // Optional: Add network check here if you have NetworkInfo
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
    // Adicionar validação básica aqui se necessário (ex: newText não vazio)
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
        // 'userAvatarUrl': authStore.user.avatarUrl, // Pegar avatar do AuthStore se tiver
        'text': text,
        // Timestamp será adicionado pelo DataSource
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
