import 'package:desafio_loomi/app/core/localization/app_localizations_en.dart';
import 'package:desafio_loomi/app/core/localization/app_localizations_pt.dart';
import 'package:desafio_loomi/app/core/localization/texts/auth_strings.dart';
import 'package:desafio_loomi/app/core/localization/texts/common_strings.dart';
import 'package:desafio_loomi/app/core/localization/texts/movie_strings.dart';
import 'package:desafio_loomi/app/core/localization/texts/profile_strings.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Arquivos de strings por feature
  late final AuthStrings auth = AuthStrings(this);
  // late final MovieStrings movies = MovieStrings(this);
  // late final ProfileStrings profile = ProfileStrings(this);
  // late final CommonStrings common = CommonStrings(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'pt'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'pt':
        return AppLocalizationsPt(locale);
      default:
        return AppLocalizationsEn(locale);
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
