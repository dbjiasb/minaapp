import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'copywriting_translations.dart';

class AppLanguage {
  const AppLanguage(this.locale, this.nativeName);

  final Locale locale;
  final String nativeName;
}

abstract final class LocalizationService {
  static const String _languageStorageKey = 'app_locale_language';
  static const String _countryStorageKey = 'app_locale_country';
  static const Locale fallbackLocale = Locale('en', 'US');

  static const List<AppLanguage> languages = [
    AppLanguage(Locale('en', 'US'), 'English'),
    AppLanguage(Locale('de', 'DE'), 'Deutsch'),
    AppLanguage(Locale('fr', 'FR'), 'Français'),
    AppLanguage(Locale('it', 'IT'), 'Italiano'),
    AppLanguage(Locale('pt', 'PT'), 'Português'),
    AppLanguage(Locale('es', 'ES'), 'Español'),
    AppLanguage(Locale('ar', 'AE'), 'العربية'),
  ];

  static List<Locale> get supportedLocales =>
      languages.map((language) => language.locale).toList(growable: false);

  static Locale get initialLocale {
    final storage = GetStorage();
    final storedLanguage = storage.read<String>(_languageStorageKey);
    final storedCountry = storage.read<String>(_countryStorageKey);
    if (storedLanguage != null) {
      return resolve(Locale(storedLanguage, storedCountry));
    }
    return resolve(Get.deviceLocale);
  }

  static Locale get currentLocale => Get.locale ?? initialLocale;

  static AppLanguage get currentLanguage => languages.firstWhere(
    (language) => language.locale.languageCode == currentLocale.languageCode,
    orElse: () => languages.first,
  );

  static Locale resolve(Locale? locale) {
    if (locale == null) return fallbackLocale;
    return languages
        .firstWhere(
          (language) => language.locale.languageCode == locale.languageCode,
          orElse: () => languages.first,
        )
        .locale;
  }

  static Future<void> updateLocale(Locale locale) async {
    final resolved = resolve(locale);
    await GetStorage().write(_languageStorageKey, resolved.languageCode);
    await GetStorage().write(_countryStorageKey, resolved.countryCode);
    await Get.updateLocale(resolved);
  }

  static String text(String key, String Function() fallback) {
    return CopywritingTranslations.valuesFor(currentLocale)?[key] ?? fallback();
  }
}
