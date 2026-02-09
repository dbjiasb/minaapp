import 'package:biz/base/crypt/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../base/crypt/security.dart';

class CachedImageProvider extends CachedNetworkImageProvider {
  CachedImageProvider._(String url, {
    int? maxHeight,
    int? maxWidth,
    double scale = 1.0,
    ErrorListener? errorListener,
    Map<String, String>? headers,
    BaseCacheManager? cacheManager,
    String? cacheKey,
  }) : super(url, maxHeight: maxHeight, maxWidth: maxWidth, scale: scale, errorListener: errorListener, headers: headers, cacheManager: cacheManager, cacheKey: cacheKey);

  factory CachedImageProvider(String originalUrl, {
    int? maxHeight,
    int? maxWidth,
    double scale = 1.0,
    ErrorListener? errorListener,
    Map<String, String>? headers,
    BaseCacheManager? cacheManager,
    String? cacheKey,
  }) {

    String processedUrl = CachedImage.processedImageUrl(originalUrl);
    return CachedImageProvider._(processedUrl, maxHeight: maxHeight, maxWidth: maxWidth, scale: scale, errorListener: errorListener, headers: headers, cacheManager: cacheManager, cacheKey: cacheKey);
  }
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
    BorderRadiusGeometry borderRadius = BorderRadius.zero
  }) {
    return CachedImage(imageUrl: imageUrl,
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
    if (!imageUrl.startsWith(Security.security_http)) {
      return Container(
        color: Colors.grey, width: width, height: height,
        child: kDebugMode ? Text('Invalid image url: $imageUrl', style: TextStyle(color: Colors.red, fontSize: 10.0),) : null,
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
      )
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
    );
  }
}