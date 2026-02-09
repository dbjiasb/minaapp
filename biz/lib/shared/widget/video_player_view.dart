// 用Getx库实现一个视频播放器，播放器接受 videoUrl 作为参数，并播放视频
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/core/util/log_util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../../base/crypt/copywriting.dart';
import '../toast/toast.dart';

class VideoPlayerView extends StatelessWidget {
  VideoPlayerView({super.key});

  VideoPlayerViewController viewController = Get.put(VideoPlayerViewController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 去掉标题栏，设置背景为黑色
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        // 设置返回按钮为白色
        title: null,
        // 去掉标题
        elevation: 0,
        // 去掉阴影
        actions: [
          if (viewController.canDownload == 1)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () {
                viewController.saveVideoToGallery();
              },
            ),
        ],
      ),
      backgroundColor: Colors.black, // 设置页面背景为黑色
      body: Center(
        child:
            viewController.isImageFile.value
                ? CachedNetImage(imageUrl: viewController.videoUrl)
                : Obx(() {
                  return viewController.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                        child: AspectRatio(
                          aspectRatio: viewController._player.controller.value.aspectRatio,
                          child: VideoPlayer(viewController._player.controller),
                        ),
                      );
                }),
      ),
      floatingActionButton:
          !viewController.isImageFile.value
              ? FloatingActionButton(
                backgroundColor: Colors.transparent,
                onPressed: () {
                  if (viewController.videoUrl.isImageFileName) return;

                  if (viewController._player.controller.value.isPlaying) {
                    viewController._player.controller.pause();
                  } else {
                    viewController._player.controller.play();
                  }
                },
                // child: Icon(playerController.value.isPlaying ? Icons.pause : Icons.play_arrow),
                child: Container(
                  // padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(60)),
                  child: Center(child: Obx(() => Icon(viewController.isPlaying.value ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32))),
                ),
              )
              : null,
    );
  }
}

class VideoPlayerViewController extends GetxController {
  late final CachedVideoPlayerPlus _player;
  final VideoCacheManager videoCacheManager = VideoCacheManager();

  String get videoUrl => Get.arguments[Security.security_videoUrl] ?? '';

  int get canDownload => Get.arguments[Security.security_canDownload] ?? 0;

  RxBool isImageFile = RxBool(false);

  var isPlaying = false.obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    AppLog.d("video_url: $videoUrl");
    _player = CachedVideoPlayerPlus.networkUrl(Uri.parse(videoUrl));

    _player.initialize().then((_) {
      isLoading.value = false;
      _player.controller.setLooping(true);
      _player.controller.addListener(() {
        if (_player.controller.value.isPlaying) {
          isPlaying.value = true;
        } else {
          isPlaying.value = false;
        }
      });
      _player.controller.play();
      isPlaying.value = true;
    }).catchError((error) {
      // isLoading.value = false;
      Toast.show('Video initialization failed. ${error.toString()}');
      AppLog.e("Video initialization error: $error");
    });
    isImageFile.value = isImageFileUrl(videoUrl);
  }

  bool isImageFileUrl(String url) {
    return url.isImageFileName || url.endsWith(".webp");
  }

  Future<void> saveVideoToGallery() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        var permission = Permission.storage;
        if (deviceInfo.version.sdkInt >= 33) {
          permission = Permission.videos;
        }

        if (await permission.isDenied || await permission.isRestricted) {
          final status = await permission.request();
          if (!status.isGranted) {
            Toast.show(Copywriting.security_please_grant_storage_permission);
            return;
          }
        }
      } else if (Platform.isIOS) {
        if (await Permission.photos.isDenied || await Permission.photos.isRestricted) {
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            Toast.show(Copywriting.security_please_grant_storage_permission);
            return;
          }
        }
      }

      String cacheKey = "cached_video_player_plus_caching_time_of_$videoUrl";
      FileInfo? fileInfo = await videoCacheManager.getFileFromMemory(cacheKey) ?? await VideoCacheManager().getFileFromCache(cacheKey);

      if (fileInfo == null || !await fileInfo.file.exists()) {
        Toast.show(Copywriting.security_failed_to_save__try_again_later_Data_Empty_);
        return;
      }

      final File videoFile = fileInfo.file;

      final result = await ImageGallerySaverPlus.saveFile(videoFile.path, name: 'video_${DateTime.now().millisecondsSinceEpoch}');

      if (result[Security.security_isSuccess] == true) {
        Toast.show(Copywriting.security_saved_successfully);
      } else {
        Toast.show(Copywriting.security_failed_to_save__try_again_later_Data_Empty_);
      }
    } catch (e) {
      Toast.show(Copywriting.security_failed_to_save__try_again_later_Data_Empty_);
    }
  }

  @override
  void onClose() {
    _player.controller.removeListener(() {});
    _player.dispose();
    super.onClose();
  }
}
