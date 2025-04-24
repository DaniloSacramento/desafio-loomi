// lib/features/movies/data/datasources/comments_firestore_data_source.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/comments_entity.dart';

abstract class CommentsFirestoreDataSource {
  Stream<List<CommentEntity>> getCommentsStream(String movieId);
  Future<void> addComment(Map<String, dynamic> commentData);
  Future<void> deleteComment(String commentId);
  Future<void> updateComment(String commentId, String newText);
}

class CommentsFirestoreDataSourceImpl implements CommentsFirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<CommentEntity>> getCommentsStream(String movieId) {
    print("[DataSource-Firestore] Obtendo stream para movieId: $movieId");
    return _firestore
        .collection('movie_comments')
        .where('movieId', isEqualTo: movieId) // Filtra pelo filme
        .orderBy('timestamp', descending: true) // Ordena pelos mais recentes
        .snapshots() // Retorna um Stream de QuerySnapshot
        .map((snapshot) {
      // <<< NOVO LOG AQUI >>>
      print(
          "[DataSource-Firestore] STREAM EMIT: Snapshot recebido para movieId: $movieId. Documentos: ${snapshot.docs.length}. Hora: ${DateTime.now().toIso8601String()}");

      // Verifica se o comentário recém-adicionado está no snapshot
      bool foundNewComment = false;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['text'] == 'kk') {
          // Use o texto que você adicionou no teste
          foundNewComment = true;
          print(
              "[DataSource-Firestore] STREAM EMIT: Comentário 'kk' ENCONTRADO no snapshot (ID: ${doc.id})!");
          break; // Encontrou, pode parar de procurar
        }
      }
      if (!foundNewComment && snapshot.docs.isNotEmpty) {
        print(
            "[DataSource-Firestore] STREAM EMIT: Comentário 'kk' NÃO encontrado no snapshot atual.");
      }
      // <<< FIM NOVO LOG >>>

      // Mapeia cada DocumentSnapshot para um CommentEntity
      try {
        final comments = snapshot.docs
            .map((doc) => CommentEntity.fromSnapshot(doc))
            .toList();
        // Log após mapeamento bem-sucedido
        print(
            "[DataSource-Firestore] STREAM EMIT: Mapeamento concluído com ${comments.length} entidades.");
        return comments;
      } catch (e, s) {
        // Log de erro no mapeamento
        print(
            "[DataSource-Firestore] STREAM EMIT: ERRO ao mapear snapshot: $e");
        print(s); // Imprime o stack trace do erro
        return <CommentEntity>[]; // Retorna lista vazia para não quebrar o stream
      }
    }).handleError((error, stackTrace) {
      // <-- Adicione/verifique este handleError
      print(
          "[DataSource-Firestore] STREAM EMIT: ERRO DIRETO NO STREAM: $error");
      print(stackTrace);
      // É importante que o erro seja relançado ou tratado para que o Repository/Store saibam
      // throw error; // Ou retorne um estado de erro específico se preferir não quebrar
    });
  }

  @override
  Future<void> deleteComment(String commentId) async {
    print("[DataSource-Firestore] Deletando comentário: $commentId");
    await _firestore.collection('movie_comments').doc(commentId).delete();
    print("[DataSource-Firestore] Comentário deletado.");
  }

  @override
  Future<void> updateComment(String commentId, String newText) async {
    print("[DataSource-Firestore] Atualizando comentário: $commentId");
    // Atualiza apenas o campo 'text' do documento
    await _firestore.collection('movie_comments').doc(commentId).update({
      'text': newText,
      // Opcional: Adicionar um timestamp de edição, se desejar
      // 'lastEditedTimestamp': FieldValue.serverTimestamp(),
    });
    print("[DataSource-Firestore] Comentário atualizado.");
  }

  @override
  Future<void> addComment(Map<String, dynamic> commentData) async {
    print("[DataSource-Firestore] Adicionando comentário: $commentData");
    final dataWithTimestamp = {
      ...commentData,
      'timestamp': FieldValue.serverTimestamp(),
    };
    try {
      print("[DataSource-Firestore] Iniciando .add() com timeout...");
      // Adiciona um timeout de 15 segundos
      await _firestore
          .collection('movie_comments')
          .add(dataWithTimestamp)
          .timeout(const Duration(seconds: 15));
      print(
          "[DataSource-Firestore] Comentário adicionado (add concluído)."); // <- Log que está faltando
    } on TimeoutException catch (e, s) {
      print("[DataSource-Firestore] ERRO: TIMEOUT ao adicionar comentário: $e");
      print(s);
      // Relança um erro claro para a camada superior saber que falhou por timeout
      throw FirebaseException(
          plugin: 'firestore',
          code: 'deadline-exceeded',
          message: 'Timeout de 15s excedido ao adicionar comentário.');
    } catch (e, s) {
      print("[DataSource-Firestore] ERRO GERAL no .add(): $e");
      print(s);
      rethrow; // Relança outros erros
    }
  }
}
