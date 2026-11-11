import 'dart:convert';

import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/chat/chat_room/chat_room_view.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_text_cell.dart';
import 'package:flutter_test/flutter_test.dart';

ChatTextMessage message(int id) => ChatTextMessage(
  id: id,
  senderId: 100,
  receiverId: 1,
  date: DateTime(2026),
  ownerId: 1,
  senderName: 'role',
  senderAvatar: '',
  type: ChatMessageType.text,
  uuid: '$id',
  info: '{}',
  lockInfo: {},
  nativeId: 'message-$id',
  sessionType: 0,
)..text = 'The same text may be sent intentionally.';

void main() {
  late ChatRoomViewController controller;
  setUp(() {
    controller = ChatRoomViewController({
      Security.security_session: jsonEncode({
        Security.security_id: '100',
        Security.security_name: 'role',
        Security.security_avatar: '',
      }),
    });
  });
  tearDown(() {
    controller.stopGeneratingTimer();
    controller.generatingMsgTimer?.cancel();
  });

  test(
    'a live notification does not duplicate a message loaded from history',
    () {
      controller.messages.add(message(1));
      controller.insertMessages([message(1)]);
      expect(controller.messages, hasLength(1));
      expect(controller.waitingMessages, isEmpty);
    },
  );

  test(
    'duplicates are ignored within a batch and across the pending queue',
    () {
      controller.insertMessages([message(1), message(2), message(2)]);
      controller.insertMessages([message(1), message(2)]);
      expect(
        controller.messages.whereType<ChatTextMessage>().map((item) => item.id),
        [1],
      );
      expect(
        controller.waitingMessages.cast<ChatMessage>().map((item) => item.id),
        [2],
      );
    },
  );

  test('separate messages with identical text are preserved', () {
    controller.messages.add(message(1));
    controller.insertMessages([message(2)]);
    expect(controller.messages.map((item) => (item as ChatMessage).id), [2, 1]);
    expect(controller.waitingMessages, isEmpty);
  });
}
