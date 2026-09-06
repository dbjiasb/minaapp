import 'package:biz/base/crypt/routes.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_text_cell.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/toast/toast.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/push_service/push_service.dart';
import '../../../base/router/router_names.dart';
import '../../../core/util/log_util.dart';
import 'av_engine.dart';
import 'call_info.dart';
import 'call_manager.dart';

const int kVoiceCallCostPerMin = 5;
const int kVideoCallCostPerMin = 30;

String kSKCallCostPerMin_Audio = Security.security_kSKCallCostPerMin_Audio;
String kSKCallCostPerMin_Video = Security.security_kSKCallCostPerMin_Video;

String kListRefreshId = Security.security_kListRefreshId;

enum CallRoomConnectState {
  none,
  connecting,   // 连接中
  connected,    // 连接成功
  fail,         // 连接失败
  close,        // 连接关闭
}

extension ChatMessageCall on ChatMessage {
  createSenderName(targetName) {
    return isMine() ? Security.security_me : targetName;
  }
}

enum VideoSizeType {
  remoteFull,
  localFull,
}

class CallController extends GetxController {

  CallController({
    required this.otherUid,
    required this.isCallOut,
    this.otherName = '',
    this.otherAvatar = '',
    this.type = StreamType.audio,
    this.autoAnswer = false}) {
    isSpeaker.value = isVideo ? true : false;
  }

  int get myUid => MyAccount.userId;

  bool everConnected = false;
  String get roomId => 'call-$callId-${isCallOut ? myUid : otherUid}-${isCallOut ? otherUid : myUid}';
  String get streamId => '$callId-$myUid';
  bool get isVideo => type == StreamType.video;
  bool get hasFreeTime => freeCallRemainTime.value > 0 && isVideo;

  int otherUid;
  bool isCallOut = false;
  String otherName;
  String otherAvatar = '';
  bool autoAnswer = false;
  RxInt freeCallRemainTime = 0.obs;//视频通话剩余分鐘
  StreamType type = StreamType.audio;
  int get callId => curCall.id;
  bool get targetAnchor => true;//curCall.otherHost == 1;//对方是否是主播

  VeoCall get curCall => CallManager.instance.curCall ?? VeoCall();
  RxInt costPerMin = kVoiceCallCostPerMin.obs;
  int get twoMinCost => perMinCost * 2;
  int get perMinCost => costPerMin.value;
  RxInt cosType = 1.obs;   /// ECurrencyType
  RxString costDescTitle = ''.obs;

  bool callEngineInited = false;
  int rechargeAlertCount = 0;
  RxBool videoAvailable = false.obs;
  final FocusNode focusNode = FocusNode();
  TextEditingController inputController = TextEditingController();
  RxBool hasFocusOnInput = false.obs;
  bool onEnterRoomSuccess = false;
  bool onRemoteUserEnterRoomSuccess = false;

  RxBool isSpeaker = false.obs;
  RxBool isMute = false.obs;
  RxBool dragging = false.obs;
  RxBool cameraEnable = true.obs;
  RxBool isFrontCamera = true.obs;

  final List<ChatMessage> messages = [];

  final GlobalKey<AnimatedListState> listViewKey = GlobalKey<AnimatedListState>();

  @override
  void onInit() {
    super.onInit();
    int cost = GetStorage().read<int>(isVideo ? kSKCallCostPerMin_Video : kSKCallCostPerMin_Audio) ?? (isVideo ? kVideoCallCostPerMin : kVoiceCallCostPerMin);
    costPerMin.value = cost;
    WakelockPlus.enable();

    focusNode.addListener(() {
      if (focusNode.hasFocus == true) {
        hasFocusOnInput.value = true;
      } else {
        hasFocusOnInput.value = false;
      }
    });

    PushService.instance.addObserver(PushId.kCallingInfoChangedMessageId, handleCallInfoChanged);
  }

  @override
  void onClose() {

    PushService.instance.removeObserver(PushId.kCallingInfoChangedMessageId, handleCallInfoChanged);
    super.onClose();
  }

  void handleCallInfoChanged(Event object) {
    Map data = object.data;
    if (data[Security.security_callId] != callId) return;
    costDescTitle.value = data[Security.security_costOrEarnContent];
    checkIfNeedRecharge();
  }

  final Rx<int> _callState = CallState.init.obs; //see CallStateEnum
  set callState(int status) {
    if (_callState.value == status) return;
    switch (status) {
      case CallState.answered: {
        if (callState == CallState.init) {
          startCallEngineConnect();
        }
      }
      break;
      case CallState.canceled:
      case CallState.rejected:
      case CallState.hangup:
      case CallState.missing:{
        Future.delayed(const Duration(seconds: 1), () {
          close();
        });
      }
      break;
      default:
        break;
    }

    _callState.value = status;
  }
  int get callState => _callState.value;

