import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:biz/base/crypt/security.dart';
import 'dart:convert';

import 'package:biz/base/crypt/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_trtc_cloud/trtc_cloud.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_def.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_listener.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_video_view.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../core/util/log_util.dart';
import '../../../shared/toast/toast.dart';

enum RoomEventType { onEnterRoom, onRemoteUserEnterRoom, onConnectionLost, onConnectionRecovery, onRemoteUserLeaveRoom }

enum StreamType { video, audio }

class VideoView {
  final bool isLocal;
  final String streamID;

  late int viewID;
  Widget? core;

  VideoView(this.isLocal, this.streamID);
}

class AVEngine {
  //生成单利
  AVEngine._internal();

  static final AVEngine _instance = AVEngine._internal();

  factory AVEngine() => _instance;

  static AVEngine get instance => _instance;

  late TRTCCloud? cloud;
  late int appId;
  late String token;
  late String _userId;
  StreamType _streamType = StreamType.audio;

  bool get _isAudioCall => _streamType == StreamType.audio;

  Function(String streamId, VideoView? view)? onAddNewStream;
  Function(String streamId)? onRemoveStream;

  bool get _isVideoCall => _streamType == StreamType.video;

  Function(Map msg)? onReceiveCustomEvent;
  Function(RoomEventType type, dynamic data)? onJoinChannel;
  Function()? onPermissionDenied;

  /// 第一步 初始化引擎
  Future<void> init({required String appId, required String token}) async {
    L.i('[CallEngine] AVEngine init, id: $appId, token: $token');
    cloud = await TRTCCloud.sharedInstance();
    this.appId = int.parse(appId);
    this.token = token;

    registerListener();
  }

  void enableCamera(bool enable) {
    L.i('[CallEngine] enableCamera: $enable');
    cloud?.muteLocalVideo(!enable);
  }

