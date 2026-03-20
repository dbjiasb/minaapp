import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:biz/base/crypt/security.dart';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/shared/formatters/date_formatter.dart';

import '../../../base/assets/image_view.dart';
import './chat_cell.dart';

//AudioCallMessage
class ChatCallMessage extends ChatMessage {
  ChatCallMessage({
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

  ChatCallMessage.fromServer(Map map) : super.fromServerData(map) {
    sendState = ChatMessageSendStatus.fromDigit(0).obs;
  }

  ChatCallMessage.fromDatabase(Map<String, Object?> map) : super.fromLocalData(map) {
    sessionId = (map[Security.security_sessionId] as String?) ?? '';
    sendState = ChatMessageSendStatus.fromDigit(map[Security.security_sendState] as int? ?? 0).obs;
  }

  Map<String, dynamic>? _data;

  Map<String, dynamic> get data {
    if (_data == null) {
      try {
        _data = jsonDecode(info);
      } catch (e) {}
    }
    return _data ?? {};
  }

  String get callIcon => (data[Security.security_audio] as int? ?? 0) == 1 ? Images.security_audio_msg_png : Images.security_video_msg_png;

  int get callType => data[Security.security_audio] ?? 0;

  int get callDuration => (data[Security.security_callTime] ?? 0) ~/ 1000;

  String get desc => data[Security.security_desc] ?? '';

  @override
  String get externalText => '[Call] $desc';
}

class ChatCallCell extends ChatCell {
  ChatCallCell({super.key, required ChatCallMessage message, super.onTap}) : super(message);

  ChatCallMessage get callMessage => message as ChatCallMessage;

  @override
  Widget build(BuildContext context) {
    bool isMine = message.isMine();
    return GestureDetector(
      onTap: () {
        super.onTap?.call(message);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xffFFF9B4).withValues(alpha: 0.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ImageView(callMessage.callIcon, width: 20, height: 20, color: Colors.black),
                SizedBox(width: 4),
                Text(callMessage.desc, style: TextStyle(color: Colors.black, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
