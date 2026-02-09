import 'package:biz/base/crypt/copywriting.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:biz/shared/app_theme.dart';

import './chat_cell.dart';
import './chat_system_message.dart';
import 'chat_message.dart';

class ChatSystemMessage extends ChatMessage {
  String content = Copywriting.security_notice__Everything_AI_says_is_made_up;

  ChatSystemMessage()
    : super(
        id: 0,
        senderId: 0,
        receiverId: 0,
        date: DateTime.now(),
        ownerId: 0,
        senderName: '',
        senderAvatar: '',
        type: ChatMessageType.system,
        uuid: '',
        info: '',
        lockInfo: {},
        nativeId: '',
        sessionType: 0,
      );
}

class ChatSystemCell extends ChatCell {
  ChatSystemCell(super.message, {super.onTap});

  ChatSystemMessage get systemMessage => message as ChatSystemMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: 290,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Color(0xFF000000).withValues(alpha: 0.2),
                ),
                child: Text(
                  Copywriting.security_notice__Everything_AI_says_is_made_up,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: AppFonts.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
