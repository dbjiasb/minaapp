import 'package:flutter/material.dart';

import '../../../base/crypt/security.dart';
import './chat_cell.dart';
import 'chat_message.dart';

class ChatTheaterBriefMessage extends ChatMessage {
  String brief = '';

  ChatTheaterBriefMessage(this.brief)
      : super(
    id: 0,
    senderId: 0,
    receiverId: 0,
    date: DateTime.now(),
    ownerId: 0,
    senderName: '',
    senderAvatar: '',
    type: ChatMessageType.customStoryBrief,
    uuid: '',
    info: '',
    lockInfo: {},
    nativeId: '',
    sessionType: 0,
  );

  ChatTheaterBriefMessage.fromDatabase(Map<String, Object?> map) : super.fromLocalData(map) {
    brief = (map[Security.security_content] as String?) ?? '';
  }

  @override
  Map<String, Object?> toDatabase() {
    return {...super.toDatabase(), Security.security_content: brief};
  }
}

//故事背景
class ChatTheaterBriefCell extends ChatCell {
  ChatTheaterBriefCell(super.message, {super.onTap});

  ChatTheaterBriefMessage get chatTheaterBriefMessage => message as ChatTheaterBriefMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(bottom: 12,top: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          color: Colors.white.withValues(alpha: 0.9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Story background", style: TextStyle(fontSize: 11, color: Color(0xFF0F0F0F), fontWeight: FontWeight.bold)),
              SizedBox(height: 10,),
              Text(chatTheaterBriefMessage.brief, style: TextStyle(fontSize: 11, color: Color(0x9F0F0F0F), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
