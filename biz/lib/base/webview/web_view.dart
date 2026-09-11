import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_config.dart';
import 'package:biz/base/api_service/api_service.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/business/purchase/payment_service.dart';
import 'package:biz/core/user_manager/user_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/util/cached_image.dart';
import '../../core/util/log_util.dart';
import '../../shared/app_theme.dart';
import '../ads/ad_utils.dart';
import '../assets/image_path.dart';
import '../router/router_names.dart';

// flutter 端
final String kJSBridgeBack = Security.security_ack;
final String kJSBridgeGetUsrInfo = Security.security_etUserIn;
final String kJSBridgeStatusBar = Security.security_etStatusBar;

// h5端
final String h5GetMsg = Security.security_receiveMessage;

class WebView extends StatefulWidget {
  final String? url;

  const WebView({super.key, this.url});

  static Future<dynamic> showWeb(
    String url, {
    Function(String url)? onPageStarted,
  }) async {
    return await Get.dialog(WebView(url: url));
  }

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  late final WebViewController _controller;
  late final Map arguments;
  late final String title;
  late final String url;
  late final bool hideAppBar;

  bool _isLoading = true;
  bool _hasError = false;
  String _currentUrl = '';
  Function(bool, String?)? _previousPurchaseCompletion;
  Function(bool, String?)? _webViewPurchaseCompletion;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    final rawArguments = Get.arguments;
    arguments = rawArguments is Map ? rawArguments : <String, dynamic>{};
    title = _stringValue(arguments[Security.security_title]);
    url = _stringValue(arguments[Security.security_url], fallback: widget.url);
    hideAppBar = _boolValue(arguments[Security.security_hideHeader]);
    _currentUrl = url;
    L.i('WebView initState, url: $url, title: $title, hideAppBar: $hideAppBar');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.base_background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String pageUrl) {
            _currentUrl = pageUrl;
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String pageUrl) {
            _currentUrl = pageUrl;
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
            L.e(
              '[WebView] resource error: ${error.errorCode}, ${error.description}',
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.prevent;
            }
            if (_isExternalUrl(uri)) {
              unawaited(loadByExternalUrl(request.url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _currentUrl = change.url!;
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        Security.security_jSBridge,
        onMessageReceived: _handleMessage,
      );

    unawaited(_configureUserAgent());

    if (Platform.isIOS &&
        kDebugMode &&
        _controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController).setInspectable(true);
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
      _isLoading = false;
      _hasError = true;
      return;
    }

    if (_isExternalUrl(uri)) {
      _isLoading = false;
      unawaited(_openInitialExternalUrl(url));
      return;
    }

    _controller.loadRequest(uri);
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
      appBar: showAppBar
          ? AppBar(
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.base_background,
              leading: IconButton(
                icon: CachedImage(
                  imageUrl: ImagePath.ic_arrow_left_circle,
                  width: 32,
                  height: 32,
                ),
                onPressed: () => RH.back(),
              ),
              actions: [
                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
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
                  Text(
                    Security.security_failed,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reloadPage,
                    child: Text(Security.security_retry),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleBackPress() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
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
    if (!_isTrustedWebOrigin(_currentUrl)) {
      L.e(
        '[WebView] ignore bridge message from untrusted origin: $_currentUrl',
      );
      return;
    }

    try {
      final decodedMessage = jsonDecode(msg.message);
      if (decodedMessage is! Map) {
        L.e('[WebView] bridge message is not a map');
        return;
      }
      final String api = _stringValue(decodedMessage[Security.security_api]);
      final dynamic data = decodedMessage[Security.security_data];
      if (api.isEmpty) return;

      dynamic retData;

      if (api.contains(kJSBridgeBack)) {
        _handleBackPress();
        return;
      } else if (api.contains(kJSBridgeGetUsrInfo)) {
        if (!_isTrustedH5Origin(_currentUrl)) {
          L.e(
            '[WebView] refuse user info bridge from non-H5 origin: $_currentUrl',
          );
          return;
        }
        var baseInfo = {...(ApiService.instance.base())};
        baseInfo[Security.security_guid] = baseInfo[Security.security_did];
        baseInfo[Security.security_channel] = baseInfo[Security.security_app];
        baseInfo[Security.security_versionName] =
            baseInfo[Security.security_ver];
        retData = jsonEncode(baseInfo);
      } else if (api.contains(kJSBridgeStatusBar)) {
        retData = statusBarHeight;
      } else if (api.startsWith(Security.security_jsWatchAd)) {
        _handleWatchAd(data);
        return;
      } else if (api.startsWith(Security.security_jsGoGemsPage)) {
        RouteHelper.toGems();
        return;
      } else if (api.startsWith(Security.security_jsRech)) {
        await _handleRecharge(data);
      } else if (api.startsWith(Security.security_jsGoPersonal)) {
        _handlePersonal(data);
      } else if (api.startsWith(Security.security_jsClearNotificationRedDot)) {
        UserManager.instance.notificationReminder.value = false;
      } else if (api.startsWith(Security.security_jsGoNativePage)) {
        final route = _stringValue(_decodeData(data));
        if (route.isNotEmpty) {
          RH.handleRoute(route);
        }
      } else {
        return;
      }

      if (retData != null) {
        await _outputDataToJsBridge({
          Security.security_api: api,
          Security.security_data: retData,
        });
      }
    } catch (e) {
      L.e('WebView >> Error handling message: $e');
    }
  }

  Future<void> _handleWatchAd(dynamic rawData) async {
    try {
      final data = _decodeData(rawData);
      if (data is! Map) {
        L.e('[WebView] invalid watch ad data: $rawData');
        return;
      }
      final AdsUtils adUtils = AdsUtils(
        data,
        grantAdCallback: (grant) {
          unawaited(
            _outputDataToJsBridge({
              Security.security_api: Security.security_onWatchAdSuccess,
              Security.security_data: rawData,
            }),
          );
        },
      );
      await adUtils.showAd();
    } catch (e) {
      L.e('[WebView] failed to handle watch ad: $e');
    }
  }

  Future<void> _handleRecharge(dynamic rawData) async {
    final item = _normalizeRechargeItem(rawData);
    if (item.isEmpty) {
      L.e('[WebView] invalid recharge item: $rawData');
      return;
    }

    final manager = PurchaseManager.instance;
    _previousPurchaseCompletion ??= manager.completion;
    final callback = (bool success, String? message) {
      if (!success) {
        L.e('[WebView] recharge failed: $message');
        _restorePurchaseCompletion();
        return;
      }

      final packageOffer = item[Security.security_packageOffer];
      final packageOfferMap = packageOffer is Map ? packageOffer : const {};
      final score =
          _intValue(item[Security.security_score]) +
          _intValue(packageOfferMap[Security.security_score]);
      unawaited(
        _outputDataToJsBridge({
          Security.security_api: Security.security_onPaySuccess,
          Security.security_data: jsonEncode({
            Security.security_currencyType:
                item[Security.security_currencyType],
            Security.security_score: score,
          }),
        }),
      );
      _restorePurchaseCompletion();
    };
    _webViewPurchaseCompletion = callback;
    manager.completion = callback;

    try {
      L.i('[WebView] recharge requested: $item');
      await manager.purchaseItem(item);
    } catch (e) {
      L.e('[WebView] failed to start recharge: $e');
    }
  }

  void _restorePurchaseCompletion() {
    final manager = PurchaseManager.instance;
    if (identical(manager.completion, _webViewPurchaseCompletion)) {
      manager.completion = _previousPurchaseCompletion;
    }
    _webViewPurchaseCompletion = null;
  }

  void _handlePersonal(dynamic rawData) {
    final data = _decodeData(rawData);
    if (data is! Map) {
      L.e('[WebView] invalid personal data: $rawData');
      return;
    }

    RouteHelper.toPage(
      Routers.person,
      args: {
        Security.security_personInfo: {
          Security.security_userInfo: {
            Security.security_baseInfo: {
              Security.security_uid: data[Security.security_uid] ?? data['uid'],
              Security.security_nickName:
                  data[Security.security_nickname] ??
                  data[Security.security_nickName] ??
                  data['nickname'],
              Security.security_avatarUrl:
                  data[Security.security_avatarUrl] ??
                  data[Security.security_avatar] ??
                  data['avatar'],
              Security.security_accountType:
                  data[Security.security_accountType] ?? data['accountType'],
            },
          },
        },
      },
    );
  }

  Map<String, dynamic> _normalizeRechargeItem(dynamic rawData) {
    final data = _decodeData(rawData);
    if (data is! Map) return {};

    dynamic value(String key, String legacyKey) => data[key] ?? data[legacyKey];
    final item = <String, dynamic>{};

    final itemId = _intValue(value(Security.security_itemId, 'itemId'));
    if (itemId > 0) {
      item[Security.security_itemId] = itemId;
    }

    final price = value(Security.security_price, 'price');
    if (price != null) {
      item[Security.security_price] = price;
    }

    final score = value(Security.security_score, 'score');
    if (score != null) {
      item[Security.security_score] = _intValue(score);
    }

    final currencyType = value(Security.security_currencyType, 'currencyType');
    if (currencyType != null) {
      item[Security.security_currencyType] = _intValue(currencyType);
    }

    final giftRatio = value(Security.security_giftRatio, 'giftRatio');
    if (giftRatio != null) {
      item[Security.security_giftRatio] = giftRatio;
    }

    final rechargeItemType = value(
      Security.security_rechargeItemType,
      'rechargeItemType',
    );
    if (rechargeItemType != null) {
      item[Security.security_rechargeItemType] = _intValue(rechargeItemType);
    }

    final channelInfo = value(Security.security_channelInfo, 'channelInfo');
    if (channelInfo is Map) {
      item[Security.security_channelInfo] = channelInfo;
    }

    final packageOffer = value(Security.security_packageOffer, 'packageOffer');
    if (packageOffer is Map) {
      item[Security.security_packageOffer] = {
        Security.security_score: _intValue(
          packageOffer[Security.security_score] ?? packageOffer['score'],
        ),
        Security.security_currencyType:
            packageOffer[Security.security_currencyType] ??
            packageOffer['currencyType'],
      };
    }

    return item;
  }

  dynamic _decodeData(dynamic data) {
    if (data is! String || data.isEmpty) return data;
    try {
      return jsonDecode(data);
    } catch (_) {
      return data;
    }
  }

  String _stringValue(dynamic value, {String? fallback}) {
    if (value is String) return value;
    if (value == null) return fallback ?? '';
    return value.toString();
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _configureUserAgent() async {
    final replacedUa = Preferences.instance.replaceUserAgent;
    if (replacedUa.isNotEmpty) {
      await _controller.setUserAgent(replacedUa);
      return;
    }

    final addedUa = Preferences.instance.addedUserAgent;
    if (addedUa.isEmpty) return;

    final userAgent = await _controller.getUserAgent();
    if (userAgent?.startsWith(addedUa) ?? true) return;
    final finalUa = '$addedUa$userAgent';
    await _controller.setUserAgent(finalUa);
    L.i('[WebView] user agent configured: $finalUa');
  }

  bool _isExternalUrl(Uri uri) => uri.queryParameters['external'] == '1';

  bool _isTrustedH5Origin(String rawUrl) => true;///_isSameOrigin(rawUrl, ApiConfig.h5);

  bool _isTrustedWebOrigin(String rawUrl) => true;

  bool _isSameOrigin(String rawUrl, String trustedUrl) {
    final urlUri = Uri.tryParse(rawUrl);
    final trustedUri = Uri.tryParse(trustedUrl);
    if (urlUri == null || trustedUri == null) return false;
    return urlUri.scheme == trustedUri.scheme &&
        urlUri.host == trustedUri.host &&
        (urlUri.hasPort ? urlUri.port : _defaultPort(urlUri.scheme)) ==
            (trustedUri.hasPort
                ? trustedUri.port
                : _defaultPort(trustedUri.scheme));
  }

  int _defaultPort(String scheme) => scheme == 'https' ? 443 : 80;

  Future<void> _openInitialExternalUrl(String rawUrl) async {
    await loadByExternalUrl(rawUrl);
    if (mounted) {
      Get.back();
    }
  }

  Future<void> _messageOut(String javaScriptString) async {
    try {
      L.i('WebView >> Send message: $javaScriptString');
      await _controller.runJavaScript(javaScriptString);
    } catch (e) {
      L.e('[WebView] failed to send JavaScript message: $e');
    }
  }

  Future<void> _outputDataToJsBridge(dynamic data) async {
    final jsonString = jsonEncode(data);
    final jsCode = '$h5GetMsg($jsonString)';
    await _messageOut(jsCode);
  }

  @override
  void dispose() {
    _restorePurchaseCompletion();
    super.dispose();
  }

  Future<void> loadByExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      L.e('[WebView] invalid external URL: $url');
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    L.e('[WebView] could not launch external URL: $url');
  }
}
