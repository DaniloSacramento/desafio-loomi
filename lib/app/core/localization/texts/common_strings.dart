import 'package:desafio_loomi/app/core/localization/app_localizations.dart';
import 'package:desafio_loomi/app/core/localization/app_localizations_pt.dart';

abstract class CommonStringsBase {
  String get okButton;
  String get cancelButton;
  String get errorTitle;
  String get retryButton;
}

class CommonStrings {
  final AppLocalizations _l;

  CommonStrings(this._l);

  String get okButton => _l is AppLocalizationsPt ? 'OK' : 'OK';
  String get cancelButton => _l is AppLocalizationsPt ? 'Cancelar' : 'Cancel';
  String get errorTitle => _l is AppLocalizationsPt ? 'Erro' : 'Error';
  String get retryButton =>
      _l is AppLocalizationsPt ? 'Tentar novamente' : 'Retry';
}
