import 'dart:ui' as ui;

import 'package:biz/base/api_service/api_config.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/assets/local_image_assets.dart';
import 'package:biz/base/crypt/images.dart';
import 'package:biz/business/discovery/video_match/match_const.dart';
import 'package:biz/business/moment/constant_state.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled artwork can all be decoded without network or ZIP setup',
    () async {
      for (final path in LocalImageAssets.paths) {
        final image = await ImageView.getImage(path).catchError((Object error) {
          throw StateError('Cannot decode $path: $error');
        });
        expect(image.width, greaterThan(0), reason: path);
        expect(image.height, greaterThan(0), reason: path);
        image.dispose();
      }
    },
  );

  test(
    'redesigned icons use img assets for both legacy and direct references',
    () {
      for (final entry in LocalImageAssets.redesigned.entries) {
        final expected = '${LocalImageAssets.redesignedPrefix}${entry.value}';
        for (final reference in [
          entry.key,
          '${ApiConfig.cdnApp}${entry.key}',
          '${LocalImageAssets.prefix}${entry.key}',
          expected,
          'assets/img/${entry.value}',
        ]) {
          expect(LocalImageAssets.resolve(reference), expected);
          final provider = ImageView.getImageProvider(reference) as AssetImage;
          expect(provider.assetName, expected);
        }
      }
    },
  );

  test('redesigned PNGs preserve transparent backgrounds', () async {
    for (final filename in LocalImageAssets.redesigned.values) {
      final image = await ImageView.getImage('assets/img/$filename');
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      // Allow imperceptible 1/255 alpha noise from generated PNGs, while
      // requiring real transparent padding and visible opaque artwork.
      expect(bytes.getUint8(3), lessThanOrEqualTo(2), reason: filename);
      var transparentPixels = 0;
      var opaquePixels = 0;
      for (var offset = 3; offset < bytes.lengthInBytes; offset += 4) {
        final alpha = bytes.getUint8(offset);
        if (alpha <= 2) transparentPixels++;
        if (alpha >= 250) opaquePixels++;
      }
      final pixelCount = image.width * image.height;
      expect(
        transparentPixels,
        greaterThan(pixelCount * .05),
        reason: filename,
      );
      expect(opaquePixels, greaterThan(pixelCount * .05), reason: filename);
      expect(image.width, greaterThanOrEqualTo(512), reason: filename);
      image.dispose();
    }
  });

  test('legacy icon names and URLs use asset providers', () {
    for (final name in [
      Images.security_coin_png,
      ImagePath.bt_0_1,
      '${MomentRes.base}iic_loading_img.png',
      '${MatchRes.base}ic_match_bg.png',
      '${ApiConfig.cdnApp}coin.png?imageMogr2/format/web',
      '${ApiConfig.cdnApp}assets/1.0.1/images/coin.png',
    ]) {
      expect(ImageView.getImageProvider(name), isA<AssetImage>(), reason: name);
      expect(CachedImageProvider(name), isA<AssetImage>(), reason: name);
    }
  });

  test('dynamic remote images keep network providers', () {
    for (final url in [
      'https://example.com/coin.png',
      '${ApiConfig.cdnApp}users/avatar.png',
    ]) {
      expect(LocalImageAssets.resolve(url), isNull);
      expect(CachedImageProvider(url), isA<CachedNetworkImageProvider>());
    }
  });

  testWidgets('both widget entry points display local icons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            ImageView(Images.security_coin_png, width: 16, height: 16),
            CachedImage(imageUrl: ImagePath.bt_0_1, width: 28, height: 28),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(2));
    expect(images.every((image) => image.image is AssetImage), isTrue);
    expect(images[0].width, 16);
    expect(images[1].width, 28);
    expect(tester.takeException(), isNull);
  });
}
