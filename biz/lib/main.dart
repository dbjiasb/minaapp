import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'package:biz/app/root_view.dart';
import 'package:biz/base/report/report_manager.dart';
import 'package:biz/base/app_info/app_manager.dart';
import 'package:biz/base/database/data_center.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/file_manager/file_manager.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/push_service/push_service.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/core/account/account_service.dart';
import 'core/util/device_util.dart';
import 'core/util/log_util.dart';

void startApp(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black, // 导航栏背景色
      systemNavigationBarIconBrightness: Brightness.light, // 图标亮度（暗色图标）
      // systemNavigationBarDividerColor: Colors.transparent, // 分割线颜色
    ));
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  try {
    await AppLog.init();
    await AppManager.instance.init();
    await Preferences.instance.init();
    await DeviceUtil.init();
    await FileManager.instance.init();
    await DataCenter.instance.init();
    // await Firebase.initializeApp();
  } catch (e) {
    debugPrint('startApp error: $e');
  }
  Preferences.instance.initAppConfig();
  ReportManager.instance.init();
  EventCenter.instance.init();
  PushService.instance.init();
  AccountService.instance.init();
  ChatManager.instance.init();
  runApp(const RootView());
}
