import '../base/crypt/copywriting.dart';
import 'localization_service.dart';
import 'tab_translations.dart';

/// Locale-aware labels for page tabs.
abstract final class TabLabels {
  static String _text(String key) =>
      TabTranslations.valuesFor(LocalizationService.currentLocale)[key] ??
      TabTranslations.en[key]!;

  static String get all => _text('all');
  static String get virtual => _text('virtual');
  static String get real => _text('real');
  static String get realGirls => _text('real_girls');
  static String get recommend => _text('recommend');
  static String get oc => _text('oc');
  static String get featured => _text('featured');
  static String get story => _text('story');
  static String get anime => _text('anime');
  static String get realistic => _text('realistic');
  static String get companions => _text('companions');
  static String get moment => _text('moment');
  static String get gallery => _text('gallery');
  static String get character => _text('character');
  static String get life => _text('life');
  static String get private => _text('private');
  static String get discovery => _text('discovery');
  static String get match => _text('match');
  static String get basic => _text('basic');
  static String get advanced => _text('advanced');
  static String get followed => _text('followed');
  static String get photos => _text('photos');
  static String get videos => _text('videos');
  static String get select => _text('select');
  static String get enter => _text('enter');

  static String get groupChat => Copywriting.security_group_Chat;
  static String get forYou => Copywriting.security_for_You;
  static String get proOnly => Copywriting.security_pro_only;
}
