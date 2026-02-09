import 'package:biz/base/crypt/routes.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/push_service/push_service.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../base/api_service/api_service_export.dart';
import '../../core/util/log_util.dart';
import './chat_message_handler.dart';
import './chat_session_handler.dart';
import 'chat_room_cells/chat_message.dart';

String kEventCenterDidPreparedImageMessage = Security.security_kEventCenterDidPreparedImageMessage;

String kEventCenterDidQueriedNewMessages = Security.security_kEventCenterDidQueriedNewMessages;
String kEventCenterDidReceivedNewMessages = Security.security_kEventCenterDidReceivedNewMessages;

String kEventCenterDidEnterChatRoom = Security.security_kEventCenterDidEnterChatRoom;
String kEventCenterWillExitChatRoom = Security.security_kEventCenterWillExitChatRoom;

String kEventCenterDidUpdateSession = Security.security_kEventCenterDidUpdateSession;

class SendMessageResponse {
  ApiResponse response;
  ChatMessage message;

  SendMessageResponse(this.response, this.message);

  bool get isSuccess => response.isSuccess;
}

class ChatManager {
  //单利模式
  static final ChatManager _instance = ChatManager._internal();

  ChatManager._internal();

  factory ChatManager() => _instance;

  static ChatManager get instance => _instance;

  ChatSessionHandler sessionHandler = ChatSessionHandler();
  ChatMessageHandler messageHandler = ChatMessageHandler();

  int get accountId => AccountService.instance.account.userId;

  String get messagePullTag => 'msg_sync_tag_$accountId';
  String lastPullTag = '';

  int get intPullTag => int.tryParse(lastPullTag) ?? 0;
  bool isQueryingMessages = false;
  Set<int> sentMessages = {};
  Set<int> didPostOutMessages = {};

  bool get loggedIn => AccountService.instance.loggedIn;

  //当前会话
  ChatSession? _currentSession;

  set currentSession(ChatSession? session) {
    if (_currentSession == session) return;
    if (_currentSession != null) {
      //退房通知
      EventCenter.instance.sendEvent(kEventCenterWillExitChatRoom, {});
    }
    _currentSession = session;
    if (_currentSession != null) {
      _currentSession!.unreadNumber.value = 0;
      sessionHandler.clearUnreadCount(sessionId: _currentSession!.id);
      EventCenter.instance.sendEvent(kEventCenterDidEnterChatRoom, {});
    }
  }

  ChatSession? get currentSession => _currentSession;

  void init() {
    if (loggedIn) {
      getMessages();
    }

    listenEvents();
  }

  Future getMessages() async {
    lastPullTag = Preferences.instance.getString(messagePullTag) ?? '';
    await getHistoryMessages();
    startTimer();
  }

  //监听登录、注销事件
  void listenEvents() {
    EventCenter.instance.addListener(kEventCenterUserDidLogin, onLogin);
    EventCenter.instance.addListener(kEventCenterUserDidLogout, onLogout);

    PushService.instance.addObserver(PushId.kBatchMessageKey, onReceivedNewMessages);
    PushService.instance.addObserver(PushId.kEditMessageId, onReceivedEditMessage);
    PushService.instance.addObserver(PushId.kCallHistoryMessageId, onReceivedCallMessages);
  }

  void onLogin(Event event) {
    getMessages();
  }

  void onLogout(Event event) {
    stopTimer();
  }

  void dispose() {
    //释放资源
    stopTimer();
    EventCenter.instance.removeListener(kEventCenterUserDidLogin, onLogin);
    EventCenter.instance.removeListener(kEventCenterUserDidLogout, onLogout);
    PushService.instance.removeObserver(PushId.kBatchMessageKey, onReceivedNewMessages);
    PushService.instance.removeObserver(PushId.kEditMessageId, onReceivedEditMessage);
    PushService.instance.removeObserver(PushId.kCallHistoryMessageId, onReceivedCallMessages);
  }

  ///GiftNotice 200001 其实是礼物
  void onReceivedCallMessages(Event event) {
    getHistoryMessages();
  }

