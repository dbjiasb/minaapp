import 'package:biz/base/crypt/routes.dart';
import 'dart:convert';

import 'package:biz/base/crypt/apis.dart';
import 'dart:async';

import 'package:get/get.dart';
import 'package:biz/base/api_service/api_request.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/api_service/api_service.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';

final String kCachedKeyCrowedConfig = Security.security_kCachedKeyCrowedConfig;

class CrowedManager {
  //单利模式
  static final CrowedManager _instance = CrowedManager._internal();

  CrowedManager._internal();

  factory CrowedManager() => _instance;

  static CrowedManager get instance => _instance;

  RxMap<dynamic, dynamic> config =
      Preferences.instance.getMap(kCachedKeyCrowedConfig).obs;

  int get onlyForPremium => config[Security.security_onlyForPremiumUser] ?? 0;

  int get maxMemberCount => config[Security.security_maxGroupMemberCount] ?? 10;

  int get minMemberCount => config[Security.security_minGroupMemberCount] ?? 1;

  int get createCostType => config[Security.security_createCostInfo]?[Security.security_costType] ?? 0;

  int get createCostValue => config[Security.security_createCostInfo]?[Security.security_costValue] ?? 0;

  Future<void> getCrowdConfigInfo() async {
    ApiRequest request = ApiRequest(Apis.security_getGroupConfig);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      Map<dynamic, dynamic> data = (response.data[Security.security_config]) ?? {};
      config.value = data;
      Preferences.instance.setMap(kCachedKeyCrowedConfig, data);
    }
    return;
  }

  void init() {
    getCrowdConfigInfo();
  }
}


class CrowdInfo {
  Map<String, dynamic> data;

  CrowdInfo(this.data);

  String get avatar => data[Security.security_avatar] ?? '';
  String get name => data[Security.security_name] ??
      '';
  int get groupId => data[Security.security_groupId] ??
      0;
  String get scenario => data[Security.security_scenario] ??
      '';
  String get chatBackground => data[Security.security_chatBackground] ??
      '';

  String get sessionId => data[Security.security_sessionId] ??
      '';

  List<dynamic> get members => data[Security.security_members] ?? [];

  List<dynamic> get membersNoOwner =>
      members.where((element) => element[Security.security_role] != 1).toList();

  CrowdInfo.none() : data = {}; // 修复构造函数语法
  bool isNone() => data.isEmpty;

  @override
  String toString() {
    return jsonEncode(data);
  }
}
