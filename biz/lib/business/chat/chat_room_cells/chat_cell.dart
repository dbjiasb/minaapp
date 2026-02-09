import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/business/chat/chat_room_cells/chat_audio_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_theater_brief_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_tip_message.dart';
import 'package:biz/core/util/cached_image.dart';

import '../../../base/assets/image_path.dart';
import '../../../base/crypt/security.dart';
import '../../../base/router/router_names.dart';
import 'chat_generating_message.dart';
import 'chat_gift_cell.dart';
// import 'chat_image_message.dart';
import 'chat_system_message.dart';
import 'chat_text_cell.dart';
// import 'chat_video_message.dart';

enum ChatCellType {
  chat, //聊天室
  category, //历史记录中的类别
}

class ChatCell extends StatelessWidget {
  ChatMessage message;
  ChatCellType type = ChatCellType.chat;
  final Function(ChatMessage message)? resend;
  final Function(ChatMessage message)? onTap; // 添加 final 修饰符
  final Function(ChatMessage message)? unlock;
  final Function(ChatMessage message)? reload;
  final Function(ChatMessage message)? download;
  final Function(ChatMessage message)? onContinue;
  final Function(ChatMessage message)? generateVideo;

  //工厂方法
  factory ChatCell.create(
    ChatMessage message, {
    ChatCellType type = ChatCellType.chat,
    Function(ChatMessage message)? resend,
    Function(ChatMessage message)? onTap,
    Function(ChatMessage message)? unlock,
    Function(ChatMessage message)? reload,
    Function(ChatMessage message)? download,
    Function(ChatMessage message)? onContinue,
    Function(ChatMessage message)? generateVideo,
  }) {
    switch (message.type) {
      case ChatMessageType.text:
      case ChatMessageType.desc:
        return ChatTextCell(
          message as ChatTextMessage,
          resend: resend,
          onTap: onTap,
          unlock: unlock,
          reload: reload,
          download: download,
          onContinue: onContinue,
        );
      case ChatMessageType.generating:
        return ChatGeneratingCell(message: message as ChatGeneratingMessage);
      // case ChatMessageType.image:
      //   return ChatImageCell(message as ChatImageMessage, unlock: unlock, reload: reload, onTap: onTap, onContinue: onContinue, generateVideo: generateVideo)
      //     ..type = type;
      // case ChatMessageType.video:
      //   return ChatVideoCell(message as ChatVideoMessage, unlock: unlock, reload: reload, onTap: onTap, onContinue: onContinue, generateVideo: generateVideo)
      //     ..type = type;
      case ChatMessageType.gift:
        return ChatGiftCell(message as ChatGiftMessage, onTap: onTap);
      case ChatMessageType.voice:
        return ChatAudioCell(message as ChatAudioMessage, unlock: unlock, download: download, onTap: onTap);
      case ChatMessageType.system:
        return ChatSystemCell(message as ChatSystemMessage, onTap: onTap);
      case ChatMessageType.tip:
        return ChatTipsCell(message as ChatTipsMessage, onTap: onTap);
      default:
        return ChatUnsupportedCell(message);
    }
  }

  factory ChatCell.createTheaterMessage(
    ChatMessage message, {
    final Function(ChatMessage message)? onTap,
    final Function(ChatMessage message)? resendMessage,
    final Function(ChatMessage message)? unlock,
  }) {
    switch (message.type) {
      case ChatMessageType.desc:
      case ChatMessageType.text:
        return ChatTheaterTextCell(message as ChatTextMessage, resend: resendMessage, unlock: unlock);
      case ChatMessageType.generating:
        return ChatGeneratingCell(message: message as ChatGeneratingMessage);
      // case ChatMessageType.image:
      //   return ChatTheaterImageCell(message as ChatImageMessage, onTap: onTap);
      case ChatMessageType.customStoryBrief:
        return ChatTheaterBriefCell(message);
      default:
        return ChatUnsupportedCell(message);
    }
  }

  // 修复构造函数参数声明
  ChatCell(this.message, {super.key, this.resend, this.onTap, this.unlock, this.reload, this.download, this.onContinue, this.generateVideo});

  Widget buildSendStatusView() {
    ChatMessageSendStatus status = message.sendState.value;
    switch (status) {
      case ChatMessageSendStatus.sending:
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE962F6)),
        );
      case ChatMessageSendStatus.failed:
        return GestureDetector(
          onTap: () {
            resend?.call(message);
          },
          child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.error, size: 24, color: Colors.red)),
        );
      case ChatMessageSendStatus.sent:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onTap: () {
        onTap?.call(message);
      },
      child:
          message.isGroup
              ? (message.isMine()
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: buildView()), SizedBox(width: 10), _buildOwnerAvatar()])
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOwnerAvatar(),
                      SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildOwnerName(), buildView()])),
                    ],
                  ))
              : buildView(),
    );
  }

  Widget _buildOwnerName() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Text(message.senderName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildOwnerAvatar() {
    return GestureDetector(
      onTap: () {
        RouteHelper.toPage(
          Routers.person,
          args: {
            Security.security_personInfo: {
              Security.security_userInfo: {
                Security.security_baseInfo: {
                  Security.security_uid: message.ownerId,
                  Security.security_name: message.senderName,
                  Security.security_avatarUrl: message.senderAvatar,
                },
              },
            },
          },
        );
      },
      child: Container(child: CachedImage.clipImage(imageUrl: message.senderAvatar, width: 36, height: 36, borderRadius: BorderRadius.circular(18))),
    );
  }

  Widget buildView() {
    return Container();
  }

  // Widget buildContinueView() {
  //   return Obx(() {
  //     return message.showContinue.value
  //         ? GestureDetector(
  //           onTap: () {
  //             onContinue?.call(message);
  //           },
  //           child: Image.asset(IMGP.ai_continue, width: 24, height: 24),
  //         ).marginOnly(left: 8)
  //         : SizedBox.shrink();
  //   });
  // }
}

class ChatUnsupportedCell extends ChatCell {
  ChatUnsupportedCell(super.message, {super.key, super.resend});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
