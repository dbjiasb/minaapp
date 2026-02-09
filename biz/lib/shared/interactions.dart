import 'package:flutter/services.dart';

import 'package:biz/shared/toast/toast.dart';

class Interactions {
  // 复制文本到剪贴板
  static Future<void> copyToClipboard(String cpyText) async {
    await Clipboard.setData(ClipboardData(text: cpyText));
    Toast.show('Copied to clipboard: $cpyText');
  }
}
