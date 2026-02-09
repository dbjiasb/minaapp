import 'package:biz/base/crypt/security.dart';
import 'dart:io';

class Constants {
  static String get replace => Platform.environment[Security.security_abc] ?? '';

  //user
  static String get tUid => Security.security_targetUid; //targetUid
  static String get senderId => Security.security_fromUserId; //fromUserId
  static String get receiverId => Security.security_toUserId; // toUserId
  static String get userData => Security.security_userInfo; //userInfo
  static String get acType => Security.security_accountType; //accountType
  static String get pVer => Security.security_poolVersion;

  //chat
  static String get nativeId => Security.security_clientId;
  static String get infoType => Security.security_msgType;
  static String get pullTag => Security.security_syncKey;
  static String get newestTag => Security.security_lastMsgId;
  static String get rawItems => Security.security_msgItems;
  static String get rawSessions => Security.security_sessions;
  static String get messages => Security.security_msgList;
  //api
  static String get statusData => Security.security_statusInfo;
  static String get apiName => Security.security_apiMethod;
  static String get secretTag => Security.security_factor;

  //call
  static String get dialId => Security.security_callId; //callId
  static String get remaining => Security.security_remainFreeTime; //remainFreeTime
  static String get dialType => Security.security_rtcType; //rtcType
  static String get initiator => Security.security_rtcSelfUid; //rtcSelfUid
  static String get recipient => Security.security_rtcTargetUid; //rtcTargetUid
  static String get costPerMinute => Security.security_costEveryMinute; //costEveryMinute
  static String get propType => Security.security_currencyType; //currencyType
  static String get profitPerMinute => Security.security_earnEveryMinute; //costEveryMinute
  static String get carrier => Security.security_payload;
  static String get commandId => Security.security_cmdID;

  //adjust
  static String get adReferrer => Security.security_fbInstallReferrer; //fbInstallReferrer
  static String get adClickTag => Security.security_clickLabel; //clickLabel
  static String get adToken => Security.security_trackerToken;
  static String get adCost => Security.security_costAmount;
  static String get adTracker => Security.security_trackerName;
  static String get adTeam => Security.security_adgroup;
  static String get adNet => Security.security_network;
  static String get adElection => Security.security_campaign;
  static String get adBuild => Security.security_creative;
  static String get adCurrency => Security.security_costCurrency;

  static String get adSetupInfo => Security.security_adjustInstallData;
  static String get adUpdate => Security.security_adjustAttrUpdate;
  static String get adDevice => Security.security_adjustDeviceId;
  static String get adKey => Security.security_adjustId;
}
