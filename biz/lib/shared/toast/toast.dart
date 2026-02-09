import 'package:flutter/cupertino.dart';

import 'easy_toast_adapter.dart';
import 'toast_interface.dart';

class Toast {
  static final IToast _adapter = EasyToastAdapter();

  static TransitionBuilder init() {
    return _adapter.init();
  }

  static void show(String msg) {
    _adapter.show(msg);
  }

  static void loading({String? status}) {
    _adapter.loading(status: status);
  }

  static void dismiss() {
    _adapter.dismiss();
  }

  static void error(String msg) {
    _adapter.error(msg);
  }

  static void success(String msg) {
    _adapter.success(msg);
  }
}
