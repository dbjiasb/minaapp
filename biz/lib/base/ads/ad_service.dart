import 'package:get/get.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/util/device_util.dart';
import '../api_service/api_request.dart';
import '../api_service/api_response.dart';
import '../api_service/api_service.dart';
import '../crypt/apis.dart';
import '../crypt/security.dart';
import '../event_center/event_center.dart';

class AdsManager {

  static RxMap adBalanceInfoCache = {}.obs;

  static Map get adBalanceInfo => adBalanceInfoCache;

  static Map? get lockImageAdBalance =>
      adBalanceInfo[Security.security_adBalanceConfig]?['5'];

  static Map? get lockVideoAdBalance =>
      adBalanceInfo[Security.security_adBalanceConfig]?['6'];

  static bool get showLockImgAd => lockImageAdBalance?[Security.security_hasShowAd] == 1;

  static bool get showLockVideoAd => lockVideoAdBalance?[Security.security_hasShowAd] == 1;

  static bool getEnableStatusResLockByType(int type) {
    bool enableStatus;
    if (type == 0) {
      enableStatus = showLockImgAd;
    } else {
      enableStatus = showLockVideoAd;
    }
    return enableStatus;
  }

  static Map? getResLockAdBalanceByType(int type) {
    if (type == 0) {
      return lockImageAdBalance;
    } else {
      return lockVideoAdBalance;
    }
  }

  static int getResLockTotalCount(int type) {
    return getResLockAdBalanceByType(type)?[Security.security_adAwardTotal] ?? 0;
  }

  static int getResLockBalanceCount(int type) {
    return getResLockAdBalanceByType(type)?[Security.security_adBalanceNum] ?? 0;
  }

  static int getResLockUseCount(int type) {
    return getResLockTotalCount(type) - getResLockBalanceCount(type);
  }

  // 获取单个广告配置
  static Future<Map?> getAdConfig(int awardType) async {
    ApiRequest request = ApiRequest(Apis.security_getAdConfig, params: {
      Security.security_awardType: awardType,
    });
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      updateBalanceAdWard(response.data);
    }

    return null;
  }

  static Future<Map?> grantAdAward(int awardType, String clientAdId,
      {String? assetId = ""}) async {

    ApiRequest request = ApiRequest(Apis.security_grantAdAward, params: {
      Security.security_awardType: awardType,
      Security.security_clientAdId: clientAdId,
      Security.security_assetId: assetId,
    });
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response.data;
  }

// 获取剩余广告奖励详情
  static Future<Map?> getBalanceAdAward() async {
    // if (DeviceUtil.deviceInChina) return null;

    ApiRequest request = ApiRequest(Apis.security_getBalanceAdAward, params: {});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      updateBalanceAdWard(response.data);
    }

    return null;
  }

  static void updateBalanceAdWard(Map getBalanceAdAwardRsp) {
    adBalanceInfoCache.value = getBalanceAdAwardRsp;
    adBalanceInfoCache.refresh();
  }

  static init() {

    if (AccountService.instance.loggedIn) {
      getBalanceAdAward();
    }

    EventCenter.instance.addListener(kEventCenterUserDidLogin, (data) {
      getBalanceAdAward();
    });
  }
}
