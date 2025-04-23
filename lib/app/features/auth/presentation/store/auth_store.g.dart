// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthStore on _AuthStoreBase, Store {
  Computed<bool>? _$isLoggedInComputed;

  @override
  bool get isLoggedIn =>
      (_$isLoggedInComputed ??= Computed<bool>(() => super.isLoggedIn,
              name: '_AuthStoreBase.isLoggedIn'))
          .value;

  late final _$userAtom = Atom(name: '_AuthStoreBase.user', context: context);

  @override
  AppUser get user {
    _$userAtom.reportRead();
    return super.user;
  }

  @override
  set user(AppUser value) {
    _$userAtom.reportWrite(value, super.user, () {
      super.user = value;
    });
  }

  late final _$strapiUserIdAtom =
      Atom(name: '_AuthStoreBase.strapiUserId', context: context);

  @override
  int? get strapiUserId {
    _$strapiUserIdAtom.reportRead();
    return super.strapiUserId;
  }

  @override
  set strapiUserId(int? value) {
    _$strapiUserIdAtom.reportWrite(value, super.strapiUserId, () {
      super.strapiUserId = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: '_AuthStoreBase.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: '_AuthStoreBase.errorMessage', context: context);

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

  late final _$_fetchAndSetStrapiUserIdAsyncAction =
      AsyncAction('_AuthStoreBase._fetchAndSetStrapiUserId', context: context);

  @override
  Future<void> _fetchAndSetStrapiUserId() {
    return _$_fetchAndSetStrapiUserIdAsyncAction
        .run(() => super._fetchAndSetStrapiUserId());
  }

  late final _$signInWithEmailAndPasswordAsyncAction = AsyncAction(
      '_AuthStoreBase.signInWithEmailAndPassword',
      context: context);

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) {
    return _$signInWithEmailAndPasswordAsyncAction
        .run(() => super.signInWithEmailAndPassword(email, password));
  }

  late final _$signUpWithEmailAndPasswordAsyncAction = AsyncAction(
      '_AuthStoreBase.signUpWithEmailAndPassword',
      context: context);

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password) {
    return _$signUpWithEmailAndPasswordAsyncAction
        .run(() => super.signUpWithEmailAndPassword(email, password));
  }

  late final _$signInWithGoogleAsyncAction =
      AsyncAction('_AuthStoreBase.signInWithGoogle', context: context);

  @override
  Future<void> signInWithGoogle() {
    return _$signInWithGoogleAsyncAction.run(() => super.signInWithGoogle());
  }

  late final _$signOutAsyncAction =
      AsyncAction('_AuthStoreBase.signOut', context: context);

  @override
  Future<void> signOut() {
    return _$signOutAsyncAction.run(() => super.signOut());
  }

  @override
  String toString() {
    return '''
user: ${user},
strapiUserId: ${strapiUserId},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
isLoggedIn: ${isLoggedIn}
    ''';
  }
}
