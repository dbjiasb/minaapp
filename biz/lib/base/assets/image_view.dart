import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

// import 'package:extended_image/extended_image.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/util/cached_image.dart';
import '../api_service/api_config.dart';
import '../environment/environment.dart';
import '../file_manager/zip_image_manager.dart';

class ImageView extends StatelessWidget {
  final String name;

  final double? width;

  final double? height;

  final Color? color;

  final BoxFit? fit;

  const ImageView(this.name, {this.width, this.height, this.color, this.fit, super.key});

  @override
  Widget build(BuildContext context) {
    if (Environment.instance.isDebug && !name.startsWith(ApiConfig.cdnApp)) {
      String pathPre = '../assets/images/';
      if (Platform.isAndroid) {
        pathPre = Images.security_packages_biz_assets_images_;
      }
      return Image.asset('$pathPre$name', width: width, height: height, color: color, fit: fit);
    }
    final path = !name.startsWith(Security.security_http) ? ZipImageManager.instance.getImagePathOrUrl(name) : name;
    if (ZipImageManager.instance.isLocalImage(path)) {
      return Image.file(File(path), fit: fit, color: color, width: width, height: height);
    } else {
      return CachedImage(
        imageUrl: path,
        width: width,
        height: height,
        color: color,
        fit: fit,
        errorWidget: (BuildContext context, String url, Object error) {
          return Container(width: width, height: height, color: color ?? Colors.grey);
        },
      );
    }
  }

  static ImageProvider getImageProvider(String name) {
    if (Environment.instance.isDebug) {
      return AssetImage('assets/images/$name', package: Security.security_biz);
    }
    final path = ZipImageManager.instance.getImagePathOrUrl(name);
    if (ZipImageManager.instance.isLocalImage(path)) {
      return FileImage(File(path));
    } else {
      return CachedImageProvider(path);
    }
  }

  static Future<ui.Image> getImage(String name) {
    final path = ZipImageManager.instance.getImagePathOrUrl(name);
    if (ZipImageManager.instance.isLocalImage(path)) {
      return loadImageFromFile(path);
    } else {
      return loadImageFromNetwork(path);
    }
  }

  static Future<ui.Image> loadImageFromNetwork(String url) async {
    Dio dio = Dio();
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return await _decodeImageFromBytes(response.data);
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
