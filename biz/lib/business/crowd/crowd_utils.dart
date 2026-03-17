import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:biz/core/util/cached_image.dart';

/// 从 CachedNetworkImage 的缓存中加载 ui.Image（支持复用缓存）
Future<ui.Image?> _loadImageFromCacheOrNetwork(String url) async {
  try {
    // 1. 尝试从缓存获取文件
    final fileInfo = await DefaultCacheManager().getSingleFile(url);
    if (await fileInfo.exists()) {
      final bytes = await fileInfo.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    }

    // 2. 缓存不存在？手动下载并缓存（可选）
    // 注意：DefaultCacheManager().getSingleFile() 本身会自动下载并缓存
    // 所以上面已经触发了下载，这里其实不会走到
    return null;
  } catch (e) {
    // 下载或解码失败
    return null;
  }
}

/// 生成群聊头像字节（PNG）
/// 支持最多 4 张图，2x2 布局
/// size: 输出图像的宽高（正方形）
Future<Uint8List?> generateGroupAvatarBytes(
  List<String> urls, {
  int size = 600,
}) async {
  final List<ui.Image> images = [];
  for (final url in urls.take(4)) {
    try {
      final image = await _loadImageFromCacheOrNetwork(
        CachedImage.processedImageUrl(url),
      );
      if (image != null) images.add(image);
    } catch (e) {
      continue;
    }
  }
  if (images.isEmpty) return null;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();

  // 🎨 先画白色背景
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = Colors.white,
  );

  final count = images.length;

  if (count == 1) {
    // 1个：居中圆形，Cover 裁剪
    final img = images[0];
    final double radius = size / 2;
    final Offset center = Offset(size / 2, size / 2);

    // 创建圆形路径
    final path =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    // 裁剪区域
    canvas.save();
    canvas.clipPath(path);

    // 计算 cover 裁剪矩形
    final cropRect = calculateCoverCrop(img, 2 * radius, 2 * radius);
    final dstRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawImageRect(img, cropRect, dstRect, paint);
    canvas.restore();
  } else if (count == 2) {
    // 2个：左右平分，每个圆形，Cover 裁剪
    for (int i = 0; i < 2; i++) {
      final img = images[i];
      final double cellWidth = size / 2;
      final double cellHeight = size.toDouble();
      final double radius = math.min(cellWidth, cellHeight) / 2;
      final double centerX = i * cellWidth + cellWidth / 2;
      final double centerY = cellHeight / 2;
      final Offset center = Offset(centerX, centerY);

      final path =
          Path()..addOval(Rect.fromCircle(center: center, radius: radius));

      canvas.save();
      canvas.clipPath(path);

      final cropRect = calculateCoverCrop(img, 2 * radius, 2 * radius);
      final dstRect = Rect.fromCircle(center: center, radius: radius);

      canvas.drawImageRect(img, cropRect, dstRect, paint);
      canvas.restore();
    }
  } else if (count == 3) {
    // 第1行：2个圆形（左/右），Cover 裁剪
    for (int i = 0; i < 2; i++) {
      final img = images[i];
      final double cellWidth = size / 2;
      final double cellHeight = size / 2;
      final double radius = math.min(cellWidth, cellHeight) / 2;
      final double centerX = i * cellWidth + cellWidth / 2;
      final double centerY = cellHeight / 2;
      final Offset center = Offset(centerX, centerY);

      final path =
          Path()..addOval(Rect.fromCircle(center: center, radius: radius));

      canvas.save();
      canvas.clipPath(path);

      final cropRect = calculateCoverCrop(img, 2 * radius, 2 * radius);
      final dstRect = Rect.fromCircle(center: center, radius: radius);

      canvas.drawImageRect(img, cropRect, dstRect, paint);
      canvas.restore();
    }

    // 第2行：第3个水平居中圆形，Cover 裁剪
    final img = images[2];
    final double cellHeight = size / 2;
    final double cellWidth = size / 2;
    final double radius = math.min(cellWidth, cellHeight) / 2;
    final double centerX = size / 2;
    final double centerY = size / 2 + cellHeight / 2;
    final Offset center = Offset(centerX, centerY);

    final path =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(path);

    final cropRect = calculateCoverCrop(img, 2 * radius, 2 * radius);
    final dstRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawImageRect(img, cropRect, dstRect, paint);
    canvas.restore();
  } else {
    // 4个：标准 2x2 圆形，Cover 裁剪
    for (int i = 0; i < 4; i++) {
      final row = i ~/ 2;
      final col = i % 2;
      final img = images[i];
      final double cellWidth = size / 2;
      final double cellHeight = size / 2;
      final double radius = math.min(cellWidth, cellHeight) / 2;
      final double centerX = col * cellWidth + cellWidth / 2;
      final double centerY = row * cellHeight + cellHeight / 2;
      final Offset center = Offset(centerX, centerY);

      final path =
          Path()..addOval(Rect.fromCircle(center: center, radius: radius));

      canvas.save();
      canvas.clipPath(path);

      final cropRect = calculateCoverCrop(img, 2 * radius, 2 * radius);
      final dstRect = Rect.fromCircle(center: center, radius: radius);

      canvas.drawImageRect(img, cropRect, dstRect, paint);
      canvas.restore();
    }
  }

  // 导出为 PNG 字节
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}

// 🔧 辅助函数：计算 Cover 裁剪矩形
Rect calculateCoverCrop(ui.Image img, double targetWidth, double targetHeight) {
  final srcW = img.width.toDouble();
  final srcH = img.height.toDouble();
  final aspect = srcW / srcH;
  final targetAspect = targetWidth / targetHeight;

  if (aspect > targetAspect) {
    // 源图更宽 → 裁剪左右
    final cropWidth = srcH * targetAspect;
    final left = (srcW - cropWidth) / 2;
    return Rect.fromLTWH(left, 0, cropWidth, srcH);
  } else {
    // 源图更高 → 裁剪上下
    final cropHeight = srcW / targetAspect;
    final top = (srcH - cropHeight) / 2;
    return Rect.fromLTWH(0, top, srcW, cropHeight);
  }
}
