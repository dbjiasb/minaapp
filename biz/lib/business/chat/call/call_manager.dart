import 'package:flutter/cupertino.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/business/chat/call/call_info.dart';

import '../../../base/push_service/push_service.dart';
import '../../../base/router/router_names.dart';
import '../../../core/account/account_service.dart';
import 'package:get/get.dart';

import '../../../core/util/log_util.dart';

class CallManager {
  //生成单利
  static final CallManager _instance = CallManager._internal();

  factory CallManager() {
    return _instance;
  }

  CallManager._internal();

  static CallManager get instance => _instance;

  void init() {
    PushService.instance.addObserver(PushId.kCalledMessageId, handleCall);
  }

  void dispose() {
    PushService.instance.removeObserver(PushId.kCalledMessageId, handleCall);
  }

  callOut(Map args) {
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

  void clearCallInfo() {
    curCall = null;
  }

  Set<int> handledCallIds = {};
  VeoCall? curCall;
  Function? onCallStateChanged;

  // 负责分发通话事件
  void handleCall(Event object) async {
    Map obj = object.data;
    VeoCall call = VeoCall(
      id: obj[Security.security_callId] ?? 0,
      from: obj[Security.security_fromUid] ?? 0,
      to: obj[Security.security_toUid] ?? 0,
      opUid: obj[Security.security_opUid] ?? 0,
      name: obj[Security.security_fromNick] ?? '',
      avatar: obj[Security.security_fromAvatar] ?? '',
      type: obj[Security.security_audio] ?? 0,
      cost: obj[Security.security_costEveryMinute] ?? 1,
      earn: obj[Security.security_earnEveryMinute] ?? 0,
      freeTime: obj[Security.security_remainFreeTime] ?? 0,
      otherHost: obj[Security.security_anchor] ?? 1,
      status: obj[Security.security_state] ?? CallState.calling,
    );
    call.costContent = obj[Security.security_costOrEarnContent] ?? '';
    L.i('call info: ${call.toMap()}');

    if (curCall != null && curCall!.id != call.id) {
      L.i('[VeoCall] handling an other call, curCall callId: ${curCall!.id}, notice callId: ${call.id}');
      return;
    }

    if (call.callStatus.value == CallState.calling && handledCallIds.contains(call.id)) {
      L.i('[VeoCall] this call is handling , ignore WATING msg');
      return;
    }
    /// being call
    if (call.callStatus.value == CallState.calling && call.callMe) {
      curCall = call;
      curCall!.meCall = false;
      RouteHelper.toCall(call.toMap());
      handledCallIds.add(call.id);
    } else {
      if (curCall == null) return;
      curCall?.callStatus.value = obj[Security.security_state] ?? 0;
      onCallStateChanged?.call(curCall!);
    }
  }

  /// 网络服务

  // 拨打电话
  Future<ApiResponse> dial({required int userId, int type = 1}) async {
    curCall = VeoCall(
        from: MyAccount.userId,
        to: userId,
        type: type
    );

    ApiRequest request = ApiRequest(Apis.security_dial, params: {Security.security_userId: userId, Security.security_type: type});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  // 接听电话
  Future<ApiResponse> answer({required int callId}) async {
    ApiRequest request = ApiRequest(Apis.security_answer, params: {Security.security_callId: callId});
    return await ApiService.instance.sendRequest(request);
  }

  // 取消拨打
  Future<ApiResponse> cancel({required int callId}) async {
    ApiRequest request = ApiRequest(Apis.security_giveUp, params: {Security.security_dialId: callId});
    return await ApiService.instance.sendRequest(request);
  }

  // 挂断电话
  Future<ApiResponse> hangup({required int callId}) async {
    ApiRequest request = ApiRequest(Apis.security_endCall, params: {Security.security_dialId: callId});
    return await ApiService.instance.sendRequest(request);
  }

  // 拒接电话
  Future<ApiResponse> refuse({required int callId}) async {
    ApiRequest request = ApiRequest(Apis.security_reject, params: {Security.security_callId: callId});
    return await ApiService.instance.sendRequest(request);
  }

  bool get isFreeCall => freeCallMinutes.value > 0;
  RxInt freeCallMinutes = 0.obs;
  RxInt freeAICallMinutes = 0.obs;

  Future<void> getCallConfig() async {
    ApiRequest request = ApiRequest(Apis.security_getMediaFree, params: {});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (!response.isSuccess) return;
    freeCallMinutes.value = response.data[Security.security_remainTime] ?? 0;
    dynamic remainTimeMap = response.data[Security.security_remainTimeMap];
    freeAICallMinutes.value = remainTimeMap?['9'] ?? 0;
  }
}
