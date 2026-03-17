import 'package:biz/base/crypt/routes.dart';

import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../shared/alert.dart';

class AIModeUtils {
  static Future<bool> showWarningAlert({String? content}) async {
    bool ret = await showConfirmAlert(Security.security_warning, content ?? Copywriting.security_the_MODE_will_only_take_effect_after_you_have_acquired_this_character__Continue_purchasing_, confirmText: Security.security_sure, cancelText: Security.security_cancel);
    return ret;
  }

  static Map fromUrl(String url) {
    Uri uri = Uri.parse(url);
    return uri.queryParameters;
  }
}
