import 'package:flutter/foundation.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'dart:io';

enum BuildType {
  release, //发布包
  debug, //内测包
}

enum NetworkType {
  prod, //正式环境
  dev, //测试环境
}

class Environment {
  static Environment? _instance;

  static Environment get instance {
    _instance ??= Environment()..init();
    return _instance!;
  }

  BuildType buildType = BuildType.release;

  NetworkType networkType = NetworkType.prod;

  bool get isRelease => buildType == BuildType.release;

  bool get isDebug => buildType == BuildType.debug;

  bool get isDev => networkType == NetworkType.dev;

  // const 不能去掉
  void init() {
    buildType =
        (const String.fromEnvironment('build${''}Type')) == BuildType.debug.name
            ? BuildType.debug
            : BuildType.release;

    if (isDebug || kDebugMode) {
      networkType = NetworkType.values.byName(
        Preferences.instance.getString(Security.security_networkType) ?? NetworkType.prod.name,
      );
    }
  }

  void updateNetworkType(NetworkType e) {
    networkType = e;
    Preferences.instance.setString(Security.security_networkType, e.name);
    Future.delayed(const Duration(milliseconds: 500), () {
      exit(0);
    });
  }
}
