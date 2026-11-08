import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_text_cell.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChatTextMessage message(
  String text, {
  bool mine = false,
  bool narration = false,
}) {
  return ChatTextMessage(
    id: 1,
    senderId: mine ? 1 : 1007,
    receiverId: mine ? 1007 : 1,
    date: DateTime(2026),
    ownerId: 1,
    senderName: 'Mina',
    senderAvatar: '',
    type: narration ? ChatMessageType.desc : ChatMessageType.text,
    uuid: 'preview',
    info: '{}',
    lockInfo: {},
    nativeId: 'preview',
    sessionType: 0,
  )..text = text;
}

double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'chat text, narration and translations remain legible at scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var taps = 0;
        final incoming = message('Hello, how was your day?');
        incoming.translationText.value = '你好，今天过得怎么样？';
        final narration = message(
          'She smiles and waves hello.',
          narration: true,
        );
        final outgoing = message(
          'I would love to hear your story.',
          mine: true,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.theme,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ChatTextCell(incoming, onTap: (_) => taps++),
                        ChatTextCell(narration),
                        ChatTextCell(outgoing),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        for (final entry in [
          (incoming.text, AppColors.chatIncoming),
          (incoming.translationText.value, AppColors.chatIncoming),
          (narration.text, AppColors.chatIncoming),
          (outgoing.text, AppColors.chatOutgoing),
        ]) {
          final text = tester.widget<Text>(find.text(entry.$1));
          expect(
            contrast(text.style!.color!, entry.$2),
            greaterThanOrEqualTo(4.5),
          );
        }
        await tester.tap(find.text(incoming.text));
        expect(taps, 1);
      },
    );
  }
}
