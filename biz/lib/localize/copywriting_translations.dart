import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'copywriting_strings_ar.dart';
import 'copywriting_strings_de.dart';
import 'copywriting_strings_en.dart';
import 'copywriting_strings_es.dart';
import 'copywriting_strings_fr.dart';
import 'copywriting_strings_it.dart';
import 'copywriting_strings_pt.dart';

final class CopywritingTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => const {
    'en_US': CopywritingStringsEn.values,
    'de_DE': CopywritingStringsDe.values,
    'fr_FR': CopywritingStringsFr.values,
    'it_IT': CopywritingStringsIt.values,
    'pt_PT': CopywritingStringsPt.values,
    'es_ES': CopywritingStringsEs.values,
    'ar_AE': CopywritingStringsAr.values,
  };

  static Map<String, String>? valuesFor(Locale locale) {
    return switch (locale.languageCode) {
      'de' => CopywritingStringsDe.values,
      'fr' => CopywritingStringsFr.values,
      'it' => CopywritingStringsIt.values,
      'pt' => CopywritingStringsPt.values,
      'es' => CopywritingStringsEs.values,
      'ar' => CopywritingStringsAr.values,
      'en' => CopywritingStringsEn.values,
      _ => null,
    };
  }
}
