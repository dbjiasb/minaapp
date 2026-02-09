import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/business/chat/chat_room_cells/chat_cell.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:uuid/uuid.dart';

import '../../../core/account/account_service.dart';
import '../chat_voice_manager.dart';
import '../chat_voice_player.dart';

class ChatAudioMessage extends ChatMessage {
  var audioStatus = ChatTextAudioStatus.unlock.obs;

  ChatAudioMessage({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.date,
    required super.ownerId,
    required super.senderName,
    required super.senderAvatar,
    required super.type,
    required super.uuid,
    required super.info,
    required super.lockInfo,
    required super.nativeId,
    required super.sessionType,
  });

  // 构造器 自己发出去那种
  ChatAudioMessage.fromAudio(
    String url,
    int tarId,
    String desc,
    int duration, {
    super.specifyRepliers,
    super.bannedRepliers,
    super.session,
  }) : super(
         id: DateTime.now().microsecondsSinceEpoch,
         senderId: AccountService.instance.account.userId,
         receiverId: tarId,
         date: DateTime.now(),
         ownerId: AccountService.instance.account.userId,
         senderName: AccountService.instance.account.name,
         senderAvatar: AccountService.instance.account.avatar,
         type: ChatMessageType.voice,
         uuid: '',
         info: '',
         sessionType: session?.type ?? 0,
         lockInfo: {},
         nativeId: (const Uuid().v4()).replaceAll('-', ''),
       ) {
    sendState = ChatMessageSendStatus.sending.obs;
    if (isMine()) audioStatus.value = ChatTextAudioStatus.ready;
    info = jsonEncode({
      Security.security_url: url,
      Security.security_desc: desc,
      Security.security_length: duration,
    });
  }

  ChatAudioMessage.fromServer(Map map) : super.fromServerData(map) {}

  ChatAudioMessage.fromDatabase(Map<String, Object?> map)
    : super.fromLocalData(map) {
    if (isMine() &&
        ChatVoiceManager.instance.voicePathForUrl(audioUrl) == null) {
      ChatVoiceManager.instance.downloadSrc(audioUrl);
    }
  }

  @override
  Map<String, dynamic> toServer() {
    return {
      ...super.toServer(),
      Security.security_jsonBody: info,
      Security.security_id: id,
    };
  }

  @override
  Map<String, Object?> toDatabase() {
    return {...super.toDatabase()};
  }

  Map<String, dynamic>? _decodedMap;

  Map<String, dynamic> get decodedMap {
    _decodedMap ??= jsonDecode(info);
    return _decodedMap ?? {};
  }

  @override
  String get audioUrl => decodedMap[Security.security_url] ?? '';

  @override
  int get audioDuration => decodedMap[Security.security_length] ?? 0;

  String get audioDesc => decodedMap[Security.security_desc] ?? '';

  // bool get locked => lockInfo[Security.security_unlock] == 1;
  //
  // int get unlockPrice => lockInfo[Security.security_cost] ?? 0;
  //
  // int get unlockCurrency => lockInfo[Security.security_costType];
}

class ChatAudioCell extends ChatCell {
  ChatAudioCell(
    ChatAudioMessage super.message, {
    super.key,
    super.resend,
    super.onTap,
    super.unlock,
    super.reload,
    super.download,
  });

  ChatAudioMessage get audioMessage => super.message as ChatAudioMessage;

  bool get isMine => audioMessage.isMine();

  void play() async {
    //1.判断资源是否存在
    String? path = ChatVoiceManager.instance.voicePathForUrl(
      audioMessage.audioUrl,
    );

    if (path == null) {
      //下载
      await download?.call(message);
    }

    ChatVoicePlayer.instance.play(audioMessage);
  }

  Widget renderMainView() {
    return Row(
      textDirection: isMine ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: play,
            child: Container(
              height: 44,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isMine
                        ? Color(0xffFFF9B4).withValues(alpha: 0.9)
                        : Color(0xff272533).withValues(alpha: 0.9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: ChatAudioView(
                message: message,
                unlock: isMine ? null : unlock,
                download: download,
              ),
            ),
          ),
        ),
        if (isMine) Obx(() => buildSendStatusView()),
        SizedBox(width: 70),
      ],
    );
  }

  @override
  Widget buildView() {
    return Container(
      padding: EdgeInsets.only(bottom: 8),
      child: renderMainView(),
    );
  }

}

