import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
}

void main() {
  testWidgets('back control is labelled, readable, and has a 48px target', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          appBar: AppBar(leading: AppBackButton(onPressed: () => taps++)),
        ),
      ),
    );
    expect(find.byTooltip('Back'), findsOneWidget);
    final button = tester.widget<BackButton>(find.byType(BackButton));
    expect(contrast(button.color!, AppColors.background), greaterThan(3));
    final target = tester.getRect(find.byType(IconButton));
    expect(target.width, greaterThanOrEqualTo(48));
    expect(target.height, greaterThanOrEqualTo(48));
    await tester.tapAt(target.topLeft + const Offset(3, 3));
    expect(taps, 1);
  });

  testWidgets('media back control stays readable over light and dark photos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: const Scaffold(body: AppBackButton(onMedia: true)),
      ),
    );
    final button = tester.widget<BackButton>(find.byType(BackButton));
    final scrim = button.style!.backgroundColor!.resolve({})!;
    for (final photo in [Colors.white, Colors.black]) {
      expect(
        contrast(button.color!, Color.alphaBlend(scrim, photo)),
        greaterThan(3),
      );
    }
  });

  testWidgets('default action pops one route', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: AppTheme.theme,
        home: const Scaffold(body: Text('previous page')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: const Text('detail page'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('previous page'), findsOneWidget);
    expect(find.text('detail page'), findsNothing);
  });

  testWidgets('custom action completes without an additional automatic pop', (
    tester,
  ) async {
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          appBar: AppBar(
            leading: AppBackButton(onPressed: () => saves++),
            title: const Text('draft'),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(find.text('draft'), findsOneWidget);
  });
}
