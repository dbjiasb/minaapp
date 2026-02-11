import 'package:biz/base/crypt/routes.dart';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/chat/chat_room_cells/chat_audio_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_tip_message.dart';
import 'package:biz/business/chat/chat_session.dart';

import '../../../core/account/account_service.dart';
import './chat_text_cell.dart';
import 'chat_gift_cell.dart';
import 'chat_theater_brief_message.dart';

//为ChatTextAudioStatus添加构造方法
enum ChatTextAudioStatus {
  unlock(0),
  loading(1),
  ready(2),
  playing(3),
  pause(4);

  final int digit;

  const ChatTextAudioStatus(this.digit);

  // 新增構造方法
  factory ChatTextAudioStatus.fromDigit(int digit) {
    return values.firstWhere(
      (e) => e.digit == digit,
      orElse: () => unlock, // 默認返回 unlock 狀態
    );
  }
}

abstract class AudioInfoInterface {
  String get audioUrl;

  int get audioDuration;
}

enum ChatMessageType {
  system(-4),
  time(-3),
  generating(-2),
  revoke(-1),
  none(0),
  text(1),
  image(2),
  voice(3),
  video(4),
  call(5),
  scene(6),
  gift(7),
  desc(8),
  genAiResAction(9),
  tip(10),
  dating(11),
  routeTip(12),
  card(13),
  activity(14),
  chatRecord(15),
  undress(16),
  customStoryBrief(17);

  final int value;

  const ChatMessageType(this.value);

  // 新增構造方法
  factory ChatMessageType.fromValue(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => none, // 默認返回 text 類型
    );
  }
}

enum ChatMessageSendStatus {
  sent(0),
  sending(1),
  failed(2);

  final int digit;

  const ChatMessageSendStatus(this.digit);

  // 新增構造方法
  factory ChatMessageSendStatus.fromDigit(int digit) {
    return values.firstWhere(
      (e) => e.digit == digit,
      orElse: () => sent, // 默認返回 sent 狀態
    );
  }
}

class ChatMessage implements AudioInfoInterface {
  final int id;
  final int senderId;
  final int receiverId;
  final DateTime date;
  final int ownerId;
  final String senderName;
  final String senderAvatar;
  final ChatMessageType type;
  final String uuid;
  String info = '{}';
  final Map lockInfo;
  final String nativeId;
  Map renewInfo = {};
  var sendState = ChatMessageSendStatus.sent.obs;
  var focused = false.obs;
  int like = 0;
  List<int>? specifyRepliers, bannedRepliers; //群聊发送对象
  ChatSession? session; //发送的时候会设置
  final int sessionType;//0普通私聊，1剧场，2群聊

  bool get isGroup => sessionType == 2;

