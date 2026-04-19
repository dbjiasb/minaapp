import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:biz/core/util/log_util.dart';
import 'package:biz/base/api_service/api_request.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/api_service/api_service.dart';
import 'package:biz/base/crypt/routes.dart';

import '../crypt/apis.dart';
import '../crypt/security.dart';
import '../environment/environment.dart';

Future<void> onBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint('[PUSH] onBackgroundMessageHandler: $message');
  await FcmService.instance.handleBackgroundMessageHandler(message);
}

class FcmService {
  static final FcmService _instance = FcmService._internal();

  factory FcmService() => _instance;

  FcmService._internal();

  static FcmService get instance => _instance;

  String? fcmToken;
  bool didApplyPermission = false;

  Future<void> init() async {
    addNotificationCallback();
  }

  Future<void> requestPermission() async {
    if (Environment.instance.isDev) return;
    if (didApplyPermission) return;
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
      L.i('[PUSH] requestPermission: ${settings.authorizationStatus}, ${settings.alert}, ${settings.badge}, ${settings.sound}, ${settings.announcement}, ${settings.notificationCenter}, ${settings.lockScreen}');

      // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Future.delayed(const Duration(seconds: 5), () {
          sendTokenToServer();
        });
      // }
      didApplyPermission = true;
    } catch (e) {
      L.e('[PUSH] requestPermission error: $e');
    }
  }

  void sendTokenToServer() async {
    if (Environment.instance.isDev) return;
    try {
      String? firebaseToken = await FirebaseMessaging.instance.getToken() ??  '';
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken() ?? '';
      if (firebaseToken.isEmpty) return;

      ApiRequest request = ApiRequest(Apis.security_registerFcmPushToken, params: {
        Security.security_pushToken: firebaseToken,
        Security.security_apnsToken: apnsToken,
      });

      ApiResponse response = await ApiService.instance.sendRequest(request);
      if (response.isSuccess) {
        L.i('[PUSH] Token send success $fcmToken');
      }
    } catch (e) {
      L.e('[PUSH] sendTokenToServer error: $e');
    }
  }

  void addNotificationCallback() async {
    if (Environment.instance.isDev) return;
    /// iOS设置前台不显示通知
    if (Platform.isIOS) await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false);

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      L.i('[PUSH] onTokenRefresh: $fcmToken');
      sendTokenToServer();
    });

    // 后台程序运行时，点击消息触发
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) => handleRemoteMessage(message));
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessageHandler);
  }

  Future<void> handleBackgroundMessageHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    // 处理后台消息的逻辑
  }

  bool handleRemoteMessage(RemoteMessage message) {
    L.i('[PUSH] Message: ${message.messageId}');
    String? wantRoute = message.data[Security.security_route];
    if (wantRoute != null && wantRoute.isNotEmpty) {
    //   final res = Get.routeTree.matchRoute(Routes.MAIN);
    //   if (res.treeBranch.isEmpty) {
    //     Get.toNamed(Routes.MAIN);
    //   } else {
    //     if (Get.currentRoute.contains('/chat')) {
    //       Get.back();
    //     }
    //   }
    //   Future.delayed(const Duration(milliseconds: 1200),(){
    //     AppRouteCenter.handleRoute(wantRoute);
    //   });

      return true;
    }
    return false;
  }

  Future<bool> handleInitMessage() async {
    try {
      RemoteMessage? message = await FirebaseMessaging.instance
          .getInitialMessage();
      L.i('[FCM] getInitialMessage: ${message.toString()}');
      if (message == null) return false;
      return handleRemoteMessage(message);
    } catch (e) {
      L.e('[FCM] getInitialMessage error: ${e.toString()}');
    }
    return false;
  }
}
