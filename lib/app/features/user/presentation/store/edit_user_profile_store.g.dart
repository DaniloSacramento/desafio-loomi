// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_user_profile_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EditUserProfileStore on _EditUserProfileStoreBase, Store {
  late final _$currentPhotoUrlAtom =
      Atom(name: '_EditUserProfileStoreBase.currentPhotoUrl', context: context);

  @override
  String? get currentPhotoUrl {
    _$currentPhotoUrlAtom.reportRead();
    return super.currentPhotoUrl;
  }

  @override
  set currentPhotoUrl(String? value) {
    _$currentPhotoUrlAtom.reportWrite(value, super.currentPhotoUrl, () {
      super.currentPhotoUrl = value;
    });
  }

  late final _$selectedImageFileAtom = Atom(
      name: '_EditUserProfileStoreBase.selectedImageFile', context: context);

  @override
  File? get selectedImageFile {
    _$selectedImageFileAtom.reportRead();
    return super.selectedImageFile;
  }

  @override
  set selectedImageFile(File? value) {
    _$selectedImageFileAtom.reportWrite(value, super.selectedImageFile, () {
      super.selectedImageFile = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: '_EditUserProfileStoreBase.isLoading', context: context);

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
      Atom(name: '_EditUserProfileStoreBase.errorMessage', context: context);

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

  late final _$updateSuccessAtom =
      Atom(name: '_EditUserProfileStoreBase.updateSuccess', context: context);

  @override
  bool get updateSuccess {
    _$updateSuccessAtom.reportRead();
    return super.updateSuccess;
  }

  @override
  set updateSuccess(bool value) {
    _$updateSuccessAtom.reportWrite(value, super.updateSuccess, () {
      super.updateSuccess = value;
    });
  }

  late final _$pickImageAsyncAction =
      AsyncAction('_EditUserProfileStoreBase.pickImage', context: context);

  @override
  Future<void> pickImage() {
    return _$pickImageAsyncAction.run(() => super.pickImage());
  }

  late final _$submitUpdateProfileAsyncAction = AsyncAction(
      '_EditUserProfileStoreBase.submitUpdateProfile',
      context: context);

  @override
  Future<void> submitUpdateProfile() {
    return _$submitUpdateProfileAsyncAction
        .run(() => super.submitUpdateProfile());
  }

  late final _$_EditUserProfileStoreBaseActionController =
      ActionController(name: '_EditUserProfileStoreBase', context: context);

  @override
  void _loadInitialData() {
    final _$actionInfo = _$_EditUserProfileStoreBaseActionController
        .startAction(name: '_EditUserProfileStoreBase._loadInitialData');
    try {
      return super._loadInitialData();
    } finally {
      _$_EditUserProfileStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentPhotoUrl: ${currentPhotoUrl},
selectedImageFile: ${selectedImageFile},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
updateSuccess: ${updateSuccess}
    ''';
  }
}
