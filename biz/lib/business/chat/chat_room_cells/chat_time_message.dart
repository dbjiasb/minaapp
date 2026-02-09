import 'package:flutter/cupertino.dart';

import './chat_cell.dart';
import 'chat_message.dart';

class ChatTimeMessage extends ChatMessage {
  // 实现构造函数，确保传递所有父类构造函数所需的必需参数
  ChatTimeMessage(DateTime date)
    : super(
        id: 0,
        // 假设 id 为 0，可根据实际情况调整
        senderId: 0,
        // 假设 senderId 为 0，可根据实际情况调整
        receiverId: 0,
        // 假设 receiverId 为 0，可根据实际情况调整
        date: date,
        ownerId: 0,
        senderName: '',
        senderAvatar: '',
        // 假设 ownerId 为 0，可根据实际情况调整
        type: ChatMessageType.time,
        // 假设存在 ChatMessageType.time，可根据实际情况调整
        uuid: '',
        // 假设 uuid 为空字符串，可根据实际情况调整
        info: '',
        // 假设 info 为空字符串，可根据实际情况调整
        lockInfo: {},
        // 假设 lockInfo 为空字符串，可根据实际情况调整
        nativeId: '', // 假设 nativeId 为空字符串，可根据实际情况调整
        sessionType: 0,
      );
}

class ChatTimeCell extends ChatCell {
  ChatTimeCell({super.key, required ChatMessage message, super.onTap}) : super(message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 56,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Color(0xffFFF9B4).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
          child: Text(message.date.toString()),
        ),
      ),
    );
  }
}
