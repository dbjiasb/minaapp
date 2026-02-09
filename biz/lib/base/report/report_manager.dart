import 'package:biz/base/crypt/routes.dart';
import 'dart:convert';
import 'dart:io';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_attribution.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event_failure.dart';
import 'package:adjust_sdk/adjust_event_success.dart';
import 'package:flutter/cupertino.dart';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/base/crypt/security.dart';

import '../../core/util/log_util.dart';

class ReportManager {
  static final ReportManager _instance = ReportManager._internal();

  factory ReportManager() => _instance;

  ReportManager._internal();

  static ReportManager get instance => _instance;

  String data = '';
  Future<String> get adId async => await Adjust.getAdid() ?? '';
  Future<String> get platformAdId async => Platform.isIOS ? (await Adjust.getIdfa() ?? '') : (await Adjust.getGoogleAdId() ?? '');

  void init() {
    // 初始化广告
    Adjust.initSdk(adjustConfig);
    Future.delayed(const Duration(seconds: 5), () async {
      if (data.isEmpty) {
        await handleAdjustAttribution(await Adjust.getAttribution());
      }
    });
  }

  AdjustConfig get adjustConfig {
    return AdjustConfig(Platform.isIOS ? Security.security_u8slrnkdzhfk : Security.security_gcjw4vodvncw, AdjustEnvironment.production)
      ..attributionCallback = (AdjustAttribution attribution) {
        handleAdjustAttribution(attribution);
      }
      ..eventSuccessCallback = (AdjustEventSuccess eventSuccess) {
        L.i('eventSuccess: $eventSuccess');
      }
      ..eventFailureCallback = (AdjustEventFailure eventFailure) {
        L.i('eventFailure: $eventFailure');
      };
  }

  Future<void> handleAdjustAttribution(AdjustAttribution attribution) async {
    await initData(attribution);
    Map<String, String> event = {Constants.adKey: await adId, Constants.adDevice: await platformAdId, Constants.adSetupInfo: data, Constants.adUpdate: '1'};
    sendEvent(Security.security_adjust, event);
  }

  Future<void> initData(AdjustAttribution attribution) async {
    Map map = {
      Constants.adReferrer: attribution.fbInstallReferrer ?? '',
      Constants.adClickTag: attribution.clickLabel ?? '',
      Constants.adToken: attribution.trackerToken ?? '',
      Constants.adCost: attribution.costAmount?.toString() ?? '',
      Constants.adTracker: attribution.trackerName ?? '',
      Constants.adTeam: attribution.adgroup ?? '',
      Constants.adNet: attribution.network ?? '',
      Constants.adElection: attribution.campaign ?? '',
      Constants.adBuild: attribution.creative ?? '',
      Security.security_adid: await adId,
      Security.security_costType: attribution.costType ?? '',
      Constants.adCurrency: attribution.costCurrency ?? '',
    };

    data = jsonEncode(map);
  }

  static sendEvent(String eventName, Map<String, String>? event) async {
    ApiRequest request = ApiRequest(Apis.security_sendData, params: {Security.security_name: eventName, Security.security_param: event});

    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      L.i('sendData success');
    } else {
      L.i('sendData failed');
    }
  }
}
