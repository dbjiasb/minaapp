import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:biz/core/account/account_service.dart';

import '../../base/api_service/api_config.dart';
import '../../base/crypt/copywriting.dart';

const kOffChatSessionId = 100000;

enum SessionType { all, ai, real, group }
enum AccType {
  real,
  ai,
  script,
  aiPlus,
  customAi;

  get i => index;
}

enum ChatStatus {
  none,     /// 默认，根据type自动选择
  real,
  ai,
  script;

  get i => index;
  bool get isScript => this == ChatStatus.script;
  factory ChatStatus.fromIndex(int i) {
    switch (i) {
      case 1:
        return ChatStatus.real;
      case 2:
        return ChatStatus.ai;
      case 3:
        return ChatStatus.script;
      default:
        return ChatStatus.none;
    }
  }

  factory ChatStatus.fromAccType(int accType) {
    switch (accType) {
      case 0:
        return ChatStatus.real;
      case 1:
      case 3:
      case 4:
        return ChatStatus.ai;
      case 2:
        return ChatStatus.script;

      default:
        return ChatStatus.none;
    }
  }

}

class ChatSession {
  String id = ''; //这个是数字Uid 例如10139
  int get userId => int.tryParse(id) ?? 0;
  String name = '';
  String avatar = '';
  DateTime lastMessageTime;
  String lastMessageText = '';
  String get showExtMessage => draft.value.isNotEmpty ? '[Draft] ${draft.value}' : lastMessageText;
  RxString backgroundUrl = ''.obs;
  bool greeted = false;
  RxInt unreadNumber = 0.obs;
  int accountType = 1;
  int type = 0;
  String bio = '';
  RxInt level = 1.obs;
  RxInt nextLevelRatio = 0.obs;
  Rx<ChatStatus> chatStatus = ChatStatus.none.obs;
  RxString draft = ''.obs;
  String sessionId ='';//这个是sessionId,例如"SINGLE_SCENE:2:10139:1"

  bool get isRealChat => accountType == AccType.real.i;
  bool get isAiChat => isGroup || accountType != AccType.real.i && !isTheater;
  bool get isScriptChat => accountType == AccType.script.i;
  bool get isPGCAI => accountType == AccType.ai.i || accountType == AccType.script.i || accountType == AccType.aiPlus.i;
  bool get isPrivateAI => !isGroup && !isRealChat&&!isTheater;
  bool get isAIPlusChat => accountType == AccType.aiPlus.i;

  int get ownerId => AccountService.instance.account.userId;

  ChatSession({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessageTime,
    required this.lastMessageText,
    required this.accountType,
  });

  @override
  toString() {
    return 'ChatSession{id: $id, name: $name, avatar: $avatar, lastMessageTime: $lastMessageTime, lastMessageText: $lastMessageText, backgroundUrl: ${backgroundUrl.value}, unreadNumber: ${unreadNumber.value}  , type:$type';
  }

  Map<String, Object?> toDatabase() {
    Map<String, Object?> dbMap = {
      Security.security_id: id,
      Security.security_ownerId: ownerId,
      Security.security_name: name,
      Security.security_avatar: avatar,
      Security.security_lastMessageTime: lastMessageTime.millisecondsSinceEpoch,
      Security.security_backgroundUrl: backgroundUrl.value,
      Security.security_unreadNumber: unreadNumber.value,
      Security.security_accountType: accountType,
      Security.security_type: type,
      Security.security_level: level.value,
      Security.security_nextLevelRatio: nextLevelRatio.value,
      Security.security_draft: draft.value,
      Security.security_lastMessageText: lastMessageText
    };

    return dbMap;
  }

