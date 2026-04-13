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
                margin: widget.margin,
                child: Stack(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF7CBC3C),
                                Color(0xFF61982A),
                              ])),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.video_call,
                            color: Colors.white,
                            size: 16,
                          ),
                          Text(
                            Copywriting.security_aD_Free,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ).marginOnly(left: 4)
                        ],
                      ),
                    ),
                    Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: const BoxDecoration(
                              color: Color(0xFF5D9B1E),
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(8))),
                          child: Text(
                            '${AdsManager.getResLockUseCount(widget.sourceType)}/${AdsManager.getResLockTotalCount(widget.sourceType)}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                        ))
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
