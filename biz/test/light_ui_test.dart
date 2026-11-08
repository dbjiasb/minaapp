import 'dart:io';

import 'package:biz/shared/app_brand.dart';
import 'dart:ui' as ui;

import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/character_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('surface text meets normal text contrast', () {
    double contrast(Color foreground, Color background) {
      final a = foreground.computeLuminance();
      final b = background.computeLuminance();
      return ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
    }

    for (final background in [
      AppColors.background,
      AppColors.surface,
      AppColors.surfaceMuted,
    ]) {
      expect(
        contrast(AppColors.textPrimary, background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.textSecondary, background),
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(
      contrast(AppColors.accentText, AppColors.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'character card fits a narrow grid at text scale $scale and opens on tap',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fontPath = Platform.environment['UI_PREVIEW_FONT'];
        if (fontPath != null) {
          await tester.runAsync(() async {
            final loader = FontLoader('PreviewSans')
              ..addFont(
                File(
                  fontPath,
                ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
              );
            await loader.load();
            final iconPath = Platform.environment['UI_PREVIEW_ICONS'];
            if (iconPath != null) {
              final icons = FontLoader('MaterialIcons')
                ..addFont(
                  File(
                    iconPath,
                  ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
                );
              await icons.load();
            }
          });
        }
        var taps = 0;
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: fontPath == null
                ? AppTheme.theme
                : AppTheme.theme.copyWith(
                    textTheme: AppTheme.theme.textTheme.apply(
                      fontFamily: 'PreviewSans',
                    ),
                  ),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(375, 812),
                textScaler: TextScaler.linear(scale),
              ),
              child: RepaintBoundary(
                key: boundaryKey,
                child: Scaffold(
                  appBar: AppBar(title: const Text(AppBrand.name)),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CharacterCard(
                            image: const ColoredBox(
                              color: Color(0xFFEAE4CE),
                              child: Center(
                                child: Icon(Icons.person_outline, size: 64),
                              ),
                            ),
                            name: 'A very long character name',
                            bio: 'A friendly companion with a story to share.',
                            creator: 'a_very_long_creator_name',
                            connections: '12.4K',
                            heat: '9.8K',
                            tags: const [
                              'Adventure',
                              'A very long descriptive character tag',
                            ],
                            onTap: () => taps++,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CharacterCard(
                            image: const ColoredBox(
                              color: Color(0xFFDCE4D5),
                              child: Center(
                                child: Icon(Icons.auto_awesome, size: 64),
                              ),
                            ),
                            name: 'Luna',
                            onTap: () => taps++,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Luna'));
        expect(taps, 1);
        if (scale == 1 && Platform.environment['LIGHT_UI_PREVIEW'] == '1') {
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '/tmp/miora-light-ui-preview.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }
}
