

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:biz/base/preferences/preferences.dart';

abstract class RvHelper {
  static Widget packWidget(Widget widget) {
    return Obx(() => Preferences.instance.isRv ? Container() : widget);
  }

  //审核通过才执行
  static void approvedInvoke(VoidCallback action) {
    if (Preferences.instance.isRv) {
      action.call();
    }
  }
}