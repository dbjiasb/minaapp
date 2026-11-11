import 'dart:async';

import 'package:biz/business/discovery/discovery_swipe_deck.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpDeck(
  WidgetTester tester, {
  int count = 3,
  required Future<bool> Function(int, bool) decide,
  ValueChanged<int>? chat,
  ValueChanged<int>? changed,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: DiscoverySwipeDeck(
          itemCount: count,
          itemBuilder: (context, index) => ColoredBox(
            color: AppColors.surface,
            child: Center(child: Text('Person $index')),
          ),
          onDecision: decide,
          onChat: chat ?? (_) {},
          onIndexChanged: changed ?? (_) {},
          exhaustedBuilder: (_) => const Text('All done'),
          chatLabel: 'Chat',
          likeLabel: 'Like',
          dislikeLabel: 'Dislike',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets(
    'left skips, right likes, and each accepted swipe advances once',
    (tester) async {
      final decisions = <(int, bool)>[];
      final indices = <int>[];
      await pumpDeck(
        tester,
        decide: (index, liked) async {
          decisions.add((index, liked));
          return true;
        },
        changed: indices.add,
      );
      final card = find.byKey(const ValueKey('discovery-swipe-card'));
      await tester.drag(card, const Offset(-220, 0));
      await tester.pumpAndSettle();
      expect(decisions, [(0, false)]);
      expect(find.text('Person 1'), findsOneWidget);
      await tester.drag(card, const Offset(220, 0));
      await tester.pumpAndSettle();
      expect(decisions, [(0, false), (1, true)]);
      expect(indices, [1, 2]);
      expect(find.text('Person 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chat targets the current card; pending decisions block duplicate actions',
    (tester) async {
      final pending = Completer<bool>();
      final decisions = <(int, bool)>[];
      final chats = <int>[];
      await pumpDeck(
        tester,
        decide: (index, liked) {
          decisions.add((index, liked));
          return pending.future;
        },
        chat: chats.add,
      );
      await tester.tap(find.byKey(const ValueKey('discovery-chat')));
      expect(chats, [0]);
      expect(decisions, isEmpty);
      await tester.tap(find.byKey(const ValueKey('discovery-like')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('discovery-like')));
      await tester.tap(find.byKey(const ValueKey('discovery-dislike')));
      await tester.tap(find.byKey(const ValueKey('discovery-chat')));
      expect(decisions, [(0, true)]);
      expect(chats, [0]);
      pending.complete(true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('discovery-chat')));
      expect(chats, [0, 1]);
    },
  );

  testWidgets(
    'short drags cancel; failed and throwing decisions restore the same card',
    (tester) async {
      var requests = 0;
      await pumpDeck(
        tester,
        decide: (_, _) async {
          requests++;
          if (requests == 2) throw StateError('offline');
          return false;
        },
      );
      await tester.timedDrag(
        find.byKey(const ValueKey('discovery-swipe-card')),
        const Offset(35, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(requests, 0);
      await tester.tap(find.byKey(const ValueKey('discovery-dislike')));
      await tester.pumpAndSettle();
      expect(find.text('Person 0'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('discovery-like')));
      await tester.pumpAndSettle();
      expect(find.text('Person 0'), findsOneWidget);
      expect(requests, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'exhaustion hides actions and appended data keeps the current position',
    (tester) async {
      Future<bool> decide(int index, bool liked) async => true;
      await pumpDeck(tester, count: 1, decide: decide);
      await tester.tap(find.byKey(const ValueKey('discovery-dislike')));
      await tester.pumpAndSettle();
      expect(find.text('All done'), findsOneWidget);
      expect(find.byKey(const ValueKey('discovery-chat')), findsNothing);
      await pumpDeck(tester, count: 2, decide: decide);
      expect(find.text('Person 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
