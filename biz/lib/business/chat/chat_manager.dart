import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/report/report_manager.dart';
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
import 'package:biz/business/chat/call/call_manager.dart';
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

class ResGenReporter {
  static Map<int, DateTime> genInfo = {};

  /// type 0: image 1: video
  static void reportGen(int mid, int type) {
    genInfo[mid] = DateTime.now();
    ReportManager.sendEvent('gen_res', {
      Security.security_mid: mid.toString(),
      Security.security_type: type == 0 ? Security.security_image : 'video',
    });
  }

  static void reportComplete(int mid, int prepare) {
    DateTime startDate = genInfo[mid] ?? DateTime.now();
    ReportManager.sendEvent('gen_res_done', {
      Security.security_mid: mid.toString(),
      Security.security_time: DateTime.now().difference(startDate).inSeconds.toString(),
      'prepare': prepare.toString(),
    });
  }
}


class SendMessageResponse {
  ApiResponse response;
  ChatMessage message;

  SendMessageResponse(this.response, this.message);

  bool get isSuccess => response.isSuccess;
}

class ChatManager {
  //单利模式
  static final ChatManager _instance = ChatManager._internal();

  ChatManager._internal({
    Future<ApiResponse> Function(ApiRequest)? requestSender,
    String? Function(String)? readTag,
    void Function(String, String)? writeTag,
  }) : _requestSender = requestSender ?? ((request) => ApiService.instance.sendRequest(request)),
       _readTag = readTag ?? ((key) => Preferences.instance.getString(key)),
       _writeTag = writeTag ?? ((key, value) { Preferences.instance.setString(key, value); });

  @visibleForTesting
  ChatManager.forTesting({
    required Future<ApiResponse> Function(ApiRequest) requestSender,
    required String? Function(String) readTag,
    required void Function(String, String) writeTag,
  }) : this._internal(requestSender: requestSender, readTag: readTag, writeTag: writeTag);

  final Future<ApiResponse> Function(ApiRequest) _requestSender;
  final String? Function(String) _readTag;
  final void Function(String, String) _writeTag;

  factory ChatManager() => _instance;

  static ChatManager get instance => _instance;

  ChatSessionHandler sessionHandler = ChatSessionHandler();
  ChatMessageHandler messageHandler = ChatMessageHandler();

  int get accountId => AccountService.instance.account.userId;

  String get messagePullTag => 'msg_sync_tag_$accountId';
  String lastPullTag = '';

  int get intPullTag => int.tryParse(lastPullTag) ?? 0;
  Object? _syncRequest;
  bool get isQueryingMessages => _syncRequest != null;

