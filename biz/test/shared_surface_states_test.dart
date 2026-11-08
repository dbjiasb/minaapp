import 'dart:async';

import 'package:biz/core/util/ui_util.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef AsyncFactory = Widget Function(Future<String?> future);

void main() {
  test('app surfaces and system bars follow the selected appearance', () {
    final theme = AppTheme.theme;
    expect(
      theme.brightness,
      AppAppearance.isLight ? Brightness.light : Brightness.dark,
    );
    for (final color in [
      theme.scaffoldBackgroundColor,
      theme.canvasColor,
      theme.appBarTheme.backgroundColor!,
      theme.bottomSheetTheme.backgroundColor!,
      theme.dialogTheme.backgroundColor!,
      theme.popupMenuTheme.color!,
    ]) {
      expect(
        color.computeLuminance(),
        AppAppearance.isLight ? greaterThan(.8) : lessThan(.1),
      );
    }
    expect(
      AppAppearance.overlayStyle.statusBarIconBrightness,
      AppAppearance.isLight ? Brightness.dark : Brightness.light,
    );
    expect(
      AppAppearance.overlayStyle.systemNavigationBarIconBrightness,
      AppAppearance.isLight ? Brightness.dark : Brightness.light,
    );
    expect(
      AppAppearance.overlayStyle.systemNavigationBarColor,
      AppColors.background,
    );
  });

  final factories = <String, AsyncFactory>{
    'discovery async helper': (future) => UiUtils.buildFutureView<String?>(
      future,
      (value, context) => Text(value!),
      emptyView: const Text('empty'),
    ),
    'shared async body': (future) =>
        AppBarExt.mainBody<String?>(future, (value, context) => Text(value!)),
  };
  for (final entry in factories.entries) {
    for (final state in ['loading', 'empty', 'error', 'data']) {
      testWidgets('${entry.key} keeps a readable $state state', (tester) async {
        final completer = Completer<String?>();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.theme,
            home: Scaffold(body: entry.value(completer.future)),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final progress = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        final luminance = AppColors.background.computeLuminance();
        final foreground = progress.color!.computeLuminance();
        expect(
          ((luminance > foreground ? luminance : foreground) + .05) /
              ((luminance > foreground ? foreground : luminance) + .05),
          greaterThan(3),
        );
        if (state == 'empty') completer.complete(null);
        if (state == 'error')
          completer.completeError(StateError('network unavailable'));
        if (state == 'data') completer.complete('loaded content');
        await tester.pump();
        if (state == 'loading') {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        } else {
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.byType(Text), findsWidgets);
        }
        if (state == 'error') {
          final text = tester.widget<Text>(
            find.textContaining('network unavailable'),
          );
          expect(text.style!.color, AppColors.textPrimary);
        }
        if (state == 'data')
          expect(find.text('loaded content'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        if (!completer.isCompleted) completer.complete(null);
      });
    }
  }
}
