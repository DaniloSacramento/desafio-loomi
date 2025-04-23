// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MovieStore on _MovieStoreBase, Store {
  Computed<Set<int>>? _$likedMovieIdsComputed;

  @override
  Set<int> get likedMovieIds =>
      (_$likedMovieIdsComputed ??= Computed<Set<int>>(() => super.likedMovieIds,
              name: '_MovieStoreBase.likedMovieIds'))
          .value;

  late final _$moviesAtom =
      Atom(name: '_MovieStoreBase.movies', context: context);

  @override
  ObservableList<Movie> get movies {
    _$moviesAtom.reportRead();
    return super.movies;
  }

  @override
  set movies(ObservableList<Movie> value) {
    _$moviesAtom.reportWrite(value, super.movies, () {
      super.movies = value;
    });
  }

  late final _$userLikesAtom =
      Atom(name: '_MovieStoreBase.userLikes', context: context);

  @override
  ObservableList<Like> get userLikes {
    _$userLikesAtom.reportRead();
    return super.userLikes;
  }

  @override
  set userLikes(ObservableList<Like> value) {
    _$userLikesAtom.reportWrite(value, super.userLikes, () {
      super.userLikes = value;
    });
  }

  late final _$isLoadingMoviesAtom =
      Atom(name: '_MovieStoreBase.isLoadingMovies', context: context);

  @override
  bool get isLoadingMovies {
    _$isLoadingMoviesAtom.reportRead();
    return super.isLoadingMovies;
  }

  @override
  set isLoadingMovies(bool value) {
    _$isLoadingMoviesAtom.reportWrite(value, super.isLoadingMovies, () {
      super.isLoadingMovies = value;
    });
  }

  late final _$isLoadingLikesAtom =
      Atom(name: '_MovieStoreBase.isLoadingLikes', context: context);

  @override
  bool get isLoadingLikes {
    _$isLoadingLikesAtom.reportRead();
    return super.isLoadingLikes;
  }

  @override
  set isLoadingLikes(bool value) {
    _$isLoadingLikesAtom.reportWrite(value, super.isLoadingLikes, () {
      super.isLoadingLikes = value;
    });
  }

  late final _$likingInProgressAtom =
      Atom(name: '_MovieStoreBase.likingInProgress', context: context);

  @override
  ObservableSet<int> get likingInProgress {
    _$likingInProgressAtom.reportRead();
    return super.likingInProgress;
  }

  @override
  set likingInProgress(ObservableSet<int> value) {
    _$likingInProgressAtom.reportWrite(value, super.likingInProgress, () {
      super.likingInProgress = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: '_MovieStoreBase.errorMessage', context: context);

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$currentPageAtom =
      Atom(name: '_MovieStoreBase.currentPage', context: context);

  @override
  int get currentPage {
    _$currentPageAtom.reportRead();
    return super.currentPage;
  }

  @override
  set currentPage(int value) {
    _$currentPageAtom.reportWrite(value, super.currentPage, () {
      super.currentPage = value;
    });
  }

  late final _$gradientColor1Atom =
      Atom(name: '_MovieStoreBase.gradientColor1', context: context);

  @override
  Color get gradientColor1 {
    _$gradientColor1Atom.reportRead();
    return super.gradientColor1;
  }

  @override
  set gradientColor1(Color value) {
    _$gradientColor1Atom.reportWrite(value, super.gradientColor1, () {
      super.gradientColor1 = value;
    });
  }

  late final _$gradientColor2Atom =
      Atom(name: '_MovieStoreBase.gradientColor2', context: context);

  @override
  Color get gradientColor2 {
    _$gradientColor2Atom.reportRead();
    return super.gradientColor2;
  }

  @override
  set gradientColor2(Color value) {
    _$gradientColor2Atom.reportWrite(value, super.gradientColor2, () {
      super.gradientColor2 = value;
    });
  }

  late final _$isGeneratingPaletteAtom =
      Atom(name: '_MovieStoreBase.isGeneratingPalette', context: context);

  @override
  bool get isGeneratingPalette {
    _$isGeneratingPaletteAtom.reportRead();
    return super.isGeneratingPalette;
  }

  @override
  set isGeneratingPalette(bool value) {
    _$isGeneratingPaletteAtom.reportWrite(value, super.isGeneratingPalette, () {
      super.isGeneratingPalette = value;
    });
  }

  late final _$fetchMoviesAsyncAction =
      AsyncAction('_MovieStoreBase.fetchMovies', context: context);

  @override
  Future<void> fetchMovies() {
    return _$fetchMoviesAsyncAction.run(() => super.fetchMovies());
  }

  late final _$fetchLikesAsyncAction =
      AsyncAction('_MovieStoreBase.fetchLikes', context: context);

  @override
  Future<void> fetchLikes() {
    return _$fetchLikesAsyncAction.run(() => super.fetchLikes());
  }

  late final _$rateMovieAsyncAction =
      AsyncAction('_MovieStoreBase.rateMovie', context: context);

  @override
  Future<void> rateMovie(int movieId, RatingAction action) {
    return _$rateMovieAsyncAction.run(() => super.rateMovie(movieId, action));
  }

  late final _$toggleLikeAsyncAction =
      AsyncAction('_MovieStoreBase.toggleLike', context: context);

  @override
  Future<void> toggleLike(int movieId) {
    return _$toggleLikeAsyncAction.run(() => super.toggleLike(movieId));
  }

  late final _$shareMovieAsyncAction =
      AsyncAction('_MovieStoreBase.shareMovie', context: context);

  @override
  Future<void> shareMovie(Movie movie) {
    return _$shareMovieAsyncAction.run(() => super.shareMovie(movie));
  }

  late final _$updateBackgroundGradientAsyncAction =
      AsyncAction('_MovieStoreBase.updateBackgroundGradient', context: context);

  @override
  Future<void> updateBackgroundGradient({bool forceUpdate = false}) {
    return _$updateBackgroundGradientAsyncAction
        .run(() => super.updateBackgroundGradient(forceUpdate: forceUpdate));
  }

  late final _$_MovieStoreBaseActionController =
      ActionController(name: '_MovieStoreBase', context: context);

  @override
  void setCurrentPage(int newPage) {
    final _$actionInfo = _$_MovieStoreBaseActionController.startAction(
        name: '_MovieStoreBase.setCurrentPage');
    try {
      return super.setCurrentPage(newPage);
    } finally {
      _$_MovieStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _resetGradientColors() {
    final _$actionInfo = _$_MovieStoreBaseActionController.startAction(
        name: '_MovieStoreBase._resetGradientColors');
    try {
      return super._resetGradientColors();
    } finally {
      _$_MovieStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
movies: ${movies},
userLikes: ${userLikes},
isLoadingMovies: ${isLoadingMovies},
isLoadingLikes: ${isLoadingLikes},
likingInProgress: ${likingInProgress},
errorMessage: ${errorMessage},
currentPage: ${currentPage},
gradientColor1: ${gradientColor1},
gradientColor2: ${gradientColor2},
isGeneratingPalette: ${isGeneratingPalette},
likedMovieIds: ${likedMovieIds}
    ''';
  }
}