  /// 本地音频设置
  void enableMic(bool enable) {
    L.i('[CallEngine] enableMic: $enable');
    if (enable) {
      cloud?.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_SPEECH);
    } else {
      cloud?.stopLocalAudio();
    }
  }

  /// 第二步 设置监听
  void registerListener() {
    cloud?.registerListener(handleCloudEvent);
  }

  void handleCloudEvent(type, params) async {
    L.i('[CallEngine] handleCloudEvent: $type, $params');
    switch (type) {
      case TRTCCloudListener.onEnterRoom:
        int result = params;
        if (result > 0) {
          onJoinChannel?.call(RoomEventType.onEnterRoom, params);
        }
        break;

    /// 用户加入房间事件
      case TRTCCloudListener.onUserVideoAvailable:
        if (params[Security.security_available]) {
          addRemoteViewStreamID(params[Security.security_userId]);
        } else {
          deleteRemoteViewStreamID(params[Security.security_userId]);
        }
        break;

      case TRTCCloudListener.onError:
        break;
      case TRTCCloudListener.onWarning:
        break;
      case TRTCCloudListener.onSwitchRole:
        break;
      case TRTCCloudListener.onRemoteUserEnterRoom:
        onJoinChannel?.call(RoomEventType.onRemoteUserEnterRoom, params);
        break;
      case TRTCCloudListener.onRemoteUserLeaveRoom:
        onJoinChannel?.call(RoomEventType.onRemoteUserLeaveRoom, params);
        break;
      case TRTCCloudListener.onConnectOtherRoom:
        break;
      case TRTCCloudListener.onDisConnectOtherRoom:
        break;
      case TRTCCloudListener.onUserSubStreamAvailable:
        break;
      case TRTCCloudListener.onUserAudioAvailable:
        break;
      case TRTCCloudListener.onFirstVideoFrame:
        break;
      case TRTCCloudListener.onFirstAudioFrame:
        break;
      case TRTCCloudListener.onNetworkQuality:
        break;
      case TRTCCloudListener.onStatistics:
        break;
      case TRTCCloudListener.onConnectionLost:
        onJoinChannel?.call(RoomEventType.onConnectionLost, params);
        break;
      case TRTCCloudListener.onTryToReconnect:
        break;
      case TRTCCloudListener.onConnectionRecovery:
        onJoinChannel?.call(RoomEventType.onConnectionRecovery, params);
        break;
      case TRTCCloudListener.onCameraDidReady:
        break;
      case TRTCCloudListener.onMicDidReady:
        break;
      case TRTCCloudListener.onDeviceChange:
        break;
      case TRTCCloudListener.onTestMicVolume:
        break;
      case TRTCCloudListener.onTestSpeakerVolume:
        break;
      case TRTCCloudListener.onStartPublishMediaStream:
        break;
      case TRTCCloudListener.onRecvCustomCmdMsg:
        onReceiveCustomEvent?.call(params);
        break;
      default:
        break;
    }
  }

  Future addRemoteViewStreamID(String streamID) async {
    L.i('[CallEngine] addRemoteViewStreamID: $streamID');
    VideoView? view;
    if (_isVideoCall) {
      view = await getVideoView(false, streamID, (viewID) {
        startPlayingStream(streamID, view!.viewID);
      });
    }

    await onAddNewStream?.call(streamID, view);
  }

  void deleteRemoteViewStreamID(String streamID) async {
    L.i('[CallEngine] deleteRemoteViewStreamID: $streamID');
    stopPlayingStream(streamID);

    onRemoveStream?.call(streamID);
  }

  void clearEventCallback() {
    L.i('[CallEngine] clearEventCallback');
    cloud?.unRegisterListener(handleCloudEvent);
  }

  Future<void> destroy() async {
    L.i('[CallEngine] destroy');
    clearEventCallback();
    await TRTCCloud.destroySharedInstance();
  }

  /// 第三步 加入房间
  Future<void> joinRoom(String roomId, String userId, StreamType streamType) async {
    L.i("[CallEngine] joinRoom, roomId: $roomId, userId: $userId, type: $streamType");
    _userId = userId;
    _streamType = streamType; // 分语音和视频

    TRTCParams params = TRTCParams();
    params.sdkAppId = appId;
    params.strRoomId = roomId;
    params.userId = _userId;
    params.userSig = token;
    cloud?.enterRoom(params, _isAudioCall ? TRTCCloudDef.TRTC_APP_SCENE_AUDIOCALL : TRTCCloudDef.TRTC_APP_SCENE_VIDEOCALL);

    if (_isVideoCall) {
      TRTCVideoEncParam encParams = TRTCVideoEncParam();
      encParams.videoResolution = TRTCCloudDef.TRTC_VIDEO_RESOLUTION_960_540;
      encParams.videoFps = 15;
      encParams.videoBitrate = 1200;
      encParams.videoResolutionMode = TRTCCloudDef.TRTC_VIDEO_RESOLUTION_MODE_PORTRAIT;
      cloud?.setVideoEncoderParam(encParams);
    }

    enableCamera(streamType == StreamType.video);

    cloud?.getDeviceManager().setSystemVolumeType(TRTCCloudDef.TRTCSystemVolumeTypeMedia);
  }

  void enableSpeaker(bool isEnable) {
    L.i("[CallEngine] enableSpeaker: $isEnable");
    int type = isEnable ? TRTCCloudDef.TRTC_AUDIO_ROUTE_SPEAKER : TRTCCloudDef.TRTC_AUDIO_ROUTE_EARPIECE;
    cloud?.getDeviceManager().setAudioRoute(type);
  }

  Future<VideoView?> startPreview(String streamID) async {
    L.i("[CallEngine] startPreview: $streamID");
    await Permission.microphone.request();
    PermissionStatus audioStatus = await Permission.microphone.status;
    if (!audioStatus.isGranted) {
      L.i("[CallEngine] microphone permission denied");
      //用英语提示用户去申请麦克风权限
      onPermissionDenied?.call();
      Toast.show(Copywriting.security_please_grant_microphone_permission);
      return null;
    }

    if (_isVideoCall) {
      await [Permission.camera].request();
      PermissionStatus cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        L.i("[CallEngine] camera permission denied");
        onPermissionDenied?.call();
        Toast.show(Copywriting.security_please_grant_camera_permission);
        return null;
      }
      await cloud?.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_SPEECH);
      VideoView view = await getVideoView(true, streamID, (viewID) {
        cloud?.startLocalPreview(true, viewID);
      });
      return view;
    }

    await cloud?.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_SPEECH);
    return null;
  }

  Future<void> stopPlayingStream(String streamID) async {
    await cloud?.stopRemoteView(streamID, TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG);
  }

  Future<void> startPlayingStream(String streamID, int viewID) async {
    await cloud?.startRemoteView(streamID, TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG, viewID);
  }

  Future<VideoView> getVideoView(bool local, String streamID, Function(int viewID) done) async {
    VideoView view = VideoView(local, streamID);
    view.core = TRTCCloudVideoView(
      key: UniqueKey(),
      viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
      onViewCreated: (viewID) async {
        view.viewID = viewID;
        done(viewID);
      },
    );

    return view;
  }

  void switchCameraDirection(bool front) {
    debugPrint("[CallEngine] switchCamera, front: $front");
    cloud?.getDeviceManager().switchCamera(front);
  }

  Future<void> exitRoom() async {
    debugPrint("[CallEngine] exitRoom");
    await cloud?.stopLocalAudio();
    await cloud?.stopLocalPreview();

    await cloud?.exitRoom();

    await TRTCCloud.destroySharedInstance();
  }

  static int breakNum = 0;

  void interruptAI(int receiverId) {
    debugPrint("[CallEngine] interruptAI, $receiverId");
    Map data = {
      Security.security_type: 20001,
      Security.security_sender: _userId,
      Security.security_receiver: ['$receiverId'],
      Constants.carrier: {
        Security.security_id: '$_userId-$receiverId-${breakNum++}',
        Security.security_timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
    };
    try {
      String encodedData = jsonEncode(data);
      cloud?.sendCustomCmdMsg(2, encodedData, false, false);
    } catch (e) {}
  }
}