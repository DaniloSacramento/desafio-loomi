// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_password_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ChangePasswordStore on _ChangePasswordStoreBase, Store {
  late final _$obscureCurrentPasswordAtom = Atom(
      name: '_ChangePasswordStoreBase.obscureCurrentPassword',
      context: context);

  @override
  bool get obscureCurrentPassword {
    _$obscureCurrentPasswordAtom.reportRead();
    return super.obscureCurrentPassword;
  }

  @override
  set obscureCurrentPassword(bool value) {
    _$obscureCurrentPasswordAtom
        .reportWrite(value, super.obscureCurrentPassword, () {
      super.obscureCurrentPassword = value;
    });
  }

  late final _$obscureNewPasswordAtom = Atom(
      name: '_ChangePasswordStoreBase.obscureNewPassword', context: context);

  @override
  bool get obscureNewPassword {
    _$obscureNewPasswordAtom.reportRead();
    return super.obscureNewPassword;
  }

  @override
  set obscureNewPassword(bool value) {
    _$obscureNewPasswordAtom.reportWrite(value, super.obscureNewPassword, () {
      super.obscureNewPassword = value;
    });
  }

  late final _$obscureConfirmPasswordAtom = Atom(
      name: '_ChangePasswordStoreBase.obscureConfirmPassword',
      context: context);

  @override
  bool get obscureConfirmPassword {
    _$obscureConfirmPasswordAtom.reportRead();
    return super.obscureConfirmPassword;
  }

  @override
  set obscureConfirmPassword(bool value) {
    _$obscureConfirmPasswordAtom
        .reportWrite(value, super.obscureConfirmPassword, () {
      super.obscureConfirmPassword = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: '_ChangePasswordStoreBase.isLoading', context: context);

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
      Atom(name: '_ChangePasswordStoreBase.errorMessage', context: context);

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

  late final _$changePasswordSuccessAtom = Atom(
      name: '_ChangePasswordStoreBase.changePasswordSuccess', context: context);

  @override
  bool get changePasswordSuccess {
    _$changePasswordSuccessAtom.reportRead();
    return super.changePasswordSuccess;
  }

  @override
  set changePasswordSuccess(bool value) {
    _$changePasswordSuccessAtom.reportWrite(value, super.changePasswordSuccess,
        () {
      super.changePasswordSuccess = value;
    });
  }

  late final _$submitChangePasswordAsyncAction = AsyncAction(
      '_ChangePasswordStoreBase.submitChangePassword',
      context: context);

  @override
  Future<void> submitChangePassword() {
    return _$submitChangePasswordAsyncAction
        .run(() => super.submitChangePassword());
  }

  late final _$_ChangePasswordStoreBaseActionController =
      ActionController(name: '_ChangePasswordStoreBase', context: context);

  @override
  void toggleCurrentPasswordVisibility() {
    final _$actionInfo = _$_ChangePasswordStoreBaseActionController.startAction(
        name: '_ChangePasswordStoreBase.toggleCurrentPasswordVisibility');
    try {
      return super.toggleCurrentPasswordVisibility();
    } finally {
      _$_ChangePasswordStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleNewPasswordVisibility() {
    final _$actionInfo = _$_ChangePasswordStoreBaseActionController.startAction(
        name: '_ChangePasswordStoreBase.toggleNewPasswordVisibility');
    try {
      return super.toggleNewPasswordVisibility();
    } finally {
      _$_ChangePasswordStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleConfirmPasswordVisibility() {
    final _$actionInfo = _$_ChangePasswordStoreBaseActionController.startAction(
        name: '_ChangePasswordStoreBase.toggleConfirmPasswordVisibility');
    try {
      return super.toggleConfirmPasswordVisibility();
    } finally {
      _$_ChangePasswordStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
obscureCurrentPassword: ${obscureCurrentPassword},
obscureNewPassword: ${obscureNewPassword},
obscureConfirmPassword: ${obscureConfirmPassword},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
changePasswordSuccess: ${changePasswordSuccess}
    ''';
  }
}
