// lib/features/movies/presentation/store/comments_store.dart
import 'dart:async';
import 'package:desafio_loomi/app/features/movies/domain/entities/comments_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/add_comment_usecase.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/delete_comment_usecase.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_comments_stream_usecase.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/update_comment_usecase.dart';
import 'package:mobx/mobx.dart';
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';

part 'comments_store.g.dart';

class ValidationFailure extends Failure {
  final String message;
  ValidationFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

class CommentsStore = _CommentsStoreBase with _$CommentsStore;

abstract class _CommentsStoreBase with Store {
  final GetCommentsStreamUseCase _getCommentsStreamUseCase;
  final AddCommentUseCase _addCommentUseCase;
  final DeleteCommentUseCase _deleteCommentUseCase;
  final UpdateCommentUseCase _updateCommentUseCase;
  final AuthStore _authStore;

  _CommentsStoreBase(
    this._getCommentsStreamUseCase,
    this._addCommentUseCase,
    this._authStore,
    this._deleteCommentUseCase,
    this._updateCommentUseCase,
  );

  @observable
  ObservableList<CommentEntity> comments = ObservableList<CommentEntity>();

  @observable
  bool isLoadingComments = false;

  @observable
  String? commentsError;

  // --- Estados para Adicionar ---
  @observable
  bool isAddingComment = false;

  @observable
  String? addCommentError;

  @observable
  bool isDeletingComment = false; // Flag geral

  @observable
  String? deletingCommentId; // Qual ID está sendo deletado

  @observable
  String? deleteCommentError; // Erro específico da deleção

  @observable
  bool isUpdatingComment = false; // Flag geral

  @observable
  String? editingCommentId;

  @observable
  String? updateCommentError; // Erro específico da atualização

  StreamSubscription? _commentsSubscription;

  String? getCurrentUserId() {
    return _authStore.isLoggedIn ? _authStore.user.id : null;
  }

  @action
  void listenToComments(String movieId) {
    print("[CommentsStore] Iniciando listener para movieId: $movieId");
    comments.clear();
    isLoadingComments = true;
    commentsError = null;
    isAddingComment = false;
    addCommentError = null;
    isDeletingComment = false;
    deletingCommentId = null;
    deleteCommentError = null;
    isUpdatingComment = false;
    editingCommentId = null;
    updateCommentError = null;

    _commentsSubscription?.cancel();

    _commentsSubscription = _getCommentsStreamUseCase(movieId).listen(
      (eitherResult) {
        print(
            "[CommentsStore] STREAM EVENT: Listener recebeu dados/erro. Hora: ${DateTime.now().toIso8601String()}. Instance: ${hashCode}");

        if (isLoadingComments) isLoadingComments = false;

        eitherResult.fold(
          (failure) {
            print(
                "[CommentsStore] STREAM EVENT: Falha recebida: ${failure.runtimeType}. Mensagem: ${_mapFailureToMessage(failure)}");
            commentsError = _mapFailureToMessage(failure);
          },
          (commentsList) {
            print(
                "[CommentsStore] STREAM EVENT: Sucesso recebido com ${commentsList.length} comentários.");

            bool foundNewComment = false;
            for (var entity in commentsList) {
              if (entity.text == 'kk') {
                // Use o texto que você adicionou no teste
                foundNewComment = true;
                print(
                    "[CommentsStore] STREAM EVENT: Comentário 'kk' ENCONTRADO na lista mapeada (ID: ${entity.id})!");
                break;
              }
            }
            if (!foundNewComment && commentsList.isNotEmpty) {
              print(
                  "[CommentsStore] STREAM EVENT: Comentário 'kk' NÃO encontrado na lista mapeada atual.");
            }

            comments.clear();
            comments.addAll(commentsList);
            print(
                "[CommentsStore] STREAM EVENT: Lista 'comments' ATUALIZADA via ObservableList.of. Novo tamanho: ${comments.length}.");
            commentsError = null;
          },
        );
      },
      onError: (error, stackTrace) {
        print(
            "[CommentsStore] STREAM ERROR (onError): Erro no listener: $error. Instance: ${hashCode}");
        print(stackTrace); // Veja o stack trace completo do erro
        isLoadingComments = false;
        commentsError = "Erro inesperado no stream: $error";
        // comments.clear();
      },
    );
  }

