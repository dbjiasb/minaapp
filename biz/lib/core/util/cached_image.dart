import 'package:biz/shared/app_theme.dart';
import 'package:biz/base/assets/local_image_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../base/crypt/security.dart';

// Keep the existing constructor-style API for decorations and precaching.
// ignore: non_constant_identifier_names
ImageProvider CachedImageProvider(
  String originalUrl, {
  int? maxHeight,
  int? maxWidth,
  double scale = 1.0,
  ErrorListener? errorListener,
  Map<String, String>? headers,
  BaseCacheManager? cacheManager,
  String? cacheKey,
}) {
  final asset = LocalImageAssets.resolve(originalUrl);
  if (asset != null) {
    return ResizeImage.resizeIfNeeded(maxWidth, maxHeight, AssetImage(asset));
  }
  return CachedNetworkImageProvider(
    CachedImage.processedImageUrl(originalUrl),
    maxHeight: maxHeight,
    maxWidth: maxWidth,
    scale: scale,
    errorListener: errorListener,
    headers: headers,
    cacheManager: cacheManager,
    cacheKey: cacheKey,
  );
}

class CachedImage extends StatelessWidget {
  String imageUrl;
  PlaceholderWidgetBuilder? placeholder;
  LoadingErrorWidgetBuilder? errorWidget;
  ImageWidgetBuilder? imageBuilder;
  double? width;
  double? height;
  BoxFit? fit;
  Alignment alignment = Alignment.center;
  ImageRepeat repeat;
  BorderRadiusGeometry borderRadius = BorderRadius.zero;
  Color? color;

  CachedImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.borderRadius = BorderRadius.zero,
    this.color,
  });

  static Widget clipImage({
    Key? key,
    required String imageUrl,
    PlaceholderWidgetBuilder? placeholder,
    LoadingErrorWidgetBuilder? errorWidget,
    ImageWidgetBuilder? imageBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    Alignment alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
  }) {
    return CachedImage(
      imageUrl: imageUrl,
      key: key,
      placeholder: placeholder,
      errorWidget: errorWidget,
      imageBuilder: imageBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = LocalImageAssets.resolve(imageUrl);
    if (asset != null) {
      final provider = AssetImage(asset);
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageBuilder != null
            ? imageBuilder!(context, provider)
            : Image(
                image: provider,
                width: width,
                height: height,
                fit: fit,
                alignment: alignment,
                repeat: repeat,
                color: color,
                errorBuilder: errorWidget == null
                    ? null
                    : (context, error, stackTrace) =>
                          errorWidget!(context, imageUrl, error),
              ),
      );
    }
    if (!imageUrl.startsWith(Security.security_http)) {
      return Container(
        color: AppColors.surfaceMuted,
        width: width,
        height: height,
        child: kDebugMode
            ? Text(
                'Invalid image url: $imageUrl',
                style: TextStyle(color: Colors.red, fontSize: 10.0),
              )
            : null,
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetImage(
        imageUrl: imageUrl,
        placeholder: placeholder,
        errorWidget: errorWidget,
        imageBuilder: imageBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        color: color,
      ),
    );
  }

  static String processedImageUrl(String url) {
    String processedUrl = url;
    if (processedUrl.contains(Security.security_cdn)) {
      if (processedUrl.contains('?')) {
        processedUrl = '$processedUrl&imageMogr2/format/web';
      } else {
        processedUrl = '$processedUrl?imageMogr2/format/web';
      }
    }
    return processedUrl;
  }
}

class CachedNetImage extends CachedNetworkImage {
  CachedNetImage._({
    super.key,
    required super.imageUrl,
    super.placeholder,
    super.errorWidget,
    super.imageBuilder,
    super.width,
    super.height,
    super.fit,
    super.alignment,
    super.repeat,
    super.color,
  });

  factory CachedNetImage({
    Key? key,
    required String imageUrl,
    PlaceholderWidgetBuilder? placeholder,
    LoadingErrorWidgetBuilder? errorWidget,
    ImageWidgetBuilder? imageBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    Alignment alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    int borderRadius = 0,
    Color? color,
  }) {
    String processedUrl = CachedImage.processedImageUrl(imageUrl);
    return CachedNetImage._(
      key: key,
      imageUrl: processedUrl,
      placeholder: placeholder,
      errorWidget: errorWidget,
      imageBuilder: imageBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      color: color,
    );
  }
}
