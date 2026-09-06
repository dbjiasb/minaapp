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

    expect(expectedKeys, hasLength(436));
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

    Get.locale = const Locale('fr', 'FR');
    expect(Copywriting.security_Cancel, 'Annuler');
    expect(Copywriting.security_Confirm, 'Confirmer');
    expect(Copywriting.security_reset, 'Réinitialiser');
    expect(Copywriting.security_Report, 'Signaler');
    expect(Copywriting.security_block, 'Bloquer');
    expect(Copywriting.security_switch, 'Changer');
    expect(
      Copywriting.security_clear_history_with_user.replaceAll('{name}', 'Alice'),
      'Effacer l’historique avec « Alice »',
    );
    expect(Copywriting.unlockCost(50, 1), 'Le déverrouillage coûtera 50 Gemmes');
    expect(Copywriting.unlockCost(20, 0), 'Le déverrouillage coûtera 20 Pièces');

    Get.locale = const Locale('en', 'US');
    expect(Copywriting.security_Cancel, 'Cancel');
    expect(Copywriting.security_Confirm, 'Confirm');
    expect(Copywriting.unlockCost(50, 1), 'Unlocking will cost 50 Gems');

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

    expect(expectedKeys, hasLength(26));
    for (final locale in locales) {
      expect(locale.keys.toSet(), expectedKeys);
      expect(locale.values, everyElement(isNotEmpty));
    }
  });

  test('tab labels follow locale changes without recreating controllers', () {
    Get.locale = const Locale('de', 'DE');
    expect(TabLabels.all, 'Alle');
    expect(TabLabels.gallery, 'Galerie');
    expect(TabLabels.chats, 'Chats');

    Get.locale = const Locale('ar', 'AE');
    expect(TabLabels.all, 'الكل');
    expect(TabLabels.gallery, 'المعرض');
    expect(TabLabels.chats, 'الدردشات');

    Get.locale = null;
  });
}