  Future<void> onImagePrepared(Map data) async {
    ChatMessage message = ChatMessage.fromServer(data);
    await messageHandler.insertMessage(message);
    //刷新图片
    EventCenter.instance.sendEvent(kEventCenterDidPreparedImageMessage, {Security.security_message: message});
  }

  void onReceivedEditMessage(Event event) {
    onImagePrepared(event.data);
  }

  void onReceivedNewMessages(Event event) async {
    Map data = event.data;
    if (data.isEmpty) return;

    int lastMessageId = data[Constants.newestTag] ?? 0;
    // if (kDebugMode) getHistoryMessages();

    ChatMessage? lastMessage = await messageHandler.selectMessage(lastMessageId);
    if (lastMessage == null) {
      getHistoryMessages();
      return;
    }

    List rawList = data[Constants.messages] ?? [];
    if (rawList.isEmpty) return;

    ChatMessage firstMessage = ChatMessage.fromServer(rawList.first);
    ChatSession? session = await sessionHandler.querySession(firstMessage.sessionId);
    if (session == null) {
      getHistoryMessages();
      return;
    }

    //遍历rawList，构造ChatMessage，并过滤shouldIgnoreMessage
    List<ChatMessage> messages = [];
    ChatMessage? newestMessage;
    for (var rawMessage in rawList) {
      ChatMessage message = ChatMessage.fromServer(rawMessage);
      if (newestMessage == null || message.date.isAfter(newestMessage.date)) {
        newestMessage = message;
      }

      if (shouldIgnoreMessage(message)) {
        L.i('[ChatManager] [shouldIgnoreMessage][from_push] ${message.id.toString()} type:${message.type.value}');
        continue;
      }
      //插入消息
      await messageHandler.insertMessage(message);

      if (didPostOutMessages.contains(message.id) == false) {
        didPostOutMessages.add(message.id);
        messages.add(message);
      } else {
        L.i('[ChatManager][PullTag][onReceivedNewMessages] didPostOutMessages contains ${message.id.toString()}');
      }
    }

    if (newestMessage != null) {
      L.i('[ChatManager][PullTag][onReceivedNewMessages] ${newestMessage.id.toString()}');
      storePullTag(newestMessage.id.toString());
    }

    if (messages.isEmpty) {
      return;
    }

    session.lastMessageText = newestMessage!.externalText;
    session.lastMessageTime = newestMessage.date;
    if ((currentSession?.id ?? '') == session.id) {
      currentSession!.lastMessageText = session.lastMessageText;
    } else {
      session.unreadNumber.value += messages.length;
    }

    await updateChatSession(session);

    EventCenter.instance.sendEvent(kEventCenterDidReceivedNewMessages, {session.id: messages});
  }

