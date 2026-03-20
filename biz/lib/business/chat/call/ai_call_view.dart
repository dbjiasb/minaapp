import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/formatters/date_formatter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../base/assets/image_view.dart';
import '../../../base/event_center/event_center.dart';
import '../../../core/util/cached_image.dart';
import '../../../core/util/log_util.dart';
import '../../../shared/toast/toast.dart';
import '../chat_session.dart';
import './call_manager.dart';
import 'av_engine.dart';
import 'call_info.dart';

enum AICallState { connecting, userSpeaking, aiThinking, aiSpeaking }

class CallInfo {
  CallInfo(this.data);
  Map<String, dynamic> data;

  int get callId => data[Constants.dialId] ?? 0;
  String get token => data[Security.security_token] ?? '';
  int get remainFreeTime => data[Constants.remaining] ?? 0;
  int get rtcType => data[Constants.dialType] ?? 0;
  String get appId => data[Security.security_appId] ?? '';
  String get rtcSelfUid => data[Constants.initiator] ?? '';
  String get rtcTargetUid => data[Constants.recipient] ?? '';
  String get roomId => data[Security.security_roomId] ?? '';
  int get ai => data[Security.security_ai] ?? 0;
  int get costEveryMinute => data[Constants.costPerMinute] ?? 15;
  int get currencyType => data[Constants.propType] ?? 0;
  double get earnEveryMinute => data[Constants.profitPerMinute] ?? 0;
}

class AICallView extends StatelessWidget {
  AICallView({super.key});

  AICallViewController viewController = Get.put(AICallViewController());

  String get statusText {
    if (viewController.muted.value) return Copywriting.security_you_have_muted;
    AICallState status = viewController.callState.value;
    if (status == AICallState.connecting) return Copywriting.security_connecting___;
    if (status == AICallState.aiThinking) return Copywriting.security_i_am_thinking___;
    if (status == AICallState.aiSpeaking) return Copywriting.security_interrupt_AI;
    if (status == AICallState.userSpeaking) return Copywriting.security_i_am_listening___;
    return Security.security_nothing;
  }

  Widget callStateView() {
    switch (viewController.callState.value) {
      case AICallState.connecting:
        return Column(
          children: [
            SizedBox(height: 184),
            Text(Copywriting.security_connecting___, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        );
      case AICallState.aiThinking:
        return Column(
          children: [
            SizedBox(height: 184),
            Text(Copywriting.security_i_am_thinking___, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        );
      case AICallState.aiSpeaking:
        return Column(
          children: [
            ImageView(Images.security_triangle_arrow_png, width: 24, height: 12),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 43),
              child: Container(
                height: 96,
                width: double.infinity,
                decoration: BoxDecoration(
                  //左上角和右上角圆角12
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x40000000), Color(0x00000000)]),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(8),
                  child: Text(viewController.speechContent.value, style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, fontWeight: FontWeight.normal)),
                ),
              ),
            ),
            SizedBox(height: 40),
            GestureDetector(onTap: viewController.interruptAI, child: ImageView(Images.security_interrupt_task_png, width: 32, height: 32)),
            SizedBox(height: 4),
            Text(Copywriting.security_interrupt_AI, style: TextStyle(fontSize: 14, color: Color(0xFFABABAD), fontWeight: FontWeight.w500)),
          ],
        );
      case AICallState.userSpeaking:
        return Column(
          children: [
            SizedBox(height: 144),
            SizedBox(height: 16),
            Text(Copywriting.security_i_am_listening___, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        );
    }
  }

  Widget _buildBackgroundView() {
    if (viewController.session.backgroundUrl.value.isNotEmpty) {
      return CachedImage(imageUrl: viewController.session.backgroundUrl.value, fit: BoxFit.cover);
    } else {
      return SizedBox.shrink();
    }
  }