  @action
  Future<bool> updateComment(String commentId, String newText) async {
    if (newText.trim().isEmpty) {
      updateCommentError = "O comentário não pode ficar vazio.";
      return false;
    }

    final originalComment = comments.firstWhere((c) => c.id == commentId,
        orElse: () => throw Exception("Comentário não encontrado para edição"));
    if (originalComment.text == newText.trim()) {
      updateCommentError = "Nenhuma alteração detectada.";
      return false;
    }

    isUpdatingComment = true;
    editingCommentId = commentId;
    updateCommentError = null;
    print("[CommentsStore] Tentando atualizar comentário: $commentId");

    final result = await _updateCommentUseCase(
      commentId: commentId,
      newText: newText.trim(),
    );

    isUpdatingComment = false;
    editingCommentId = null;

    return result.fold(
      (failure) {
        print(
            "[CommentsStore] Falha ao atualizar comentário: ${failure.runtimeType}");
        if (failure is ValidationFailure) {
          updateCommentError = failure.message;
        } else {
          updateCommentError = _mapFailureToMessage(failure);
        }
        return false;
      },
      (_) {
        print(
            "[CommentsStore] Comentário atualizado com sucesso! Aguardando stream...");
        return true;
      },
    );
  }

  @action
  Future<bool> deleteComment(String commentId) async {
    if (commentId.isEmpty) {
      deleteCommentError = "ID do comentário inválido.";
      return false;
    }

    isDeletingComment = true;
    deletingCommentId = commentId;
    deleteCommentError = null;
    print("[CommentsStore] Tentando deletar comentário: $commentId");

    final result = await _deleteCommentUseCase(commentId);

    isDeletingComment = false;
    deletingCommentId = null; // Limpa o ID aqui

    return result.fold(
      (failure) {
        print(
            "[CommentsStore] Falha ao deletar comentário: ${failure.runtimeType}");
        deleteCommentError = _mapFailureToMessage(failure);
        return false;
      },
      (_) {
        print(
            "[CommentsStore] Comentário deletado com sucesso! Aguardando stream...");
        return true;
      },
    );
  }

  @action
  Future<bool> addComment(String movieId, String text) async {
    if (text.trim().isEmpty) {
      addCommentError = "Comentário não pode ser vazio.";
      return false;
    }
    if (!_authStore.isLoggedIn || _authStore.user.id.isEmpty) {
      addCommentError = "Faça login para comentar.";
      return false;
    }
    final userId = _authStore.user.id;
    final userName = _authStore.user.name ??
        _authStore.user.email?.split('@')[0] ??
        "Usuário";

    isAddingComment = true; // ANTES do await
    addCommentError = null;
    print("[CommentsStore] Tentando adicionar comentário...");

    final result = await _addCommentUseCase(
      movieId: movieId,
      userId: userId,
      userName: userName,
      text: text.trim(),
    );

    isAddingComment = false; // DEPOIS do await

    return result.fold(
      (failure) {
        print(
            "[CommentsStore] Falha ao adicionar comentário: ${failure.runtimeType}");
        addCommentError = _mapFailureToMessage(failure);
        return false;
      },
      (_) {
        return true;
      },
    );
  }

  void dispose() {
    print("[CommentsStore] dispose: Cancelando listener de comentários.");
    _commentsSubscription?.cancel();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message ?? 'Erro no Servidor';
    } else if (failure is ValidationFailure) {
      // Adiciona tratamento para ValidationFailure
      return failure.message;
    }
    // Adicione outros tipos de Failure se tiver
    return 'Ocorreu um erro inesperado.';
  }
}
