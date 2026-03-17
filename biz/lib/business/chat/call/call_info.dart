import 'package:biz/base/crypt/routes.dart';
import 'package:biz/core/account/account_service.dart';
import '../../../base/crypt/constants.dart';
import '../../../base/crypt/security.dart';
import '../../../base/event_center/event_center.dart';
import 'package:get/get.dart';

class CallState {
  static const int init = 0;
  static const int calling = 1;
  static const int canceled = 2;
  static const int rejected = 3;
  static const int answered = 4;
  static const int hangup = 5;
  static const int missing = 6;
}

class VeoCall {
  int id = 0;
  bool meCall = true;
  int from = 0;
  int to = 0;
  String? name;
  String? avatar;
  int type = 0;
  int cost = 0;
  double earn = 0;
  int freeTime = 0;
  int otherHost = 1;
  String intro = '';
  int opUid = 0;

  String rtcAppId = '';
  int rtcType = 1;
  String rtcToken = '';
  String myRtcUid = '';
  String otherRtcUid = '';
  String costContent = '';

  String roomId = '';
  Rx<int> callStatus = CallState.init.obs;

  VeoCall({
    this.id = 0,
    this.meCall = true,
    this.from = 0,
    this.to = 0,
    this.opUid = 0,
    this.name,
    this.avatar,
    this.type = 0,
    this.cost = 0,
    this.earn = 0,
    this.freeTime = 0,
    this.otherHost = 0,
    int status = 0}) {
    callStatus.value = status;
  }

  bool get callMe => to == MyAccount.userId;

  Map toMap() {
    return {
      Security.security_id: '$id',
      Security.security_meCall: '${meCall ? 1 : 0}',
      Security.security_to: '$to',
      Security.security_name: name ?? '',
      Security.security_avatar: avatar ?? '',
      Security.security_type: '$type',
      Security.security_cost: '$cost',
      Security.security_earn: '$earn',
      Security.security_freeTime: '$freeTime',
      Security.security_otherHost: '$otherHost',
      Security.security_status: '$callStatus',
      Security.security_opUid: '$opUid',
      Security.security_costContent: costContent,
    };
  }

  static VeoCall fromMap(Map map) {
    VeoCall call = VeoCall();
    call.id = int.parse(map[Security.security_id]);
    call.meCall = map[Security.security_meCall] == '1';
    call.to = int.parse(map[Security.security_uid]);
    call.name = map[Security.security_name];
    call.avatar = map[Security.security_avatar];
    call.type = int.parse(map[Security.security_type]);
    call.cost = int.parse(map[Security.security_cost]);
    call.earn = double.parse(map[Security.security_earn]);
    call.freeTime = int.parse(map[Security.security_freeTime]);
    call.otherHost = map[Security.security_toHost];
    call.costContent = map[Security.security_costContent] ?? '';
    return call;
  }
}