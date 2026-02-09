import 'package:biz/base/crypt/security.dart';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:biz/business/chat/chat_room_cells/chat_cell.dart';
import 'package:biz/core/account/account_service.dart';

import '../../../core/util/cached_image.dart';
import '../../../core/util/log_util.dart';
import 'chat_message.dart';

class ChatGiftMessage extends ChatMessage {
  ChatGiftMessage({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.type,
    required super.date,
    required super.ownerId,
    required super.senderName,
    required super.senderAvatar,
    required super.uuid,
    required super.info,
    required super.lockInfo,
    required super.nativeId,
    required super.sessionType,
  });

  ChatGiftMessage.fromServer(super.data) : super.fromServerData() {
    // AccountService.instance.refreshBalance();
  }

  ChatGiftMessage.fromDatabase(super.data) : super.fromLocalData();

  @override
  Map<String, dynamic> toDatabase() {
    return super.toDatabase();
  }

  Map<String, dynamic>? _decodedInfo;

  Map<String, dynamic> get decodedInfo {
    try {
      _decodedInfo ??= jsonDecode(info);
    } catch (e) {
      L.e('[ChatGiftMessage] decode info error: $e');
    }
    return _decodedInfo ?? {};
  }

  String get imageUrl => decodedInfo[Security.security_giftIcon] ?? '';

  int get giftCount => decodedInfo[Security.security_giftCount] ?? 0;

  String get giftName => decodedInfo[Security.security_giftName] ?? '';

  @override
  String get externalText => '[Gift] $giftName x$giftCount';
}

class ChatGiftCell extends ChatCell {
  ChatGiftCell(super.message, {super.key, super.onTap});

  ChatGiftMessage get giftMessage => message as ChatGiftMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: giftMessage.isMine() ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: giftMessage.isMine() ? Color(0xffB661EF).withValues(alpha: 0.9) : Color(0xff272533).withValues(alpha: 0.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: giftMessage.isMine() ? Radius.circular(12) : Radius.circular(4),
                bottomRight: giftMessage.isMine() ? Radius.circular(4) : Radius.circular(12),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min, // 防止横向拉伸
              children: [
                Column(
                  children: [
                    Text(giftMessage.giftName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(
                      'You ${giftMessage.isMine() ? Security.security_Send : 'Received'}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 11),
                    ),
                  ],
                ),
                SizedBox(width: 4),
                CachedImage(imageUrl: giftMessage.imageUrl, width: 32, height: 32),
                SizedBox(width: 4),
                Text('x${giftMessage.giftCount}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: '.SF Pro Text')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
