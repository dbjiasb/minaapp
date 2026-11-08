import 'package:biz/shared/app_theme.dart';
import 'package:biz/base/crypt/security.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'local_image_assets.dart';

import '../../core/util/cached_image.dart';
import '../api_service/api_config.dart';

class ImageView extends StatelessWidget {
  final String name;

  final double? width;

  final double? height;

  final Color? color;

  final BoxFit? fit;

  const ImageView(
    this.name, {
    this.width,
    this.height,
    this.color,
    this.fit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final asset = LocalImageAssets.resolve(name);
    if (asset != null) {
      return Image.asset(
        asset,
        width: width,
        height: height,
        color: color,
        fit: fit,
      );
    }
    return _buildRemoteImage();
  }

  Widget _buildRemoteImage() {
    final path = name.startsWith('/') || name.startsWith(Security.security_http)
        ? name
        : '${ApiConfig.cdnApp}$name';
    if (path.startsWith('/')) {
      return Image.file(
        File(path),
        fit: fit,
        color: color,
        width: width,
        height: height,
      );
    } else {
      return CachedImage(
        imageUrl: path,
        width: width,
        height: height,
        color: color,
        fit: fit,
        errorWidget: (BuildContext context, String url, Object error) {
          return Container(
            width: width,
            height: height,
            color: color ?? AppColors.surfaceMuted,
          );
        },
      );
    }
  }

  static ImageProvider getImageProvider(String name) {
    final asset = LocalImageAssets.resolve(name);
    if (asset != null) return AssetImage(asset);
    final path = name.startsWith('/') || name.startsWith(Security.security_http)
        ? name
        : '${ApiConfig.cdnApp}$name';
    if (path.startsWith('/')) {
      return FileImage(File(path));
    } else {
      return CachedImageProvider(path);
    }
  }

  static Future<ui.Image> getImage(String name) async {
    final asset = LocalImageAssets.resolve(name);
    if (asset != null) {
      final data = await rootBundle.load(asset);
      return _decodeImageFromBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
    if (name.startsWith('/')) return loadImageFromFile(name);
    final url = name.startsWith(Security.security_http)
        ? name
        : '${ApiConfig.cdnApp}$name';
    return loadImageFromNetwork(url);
  }

  static Future<ui.Image> loadImageFromNetwork(String url) async {
    Dio dio = Dio();
    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode == 200) {
      return await _decodeImageFromBytes(Uint8List.fromList(response.data!));
    } else {
      throw Exception('Failed to load image: ${response.statusCode}');
    }
  }

  static Future<ui.Image> loadImageFromFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return await _decodeImageFromBytes(bytes);
  }

  static Future<ui.Image> _decodeImageFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
