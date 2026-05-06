import 'package:biz/base/crypt/routes.dart';
import 'package:get/get.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/core/account/account_service.dart';

import '../../../../base/api_service/api_request.dart';
import '../../../../base/api_service/api_response.dart';
import '../../../../base/api_service/api_service.dart';
import 'package:bot_toast/bot_toast.dart';

import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../shared/toast/toast.dart';
import '../utils/utils.dart';

extension MapModeExt on Map {
  bool get isOwn => (this[Security.security_own] ?? 0) == 1;
  set isOwn(bool value) => this[Security.security_own] = value ? 1 : 0;

  bool get isSelected => (this[Security.security_selected] ?? 0) == 1;
  set isSelected(bool value) => this[Security.security_selected] = value ? 1 : 0;

  int get uid => this[ES.tuid] ?? 0;
  set uid(int uid) => this[ES.tuid] = uid;

  String get id => this[Security.security_id] ?? '';
  set id(String aId) => this[Security.security_id] = aId;

}

class ModeApi {
  static String get payForAIMode => Security.security_buyModel;
  static String get queryMallModes => Security.security_getStoreList;
  static String get batchQueryModes => Security.security_getUniqueModelInfo;
  static String get queryModeStoreNotices => Security.security_getStoreMarqueeInfo;
  static String get changeAIMode => Security.security_switchAiPersonality;
  static String get queryAIModel => Security.security_getAiPersonality;
  static String get queryCurAIMode => Security.security_getCurrentAiPersonality;
  static String get queryAIChatModels => Security.security_getChatModelList;
  static String get changeAIChatModel => Security.security_switchChatModel;
}

class ES { ///EncodedString
  static String get mode => Security.security_mode;
  static String get hasComfirm => Security.security_hasComfirm;
  static String get tuid => Security.security_targetUid;
  static String get costType => Security.security_currencyType;

  static String get pageIndex => Security.security_pageIndex;
  static String get pageSize => Security.security_pageSize;

  static String get dd => Security.security_detailDesc;
  static String get pl => Security.security_personality;
  static String get modes => Security.security_personalities;
  static String get ct => Security.security_currencyType;
  static String get cbg => Security.security_chatBackground;
  static String get cName => Security.security_characterName;
  static String get avatar => Security.security_avatarUrl;
  static String get switchTips => Copywriting.security_switch_Succeed__enjoy_your_chat;

  static String get sb => Security.security_storeBackground;
  static String get cb => Security.security_chatBackground;
  static String get tagURL => Security.security_seriesTagUrl;

  static String get dp => Security.security_discountPrice;

}

class AIModeService{

  static AIModeService? _single;
  AIModeService._();

  static AIModeService get instance {
    _single ??= AIModeService._();
    return _single!;
  }

  Function(int targetUid, Map mode)? onAIModeChanged;
  RxMap _curModes = {}.obs;
  void cacheCurMode(value) {
    String uid = value[Security.security_targetUid].toString();
    _curModes[uid] = value;
    _curModes.refresh();
    Preferences.instance.setMap(Security.security_kCachedModesvv, _curModes);
  }
  Map getCurMode(String uid) {
    if (_curModes.isEmpty) {
      _curModes.value = Preferences.instance.getMap(Security.security_kCachedModesvv).obs;
    }
    if (_curModes[uid] == null) {
      queryCurrentMode(uid);
      return {};
    }
    return _curModes[uid];
  }

  Function(Map mode)? onPayModeSuccess;

  Future<ApiResponse> queryAIMode(int uid) async {
    ApiRequest req = ApiRequest(
      ModeApi.queryAIModel,
      params: {
        ES.tuid: uid,
        Security.security_type: 1
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response;
  }

  Future<bool> payForAIMode(Map item, {bool confirm = false}) async {
    Toast.loading();
    ApiResponse rsp = await payForAIModeWithId(item[ES.tuid], item[Security.security_id] ?? '', confirm: confirm);
    Toast.dismiss();

    if (rsp.bsnsCode == ApiError.notEnoughBalance.v) {

      RH.toRecharge(0);
      Future.delayed(Duration(milliseconds: 200), () {
        Toast.show( Copywriting.security_not_enough_balance);
      });

      return false;
    }

    if (rsp.bsnsCode == 3104) {
      bool ret = await AIModeUtils.showWarningAlert(content: rsp.description);
      if (!ret) return false;
      return payForAIMode(item, confirm: true);
    }

    if (rsp.isSuccess) {
      item.isOwn = true;
      onPayModeSuccess?.call(item);
      return true;
    }

    Toast.show( rsp.description);
    return false;
  }

  Future<ApiResponse> payForAIModeWithId(int targetUid, String id, {bool confirm = false}) async {

    ApiRequest req = ApiRequest(
      ModeApi.payForAIMode,
      params: {
        ES.hasComfirm:confirm ? 1 : 0,
        ES.tuid: targetUid,
        Security.security_id: id
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);
    if (response.isSuccess) {
      AccountService.instance.refreshBalance();
    }
    return response;
  }

  Future<Map?> queryMallModes(int page) async {
    ApiRequest req = ApiRequest(
      ModeApi.queryMallModes,
      params: {
        ES.pageIndex:page,
        ES.pageSize:100
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response.data;
  }

  Future<Map?> batchQueryModes(int tuid, String id) async {
    ApiRequest req = ApiRequest(
      ModeApi.batchQueryModes,
      params: {
        Security.security_models: [
          {Security.security_grade: int.parse(id), ES.tuid: tuid}
        ]
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response.data;
  }

  Future<Map?> queryModeStoreNotices() async {
    ApiRequest req = ApiRequest(
      ModeApi.queryModeStoreNotices,
      params: {},
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response.data;
  }


  Future changeAIMode(Map value) async {
    if (value.isSelected) {
      return null;
    }

    await changeAIModeWithId(value[ES.tuid], value[Security.security_id], value: value);
  }

  Future changeAIModeWithId(int uid, String id, {Map? value}) async {
    Toast.loading();

    ApiRequest req = ApiRequest(
      ModeApi.changeAIMode,
      params: {
        ES.tuid: uid,
        Security.security_id: id,
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);
    Toast.dismiss();

    var rsp = response.data;
    if (response.isSuccess) {
      if (value != null) cacheCurMode(value);
      if (value != null) onAIModeChanged?.call(value[Security.security_uid], value);
    } else {
      Toast.show( response.description);
    }
    return rsp;
  }

  Future<dynamic> queryCurrentMode(String uid) async {
    ApiRequest req = ApiRequest(
      ModeApi.queryCurAIMode,
      params: {
        ES.tuid: uid,
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);

    var rsp = response.data;
    if (response.isSuccess && (rsp[Security.security_personality]?[Security.security_id] ?? '').isNotEmpty) {
      cacheCurMode(rsp[Security.security_personality]!);
    }
    return rsp;
  }


  Future<Map?> queryAIChatModels() async {

    ApiRequest req = ApiRequest(
      ModeApi.queryAIChatModels,
      params: {},
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);

    if (response.isSuccess) {
      return response.data;
    } else {
      Toast.show( response.description);
      return null;
    }
  }

  Future changeAIChatModel(int modelId) async {

    Toast.loading();

    ApiRequest req = ApiRequest(
      ModeApi.changeAIChatModel,
      params: {
        Security.security_modelId: modelId
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(req);
    Toast.dismiss();

    if (response.isSuccess) {
      Toast.show( ES.switchTips);
      Future.delayed(const Duration(seconds: 1), () {
        RouteHelper.back();
      });
      return response.data;
    } else {
      Toast.show( response.description);
    }
  }
}