import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_service.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/core/user_manager/user_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/util/log_util.dart';
import '../../shared/app_theme.dart';
import '../assets/image_path.dart';
import '../router/router_names.dart';

// flutter 端
String kJSBridgeBack = Security.security_ack;
String kJSBridgeGetUsrInfo = Security.security_etUserIn;
String kJSBridgeStatusBar = Security.security_etStatusBar;

// h5端
String h5GetMsg = Security.security_receiveMessage;

class WebView extends StatefulWidget {
  String? url;

  WebView({this.url}) : super();

  static Future<dynamic> showWeb(String url, {Function(String url)? onPageStarted}) async {
    return await Get.dialog(WebView(url: url));
  }

  @override
  _WebViewState createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  late final WebViewController _controller;
  late final Map arguments;
  late final String title;
  late final String url;
  late final bool hideAppBar;

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    arguments = Get.arguments ?? {};
    title = arguments[Security.security_title] ?? '';
    url = arguments[Security.security_url] ?? widget.url ?? '';
    hideAppBar = (arguments[Security.security_hideHeader] ?? 0) == 1;
    L.i('WebView initState, url: $url, title: $title, hideAppBar: $hideAppBar');
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(AppColors.base_background)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _controller.getUserAgent().then((userAgent) {
                  String replacedUa = Preferences.instance.replaceUserAgent;
                  String addedUa = Preferences.instance.addedUserAgent;
                  L.i('[WebView] before: User Agent: $userAgent');
                  if (replacedUa.isEmpty && addedUa.isNotEmpty) {
                    String finalUa = '$addedUa$userAgent';
                    _controller.setUserAgent(finalUa);
                    L.i('[WebView] after: User Agent: $finalUa');
                  }
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              },
              onUrlChange: (UrlChange change) {},
            ),
          )
          ..addJavaScriptChannel(Security.security_jSBridge, onMessageReceived: _handleMessage)
          ..loadRequest(Uri.parse(url));
    String replacedUa = Preferences.instance.replaceUserAgent;
    if (replacedUa.isNotEmpty) {
      _controller.setUserAgent(replacedUa);
    }
    // 安全的iOS平台检测和配置
    if (Platform.isIOS && _controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController).setInspectable(true);
    }

    // 使用外部浏览器打开
    if (url.contains('external=1')) {
      loadByExternalUrl(url);
    }
  }

  static double get statusBarHeight {
    return Get.mediaQuery.padding.top;
  }

  bool get showAppBar => !hideAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: !showAppBar,
      extendBodyBehindAppBar: !showAppBar,
      backgroundColor: Color(0xFF12151D),
      appBar:
          showAppBar
              ? AppBar(
                systemOverlayStyle: SystemUiOverlayStyle.light,
                title: Text(title, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.base_background,
                leading: IconButton(icon: Image.asset(ImagePath.ic_arrow_left_circle, width: 32, height: 32), onPressed: () => RH.back()),
                actions: [
                  if (_isLoading)
                    Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)),
                      ),
                    ),
                ],
              )
              : null,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) Center(child: CircularProgressIndicator()),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(Security.security_failed, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: _reloadPage, child: Text(Security.security_retry)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleBackPress() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else {
      Get.back();
    }
  }

  void _reloadPage() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.reload();
  }

  void _handleMessage(JavaScriptMessage msg) async {
    L.i('WebView >> Received message: ${msg.message}');
    try {
      final Map<String, dynamic> messageContent = jsonDecode(msg.message);
      final String api = messageContent[Security.security_api] ?? '';
      String data = messageContent[Security.security_data] ?? '';

      dynamic retData;

      // 使用精确匹配而不是contains
      if (api.contains(kJSBridgeBack)) {
        _handleBackPress();
        return;
      } else if (api.contains(kJSBridgeGetUsrInfo)) {
        var baseInfo = {...(ApiService.instance.base())};
        baseInfo[Security.security_guid] = baseInfo[Security.security_did];
        baseInfo[Security.security_channel] = baseInfo[Security.security_app];
        baseInfo[Security.security_versionName] = baseInfo[Security.security_appVer];
        retData = jsonEncode(baseInfo);
      } else if (api.contains(kJSBridgeStatusBar)) {
        retData = statusBarHeight;
      } else if (api.startsWith(Security.security_jsWatchAd)) {
        try {
        } catch (e) {
          // debugPrint('Error parsing ad data: $e');
        }
        return;
      } else if (api.startsWith(Security.security_jsGoGemsPage)) {
        RouteHelper.toGems();
        return;
      } else if (api.startsWith(Security.security_jsRech)) {

      } else if (api.startsWith(Security.security_jsGoPersonal)) {
        Map user = jsonDecode(data);
        RouteHelper.toPage(
          Routers.person,
          args: {
            Security.security_personInfo: {
              Security.security_userInfo: {
                Security.security_baseInfo: {
                  Security.security_uid: user[Security.security_uid],
                  Security.security_name: user[Security.security_nickname],
                  Security.security_avatarUrl: user[Security.security_avatar],
                  Security.security_accountType: user[Security.security_accountType],
                },
              },
            },
          },
        );
      } else if (api.startsWith(Security.security_jsClearNotificationRedDot)) {
        UserManager.instance.notificationReminder.value = false;
      } else {
        return;
      }

      if (retData != null) {
        await _outputDataToJsBridge({Security.security_api: api, Security.security_data: retData});
      }
    } catch (e) {
      L.e('WebView >> Error handling message: $e');
    }
  }

  Future<void> _messageOut(String javaScriptString) async {
    try {
      L.i('WebView >> Send message: $javaScriptString');
      await _controller.runJavaScript(javaScriptString);
    } catch (e) {}
  }

  Future<void> _outputDataToJsBridge(dynamic data) async {
    final jsonString = jsonEncode(data);
    final jsCode = '$h5GetMsg($jsonString)';
    await _messageOut(jsCode);
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadByExternalUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
