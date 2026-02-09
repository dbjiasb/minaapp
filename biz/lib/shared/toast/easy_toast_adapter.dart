import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import './toast_interface.dart';
class EasyToastAdapter implements IToast {
  @override
  void dismiss() {
    EasyLoading.dismiss();
  }

  @override
  void error(String msg) {
    dismiss();
    EasyLoading.showError(msg);
  }

  @override
  void loading({String? status}) {
    EasyLoading.show(status: status);
  }

  @override
  void show(String msg) {
    dismiss();
    EasyLoading.showToast(msg);
  }

  @override
  void success(String msg) {
    dismiss();
    EasyLoading.showSuccess(msg);
  }

  @override
  TransitionBuilder init() {
    return EasyLoading.init();
  }
}