  //发送消息
  Future<SendMessageResponse> sendMessage(ChatMessage message) async {
    if (currentSession != null) {
      currentSession!.lastMessageText = message.externalText;
      currentSession!.lastMessageTime = message.date;
      await updateChatSession(currentSession!);
    }

    ApiRequest request = ApiRequest(Apis.security_sendChatMsg, params: {Security.security_msg: message.toServer()});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      if (message.receiverId == kOffChatSessionId) {
        L.uploadIfNeed();
      }

      ChatMessage newMessage = ChatMessage.fromServer(response.data[Security.security_msg]);
      int result = await messageHandler.updateLocalMessage(newMessage);
      L.i('插入消息结果: $result');
      addSentMessages(newMessage);
      return SendMessageResponse(response, newMessage);
    } else {
      message.sendState.value = ChatMessageSendStatus.failed;
      await messageHandler.updateLocalMessage(message);
      L.i('发送消息失败: ${response.description}');
      Toast.show(response.description);
    }
    return SendMessageResponse(response, message);
  }

  void addSentMessages(ChatMessage message) {
    if (sentMessages.contains(message.id)) return;
    sentMessages.add(message.id);
    printSentMessages();
  }

  void printSentMessages() {
    L.i('已发送消息: $sentMessages');
  }

  bool isSentMessage(ChatMessage message) {
    return sentMessages.contains(message.id);
  }

  Future<void> getHistoryMessages() async {
    if (isQueryingMessages) return;
    stopDelaySyncMsgTimer();

    lastPullTime = DateTime.now();

    isQueryingMessages = true;
    debugPrint('[${DateTime.now()}] [ChatManager][PullTag][sync] getHistoryMessages: $lastPullTag ');
    ApiRequest request = ApiRequest(Apis.security_syncChatHistory, params: {Security.security_position: lastPullTag});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      await handleApiResponse(response);
    } else {
      L.i('获取历史消息失败: ${response.description}');
    }

    isQueryingMessages = false;

    bool hasMore = response.data[Security.security_hasMore] ?? false;
    if (hasMore) {
      getHistoryMessages();
    } else {}
  }

  //处理ApiResponse
  Future<void> handleApiResponse(ApiResponse response) async {
    //取出会话
    List rawSessions = response.data[Constants.rawSessions] ?? [];
    if (rawSessions.isEmpty) return;

    //取出消息
    for (var rawSession in rawSessions) {
      L.i('[ChatManager][PullTag][onPullMessageRsp][Session] ${rawSession[Security.security_id]}-${rawSession[Security.security_sessionId]}');
      List rawMessages = rawSession[Constants.rawItems] ?? [];
      if (rawMessages.isEmpty) continue;

      int unreadNumber = 0;
      List<ChatMessage> messages = [];

      for (var rawMessage in rawMessages) {
        ChatMessage message = ChatMessage.fromServer(rawMessage);
        if (shouldIgnoreMessage(message)) {
          L.i('[ChatManager][shouldIgnoreMessage][from_pull] ${message.id.toString()} type:${message.type.value}');
          continue;
        }

        //插入消息
        await messageHandler.insertMessage(message);
        if (didPostOutMessages.contains(message.id) == false) {
          didPostOutMessages.add(message.id);
          messages.add(message);
          if (!message.isMine()) unreadNumber++;
        } else {
          L.i('[ChatManager][PullTag][onReceivedNewMessages] didPostOutMessages contains ${message.id.toString()}');
        }
      }

      if (messages.isEmpty) continue;

      late ChatSession session;
      ChatMessage lastMessage = messages.last;
      ChatSession? localSession = await sessionHandler.querySession(lastMessage.sessionId);
      if (localSession != null) {
        localSession.lastMessageText = lastMessage.externalText;
        localSession.lastMessageTime = lastMessage.date;
        session = localSession;
      } else {
        int type = rawSession[Security.security_type] ?? 0;
        session = ChatSession(
          id: type == 0 ? rawSession[Security.security_id].toString() : rawSession[Security.security_sessionId],
          name: rawSession[Security.security_title],
          avatar: rawSession[Security.security_icon],
          lastMessageTime: lastMessage.date,
          lastMessageText: lastMessage.externalText,
          accountType: rawSession[Security.security_acctType] ?? 1,
        );
      }

      if ((currentSession?.id ?? '') == session.id) {
        currentSession!.lastMessageText = session.lastMessageText;
      } else {
        session.unreadNumber.value += unreadNumber;
      }
      await updateChatSession(session);

      EventCenter.instance.sendEvent(kEventCenterDidQueriedNewMessages, {session.id: messages});

    }
    storePullTag(response.data[Constants.pullTag] ?? '');
  }

  bool shouldIgnoreMessage(ChatMessage message) {
    return !supportedMessageTypes.contains(message.type) || isSentMessage(message) || intPullTag >= message.id;
  }

  Set<ChatMessageType> supportedMessageTypes = {
    ChatMessageType.text,
    ChatMessageType.call,
    ChatMessageType.image,
    ChatMessageType.video,
    ChatMessageType.gift,
    ChatMessageType.tip,
    ChatMessageType.desc,
    ChatMessageType.voice,
  };

  void storePullTag(String pullTag) {
    if (pullTag == lastPullTag) return;
    L.i('[ChatManager] storePullTag: $pullTag');
    if (pullTag.isEmpty) return;

    int newKey = int.tryParse(pullTag) ?? 0;
    int oldKey = int.tryParse(lastPullTag) ?? 0;

    if (newKey <= oldKey) return;

    lastPullTag = pullTag;
    Preferences.instance.setString(messagePullTag, pullTag);
    L.i('[${DateTime.now()}] [ChatManager] [PullTag] storePullTag: $newKey [$oldKey]');
  }

  //定时器
  Timer? timer;

  void startTimer() {
    stopTimer();
    timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      onTimeout();
    });
  }

  DateTime lastPullTime = DateTime.now();

  void onTimeout() {
    getHistoryMessages();
  }

  void stopTimer() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
      timer = null;
    }
  }

  void sayHelloIfNeeded(ChatSession session) async {
    //发送消息
    ApiRequest request = ApiRequest(
      Apis.security_sayHello,
      params: {
        Security.security_userId: int.tryParse(session.id) ?? 0,
        Security.security_sessionId: session.isGroup || session.isTheater ? session.sessionId : '',
        Security.security_toGroup: [0],
        Security.security_status: session.isRealChat ? 1 : 2,
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      //处理响应
      session.greeted = true;

      int result = await updateChatSession(session);
      L.i('insert session:${session.id} result:$result');
    } else {
      L.i('sayHelloIfNeeded failed: ${response.description}');
    }
  }

  Future<ApiResponse> unlockMessage(ChatMessage message) async {
    var usePrem = 0;
    if (message.lockInfo[Security.security_costType] == 1) {
      usePrem = 0;
    } else if (message.type == ChatMessageType.video && MyAccount.freeVdoLeftTimes > 0 ||
        message.type == ChatMessageType.image && MyAccount.freeImgLeftTimes > 0 ||
        message.type == ChatMessageType.voice && MyAccount.freeVdoLeftTimes > 0) {
      usePrem = 1;
    }
    ApiRequest request = ApiRequest(Apis.security_deblockingMessage, params: {Security.security_mid: message.uuid, Security.security_usePrem: usePrem});
    return await ApiService.instance.sendRequest(request);
  }

  Future<ApiResponse> reloadMessage(ChatMessage message) async {
    ApiRequest request = ApiRequest(Apis.security_replaceMsg, params: {Security.security_uuid: message.uuid, Security.security_action: 1});
    return await ApiService.instance.sendRequest(request);
  }

  void onResponseCalled(Event object) {
  }

  Future updateChatSession(ChatSession session) async {
    if (kDebugMode && session.lastMessageText.isEmpty) {
      L.i('[ChatManager] [updateChatSession] ${StackTrace.current.toString()}');
    }
    int ret = await sessionHandler.upsertSession(session);
    EventCenter.instance.sendEvent(kEventCenterDidUpdateSession, {Security.security_kUpdatedSession: session});
    return ret;
  }

  Future<ChatSession?> querySession(String sessionId) async {
    return await sessionHandler.querySession(sessionId);
  }

  Future aiContinue(int sid, {bool group = false, String? sessionId, List<int>? specifyRepliers, List<int>? bannedRepliers}) async {
    Map<String, dynamic> arg = {
      Security.security_cidUid: group ? 0 : sid,
      Security.security_sessionId: sessionId,
      Security.security_specifyRepliers: specifyRepliers ?? [],
      Security.security_bannedRepliers: bannedRepliers ?? [],
    };

    Toast.loading();
    ApiRequest request = ApiRequest(Apis.security_aiContinueToSendMsg, params: arg);
    ApiResponse rsp = await ApiService.instance.sendRequest(request);

    if (rsp.isSuccess) {
      Toast.dismiss();
      startDelaySyncMsgTimer();
      return true;
    } else {
      Toast.show(rsp.description);
      return false;
    }
  }

  Timer? syncMsgTimer;

  Future startDelaySyncMsgTimer() async {
    syncMsgTimer?.cancel();
    syncMsgTimer = Timer(Duration(seconds: 10), () {
      getHistoryMessages();
    });
  }

  void stopDelaySyncMsgTimer() {
    syncMsgTimer?.cancel();
    syncMsgTimer = null;
  }

  Future<ApiResponse> queryMsgWithUuid(String uuid) async {
    Map<String, dynamic> arg = {
      Security.security_uuid: uuid,
    };

    ApiRequest request = ApiRequest(Apis.security_getMsgDetail, params: arg);
    ApiResponse rsp = await ApiService.instance.sendRequest(request);
    return rsp;
  }
}
