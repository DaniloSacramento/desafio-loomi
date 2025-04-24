// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CommentsStore on _CommentsStoreBase, Store {
  late final _$commentsAtom =
      Atom(name: '_CommentsStoreBase.comments', context: context);

  @override
  ObservableList<CommentEntity> get comments {
    _$commentsAtom.reportRead();
    return super.comments;
  }

  @override
  set comments(ObservableList<CommentEntity> value) {
    _$commentsAtom.reportWrite(value, super.comments, () {
      super.comments = value;
    });
  }

  late final _$isLoadingCommentsAtom =
      Atom(name: '_CommentsStoreBase.isLoadingComments', context: context);

  @override
  bool get isLoadingComments {
    _$isLoadingCommentsAtom.reportRead();
    return super.isLoadingComments;
  }

  @override
  set isLoadingComments(bool value) {
    _$isLoadingCommentsAtom.reportWrite(value, super.isLoadingComments, () {
      super.isLoadingComments = value;
    });
  }

  late final _$commentsErrorAtom =
      Atom(name: '_CommentsStoreBase.commentsError', context: context);

  @override
  String? get commentsError {
    _$commentsErrorAtom.reportRead();
    return super.commentsError;
  }

  @override
  set commentsError(String? value) {
    _$commentsErrorAtom.reportWrite(value, super.commentsError, () {
      super.commentsError = value;
    });
  }

  late final _$isAddingCommentAtom =
      Atom(name: '_CommentsStoreBase.isAddingComment', context: context);

  @override
  bool get isAddingComment {
    _$isAddingCommentAtom.reportRead();
    return super.isAddingComment;
  }

  @override
  set isAddingComment(bool value) {
    _$isAddingCommentAtom.reportWrite(value, super.isAddingComment, () {
      super.isAddingComment = value;
    });
  }

  late final _$addCommentErrorAtom =
      Atom(name: '_CommentsStoreBase.addCommentError', context: context);

  @override
  String? get addCommentError {
    _$addCommentErrorAtom.reportRead();
    return super.addCommentError;
  }

  @override
  set addCommentError(String? value) {
    _$addCommentErrorAtom.reportWrite(value, super.addCommentError, () {
      super.addCommentError = value;
    });
  }

  late final _$isDeletingCommentAtom =
      Atom(name: '_CommentsStoreBase.isDeletingComment', context: context);

  @override
  bool get isDeletingComment {
    _$isDeletingCommentAtom.reportRead();
    return super.isDeletingComment;
  }

  @override
  set isDeletingComment(bool value) {
    _$isDeletingCommentAtom.reportWrite(value, super.isDeletingComment, () {
      super.isDeletingComment = value;
    });
  }

  late final _$deletingCommentIdAtom =
      Atom(name: '_CommentsStoreBase.deletingCommentId', context: context);

  @override
  String? get deletingCommentId {
    _$deletingCommentIdAtom.reportRead();
    return super.deletingCommentId;
  }

  @override
  set deletingCommentId(String? value) {
    _$deletingCommentIdAtom.reportWrite(value, super.deletingCommentId, () {
      super.deletingCommentId = value;
    });
  }

  late final _$deleteCommentErrorAtom =
      Atom(name: '_CommentsStoreBase.deleteCommentError', context: context);

  @override
  String? get deleteCommentError {
    _$deleteCommentErrorAtom.reportRead();
    return super.deleteCommentError;
  }

  @override
  set deleteCommentError(String? value) {
    _$deleteCommentErrorAtom.reportWrite(value, super.deleteCommentError, () {
      super.deleteCommentError = value;
    });
  }

  late final _$isUpdatingCommentAtom =
      Atom(name: '_CommentsStoreBase.isUpdatingComment', context: context);

  @override
  bool get isUpdatingComment {
    _$isUpdatingCommentAtom.reportRead();
    return super.isUpdatingComment;
  }

  @override
  set isUpdatingComment(bool value) {
    _$isUpdatingCommentAtom.reportWrite(value, super.isUpdatingComment, () {
      super.isUpdatingComment = value;
    });
  }

  late final _$editingCommentIdAtom =
      Atom(name: '_CommentsStoreBase.editingCommentId', context: context);

  @override
  String? get editingCommentId {
    _$editingCommentIdAtom.reportRead();
    return super.editingCommentId;
  }

  @override
  set editingCommentId(String? value) {
    _$editingCommentIdAtom.reportWrite(value, super.editingCommentId, () {
      super.editingCommentId = value;
    });
  }

  late final _$updateCommentErrorAtom =
      Atom(name: '_CommentsStoreBase.updateCommentError', context: context);

  @override
  String? get updateCommentError {
    _$updateCommentErrorAtom.reportRead();
    return super.updateCommentError;
  }

  @override
  set updateCommentError(String? value) {
    _$updateCommentErrorAtom.reportWrite(value, super.updateCommentError, () {
      super.updateCommentError = value;
    });
  }

  late final _$updateCommentAsyncAction =
      AsyncAction('_CommentsStoreBase.updateComment', context: context);

  @override
  Future<bool> updateComment(String commentId, String newText) {
    return _$updateCommentAsyncAction
        .run(() => super.updateComment(commentId, newText));
  }

  late final _$deleteCommentAsyncAction =
      AsyncAction('_CommentsStoreBase.deleteComment', context: context);

  @override
  Future<bool> deleteComment(String commentId) {
    return _$deleteCommentAsyncAction.run(() => super.deleteComment(commentId));
  }

  late final _$addCommentAsyncAction =
      AsyncAction('_CommentsStoreBase.addComment', context: context);

  @override
  Future<bool> addComment(String movieId, String text) {
    return _$addCommentAsyncAction.run(() => super.addComment(movieId, text));
  }

  late final _$_CommentsStoreBaseActionController =
      ActionController(name: '_CommentsStoreBase', context: context);

  @override
  void listenToComments(String movieId) {
    final _$actionInfo = _$_CommentsStoreBaseActionController.startAction(
        name: '_CommentsStoreBase.listenToComments');
    try {
      return super.listenToComments(movieId);
    } finally {
      _$_CommentsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
comments: ${comments},
isLoadingComments: ${isLoadingComments},
commentsError: ${commentsError},
isAddingComment: ${isAddingComment},
addCommentError: ${addCommentError},
isDeletingComment: ${isDeletingComment},
deletingCommentId: ${deletingCommentId},
deleteCommentError: ${deleteCommentError},
isUpdatingComment: ${isUpdatingComment},
editingCommentId: ${editingCommentId},
updateCommentError: ${updateCommentError}
    ''';
  }
}
