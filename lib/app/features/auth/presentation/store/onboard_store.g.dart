// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboard_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OnboardStore on _OnboardStoreBase, Store {
  late final _$isLoadingAtom =
      Atom(name: '_OnboardStoreBase.isLoading', context: context);

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
      Atom(name: '_OnboardStoreBase.errorMessage', context: context);

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

  late final _$userDataAtom =
      Atom(name: '_OnboardStoreBase.userData', context: context);

  @override
  Map<String, dynamic>? get userData {
    _$userDataAtom.reportRead();
    return super.userData;
  }

  @override
  set userData(Map<String, dynamic>? value) {
    _$userDataAtom.reportWrite(value, super.userData, () {
      super.userData = value;
    });
  }

  late final _$completeOnboardingAsyncAction =
      AsyncAction('_OnboardStoreBase.completeOnboarding', context: context);

  @override
  Future<void> completeOnboarding() {
    return _$completeOnboardingAsyncAction
        .run(() => super.completeOnboarding());
  }

  late final _$fetchUserDataAsyncAction =
      AsyncAction('_OnboardStoreBase.fetchUserData', context: context);

  @override
  Future<void> fetchUserData() {
    return _$fetchUserDataAsyncAction.run(() => super.fetchUserData());
  }

  late final _$updateProfileAsyncAction =
      AsyncAction('_OnboardStoreBase.updateProfile', context: context);

  @override
  Future<void> updateProfile(Map<String, dynamic> data) {
    return _$updateProfileAsyncAction.run(() => super.updateProfile(data));
  }

  late final _$deleteAccountAsyncAction =
      AsyncAction('_OnboardStoreBase.deleteAccount', context: context);

  @override
  Future<void> deleteAccount() {
    return _$deleteAccountAsyncAction.run(() => super.deleteAccount());
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
errorMessage: ${errorMessage},
userData: ${userData}
    ''';
  }
}
