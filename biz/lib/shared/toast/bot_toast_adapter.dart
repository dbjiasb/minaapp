import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import './toast_interface.dart';

// 创建扩展类实现IToast接口
class BotToastAdapter implements IToast {
  // 实现IToast接口中的showSuccess方法
  void showSuccess(String message) {
    BotToast.closeAllLoading();
    BotToast.showText(
      text: message,
      duration: const Duration(seconds: 2),
      contentColor: Colors.green.withOpacity(0.8),
      textStyle: const TextStyle(color: Colors.white),
    );
  }

  // 实现IToast接口中的showError方法
  void showError(String message) {
    BotToast.closeAllLoading();
    BotToast.showText(text: message);
  }

  @override
  void dismiss() {
    BotToast.closeAllLoading();
  }

  @override
  void error(String msg) {
    dismiss();
    BotToast.showText(
      text: msg,
      duration: const Duration(seconds: 2),
      contentColor: Colors.red.withOpacity(0.8),
      textStyle: const TextStyle(color: Colors.white),
    );
  }

  @override
  TransitionBuilder init() {
    return BotToastInit();
  }

  @override
  void loading({String? status}) {
    BotToast.showLoading(clickClose: false, allowClick: false);
  }

  @override
  void show(String msg) {
    dismiss();
    BotToast.showText(text: msg, duration: const Duration(seconds: 2));
  }

  @override
  void success(String msg) {
    dismiss();
    BotToast.showText(
      text: msg,
      duration: const Duration(seconds: 2),
      contentColor: Colors.green.withOpacity(0.8),
      textStyle: const TextStyle(color: Colors.white),
    );
  }
}