  Rx<CallRoomConnectState> connectState = CallRoomConnectState.none.obs;

  Rx<VideoView> mineView = Rx<VideoView>(VideoView(true, ''));
  Rx<VideoView> otherView = Rx<VideoView>(VideoView(false, ''));

  bool get needCost => isCallOut || targetAnchor;

  OverlayEntry? overlayEntry;

  Timer? countingTimer;
  Timer? CallRoomConnectTimer;//30秒内双方没有进房成功挂断电话
  Timer? connectionTimeoutTimer;//通话过程中网络差连接丢失后，30秒内若没有重连成功，挂断电话
  RxInt duration = 0.obs;
  Rx<VideoSizeType> sizeType = VideoSizeType.localFull.obs;

  void close() async {
    L.i('[VeoCall] close');

    WakelockPlus.disable();

    overlayEntry?.remove();  ///暂时去掉视频相关代码
    countingTimer?.cancel();

    CallManager.instance.clearCallInfo();
    CallManager.instance.onCallStateChanged = null;

    if (callEngineInited) {
      AVEngine.instance.stopPlayingStream(streamId);
      AVEngine.instance.exitRoom();
      AVEngine.instance.destroy();
      callEngineInited = false;
    }

    Future.delayed(const Duration(seconds: 1), () {
      ChatManager.instance.getHistoryMessages();
    });

    if (RouteHelper.currentRoute().startsWith(Routers.call)) {
      RouteHelper.back();
    }
    CallManager.instance.getCallConfig();
    AccountService.instance.queryMyInfo();
    callState = CallState.init;
    everConnected = false;
  }

  Future initCallStateChange() async {
    CallManager.instance.onCallStateChanged = (VeoCall call) {
      L.i('[VeoCall] onStateChange, before: $CallState, new: ${call.callStatus}, id: ${call.id}');
      /// 我的操作不处理
      callState = call.callStatus.value;
    };
  }

  Future setupCallEngineObserver() async {
    AVEngine.instance.onAddNewStream = (streamId, viewObject) {
      L.i('[VeoCall] newStream, streamId: $streamId, viewObject: ${viewObject?.core == null ? 'no view' : 'has view'}');
      videoAvailable.value = true;
      type == StreamType.video ? otherView.value = viewObject! : null;
      sizeType.value = VideoSizeType.remoteFull;
    };

    AVEngine.instance.onRemoveStream = (streamId) {
      if (otherView.value.streamID == streamId) {
        otherView.value = VideoView(false, '0');
      }
    };

    AVEngine.instance.onJoinChannel = (type, params) {
      switch (type) {
        case RoomEventType.onEnterRoom:
          onEnterRoomSuccess = true;
          connectState.value = (onEnterRoomSuccess && onRemoteUserEnterRoomSuccess) ? CallRoomConnectState.connected : CallRoomConnectState.connecting;
          if (connectState.value == CallRoomConnectState.connected) {
            startCountingTimer();
            stopCallRoomConnectTimer();
          }
          break;
        case RoomEventType.onRemoteUserEnterRoom:
          onRemoteUserEnterRoomSuccess = true;
          connectState.value = (onEnterRoomSuccess && onRemoteUserEnterRoomSuccess) ? CallRoomConnectState.connected : CallRoomConnectState.connecting;
          if (connectState.value == CallRoomConnectState.connected) {
            startCountingTimer();
            stopCallRoomConnectTimer();
          }
          break;
        case RoomEventType.onConnectionLost:
          startConnectionTimeoutTimer();
          break;
        case RoomEventType.onConnectionRecovery:
          stopConnectionTimeoutTimer();
          break;
        case RoomEventType.onRemoteUserLeaveRoom:
          endCall();
          break;
      }
    };
  }

  void startCallEngineConnect() async {
    everConnected = true;
    startCallRoomConnectTimer();
    if (!callEngineInited) {
      await setupCallEngine();
    }

    setupCallEngineObserver();

    String userId = curCall.myRtcUid.isEmpty ? '${MyAccount.userId}' : curCall.myRtcUid;
    await AVEngine.instance.joinRoom(curCall.roomId, userId, type);
    startPreview();
  }

