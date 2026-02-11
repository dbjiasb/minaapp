import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/business/chat/chat_voice_manager.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/alert.dart';
import 'package:uuid/uuid.dart';

import '../../../base/router/route_helper.dart';
import '../../../core/util/cached_image.dart';
import '../../../core/util/log_util.dart';
import '../chat_session.dart';
import '../chat_voice_player.dart';
import './chat_message.dart';
import 'chat_cell.dart';

//### TextMessage
class ChatTextMessage extends ChatMessage {
  String text = '';
  var audioStatus = ChatTextAudioStatus.unlock.obs;

  RxString translationText = ''.obs;

  ChatTextMessage({
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

  @override
  Map<String, dynamic> toServer() {
    return {...super.toServer(), Security.security_content: text};
  }

  @override
  Map<String, Object?> toDatabase() {
    return {...super.toDatabase(), Security.security_content: text};
  }

  // 修复后的 fromDatabase 构造函数
  ChatTextMessage.fromDatabase(Map<String, Object?> map) : super.fromLocalData(map) {
    text = (map[Security.security_content] as String?) ?? '';
    sessionId = (map[Security.security_sessionId] as String?) ?? '';
    sendState = ChatMessageSendStatus.fromDigit(map[Security.security_sendState] as int? ?? 0).obs;
    bool locked = lockInfo[Security.security_unlock] == 1;
    audioStatus = ChatTextAudioStatus.fromDigit(locked ? ChatTextAudioStatus.ready.digit : 0).obs;
  }

  ChatTextMessage.fromServer(Map map) : super.fromServerData(map) {
    text = map[Security.security_content] ?? '';
    int sessionType = map[Security.security_sessionType] ?? 0;
    sessionId = sessionType == 0 ? (senderId == ownerId ? receiverId : senderId).toString() : (map[Security.security_sessionId] ?? '');
    sendState = ChatMessageSendStatus.fromDigit(0).obs;
    bool locked = map[Security.security_unlock]?[Security.security_unlock] == 1;
    audioStatus = ChatTextAudioStatus.fromDigit(locked ? ChatTextAudioStatus.ready.digit : 0).obs;
  }

  // 改为构造函数
  ChatTextMessage.fromText(this.text, int receiverId, {super.specifyRepliers, super.bannedRepliers, super.session})
    : super(
        id: DateTime.now().microsecondsSinceEpoch,
        senderId: AccountService.instance.account.userId,
        receiverId: receiverId,
        date: DateTime.now(),
        ownerId: AccountService.instance.account.userId,
        senderName: AccountService.instance.account.name,
        senderAvatar: AccountService.instance.account.avatar,
        type: ChatMessageType.text,
        uuid: '',
        info: '',
        sessionType: session?.type ?? 0,
        lockInfo: {},
        nativeId: (const Uuid().v4()).replaceAll('-', ''),
      ) {
    sendState = ChatMessageSendStatus.sending.obs;
    sessionId = sessionType == 0 ? (senderId == ownerId ? receiverId : senderId).toString() : session?.sessionId ?? '';
  }

  @override
  String get externalText => text;

  Map<String, dynamic>? _decodedInfo;

  Map<String, dynamic> get decodedInfo {
    try {
      _decodedInfo ??= JsonDecoder().convert(info);
    } catch (e) {
      L.e('ChatTextMessage.fromText decodedInfo error: $e');
    }
    return _decodedInfo ?? {};
  }

  int get unlockPrice => lockInfo[Security.security_cost];

  int get unlockCurrency => lockInfo[Security.security_costType];

  bool get isOfficial => senderId == kOffChatSessionId;

  bool get isGroupChat => sessionType == 2;

  @override
  set info(String value) {
    super.info = value;
    _decodedInfo = null;
  }

  @override
  int get audioDuration => decodedInfo[Security.security_ttsDuration] ?? 0;

  @override
  String get audioUrl => decodedInfo[Security.security_ttsUrl] ?? '';

  Map<String, dynamic> sortSplitter() {
    final splitter = decodedInfo[Security.security_splitter];
    if (splitter is! Map<String, dynamic>) {
      return {};
    }
    final entries = splitter.entries.toList();
    if (_isNumericKeys(entries)) {
      entries.sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    } else {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }

    return Map.fromEntries(entries);
  }

  bool _isNumericKeys(List<MapEntry<String, dynamic>> entries) {
    if (entries.isEmpty) return false;
    try {
      for (final entry in entries) {
        int.parse(entry.key);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ChatTextCell extends ChatCell {
  ChatTextCell(ChatTextMessage super.message, {super.key, super.resend, super.onTap, super.unlock, super.reload, super.download, super.onContinue});

  ChatTextMessage get textMessage => super.message as ChatTextMessage;

  bool get isMine => textMessage.isMine();

  Widget renderMainView() {
    return Row(
      textDirection: isMine ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () {
              onTap?.call(message);
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine ? Color(0xFFFFF9B4).withValues(alpha: 0.9) : Color(0xFF272533).withValues(alpha: 0.9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Obx(() {
                return Column(
                  children: [
                    buildText(),
                    if (textMessage.translationText.isNotEmpty) Divider(height: 26, thickness: 2.0, color: Color(0x0DFFFFFF)),
                    if (textMessage.translationText.isNotEmpty)
                      Text(
                        textMessage.translationText.value,
                        style: TextStyle(color: isMine ? Color(0xFF3D3734) : Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
        if (isMine) Obx(() => buildSendStatusView()),
        Obx(() {
          return SizedBox(width: message.showContinue.value ? 32 : 64);
        }),
      ],
    );
  }

  Widget buildText() {
    String text = textMessage.text;
    // if (textMessage.isOfficial) {
    //   return Linkify(
    //     onOpen: (link) async {
    //       if (link.url.startsWith(Security.security_http)) RH.handleRoute(link.url);
    //     },
    //     text: text,
    //     style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
    //     linkStyle: const TextStyle(color: Colors.blue, fontSize: 14, height: 1.5, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
    //   );
    // }

    Map sortSplitter = textMessage.sortSplitter();
    Widget textWidget() => Text(
      text,
      style: TextStyle(
        color: isMine ? Color(0xFF3D3734) : (textMessage.isText ? Colors.white : Colors.white.withValues(alpha: 0.6)),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontStyle: textMessage.isText ? FontStyle.normal : FontStyle.italic,
      ),
    );

    if (!textMessage.isGroupChat || isMine) {
      return textWidget();
    }

    try {
      List<TextSpan> splitContent = [];
      int start = 0;
      int runLength = text.runes.length;
      sortSplitter.forEach((key, value) {
        int keyInt = int.parse(key);
        int sta = start > runLength ? runLength : start;
        var charCodes = text.runes.skip(sta).take(keyInt > runLength ? runLength : keyInt - sta);
        splitContent.add(
          TextSpan(
            text: String.fromCharCodes(charCodes),
            style: TextStyle(
              color: value == 1 ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.4,
              fontStyle: value == 1 ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        );
        start = keyInt;
      });
      return Text.rich(TextSpan(children: splitContent));
    } catch (e) {
      return textWidget();
    }
  }

  @override
  Widget buildView() {
    return Stack(
      children: [
        Obx(() => Container(padding: EdgeInsets.only(bottom: 8, top: textMessage.focused.value ? 16 : 0), child: renderMainView())),
        Obx(
          () => textMessage.focused.value ? Positioned(child: ChatTextAudioView(message: textMessage, unlock: unlock, download: download)) : SizedBox.shrink(),
        ),
      ],
    );
  }
}

class ChatTheaterTextCell extends ChatCell {
  ChatTheaterTextCell(ChatTextMessage super.message, {super.key, super.resend, super.onTap, super.unlock, super.reload, super.download, super.onContinue});

  ChatTextMessage get textMessage => super.message as ChatTextMessage;

  bool get isMine => textMessage.isMine();

  Widget buildText() {
    String text = textMessage.text;

    Map sortSplitter = textMessage.sortSplitter();
    Widget textWidget() => Text(
      text,
      style: TextStyle(
        color: Color(0xFF0F0F0F),
        // color: isMine ? Color(0xFF3D3734) : (textMessage.isText ? Colors.white : Colors.white.withValues(alpha: 0.6)),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontStyle: textMessage.isText ? FontStyle.normal : FontStyle.italic,
      ),
    );

    if (!textMessage.isGroupChat || isMine) {
      return textWidget();
    }

    try {
      List<TextSpan> splitContent = [];
      int start = 0;
      int runLength = text.runes.length;
      sortSplitter.forEach((key, value) {
        int keyInt = int.parse(key);
        int sta = start > runLength ? runLength : start;
        var charCodes = text.runes.skip(sta).take(keyInt > runLength ? runLength : keyInt - sta);
        splitContent.add(
          TextSpan(
            text: String.fromCharCodes(charCodes),
            style: TextStyle(
              color: value == 1 ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.4,
              fontStyle: value == 1 ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        );
        start = keyInt;
      });
      return Text.rich(TextSpan(children: splitContent));
    } catch (e) {
      return textWidget();
    }
  }

  Widget renderAiInfoView() {
    String name = textMessage.senderName;
    String url = textMessage.senderAvatar;
    return Stack(
      children: [
        IntrinsicWidth(
          child: Container(
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(left: 18, top: 6),
            padding: EdgeInsets.only(right: 12, left: 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Color(0xFF823AF9), Color(0xFFB63AFF)])),
            height: 24,
            child: Text(name, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(image: CachedImageProvider(url), fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget renderMineInfoView() {
    String name = textMessage.senderName;
    String url = textMessage.senderAvatar;
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        IntrinsicWidth(
          child: Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(right: 18, top: 6),
            padding: EdgeInsets.only(left: 12, right: 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Color(0xFFFF703A), Color(0xFFF93A98)])),
            height: 24,
            child: Text(name, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),

        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(image: CachedImageProvider(url), fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget renderMainView() {
    return Flexible(
      child: GestureDetector(
        onTap: () {
          onTap?.call(message);
        },
        child: Stack(
          alignment: textMessage.isMine() ? Alignment.topRight : Alignment.topLeft,
          children: [
            Container(
              alignment: isMine ? null :Alignment.centerLeft,
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine ? Color(0xFFFFF9B4).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Obx(() {
                return Column(
                  children: [
                    buildText(),
                    if (textMessage.translationText.isNotEmpty) Divider(height: 26, thickness: 2.0, color: Color(0x0DFFFFFF)),
                    if (textMessage.translationText.isNotEmpty)
                      Text(
                        textMessage.translationText.value,
                        style: TextStyle(color: isMine ? Color(0xFF3D3734) : Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                  ],
                );
              }),
            ),
            textMessage.isMine() ? renderMineInfoView() : renderAiInfoView(),

            !textMessage.isMine()
                ? Positioned(
                  right: 0,
                  child: Transform.translate(offset: Offset(0, 10), child: ChatTextAudioView(message: textMessage, unlock: unlock, download: download)),
                )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildView() {
    return Stack(
      children: [
        Obx(
          () => Container(
            padding: EdgeInsets.only(bottom: 8, top: textMessage.focused.value ? 16 : 0),
            child: Row(
              textDirection: isMine ? TextDirection.rtl : TextDirection.ltr,
              children: [renderMainView(), if (isMine) Obx(() => buildSendStatusView()), SizedBox(width: 70)],
            ),
          ),
        ),
      ],
    );
  }
}

class ChatTextAudioView extends StatelessWidget {
  ChatMessage message;
  final Function(ChatMessage message)? unlock;
  final Function(ChatMessage message)? download;

  ChatTextAudioView({super.key, required this.message, required this.unlock, required this.download});

  ChatTextMessage get textMessage => message as ChatTextMessage;

  Widget buildAudioStatusIcon() {
    ChatTextAudioStatus status = textMessage.audioStatus.value;
    switch (status) {
      case ChatTextAudioStatus.unlock:
        return Image.asset(ImagePath.play_icon, width: 16, height: 16);
      case ChatTextAudioStatus.loading:
        return Container(
          padding: EdgeInsets.all(2),
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        );
      case ChatTextAudioStatus.ready:
        return Image.asset(ImagePath.play_icon, width: 16, height: 16);
      case ChatTextAudioStatus.playing:
        return Image.asset(ImagePath.play_icon, width: 16, height: 16);
      case ChatTextAudioStatus.pause:
        return Image.asset(ImagePath.play_icon, width: 16, height: 16);
    }
  }

  static String kChatTTSPrompted = Security.security_kHasTTSPrompted;

  bool get prompted => Preferences.instance.getString(kChatTTSPrompted) != null;

  set prompted(bool value) {
    if (value) {
      Preferences.instance.setString(kChatTTSPrompted, '$kChatTTSPrompted:1');
    } else {
      Preferences.instance.remove(kChatTTSPrompted);
    }
  }

  void showUnlockAlertIfNeeded() {
    // // 会员解锁
    // if (MyAccount.isWkPrem && MyAccount.freeAdoLeftTimes > 0 || MyAccount.isMthPrem || MyAccount.isYrPrem) {
    //   unlockMessage(1);
    //   return;
    // }

    // 普通解锁
    // if (textMessage.unlockPrice > 0 && !prompted) {
    //   showUnlockAlert();
    // } else {
      unlockMessage(0);
    // }
  }

  void showUnlockAlert() {
    showConfirmAlert(
      Copywriting.security_unlock_Audio,
      'Unlocking will cost ${textMessage.unlockPrice} ${textMessage.unlockCurrency == 1 ? 'Gems' : 'Coins'}',
      onConfirm: () {
        //解锁资源
        unlockMessage(0);
        prompted = true;
      },
    );
  }

  void unlockMessage(int usePrem) async {
    textMessage.audioStatus.value = ChatTextAudioStatus.loading; //解锁中
    bool success = await unlock?.call(message);
    L.i('unlockMessage success: $success');
    if (!success) {
      textMessage.audioStatus.value = ChatTextAudioStatus.unlock;
      return;
    }
    // if (usePrem == 1) {
    //   if (MyAccount.isWkPrem) {
    //     Toast.show('Premium Benefits for Audio, used: ${MyAccount.freeAdoUsedTimes},total: ${MyAccount.freeAdoLeftTimes + MyAccount.freeAdoUsedTimes}');
    //   } else {
    //     Toast.show(Copywriting.security_premium_Benefits_for_Audio__unlimited);
    //   }
    // }
  }

  void play() async {
    //1.判断资源是否存在
    String? path = ChatVoiceManager.instance.voicePathForUrl(textMessage.audioUrl);

    if (path == null) {
      //下载
      await download?.call(message);
    }

    ChatVoicePlayer.instance.play(textMessage);
  }

  void continuePlay() {
    textMessage.audioStatus.value = ChatTextAudioStatus.playing;
  }

  void pause() {
    textMessage.audioStatus.value = ChatTextAudioStatus.pause;
  }

  void onTap() {
    ChatTextAudioStatus status = textMessage.audioStatus.value;
    switch (status) {
      case ChatTextAudioStatus.unlock:
        //弹窗
        showUnlockAlertIfNeeded();
        break;
      case ChatTextAudioStatus.loading:
        break;
      case ChatTextAudioStatus.ready:
        play();
        break;
      case ChatTextAudioStatus.playing:
        pause();
        break;
      case ChatTextAudioStatus.pause:
        continuePlay();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          // gradient: MyAccount.isSubscribed?LinearGradient(
          //   colors: [Color(0xFFF6C2D8), Color(0xFFDB80F9), Color(0xFFC07CF7), Color(0xFF6F71F6)],
          //   begin: Alignment.centerLeft,
          //   end: Alignment.centerRight,
          // ):null,
          color:
          // MyAccount.isSubscribed ?null :
          Color(0xFFCA5CDA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => buildAudioStatusIcon()),
            if (textMessage.audioDuration > 0)
              Container(
                margin: EdgeInsets.only(left: 4),
                child: Text('${textMessage.audioDuration}"', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          // gradient: MyAccount.isSubscribed?LinearGradient(
          //   colors: [Color(0xFFF6C2D8), Color(0xFFDB80F9), Color(0xFFC07CF7), Color(0xFF6F71F6)],
          //   begin: Alignment.centerLeft,
          //   end: Alignment.centerRight,
          // ):null,
          color:
          // MyAccount.isSubscribed ?null :
          Color(0xFF997B2F),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => buildAudioStatusIcon()),
            if (textMessage.audioDuration > 0)
              Container(
                margin: EdgeInsets.only(left: 4),
                child: Text('${textMessage.audioDuration}"', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
