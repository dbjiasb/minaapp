import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../crypt/copywriting.dart';
import '../crypt/security.dart';
import 'ad_service.dart';
import 'ad_utils.dart';

class MediaAdsButton extends StatefulWidget {
  final String assetId;
  final int sourceType;
  final VoidCallback? adPlayStart;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final Function(Map? adAwardRsp)? grantAdCallback;

  const MediaAdsButton(this.assetId, this.sourceType,
      {this.adPlayStart, this.width, this.height, this.margin,this.grantAdCallback, super.key});

  @override
  State<MediaAdsButton> createState() => _MediaAdsButtonState();
}

class _MediaAdsButtonState extends State<MediaAdsButton> {
  AdsUtils? adModUtils;

  void _tryShowAd() {
    widget.adPlayStart?.call();
    adModUtils ??= AdsUtils(
        widget.sourceType == 0
            ? AdsManager.lockImageAdBalance![Security.security_adConfig]!
            : AdsManager.lockVideoAdBalance![Security.security_adConfig]!,
        assetId: widget.assetId,
        grantAdCallback: widget.grantAdCallback);
    adModUtils?.showAd(adCompleteCallback: (adConfig) {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AdsManager.getEnableStatusResLockByType(widget.sourceType)
          ? InkWell(
              onTap: _tryShowAd,
              child: Container(
                width: widget.width,
                height: widget.height,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // color: Color(0xFF1FE08A),
                    gradient: const LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: [
                          Color(0xFF1FE08A),
                          Color(0xFF0FBF7A),
                        ])
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    const Icon(
                      Icons.video_library,
                      color: Colors.white,
                      size: 16,
                    ),
                    Text(
                      Copywriting.security_aD_Free,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ).marginOnly(left: 4, right: 4),
                    Container(
                      // alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${AdsManager.getResLockUseCount(widget.sourceType)}/${AdsManager.getResLockTotalCount(widget.sourceType)}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            )
          : Container();
    });
  }

  @override
  void dispose() {
    adModUtils?.releaseAd();
    super.dispose();
  }
}
