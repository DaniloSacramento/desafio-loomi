// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_player_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VideoPlayerStore on _VideoPlayerStoreBase, Store {
  late final _$subtitlesAtom =
      Atom(name: '_VideoPlayerStoreBase.subtitles', context: context);

  @override
  ObservableList<Subtitle> get subtitles {
    _$subtitlesAtom.reportRead();
    return super.subtitles;
  }

  @override
  set subtitles(ObservableList<Subtitle> value) {
    _$subtitlesAtom.reportWrite(value, super.subtitles, () {
      super.subtitles = value;
    });
  }

  late final _$selectedSubtitleAtom =
      Atom(name: '_VideoPlayerStoreBase.selectedSubtitle', context: context);

  @override
  Subtitle? get selectedSubtitle {
    _$selectedSubtitleAtom.reportRead();
    return super.selectedSubtitle;
  }

  @override
  set selectedSubtitle(Subtitle? value) {
    _$selectedSubtitleAtom.reportWrite(value, super.selectedSubtitle, () {
      super.selectedSubtitle = value;
    });
  }

  late final _$isLoadingSubtitlesAtom =
      Atom(name: '_VideoPlayerStoreBase.isLoadingSubtitles', context: context);

  @override
  bool get isLoadingSubtitles {
    _$isLoadingSubtitlesAtom.reportRead();
    return super.isLoadingSubtitles;
  }

  @override
  set isLoadingSubtitles(bool value) {
    _$isLoadingSubtitlesAtom.reportWrite(value, super.isLoadingSubtitles, () {
      super.isLoadingSubtitles = value;
    });
  }

  late final _$subtitleErrorAtom =
      Atom(name: '_VideoPlayerStoreBase.subtitleError', context: context);

  @override
  String? get subtitleError {
    _$subtitleErrorAtom.reportRead();
    return super.subtitleError;
  }

  @override
  set subtitleError(String? value) {
    _$subtitleErrorAtom.reportWrite(value, super.subtitleError, () {
      super.subtitleError = value;
    });
  }

  late final _$fetchSubtitlesAsyncAction =
      AsyncAction('_VideoPlayerStoreBase.fetchSubtitles', context: context);

  @override
  Future<void> fetchSubtitles(int movieId) {
    return _$fetchSubtitlesAsyncAction.run(() => super.fetchSubtitles(movieId));
  }

  late final _$_VideoPlayerStoreBaseActionController =
      ActionController(name: '_VideoPlayerStoreBase', context: context);

  @override
  void selectSubtitle(Subtitle? subtitle) {
    final _$actionInfo = _$_VideoPlayerStoreBaseActionController.startAction(
        name: '_VideoPlayerStoreBase.selectSubtitle');
    try {
      return super.selectSubtitle(subtitle);
    } finally {
      _$_VideoPlayerStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
subtitles: ${subtitles},
selectedSubtitle: ${selectedSubtitle},
isLoadingSubtitles: ${isLoadingSubtitles},
subtitleError: ${subtitleError}
    ''';
  }
}
