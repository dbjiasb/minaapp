import 'package:biz/base/crypt/copywriting.dart';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/routes.dart';

import '../../base/assets/image_view.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/images.dart';
import '../../base/crypt/security.dart';
import '../../base/router/route_helper.dart';
import '../../base/router/router_names.dart';
import '../../core/util/cached_image.dart';
import '../../core/util/ui_util.dart';
import '../../shared/widget/video_file_view.dart';
// import 'logic.dart';

class PhotoView extends StatefulWidget {
  final List resInfoList;
  final int accountType;
  final bool isLocked;
  Future<bool> Function(int galleryResId, int costValue, int costType)? unLockRes;

  PhotoView(this.resInfoList, this.accountType, {this.isLocked = false, super.key, this.unLockRes});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.transparent, child: widget.resInfoList.isEmpty ? UiUtils.buildCommonEmptyView() : _buildPhotoList());
  }

  void toViewer(String url) {
    Map arguments = {
      Security.security_imageUrl: url,
      Security.security_canDownload: 0,
      Security.security_canGenerateVideo: false,
    };
    Get.toNamed(Routers.imageBrowser, arguments: arguments);
  }

  Widget _buildPhotoList() {
    List<Widget> firstList = [];
    List<Widget> secondList = [];
    widget.resInfoList.forEachIndexed((index, element) {
      Widget img;
      if (index == 0) {
        img = GestureDetector(
          onTap: () {
            if (element[Security.security_unlocked] == 0) {
              _showUnlockDialog(element);
            } else {
              toViewer(element[Security.security_url] ?? '');
            }
          },
          child: element[Security.security_unlocked] == 0
              ? _buildLockedImage(element, 168.w, 168.w)
              : CachedImage.clipImage(
            imageUrl: element[Security.security_url] ?? '',
            width: 168.w,
            height: 168.w,
            borderRadius: BorderRadius.circular(16),
            fit: BoxFit.cover,
          ).marginOnly(bottom: 8),
        );
        firstList.add(img);
      } else {
        img = element[Security.security_type] == 2
            ? GestureDetector(
          onTap: () {
            if ((element[Security.security_unlocked] ?? 0) != 0) {
              Get.toNamed(Routers.videoPlayer, arguments: {Security.security_videoUrl: element[Security.security_url] ?? ''});
            } else {
              _showUnlockDialog(element);
            }
          },
          child: Container(
            height: 256.w,
            margin: const EdgeInsets.only(bottom: 8),
            child: (element[Security.security_unlocked] ?? 0) == 0
                ? _buildLockedImage(element, double.infinity, 256.w)
                : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: VideoFileView(url: element[Security.security_url] ?? '', thumbnailUrl: element[Security.security_thumbnailUrl] ?? '',),
            ),
          ),
        )
            : GestureDetector(
          onTap: () {
            if ((element[Security.security_unlocked] ?? 0) != 0) {
              toViewer(element[Security.security_url] ?? '');
            } else {
              _showUnlockDialog(element);
            }
          },
          child: (element[Security.security_unlocked] ?? 0) == 0
              ? _buildLockedImage(element, double.infinity, 256.w)
              : CachedImage.clipImage(
            imageUrl: element[Security.security_url] ?? '',
            height: 256.w,
            width: double.infinity,
            borderRadius: BorderRadius.circular(16),
            fit: BoxFit.cover,
          ).marginOnly(bottom: 8),
        );
        if (index % 2 == 0) {
          firstList.add(img);
        } else {
          secondList.add(img);
        }
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 64),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: firstList),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: secondList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedImage(Map resInfo, double width, double height) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: resInfo[Security.security_type] == 2
                  ? VideoFileView(url: resInfo[Security.security_url] ?? '', thumbnailUrl: resInfo[Security.security_thumbnailUrl] ?? '',)
                  : CachedImage(imageUrl: resInfo[Security.security_url] ?? '', width: width, height: height, fit: BoxFit.cover),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageView(resInfo[Security.security_costType] == 0 ? Images.security_coin_png : Images.security_gem_png, width: 24, height: 24),
                  const SizedBox(width: 4),
                  Text(
                    '${resInfo[Security.security_costValue]}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                height: 36,
                decoration: BoxDecoration(color: AppColors.ocMain, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, color: Colors.black, size: 16),
                    // ImageView(ImageNames.lock_icon, width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      ' Unlock',
                      style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(Map resInfo) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Copywriting.security_Unlock_this_photo,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.base_background),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Security.security_price,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.base_background),
                  ),
                  Row(
                    children: [
                      ImageView(resInfo[Security.security_costType] == 0 ? Images.security_coin_png : Images.security_gem_png, width: 20, height: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${resInfo[Security.security_costValue]}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.base_background),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Copywriting.security_Your_balance,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.base_background),
                  ),
                  Row(
                    children: [
                      ImageView(resInfo[Security.security_costType] == 0 ? Images.security_coin_png : Images.security_gem_png, width: 20, height: 20),
                      // ImageView(ImageNames.gems_icon, width: 20, height: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${resInfo[Security.security_costType] == 0 ? MyAccount.coins : MyAccount.gems}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.base_background),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          Security.security_cancel,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.undo),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        bool? unlockResult = await widget.unLockRes?.call(resInfo[Security.security_id], resInfo[Security.security_costValue], resInfo[Security.security_costType]);
                        if (unlockResult == true) {
                          setState(() {
                            resInfo[Security.security_unlocked] = 1;
                          });
                          Get.back();
                        }
                      },
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.ocMain, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          ' Unlock',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
