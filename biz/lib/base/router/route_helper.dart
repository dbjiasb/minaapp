import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/business/chat/chat_manager.dart';

import '../../business/chat/chat_session.dart';
import '../../core/util/log_util.dart';
import '../app_info/app_manager.dart';
import '../crypt/security.dart';
import 'router_names.dart';

typedef RH = RouteHelper;

class RouteHelper {
  static void back() {
    Get.back();
  }

  static String currentRoute() {
    return Get.routing.current;
  }

  static void toLoginPage() {
    popAllAndToPage(Routers.loginChannel);
  }

  static Future toSupportChat() async {
    ChatSession s = ChatSession.offChatSession;
    await toChat(id: s.id, name: s.name, avatar: s.avatar, accountType: s.accountType);
  }

  static Future toChat({String id = '', String name = '', String avatar = '', String coverUrl = '', int accountType = 0, int type = 0}) async {
    ChatSession? s;
    String? args;
    try {
      s = await ChatManager.instance.querySession(id);
      args ??= s?.toRouter();
    } catch (e) {
      L.e('toChat querySession error: $e');
    }

    args ??= jsonEncode({
      Security.security_id: id,
      Security.security_name: name,
      Security.security_avatar: avatar,
      Security.security_backgroundUrl: coverUrl,
      Security.security_accountType: accountType,
      Security.security_type: type,
    });

    Map<String, dynamic> param = {Security.security_session: args};
    toChatBase(param);
  }

  static Route<dynamic>? lastChatRoute;

  static Future toChatTheater(Map map) async {
    map["isTheater"] = true;
    toPage(Routers.chatTheater, args: map);
  }

  static Future toChatBase(Map map) async {
    if (lastChatRoute != null && lastChatRoute?.isActive == true) {
      Get.removeRoute(lastChatRoute!);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    toPage(Routers.chat, args: map, preventDuplicates: false);
    lastChatRoute = Get.routing.route;
  }

  static void toCallOut(Map args) {
    Map sessionInfo = args[Security.security_session];

    if (args[Security.security_ai] == 1) {
      RouteHelper.toAICall(args);
    } else {
      Map realArgs = {
        Security.security_targetUid: sessionInfo[Security.security_id] ?? 0,
        Security.security_targetName: sessionInfo[Security.security_name] ?? '',
        Security.security_targetAvatar: sessionInfo[Security.security_avatar] ?? '',
        Security.security_isCallOut: true,
        Security.security_type: args[Security.security_type] ?? 1,
        Security.security_autoAnswer: false,
      };
      RouteHelper.toCall(realArgs);
    }
  }

  static void toAICall(Map args) {
    toPage(Routers.aiCall, args: args);
  }

  static void toCall(Map args) {
    toPage(Routers.call, args: args);
  }

  static Future toPage(String name, {dynamic args, Map<String, String>? params, bool preventDuplicates = true}) async {
    try {
      return await Get.toNamed(name, arguments: args, parameters: params, preventDuplicates: preventDuplicates);
    } catch (e) {
      L.e('toPage error: $e');
    }
  }

  static Future toView(Widget page, {dynamic args, Map<String, String>? params, bool preventDuplicates = true}) async {
    try {
      return await Get.to(page, arguments: args, preventDuplicates: preventDuplicates);
    } catch (e) {
      L.e('toPage error: $e');
    }
  }

  static void popAllAndToPage(String name, {Map? args, Map<String, String>? params}) {
    Get.offAllNamed(name, arguments: args, parameters: params);
  }

  static Future toRecharge(int type) async {
    if (type == 1) {
      return await toGems();
    } else {
      return await toCoins();
    }
  }

  static Future toPremium() async {
    String url = Preferences.instance.premiumUrl;
    if (url.isNotEmpty) {
      return await handleRoute(url);
    }
    return await toPage(Routers.rechargePremium);
  }

  static Future toGems() async {
    if (!kDebugMode) {
      String url = Preferences.instance.rpUrl;
      if (url.isNotEmpty) {
        return await toWeb(url, title: '', hideHeader: 1);
      }
    }
    return await toPage(Routers.rechargeCurrency, args: {Security.security_rcgType: 1});
  }

  static Future toCoins() async {
    String url = Preferences.instance.coinUrl;
    if (url.isNotEmpty) {
      return await handleRoute(url);
    }
    return await toPage(Routers.rechargeCurrency, args: {Security.security_rcgType: 0});
  }

  static Future toWeb(String url, {String? title, int hideHeader = 0}) async {
    return await toPage(Routers.webView, args: {Security.security_title: title ?? '', Security.security_url: url, Security.security_hideHeader: hideHeader});
  }

  static Future toTask() async {
    return await toWeb(AppManager.instance.taskUrl, title: '', hideHeader: 1);
  }

  static Future toPersonalView({required int uid, required int accountType, String name = '', String avatar = ''}) async {
    return await RouteHelper.toPage(
      Routers.person,
      args: {
        Security.security_personInfo: {
          Security.security_userInfo: {
            Security.security_baseInfo: {
              Security.security_uid: uid,
              Security.security_nickName: name,
              Security.security_avatarUrl: avatar,
              Security.security_accountType: accountType,
            },
          },
        },
      },
      preventDuplicates: false,
    );
  }

  static Future handleRoute(String route, {Map? args, Map<String, String>? params}) async {
    if (route.startsWith(Security.security_http)) {
      Map<String, dynamic> param = Uri.parse(route).queryParameters;
      String title = param[Security.security_title] ?? '';
      int hideHeader = int.tryParse(param[Security.security_hideHeader] ?? '0') ?? 0;
      return await toWeb(route, title: title, hideHeader: hideHeader);
    }
    if (route.startsWith(Routers.chat)) {
      try {
        Map<String, dynamic> param = Uri.parse(route).queryParameters;
        if (param.isEmpty) return;
        return await toChat(
          id: param[Security.security_id] ?? '',
          name: param[Security.security_name] ?? '',
          avatar: param[Security.security_avatar] ?? '',
          coverUrl: param[Security.security_backgroundUrl] ?? '',
          accountType: int.tryParse(param[Security.security_accountType] ?? '0') ?? 0,
          type: int.tryParse(param[Security.security_type] ?? '0') ?? 0,
        );
      } catch (e) {
        return;
      }
    }
    return await toPage(route, args: args, params: params);
  }
}