  Widget buildCostWidget(bool hidden) {
    return Container(
      margin: EdgeInsets.only(right: hidden ? 16 : 0, left: hidden ? 0 : 16),
      child: Obx(
        () => RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hidden ? Colors.transparent : Colors.white),
            children: [
              TextSpan(text: '${viewController.callInfo.value?.costEveryMinute ?? 15} '),
              WidgetSpan(
                child: ImageView(viewController.callInfo.value?.currencyType == 1 ? Images.security_gem_png : Images.security_coin_png, height: 16, width: 16),
                alignment: PlaceholderAlignment.middle, // 图片对齐方式
              ),
              TextSpan(text: Copywriting.security_per_minute),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0B12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 使用 BackdropFilter 为 CachedImage 添加高斯模糊效果
          // 先放置原始的背景图
          Obx(() => _buildBackgroundView()),
          // 再放置带有模糊效果的层
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0), // 调整模糊程度
            child: Container(
              color: Colors.transparent, // 确保容器透明
            ),
          ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(Copywriting.security_consuming_props_during_call, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      buildCostWidget(false),
                      SizedBox(height: 66),

                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image: NetworkImage(viewController.session.avatar), fit: BoxFit.cover),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(viewController.session.name, style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Obx(() => callStateView()),
                  Column(
                    // mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          Text(Copywriting.security_call_Duration, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          Obx(
                            () => Text(
                              DateFormatter.formatSeconds(viewController.duration.value),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(onTap: viewController.onCallCancel, child: ImageView(Images.security_hang_up_png, width: 64, height: 64)),
                          SizedBox(width: 60),
                          GestureDetector(
                            onTap: () {
                              viewController.mute(!viewController.muted.value);
                            },
                            child: Obx(
                              () =>
                                  !viewController.muted.value
                                      ? ImageView(Images.security_open_mic_png, width: 64, height: 64)
                                      : Container(
                                        height: 64,
                                        width: 64,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xff000000).withValues(alpha: 0.2)),
                                        child: Icon(Icons.mic_off_rounded, size: 32),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AICallViewController extends GetxController {
  final ChatSession session = ChatSession.fromRouter(Get.arguments[Security.security_session]);
  Rx<CallInfo?> callInfo = Rx<CallInfo?>(null);
  bool isEnd = false;
  bool isEngineCreated = false;
  Timer? timer;

  var duration = 0.obs;
  var callState = AICallState.connecting.obs;
  var muted = false.obs;
  var speechContent = ''.obs;

  int get accountId => AccountService.instance.account.userId;

  String get streamId => '${callInfo.value?.callId ?? ''}-$accountId';

  @override
  void onInit() {
    super.onInit();
    WakelockPlus.enable();
  }

  @override
  void onReady() {
    super.onReady();
    dial();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  void mute(bool mute) {
    muted.value = mute;
    enableMic(!mute);
  }

  void onCallCancel() {
    disconnect();
  }

  void dial() async {
    ApiResponse response = await CallManager.instance.dial(userId: int.parse(session.id));

    int callId = response.data[Constants.dialId] ?? 0;
    String appId = response.data[Security.security_appId] ?? '';

    if (!response.isSuccess || callId == 0 || appId.isEmpty) {
      close();
      Toast.error(response.description);
      return;
    }

    if (isClosed) {
      CallManager.instance.cancel(callId: callId);
      return;
    }

    callInfo.value = CallInfo(response.data as Map<String, dynamic>);

    //创建引擎
    await createEngine();
    //开始连接
    connect();
  }

  void close() async {
    WakelockPlus.disable();
    stopTimer();
    CallManager.instance.clearCallInfo();

    if (isEngineCreated) {
      await AVEngine.instance.stopPlayingStream(streamId);
      await AVEngine.instance.exitRoom();
      await AVEngine.instance.destroy();
      isEngineCreated = false;
    }

    if (isClosed || isEnd) return;
    isEnd = true;
    EventCenter.instance.sendEvent(kEventCenterRefreshCurrency, {});
    Get.back();
  }

  //创建引擎
  Future<void> createEngine() async {
    if (isEngineCreated) return;
    //初始化
    await AVEngine.instance.init(appId: callInfo.value!.appId, token: callInfo.value!.token);
    AVEngine.instance.onReceiveCustomEvent = (data) {
      onReceiveCustomEvent(data);
    };
    AVEngine.instance.onPermissionDenied = () {
      disconnect();
    };
    isEngineCreated = true;
  }

  onReceiveCustomEvent(Map data) {
    if (data[Constants.commandId] == 1) {
      String json = data[Security.security_message];
      try {
        handleCustomEvent(jsonDecode(json));
      } catch (e) {
        L.i('onReceiveCustomEvent error: $e');
      }
    }
  }

  void handleCustomEvent(Map event) {
    int eventId = event[Security.security_type] ?? 0;
    switch (eventId) {
      case 10003:
        {
          callState.value = AICallState.userSpeaking;
          startTimer();
          break;
        }
      case 10000: //字幕
        {
          String sender = event[Security.security_sender];
          String text = event[Constants.carrier]?[Security.security_text] ?? '';
          bool isEnd = event[Constants.carrier]?[Security.security_end] ?? false;
          // String round = event[Constants.carrier]?['roundid'] ?? '';
          // int? startMs = event[Constants.carrier]?['start_time_ms'] ?? -1;
          // String target = '';

          if (sender == accountId.toString()) {
            if (isEnd) {
              //结束
              callState.value = AICallState.aiThinking;
            } else {
              //拉取消息
            }
          } else {
            speechContent.value = text;
          }

          break;
        }

      case 10001:
        {
          int? state = event[Constants.carrier][Security.security_state] ?? 0;
          // int? timestamp = event[Constants.carrier][Security.security_timestamp] ?? 0;
          switch (state) {
            case 1: // 聆听中
              /// 在短时间内拨打下一个电话的时候没有回调ready导致没有计时，这里判断一下开启计时
              if (callState.value == AICallState.connecting) startTimer();
              callState.value = AICallState.userSpeaking;
              break;
            case 2: // 思考中
              callState.value = AICallState.aiThinking;
              break;
            case 3: // 说话中
              callState.value = AICallState.aiSpeaking;

              break;
            case 4: // 被打断
              callState.value = AICallState.userSpeaking;
              break;
            default:
              break;
          }
          break;
        }

      default:
        break;
    }
  }

  void connect() async {
    //开始连接
    // await createEngine();

    addJoinRoomListener();
    String userId = callInfo.value?.rtcSelfUid ?? '';
    await AVEngine.instance.joinRoom(callInfo.value?.roomId ?? '', userId, StreamType.audio);
    onSpeakerAction(true);
    startPreview();
  }

  disconnect() async {
    if (callInfo.value?.callId == null || callInfo.value?.callId == 0) {
      close();
      return;
    }

    if (callState.value == AICallState.connecting) {
      CallManager.instance.cancel(callId: callInfo.value!.callId);
      close();
      return;
    } else {
      CallManager.instance.hangup(callId: callInfo.value!.callId);
    }

    close();
  }

  Future<void> addJoinRoomListener() async {
    AVEngine.instance.onJoinChannel = (type, params) {
      L.i('onJoinChannel: $type, $params');
    };
  }

  void onSpeakerAction(bool isSpeaker) {
    AVEngine.instance.enableSpeaker(isSpeaker);
  }

  Future<void> startPreview() async {
    await AVEngine.instance.startPreview(streamId);
  }

  void interruptAI() async {
    AVEngine.instance.interruptAI(int.parse(callInfo.value?.rtcTargetUid ?? '0'));
  }

  void enableMic(bool enable) {
    AVEngine.instance.enableMic(enable);
  }

  //#Timer
  void startTimer() {
    L.i(Security.security_startTimer);
    if (timer != null) return;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      onTimeout(timer);
    });
  }

  void onTimeout(Timer timer) {
    L.i(Security.security_onTimeout);
    duration.value++;
  }

  void stopTimer() {
    L.i(Security.security_stopTimer);
    if (timer != null) {
      timer?.cancel();
      timer = null;
    }
  }
}