  bool _isCurrent(Account account) => account.isLoggedIn && identical(account, MyAccount);
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
    final account = MyAccount;
    if (!_isCurrent(account)) return;
    lastPullTag = _readTag(messagePullTag) ?? '';
    await getHistoryMessages();
    if (_isCurrent(account)) startTimer();
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
    _resetAccountState();
    getMessages();
  }

  void onLogout(Event event) {
    _resetAccountState();
  }

  void _resetAccountState() {
    stopTimer();
    stopDelaySyncMsgTimer();
    _syncRequest = null;
    currentSession = null;
    lastPullTag = '';
    sentMessages.clear();
    didPostOutMessages.clear();
  }

  void dispose() {
    //释放资源
    _resetAccountState();
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
    final account = MyAccount;
    if (!_isCurrent(account)) return;

    ChatMessage message = ChatMessage.fromServer(data);
    await messageHandler.insertMessage(message);
    if (!_isCurrent(account)) return;
    //刷新图片
    EventCenter.instance.sendEvent(kEventCenterDidPreparedImageMessage, {Security.security_message: message});
  }

  void onReceivedEditMessage(Event event) {
    onImagePrepared(event.data);
  }

  void onReceivedNewMessages(Event event) async {
    final account = MyAccount;
    if (!_isCurrent(account)) return;

    Map data = event.data;
    if (data.isEmpty) return;

    int lastMessageId = data[Constants.newestTag] ?? 0;
    // if (kDebugMode) getHistoryMessages();

    ChatMessage? lastMessage = await messageHandler.selectMessage(lastMessageId);
    if (!_isCurrent(account)) return;
    if (lastMessage == null) {
      getHistoryMessages();
      return;
    }

    List rawList = data[Constants.messages] ?? [];
    if (rawList.isEmpty) return;

    ChatMessage firstMessage = ChatMessage.fromServer(rawList.first);
    ChatSession? session = await sessionHandler.querySession(firstMessage.sessionId);
    if (!_isCurrent(account)) return;
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
        L.i('[Chat][Ignore][push] ${message.id.toString()} type:${message.type.value}');
        continue;
      }
      //插入消息
      await messageHandler.insertMessage(message);
      if (!_isCurrent(account)) return;

      if (didPostOutMessages.contains(message.id) == false) {
        didPostOutMessages.add(message.id);
        messages.add(message);
      } else {
        L.i('[Chat][Pull][receivedMessages] didPostOutMessages contains ${message.id.toString()}');
      }
    }

    if (newestMessage != null) {
      L.i('[Chat][Pull][receivedMessages] ${newestMessage.id.toString()}');
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
    if (!_isCurrent(account)) return;

    EventCenter.instance.sendEvent(kEventCenterDidReceivedNewMessages, {session.id: messages});
  }

  //发送消息
  Future<SendMessageResponse> sendMessage(ChatMessage message) async {
    final account = MyAccount;

    SendMessageResponse stale() => SendMessageResponse(ApiResponse.withError({
      Security.security_code: -1,
      Security.security_description: 'Account changed',
    }), message);
    if (!_isCurrent(account) || message.ownerId != account.userId) return stale();
    if (currentSession != null) {
      currentSession!.lastMessageText = message.externalText;
      currentSession!.lastMessageTime = message.date;
      await updateChatSession(currentSession!);
      if (!_isCurrent(account)) return stale();
    }

    ApiRequest request = ApiRequest(Apis.security_sendChatMsg, params: {Security.security_msg: message.toServer()});
    ApiResponse response = await _requestSender(request);
    if (!_isCurrent(account)) return stale();
    if (response.isSuccess) {
      if (message.receiverId == kOffChatSessionId) {
        L.uploadIfNeed();
      }

      ChatMessage newMessage = ChatMessage.fromServer(response.data[Security.security_msg]);
      int result = await messageHandler.updateLocalMessage(newMessage);
      if (!_isCurrent(account)) return stale();
      L.i('插入消息结果: $result');
      addSentMessages(newMessage);
      return SendMessageResponse(response, newMessage);
    } else {
      message.sendState.value = ChatMessageSendStatus.failed;
      await messageHandler.updateLocalMessage(message);
      if (!_isCurrent(account)) return stale();
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
    final account = MyAccount;
    if (!_isCurrent(account) || isQueryingMessages) return;
    final requestId = Object();
    _syncRequest = requestId;
    stopDelaySyncMsgTimer();
    try {
      bool hasMore;
      do {
        lastPullTime = DateTime.now();
        final response = await _requestSender(ApiRequest(
          Apis.security_syncChatHistory,
          params: {Security.security_position: lastPullTag},
        ));
        if (!_isCurrent(account)) return;
        if (!response.isSuccess) {
          L.i('获取历史消息失败: ${response.description}');
          return;
        }
        final previousTag = lastPullTag;
        await handleApiResponse(response, forAccount: account);
        if (!_isCurrent(account)) return;
        hasMore = response.data[Security.security_hasMore] == true;
        // A malformed/no-progress page must not create an infinite pull loop.
        if (lastPullTag == previousTag) return;
      } while (hasMore);
    } finally {
      // An old request must not unlock the new account's in-flight request.
      if (identical(_syncRequest, requestId)) _syncRequest = null;
    }
  }

  //处理ApiResponse
  Future<void> handleApiResponse(ApiResponse response, {Account? forAccount}) async {
    final account = forAccount ?? MyAccount;
    if (!_isCurrent(account)) return;
    //取出会话
    List rawSessions = response.data[Constants.rawSessions] ?? [];

    //取出消息
    for (var rawSession in rawSessions) {
      L.i('[Chat][Pull][onPullMessageRsp][Session] ${rawSession[Security.security_id]}-${rawSession[Security.security_sessionId]}');
      List rawMessages = rawSession[Constants.rawItems] ?? [];
      if (rawMessages.isEmpty) continue;

      int unreadNumber = 0;
      List<ChatMessage> messages = [];

      for (var rawMessage in rawMessages) {
        ChatMessage message = ChatMessage.fromServer(rawMessage);
        if (shouldIgnoreMessage(message)) {
          L.i('[Chat][shouldIgnoreMessage][from_pull] ${message.id.toString()} type:${message.type.value}');
          continue;
        }

        //插入消息
        int ret = await messageHandler.insertMessage(message);
        if (!_isCurrent(account)) return;
        if (didPostOutMessages.contains(message.id) == false) {
          didPostOutMessages.add(message.id);
          messages.add(message);
          if (!message.isMine()) unreadNumber++;
        } else {
          L.i('[Chat][Pull][receivedMessages] didPostOutMessages contains ${message.id.toString()}');
        }
      }

      if (messages.isEmpty) continue;

      late ChatSession session;
      ChatMessage lastMessage = messages.last;
      ChatSession? localSession = await sessionHandler.querySession(lastMessage.sessionId);
      if (!_isCurrent(account)) return;
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
        )..type = type;
      }

      if ((currentSession?.id ?? '') == session.id) {
        currentSession!.lastMessageText = session.lastMessageText;
      } else {
        session.unreadNumber.value += unreadNumber;
      }
      await updateChatSession(session);
      if (!_isCurrent(account)) return;

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
    L.i('[Chat] storePullTag: $pullTag');
    if (pullTag.isEmpty) return;

    int newKey = int.tryParse(pullTag) ?? 0;
    int oldKey = int.tryParse(lastPullTag) ?? 0;

    if (newKey <= oldKey) return;

    lastPullTag = pullTag;
    _writeTag(messagePullTag, pullTag);
    L.i('[${DateTime.now()}] [Chat] [Pull] storePullTag: $newKey [$oldKey]');
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
    final account = MyAccount;
    if (!_isCurrent(account)) return;

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
    ApiResponse response = await _requestSender(request);
    if (!_isCurrent(account)) return;
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
    return await _requestSender(request);
  }

  Future<ApiResponse> reloadMessage(ChatMessage message) async {
    ApiRequest request = ApiRequest(Apis.security_replaceMsg, params: {Security.security_uuid: message.uuid, Security.security_action: 1});
    return await _requestSender(request);
  }

  void onResponseCalled(Event object) {
    CallManager.instance.handleCall(object);
  }

  Future updateChatSession(ChatSession session) async {
    final account = MyAccount;
    if (!_isCurrent(account) || session.ownerId != account.userId) return 0;
    if (kDebugMode && session.lastMessageText.isEmpty) {
      L.i('[Chat] [updateChatSession] ${StackTrace.current.toString()}');
    }
    int ret = await sessionHandler.upsertSession(session);
    if (!_isCurrent(account)) return ret;
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
    ApiResponse rsp = await _requestSender(request);

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
    ApiResponse rsp = await _requestSender(request);
    return rsp;
  }
}
