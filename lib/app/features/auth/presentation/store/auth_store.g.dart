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

  late final _$isDeletingAccountAtom =
      Atom(name: '_AuthStoreBase.isDeletingAccount', context: context);

  @override
  bool get isDeletingAccount {
    _$isDeletingAccountAtom.reportRead();
    return super.isDeletingAccount;
  }

  @override
  set isDeletingAccount(bool value) {
    _$isDeletingAccountAtom.reportWrite(value, super.isDeletingAccount, () {
      super.isDeletingAccount = value;
    });
  }

  late final _$deleteAccountErrorAtom =
      Atom(name: '_AuthStoreBase.deleteAccountError', context: context);

  @override
  String? get deleteAccountError {
    _$deleteAccountErrorAtom.reportRead();
    return super.deleteAccountError;
  }

  @override
  set deleteAccountError(String? value) {
    _$deleteAccountErrorAtom.reportWrite(value, super.deleteAccountError, () {
      super.deleteAccountError = value;
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

  late final _$isLoadingProfileAtom =
      Atom(name: '_AuthStoreBase.isLoadingProfile', context: context);

  @override
  bool get isLoadingProfile {
    _$isLoadingProfileAtom.reportRead();
    return super.isLoadingProfile;
  }

  @override
  set isLoadingProfile(bool value) {
    _$isLoadingProfileAtom.reportWrite(value, super.isLoadingProfile, () {
      super.isLoadingProfile = value;
    });
  }

  late final _$_fetchAndSyncStrapiProfileAsyncAction = AsyncAction(
      '_AuthStoreBase._fetchAndSyncStrapiProfile',
      context: context);

  @override
  Future<void> _fetchAndSyncStrapiProfile() {
    return _$_fetchAndSyncStrapiProfileAsyncAction
        .run(() => super._fetchAndSyncStrapiProfile());
  }

  late final _$signInWithGoogleAsyncAction =
      AsyncAction('_AuthStoreBase.signInWithGoogle', context: context);

  @override
  Future<AppUser> signInWithGoogle() {
    return _$signInWithGoogleAsyncAction.run(() => super.signInWithGoogle());
  }

  late final _$signInWithAppleAsyncAction =
      AsyncAction('_AuthStoreBase.signInWithApple', context: context);

  @override
  Future<AppUser> signInWithApple() {
    return _$signInWithAppleAsyncAction.run(() => super.signInWithApple());
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

  late final _$signOutAsyncAction =
      AsyncAction('_AuthStoreBase.signOut', context: context);

  @override
  Future<void> signOut() {
    return _$signOutAsyncAction.run(() => super.signOut());
  }

  late final _$updateUserProfileAsyncAction =
      AsyncAction('_AuthStoreBase.updateUserProfile', context: context);

  @override
  Future<void> updateUserProfile({required String username}) {
    return _$updateUserProfileAsyncAction
        .run(() => super.updateUserProfile(username: username));
  }

  late final _$deleteUserAccountAsyncAction =
      AsyncAction('_AuthStoreBase.deleteUserAccount', context: context);

  @override
  Future<void> deleteUserAccount(String currentPassword) {
    return _$deleteUserAccountAsyncAction
        .run(() => super.deleteUserAccount(currentPassword));
  }

  late final _$changePasswordAsyncAction =
      AsyncAction('_AuthStoreBase.changePassword', context: context);

  @override
  Future<void> changePassword(String currentPassword, String newPassword) {
    return _$changePasswordAsyncAction
        .run(() => super.changePassword(currentPassword, newPassword));
  }

  late final _$_AuthStoreBaseActionController =
      ActionController(name: '_AuthStoreBase', context: context);

  @override
  void _clearErrorAndLoading() {
    final _$actionInfo = _$_AuthStoreBaseActionController.startAction(
        name: '_AuthStoreBase._clearErrorAndLoading');
    try {
      return super._clearErrorAndLoading();
    } finally {
      _$_AuthStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleAuthError(dynamic e) {
    final _$actionInfo = _$_AuthStoreBaseActionController.startAction(
        name: '_AuthStoreBase._handleAuthError');
    try {
      return super._handleAuthError(e);
    } finally {
      _$_AuthStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
user: ${user},
strapiUserId: ${strapiUserId},
isDeletingAccount: ${isDeletingAccount},
deleteAccountError: ${deleteAccountError},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
isLoadingProfile: ${isLoadingProfile},
isLoggedIn: ${isLoggedIn}
    ''';
  }
}
