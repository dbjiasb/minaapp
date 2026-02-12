import 'package:package_info_plus/package_info_plus.dart';

import '../api_service/api_config.dart';

class AppManager {
  //生成单利
  static final AppManager _instance = AppManager._internal();

  factory AppManager() {
    return _instance;
  }

  AppManager._internal();

  static AppManager get instance => _instance;

  late final PackageInfo packageInfo;

  Future<void> init() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  String get appVersion => packageInfo.version;
  String get appBuild => packageInfo.buildNumber;

  // static const appRes = 'https://$cdn/soulink/app/';

  // String get createOcHtml => 'https://$cdn/soulink/createoc.html';

  String get privacyHtml => '${ApiConfig.cdn}/mina/privacy.html';

  String get termsHtml => '${ApiConfig.cdn}/mina/term.html';

  // String get feedBackUrl => 'https://discord.gg/qdRqGq5WDG?external=1';

  // String get taskUrl => 'https://$cdn/h5/dailyTask/index.html#/coins?type=0';

  // String get notificationUrl => 'https://$cdn/h5/notification/index.html#/';
}