  void startCountingTimer() {
    countingTimer?.cancel();
    countingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      duration++;
      if (!needCost) return;
      if (freeCallRemainTime.value > 0 && duration > freeCallRemainTime.value * 60) {
        freeCallRemainTime.value = 0;
      }
      bool canContinue = MyAccount.gems > perMinCost || freeCallRemainTime.value > 0;
      if (duration.value % 30 == 0 && canContinue) {
        checkIfNeedRecharge();
      }
    });
  }

  void startCallRoomConnectTimer() {
    CallRoomConnectTimer?.cancel();
    CallRoomConnectTimer = Timer(const Duration(seconds: 30), () {
      L.i('[VeoCall] enterRoomTimeout, end call');
      endCall();
    });
  }

  void stopCallRoomConnectTimer() {
    CallRoomConnectTimer?.cancel();
    CallRoomConnectTimer = null;
  }

  void startConnectionTimeoutTimer() {
    connectionTimeoutTimer?.cancel();
    connectionTimeoutTimer = Timer(const Duration(seconds: 30), () {
      L.i('[VeoCall] rt conntion Timeout, end call');
      endCall();
    });
  }

  void stopConnectionTimeoutTimer() {
    connectionTimeoutTimer?.cancel();
    connectionTimeoutTimer = null;
  }

  @override
  void onReady() {
    L.i('[VeoCall] onReady, otherUid: $otherUid, isCallOut: $isCallOut, callId: $callId');
    // !isCallOut && callId == 0 ? throw Exception('Should have callId while being called, check it again!') : null;

    initCallStateChange();

    EventCenter.instance.addListener(kEventCenterDidQueriedNewMessages, newMsgsCallback);
    EventCenter.instance.addListener(kEventCenterDidReceivedNewMessages, newMsgsCallback);

    if (curCall.costContent.isNotEmpty) {
      costDescTitle.value = curCall.costContent;
    } else {
      costDescTitle.value = '$costPerMin ${Copywriting.security_per_minute}';
    }

    if (isCallOut) {
      callOut();
    }

    if (autoAnswer) {
      Future.delayed(const Duration(milliseconds: 100), () {
        accept();
      });
    }

  }

  newMsgsCallback(notification) {
    dynamic obj = notification.data;
    List<ChatMessage>? msgs = obj['$otherUid'];
    if (msgs?.isNotEmpty ?? false) {
      addSomeListAnimatedItem(msgs!);
    }
  }

  void callOut() async {

    final rsp = await CallManager.instance.dial(
        type: type.index, userId: otherUid
    );

    Map? callInfo = rsp.data;
    if (callInfo[Security.security_callId] == 0 || (callInfo[Security.security_appId]?.isEmpty ?? true)) {
      Toast.show(rsp.description);
      Future.delayed(const Duration(milliseconds: 1000), () {
        close();
      });
      return;
    }

    if (callState != CallState.init) {
      L.i('[VeoCall] call is end...');
      CallManager.instance.cancel(callId: callInfo[Security.security_callId]);
      return;
    }

    int cost = callInfo[Security.security_costEveryMinute];
    GetStorage().write(isVideo ? kSKCallCostPerMin_Video : kSKCallCostPerMin_Audio, cost);
    cosType.value = callInfo[Security.security_currencyType];
    costPerMin.value = cost;
    freeCallRemainTime.value = callInfo[Security.security_remainFreeTime] ?? 0;
    curCall.id = callInfo[Security.security_callId];
    curCall.myRtcUid = callInfo[Security.security_rtcSelfUid]!;
    curCall.otherRtcUid = callInfo[Security.security_rtcTargetUid]!;
    curCall.roomId = callInfo[Security.security_roomId]!;
    curCall.rtcAppId = callInfo[Security.security_appId]!;
    curCall.rtcType = callInfo[Security.security_rtcType];
    curCall.rtcToken = callInfo[Security.security_token] ?? '';
    if (callInfo[Security.security_costOrEarnContent]?.isNotEmpty ?? false) {
      costDescTitle.value = callInfo[Security.security_costOrEarnContent].toString();
    }

    setupCallEngine();
  }

  void endCall() {
    RouteHelper.back();

    L.i('[VeoCall] end call, $CallState, callId: $callId');

    switch (callState) {
      case CallState.answered:
        CallManager.instance.hangup(callId: callId);
        callState = CallState.hangup;
        break;
      default:
        if (isCallOut) {
          if (callId > 0) CallManager.instance.cancel(callId: callId);
          callState = CallState.canceled;
        } else {
          CallManager.instance.refuse(callId: callId);
          callState = CallState.rejected;
        }
        break;
    }
  }

  void accept() async {
    L.i('[VeoCall] answer');
    final rsp = await CallManager.instance.answer(callId: callId);
    if (!rsp.isSuccess) {
      Toast.show(rsp.description);
      return;
    }

    Map callInfo = rsp.data;
    curCall.id = callInfo[Security.security_callId];
    curCall.myRtcUid = callInfo[Security.security_rtcSelfUid]!;
    curCall.otherRtcUid = callInfo[Security.security_rtcTargetUid]!;
    curCall.roomId = callInfo[Security.security_roomId]!;
    curCall.rtcAppId = callInfo[Security.security_appId]!;
    curCall.rtcType = callInfo[Security.security_rtcType];
    curCall.rtcToken = callInfo[Security.security_token] ?? '';

    callState = CallState.answered;
  }

  void onMuteTaped(bool isMuted) {
    L.i('[VeoCall] onMuted');
    AVEngine.instance.enableMic(!isMuted);
  }

  void onSpeakerTaped(bool isSpeaker) {
    L.i('[VeoCall] onSpeaker');
    AVEngine.instance.enableSpeaker(isSpeaker);
  }

  void onCameraTaped(bool isEnable) {
    L.i('[VeoCall] onCameraAction');
    AVEngine.instance.enableCamera(isEnable);
  }

  void onSwitchCamera(bool isFrontCamera) {
    L.i('[VeoCall] onSwitchCamera');
    AVEngine.instance.switchCameraDirection(isFrontCamera);
  }

  Future<void> startPreview() async {
    VideoView? viewObject = await AVEngine.instance.startPreview(streamId);
    isVideo && viewObject != null ? mineView.value = viewObject : null;
  }

  String curStatusDesc() {
    switch (callState) {
      case CallState.init:
        return isCallOut ? Security.security_calling : '${Copywriting.security_invites_you} to ${isVideo ? 'video' : Security.security_audio} call';
      case CallState.missing:
        return Copywriting.security_call_wasn__t_answered;
      case CallState.answered: {
        return Duration(seconds: duration.value).toString().split('.').first;
      }
      case CallState.canceled:
        return Copywriting.security_cancelled_by_Caller;
      case CallState.rejected:
        return Security.security_declined;
      case CallState.hangup:
        return Copywriting.security_ending___;
      default:
        return '';

    }
  }

  Future setupCallEngine() async {
    L.i('[VeoCall] setupCallEngine, appId: ${curCall.rtcAppId}, token: ${curCall.rtcToken}, rtcType: ${curCall.rtcType}');
    await AVEngine.instance.init(appId: curCall.rtcAppId, token: curCall.rtcToken);
    callEngineInited = true;
  }

  void checkIfNeedRecharge() async {
    await AccountService.instance.refreshBalance();

    int myGems = MyAccount.gems;
    /// 少于2分钟扣费弹窗充值
    if (myGems <= twoMinCost && rechargeAlertCount == 0) {
      rechargeAlertCount++;
      RouteHelper.toGems();
      Future.delayed(Duration(milliseconds: 200), () {
        Toast.show(Copywriting.security_not_enough_gems__please_recharge);
      });

    } else if (myGems <= perMinCost && rechargeAlertCount == 1) {
      rechargeAlertCount++;
      /// 少于1分钟扣费弹窗充值
      RouteHelper.toGems();
    }
  }

  void sendTextMsg(String text) {
    ChatTextMessage msg = ChatTextMessage.fromText(text, otherUid);
    sendMsg(msg);
  }

  Future<void> sendMsg(ChatMessage chatItem, {bool isResend = false}) async {

    chatItem.sendState.value = ChatMessageSendStatus.sending;
    if (!isResend) {
      addListAnimatedItem(chatItem);
    }

    SendMessageResponse? rsp = await ChatManager.instance.sendMessage(chatItem);
    if (!rsp.isSuccess) {
      chatItem.sendState.value = ChatMessageSendStatus.failed;
      return;
    }
    chatItem.sendState.value = ChatMessageSendStatus.sent;

    L.i('[Chat] sendPrivateMessage to video call user: $otherName,$otherUid, content: ${(chatItem as ChatTextMessage).text}');
  }

  void reloadMsg() {
    // update([kListRefreshId]);
  }

  void addListAnimatedItem(ChatMessage model) {
    if (!model.isText) {
      return;
    }
    messages.insert(0, model as ChatTextMessage);
    listViewKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));
  }

  void addSomeListAnimatedItem(List<ChatMessage> models) {
    if (models.isEmpty) {
      return;
    }
    List<ChatMessage> msgs = [];
    for (var msg in models) {
      if (!msg.isText && !msg.isGift) {
        continue;
      }
      msgs.add(msg);
    }
    messages.insertAll(0, msgs);
    listViewKey.currentState?.insertAllItems(0, models.length, duration: const Duration(milliseconds: 300), isAsync: true);
  }
}
