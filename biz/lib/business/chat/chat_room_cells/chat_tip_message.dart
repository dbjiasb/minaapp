import 'package:biz/base/crypt/copywriting.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:biz/shared/app_theme.dart';

import '../../../base/crypt/security.dart';
import './chat_cell.dart';
import 'chat_message.dart';

class ChatTipsMessage extends ChatMessage {

  String text = '';

  String get externalText => '[TIPS] $text';

  ChatTipsMessage.fromServer(Map map) : super.fromServerData(map) {
    text = map[Security.security_content] ?? '';
  }

  ChatTipsMessage.fromDatabase(Map<String, Object?> map) : super.fromLocalData(map) {
    text = (map[Security.security_content] as String?) ?? '';
  }

  @override
  Map<String, Object?> toDatabase() {
    return {...super.toDatabase(), Security.security_content: text};
  }

}

class ChatTipsCell extends ChatCell {
  ChatTipsCell(super.message, {super.onTap});

  ChatTipsMessage get tipsMessage => message as ChatTipsMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.black.withValues(alpha: 0.5)
          ),
          child: Text(
            tipsMessage.text,
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: AppFonts.medium),
          ),
        ))
      ],
    );
  }
}
