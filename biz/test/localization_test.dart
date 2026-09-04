import 'dart:ui';

import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/localize/copywriting_strings_ar.dart';
import 'package:biz/localize/copywriting_strings_de.dart';
import 'package:biz/localize/copywriting_strings_es.dart';
import 'package:biz/localize/copywriting_strings_fr.dart';
import 'package:biz/localize/copywriting_strings_it.dart';
import 'package:biz/localize/copywriting_strings_pt.dart';
import 'package:biz/localize/localization_service.dart';
import 'package:biz/localize/tab_labels.dart';
import 'package:biz/localize/tab_translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  test('every translated locale contains the complete Copywriting key set', () {
    final expectedKeys = CopywritingStringsDe.values.keys.toSet();
    final locales = <Map<String, String>>[
      CopywritingStringsFr.values,
      CopywritingStringsIt.values,
      CopywritingStringsPt.values,
      CopywritingStringsEs.values,
      CopywritingStringsAr.values,
    ];

    expect(expectedKeys, hasLength(423));
    for (final locale in locales) {
      expect(locale.keys.toSet(), expectedKeys);
      expect(locale.values, everyElement(isNotEmpty));
    }
  });

  test('locale resolution supports language-only device locales', () {
    expect(
      LocalizationService.resolve(const Locale('de')),
      const Locale('de', 'DE'),
    );
    expect(
      LocalizationService.resolve(const Locale('ar')),
      const Locale('ar', 'AE'),
    );
    expect(
      LocalizationService.resolve(const Locale('zh')),
      LocalizationService.fallbackLocale,
    );
  });

  test('Arabic widget localization uses right-to-left layout', () async {
    final localization = await GlobalWidgetsLocalizations.delegate.load(
      const Locale('ar', 'AE'),
    );
    expect(localization.textDirection, TextDirection.rtl);
  });

  test('Copywriting getters follow the active locale', () {
    Get.locale = const Locale('de', 'DE');
    expect(Copywriting.security_language, 'Sprache');

    Get.locale = const Locale('ar', 'AE');
    expect(Copywriting.security_language, 'لغة');

    Get.locale = null;
  });

  test('every supported locale contains the complete tab label set', () {
    final expectedKeys = TabTranslations.en.keys.toSet();
    final locales = <Map<String, String>>[
      TabTranslations.de,
      TabTranslations.fr,
      TabTranslations.it,
      TabTranslations.pt,
      TabTranslations.es,
      TabTranslations.ar,
    ];

    expect(expectedKeys, hasLength(25));
    for (final locale in locales) {
      expect(locale.keys.toSet(), expectedKeys);
      expect(locale.values, everyElement(isNotEmpty));
    }
  });

  test('tab labels follow locale changes without recreating controllers', () {
    Get.locale = const Locale('de', 'DE');
    expect(TabLabels.all, 'Alle');
    expect(TabLabels.gallery, 'Galerie');

    Get.locale = const Locale('ar', 'AE');
    expect(TabLabels.all, 'الكل');
    expect(TabLabels.gallery, 'المعرض');

    Get.locale = null;
  });
}