  RxBool showContinue = false.obs;
  int chatStatus = 0;   ///发消息给剧本时，需要将chatStatus设置为2（AI），否则不回消息，其他场景暂时没用，后面状态切换之后需要用

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.date,
    required this.ownerId,
    required this.type,
    required this.uuid,
    required this.info,
    required this.lockInfo,
    required this.nativeId,
    required this.senderName,
    required this.senderAvatar,
    required this.sessionType,
    this.specifyRepliers,
    this.bannedRepliers,
    this.session,
  });

  bool isMine() {
    return senderId == ownerId;
  }

  String _sessionId = '';

  bool get isCall => type == ChatMessageType.call;

  bool get isText => type == ChatMessageType.text;

  bool get isGift => type == ChatMessageType.gift;

  String get sessionId {
    if (_sessionId.isEmpty) {
      _sessionId = (isMine() ? receiverId : senderId).toString();
    }
    return _sessionId;
  }

  set sessionId(String sessionId) {
    _sessionId = sessionId;
  }

  static String get tableName => Security.security_chat_message;

  static String get createTableSql => '''
      CREATE TABLE IF NOT EXISTS $tableName (
        ${Security.security_id} INTEGER PRIMARY KEY,
        ${Security.security_ownerId} INTEGER NOT NULL,
        ${Security.security_senderId} INTEGER NOT NULL,
        ${Security.security_receiverId} INTEGER NOT NULL,
        ${Security.security_type} INTEGER NOT NULL,
        ${Security.security_sessionId} TEXT NOT NULL,
        ${Security.security_date} INTEGER NOT NULL,
        ${Security.security_nativeId} TEXT,
        ${Security.security_content}  TEXT,
        ${Security.security_sendState}  INTEGER NOT NULL DEFAULT 0,
        ${Security.security_info}  TEXT,
        ${Security.security_lockInfo}  TEXT,
        ${Security.security_uuid}  TEXT,
        ${Security.security_renewInfo}  TEXT,
        ${Security.security_like}  INTEGER NOT NULL DEFAULT 0,
        ${Security.security_name}  TEXT,
        ${Security.security_avatar}  TEXT,
        ${Security.security_sessionType}  INTEGER DEFAULT 0
      )
    ''';

  Map<String, Object?> toDatabase() {
    return {
      Security.security_id: id,
      Security.security_ownerId: ownerId,
      Security.security_senderId: senderId,
      Security.security_receiverId: receiverId,
      Security.security_sessionId: sessionId,
      Security.security_date: date.millisecondsSinceEpoch,
      Security.security_nativeId: nativeId,
      Security.security_type: type.value,
      Security.security_sendState: sendState.value.digit,
      Security.security_info: info,
      Security.security_lockInfo: JsonEncoder().convert(lockInfo),
      Security.security_uuid: uuid,
      Security.security_renewInfo: JsonEncoder().convert(renewInfo),
      Security.security_like: like,
      Security.security_name: senderName,
      Security.security_avatar: senderAvatar,
      Security.security_sessionType: sessionType,
    };
  }

  //提供一个fromData方法，用初始化列表实现
  ChatMessage.fromLocalData(Map<String, Object?> map)
      : id = (map[Security.security_id] as int?) ?? 0,
        senderId = (map[Security.security_senderId] as int?) ?? 0,
        receiverId = (map[Security.security_receiverId] as int?) ?? 0,
        date = DateTime.fromMillisecondsSinceEpoch(
            (map[Security.security_date] as int?) ?? 0),
        ownerId = (map[Security.security_ownerId] as int?) ?? 0,
        senderName = (map[Security.security_name] as String?) ?? '',
        senderAvatar = (map[Security.security_avatar] as String?) ?? '',
        type = ChatMessageType.fromValue(
            (map[Security.security_type] as int?) ?? 0),
        uuid = (map[Security.security_uuid] as String?) ?? '',
        info = (map[Security.security_info] as String?) ?? '{}',
        nativeId = map[Security.security_nativeId] as String? ?? '',
        like = (map[Security.security_like] as int?) ?? 0,
        sessionType = (map[Security.security_sessionType] as int?) ?? 0,
        lockInfo = JsonDecoder().convert(
            map[Security.security_lockInfo] as String? ?? '{}') {
    sessionId = (map[Security.security_sessionId] as String?) ?? '';
    sendState = ChatMessageSendStatus
        .fromDigit((map[Security.security_sendState] as int?) ?? 0)
        .obs;
    renewInfo = JsonDecoder().convert(
        map[Security.security_renewInfo] as String? ?? '{}');
  }

  //工厂方法实现
  factory ChatMessage.fromDatabase(Map<String, Object?> map) {
    int messageType = (map[Security.security_type] as int?) ?? 0;
    //创建ChatMessageType
    ChatMessageType type = ChatMessageType.values.firstWhere(
      (element) => element.value == messageType,
    );
    switch (type) {
      case ChatMessageType.text:
      case ChatMessageType.desc:
        return ChatTextMessage.fromDatabase(map);
      // case ChatMessageType.call:
      //   return ChatCallMessage.fromDatabase(map);
      // case ChatMessageType.image:
      //   return ChatImageMessage.fromDatabase(map);
      // case ChatMessageType.video:
      //   return ChatVideoMessage.fromDatabase(map);
      case ChatMessageType.gift:
        return ChatGiftMessage.fromDatabase(map);
      case ChatMessageType.voice:
        return ChatAudioMessage.fromDatabase(map);
      case ChatMessageType.tip:
        return ChatTipsMessage.fromDatabase(map);
      case ChatMessageType.customStoryBrief:
        return ChatTheaterBriefMessage.fromDatabase(map);
      default:
        return ChatMessage.none();
    }
  }

  Map<String, dynamic> toServer() {
    if (session != null && session!.isGroup || session!.isTheater) {
      return {
        Constants.receiverId: session!.isTheater ? receiverId : 0,
        Security.security_toGroupId: session!.isTheater ? 0 : session!.groupId,
        Security.security_sessionType: session!.type,
        Security.security_sessionId: session!.sessionId,
        Constants.senderId: senderId,
        Constants.infoType: type.value,
        Constants.nativeId: nativeId,
        Security.security_specifyRepliers: specifyRepliers ?? [],
        Security.security_bannedRepliers: bannedRepliers ?? [],
      };
    } else {
      return {
        Constants.receiverId: receiverId,
        Constants.senderId: senderId,
        Constants.infoType: type.value,
        Constants.nativeId: nativeId,
        Security.security_chatStatus: chatStatus,
      };
    }
  }

  //fromServerData，用初始化列表实现
  ChatMessage.fromServerData(Map map)
      : id = (map[Security.security_id] as int?) ?? 0,
        senderId = (map[Constants.senderId] as int?) ?? 0,
        receiverId = (map[Constants.receiverId] as int?) ?? 0,
        date = DateTime.fromMillisecondsSinceEpoch(
          (map[Security.security_sendAt] ?? 0) * 1000,
        ),
        ownerId = AccountService.instance.account.userId,
        senderName = (map[Security.security_fromNick] as String?) ?? '',
        senderAvatar = (map[Security.security_fromAvatar] as String?) ?? '',
        type = ChatMessageType.fromValue(
            (map[Constants.infoType] as int?) ?? 0),
        uuid = (map[Security.security_uuid] as String?) ?? '',
        info = (map[Security.security_jsonBody] as String?) ?? '{}',
        nativeId = map[Constants.nativeId] as String? ?? '',
        like = (map[Security.security_like] as int?) ?? 0,
        sessionType = (map[Security.security_sessionType] as int?) ?? 0,
        lockInfo = map[Security.security_unlock] as Map? ?? {} {
    sendState = ChatMessageSendStatus.sent.obs;
    renewInfo = map[Security.security_reload] as Map? ?? {};
  }

  factory ChatMessage.fromServer(Map map) {
    //创建ChatMessageType
    ChatMessageType type = ChatMessageType.fromValue(
      map[Constants.infoType] ?? 0,
    );
    switch (type) {
      case ChatMessageType.text:
      case ChatMessageType.desc:
        return ChatTextMessage.fromServer(map);
      // case ChatMessageType.video:
      //   return ChatVideoMessage.fromServer(map);
      case ChatMessageType.gift:
        return ChatGiftMessage.fromServer(map);
      case ChatMessageType.voice:
        return ChatAudioMessage.fromServer(map);
      case ChatMessageType.tip:
        return ChatTipsMessage.fromServer(map);
      default:
        return ChatMessage.none(); //不支持的消息类型，返回默认值
    }
  }

  String get externalText => '';

  ChatMessage.none()
    : id = 0,
      senderId = 0,
      receiverId = 0,
      date = DateTime.now(),
      ownerId = 0,
      senderName = '',
      senderAvatar = '',
      type = ChatMessageType.none,
      uuid = '',
      info = '',
      lockInfo = {},
      nativeId = '',
      sessionType = 0,
      like = 0;

  @override
  int get audioDuration => 0;

  @override
  String get audioUrl => '';

  bool get unlocked =>
      lockInfo.isEmpty || lockInfo[Security.security_unlock] == 1;

  set unlocked(bool unlocked) {
    lockInfo[Security.security_unlock] = unlocked ? 1 : 0;
  }

  int get unlockPrice => lockInfo[Security.security_cost] ?? 0;

  int get currencyType => lockInfo[Security.security_costType] ?? 0;
}
