import 'package:desafio_loomi/app/core/localization/app_localizations.dart';
import 'package:desafio_loomi/app/core/localization/app_localizations_pt.dart';

abstract class AuthStringsBase {
  String get loginTitle;
  String get emailLabel;
  String get passwordLabel;
  String get loginButton;
  String get registerButton;
  String get googleLogin;
}

class AuthStrings {
  final AppLocalizations _l;

  AuthStrings(this._l);

  String get loginTitle => _l is AppLocalizationsPt ? 'Login' : 'Sign In';

  String get emailLabel => _l is AppLocalizationsPt ? 'E-mail' : 'Email';
}