// 自己发送的
class ChatAudioView extends StatelessWidget {
  ChatMessage message;
  final Function(ChatMessage message)? unlock; // 如果是自己的，这里传入的unlock为null
  final Function(ChatMessage message)? download;

  bool get isMine => audioMessage.isMine();

  int get length => (audioMessage.audioDuration / 1000).ceil();

  String get desc => audioMessage.audioDesc;

  String get url => audioMessage.audioUrl;

  ChatAudioView({
    super.key,
    required this.message,
    required this.unlock,
    required this.download,
  });

  ChatAudioMessage get audioMessage => message as ChatAudioMessage;

  // static String kChatTTSPrompted = Security.security_kChatTTSPrompted;
  //
  // bool get prompted => Preferences.instance.getString(kChatTTSPrompted) != null;
  //
  // set prompted(bool value) {
  //   if (value) {
  //     Preferences.instance.setString(kChatTTSPrompted, '$kChatTTSPrompted:1');
  //   } else {
  //     Preferences.instance.remove(kChatTTSPrompted);
  //   }
  // }
  //
  // void showUnlockAlertIfNeeded() {
  //   // 会员解锁
  //   if (MyAccount.isWkPrem && MyAccount.freeAdoLeftTimes > 0 || MyAccount.isMthPrem || MyAccount.isYrPrem) {
  //     unlockMessage(1);
  //     return;
  //   }
  //
  //   // 普通解锁
  //   if (audioMessage.unlockPrice > 0 && !prompted) {
  //     showUnlockAlert();
  //   } else {
  //     unlockMessage(0);
  //   }
  // }
  //
  // void showUnlockAlert() {
  //   showConfirmAlert(
  //     Copywriting.security_unlock_Audio,
  //     'Unlocking will cost ${audioMessage.unlockPrice} ${audioMessage.unlockCurrency == 1 ? 'Gems' : 'Coins'}',
  //     onConfirm: () {
  //       //解锁资源
  //       unlockMessage(0);
  //       prompted = true;
  //     },
  //   );
  // }
  //
  // void unlockMessage(int usePrem) async {
  //   audioMessage.audioStatus.value = ChatTextAudioStatus.loading; //解锁中
  //   bool success = await unlock?.call(message);
  //   debugPrint('unlockMessage success: $success');
  //   if (!success) {
  //     audioMessage.audioStatus.value = ChatTextAudioStatus.unlock;
  //     return;
  //   }
  //   if (usePrem == 1) {
  //     Toast.show('Unlock use prem, used: ${MyAccount.freeAdoUsedTimes},total: ${MyAccount.freeAdoLeftTimes + MyAccount.freeAdoUsedTimes}');
  //   }
  // }

  // 播放

  final imagePaths = [
    // ImagePath.voice_play1,
    // ImagePath.voice_play2,
    // ImagePath.voice_play3,
    ImagePath.play_icon,
  ];
  final currentIndex = 2.obs;

  // final actionAnim = false.obs;
  Timer? _timer;

  void _stop() {
    // anim
    _timer?.cancel();
    // actionAnim.value = false;
    currentIndex.value = 2;
  }

  void _start() {
    // anim
    // actionAnim.value = true;
    _timer = Timer.periodic(Duration(milliseconds: 400), (timer) {
      currentIndex.value = (currentIndex.value + 1) % imagePaths.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    ever(ChatVoicePlayer.instance.playingMessage, (message) {
      if (message == audioMessage) {
        _start();
      } else {
        _stop();
      }
    });
    return Wrap(
      children: [
        Text(
          '$length"',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: AppFonts.medium,
          ),
        ),
        // Obx(() => Image.asset(imagePaths[currentIndex.value], height: 20, width: 20)),
        Image.asset(ImagePath.play_icon, height: 20, width: 20),
      ],
    );
  }
}