  ChatSession.fromDatabase(Map<String, dynamic> map)
    : id = map[Security.security_id] as String,
      name = map[Security.security_name] as String,
      avatar = map[Security.security_avatar] as String,
      lastMessageTime = DateTime.fromMillisecondsSinceEpoch(
        map[Security.security_lastMessageTime] as int,
      ),
      lastMessageText = map[Security.security_lastMessageText] ?? '',
      backgroundUrl =
          (map[Security.security_backgroundUrl] as String? ?? '').obs,
      unreadNumber = (map[Security.security_unreadNumber] as int? ?? 0).obs,
      accountType = map[Security.security_accountType] as int,
      type = (map[Security.security_type] as int? ?? 0),
      greeted = true {
    level.value = map[Security.security_level] as int? ?? 1;
    nextLevelRatio.value = map[Security.security_nextLevelRatio] as int? ?? 0;
    draft.value = map[Security.security_draft] as String? ?? '';
    // 构造函数主体可以为空
  }

  //从别的页面跳转到聊天页面，用于初始化聊天页面
  ChatSession.fromRouter(Map router)
    : id = router[Security.security_id],
      name = router[Security.security_name],
      avatar = router[Security.security_avatar],
      lastMessageTime =
          router[Security.security_lastMessageTime] == null
              ? DateTime.now()
              : DateTime.fromMillisecondsSinceEpoch(
                router[Security.security_lastMessageTime],
              ),
      lastMessageText = router[Security.security_lastMessageText] ?? '',
      backgroundUrl = (router[Security.security_backgroundUrl] as String? ?? '').obs,
      unreadNumber = (router[Security.security_unreadNumber] as int? ?? 0).obs,
      // 修复：显式转换类型后使用 .obs
      greeted = router[Security.security_greeted] ?? false,
      accountType = router[Security.security_accountType] ?? 1,
      type = router[Security.security_type] ?? 0,
    level = (router[Security.security_level] as int? ?? 1).obs,
    nextLevelRatio = (router[Security.security_nextLevelRatio] as int? ?? 0).obs,
    draft = (router[Security.security_draft] as String? ?? '').obs;

  ChatSession.fromStory(Map router)
      : id = "${router["targetRoleInfo"]?["targetUid"]}",
        name = router[Security.security_name],
        avatar = router["backgroundUrl"],
        // backgroundUrl = (router[Security.security_backgroundUrl] as String? ?? '').obs,
        backgroundUrl = (router['coverUrl'] as String? ?? '').obs,
        lastMessageTime =
        router[Security.security_lastMessageTime] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(
          router[Security.security_lastMessageTime],
        ),
        lastMessageText = router[Security.security_lastMessageText] ?? '',
        accountType = 0,
        type = 1,
        sessionId = router[Security.security_sessionId] ?? "",
        draft = (router[Security.security_draft] as String? ?? '').obs;

  String toRouter() {
    //转换成map再用json.encode
    return JsonEncoder().convert({
      Security.security_id: id,
      Security.security_name: name,
      Security.security_avatar: avatar,
      Security.security_lastMessageTime: lastMessageTime.millisecondsSinceEpoch,
      Security.security_lastMessageText: lastMessageText,
      Security.security_greeted: greeted,
      Security.security_backgroundUrl: backgroundUrl.value,
      Security.security_unreadNumber: unreadNumber.value,
      Security.security_accountType: accountType,
      Security.security_type: type,
      Security.security_level: level.value,
      Security.security_nextLevelRatio: nextLevelRatio.value,
      Security.security_draft: draft.value,
    });
  }

  static ChatSession get offChatSession => ChatSession(
    id: '$kOffChatSessionId',
    // name: Copywriting.security_soulink_Team,
    name: "Mina Team",
    avatar: "",
    // avatar: "${ApiConfig.cdn}/services/${Security.security_client_config}/icon/soulink_team_v2.png",
    lastMessageText: Copywriting.security_contact_us_for_support_,
    lastMessageTime: DateTime.fromMillisecondsSinceEpoch(0),
    accountType: 0,
  );

  bool get isOffChatSession => id == kOffChatSessionId.toString();

  bool get isGroup => type == 2;
  bool get isTheater => type == 1;

  int get groupId => safeExtractId(id) ?? 0;

  int? safeExtractId(String? input) {
    if (input == null) return null;
    final match = RegExp(r'\d+').firstMatch(input);
    if (match == null) return null;
    try {
      return int.parse(match.group(0)!);
    } catch (e) {
      return null; // 数字太大或格式错误
    }
  }
}
