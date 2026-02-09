import 'package:biz/base/crypt/routes.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../base/crypt/copywriting.dart';
import '../../core/util/cached_image.dart';

class ImageViewer extends StatelessWidget {
  ImageViewer({super.key});

  final String kChatImageViewGenerateVideo = Security.security_kChatImageViewGenerateVideo;

  final String imageUrl = Get.arguments[Security.security_imageUrl];
  final int canDownload = Get.arguments[Security.security_canDownload] ?? 0;
  final bool canGenerateVideo = Get.arguments[Security.security_canGenerateVideo] ?? false;
  final String imageDes = Get.arguments[Security.security_imageDes] ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 去除默认的 AppBar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // 设置为透明背景
        backgroundColor: Colors.transparent,
        // 去除阴影
        elevation: 0,
        // 左上方添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (canGenerateVideo)
            GestureDetector(
              onTap: () {
                EventCenter.instance.sendEvent(kChatImageViewGenerateVideo, {Security.security_imageUrl: imageUrl, Security.security_desc: imageDes});
              },
              child: Image.asset(ImagePath.play_icon, height: 24, width: 24),
            ),

          if (canDownload == 1)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () {
                onSave();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Center(
              // 使用 InteractiveViewer 实现双指捏合缩放和拖动
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedImage(
                  imageUrl: imageUrl,
                  placeholder:
                      (context, url) => Container(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(width: 32, height: 32, child: const CircularProgressIndicator(color: Colors.white)),
                      ),
                ),
              ),
            ),
          ),

          imageDes.isNotEmpty
              ? Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(16),
                  color: Color(0xFF12151C),
                  child: Text(imageDes, style: TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  void onSave() async {
    String url = CachedImage.processedImageUrl(imageUrl);
    Toast.loading(status: Copywriting.security_saving___);
    if (url.isEmpty) {
      Toast.show(Copywriting.security_failed_to_save__image_URL_is_empty);
      return;
    }

    FileInfo? fileInfo = await DefaultCacheManager().getFileFromMemory(url) ?? await DefaultCacheManager().getFileFromCache(url);
    if (fileInfo == null) {
      Toast.show(Copywriting.security_failed_to_save__try_again_later);
      return;
    }
    Uint8List imgData = await fileInfo.file.readAsBytes();
    if (imgData.isEmpty) {
      Toast.show(Copywriting.security_failed_to_save__try_again_later_Data_Empty_);
      return;
    }

    await ImageGallerySaverPlus.saveImage(imgData, quality: 100);
    Toast.show(Copywriting.security_saved_successfully);
  }
}

class ImageViewerViewController extends GetxController {
  final String imageUrl;

  ImageViewerViewController(this.imageUrl);
}
