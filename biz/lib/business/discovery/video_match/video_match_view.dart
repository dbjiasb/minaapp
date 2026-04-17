import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/report/report_manager.dart';
import 'package:biz/business/chat/call/call_manager.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/router/route_helper.dart';
import '../../../base/webview/web_view.dart';
import '../services/match_service.dart';
import 'match_const.dart';
import 'match_task/match_task_view.dart';
import 'video_match_logic.dart';

class VideoMatchView extends GetView<VideoMatchLogic> {
  const VideoMatchView({super.key});

  @override
  VideoMatchLogic get controller => Get.put(VideoMatchLogic());

  @override
  Widget build(BuildContext context) {
    ReportManager.sendEvent(Security.security_pv_user_user_video_match, {});
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedImageProvider(MatchRes.base + Images.security_ic_match_bg_png), // 替换为你的图片路径
          fit: BoxFit.cover, // 图片填充整个屏幕
        ),
      ),
      child: Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, toolbarHeight: 0),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      SVGAEasyPlayer(resUrl: MatchRes.base + 'match_anchor_list.svga', fit: BoxFit.fitHeight),
                      Container(
                        alignment: Alignment.center,
                        child: Obx(() {
                          return SizedBox(
                            width: 200.w,
                            height: 280.w,
                            child:
                                MatchService.to.avatarUrlPlaceHolders.isNotEmpty
                                    ? AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      // 淡入淡出动画时间
                                      transitionBuilder: (Widget child, Animation<double> animation) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                      child: _buildCardItem(MatchService.to.avatarUrlPlaceHolders[controller.currentIndex.value] ?? ''),
                                    )
                                    : Container(),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                // _buildGetFreeCardView(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: double.infinity, height: 80, child: SVGAEasyPlayer(resUrl: MatchRes.base + 'ic_match_bnt.svga', fit: BoxFit.fitHeight)),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 70,
                      right: 70,
                      child: GestureDetector(
                        onTap: () {
                          controller.tryStartMatch();
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(Copywriting.security_start_Match, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Obx(() {
                                return CallManager.instance.isFreeCall
                                    ? Text(
                                      'Get ${CallManager.instance.freeCallMinutes} minutes Free Call Trial',
                                      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                                    )
                                    : Container();
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ).marginOnly(top: 20),
                // if (Preferences.instance.callGiftUrl.isNotEmpty || CallManager.instance.isFreeCall) _buildVideoBalanceView(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(String? url) {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC370F2), Color(0xFFF570CB)],
          // 渐变色数组
          begin: Alignment.topCenter,
          // 渐变起始点
          end: Alignment.bottomCenter,
          // 渐变结束点
          stops: [0.0, 1.0],
          // 渐变颜色的分布位置
          tileMode: TileMode.clamp, // 渐变模式
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CachedImage(
        imageUrl: url ?? '',
        borderRadius: BorderRadius.circular(16),
        width: 200.w,
        height: 280.w,
        // useOldImageOnUrlChange: true,
        errorWidget: (context, url, error) {
          return Container();
        },
        placeholder: (context, url) {
          return Container();
        },
      ),
    );
  }

  Widget _buildGetFreeCardView() {
    return Obx(() {
      return MatchService.to.isShowMatchTask
          ? GestureDetector(
            onTap: () {
              MatchTaskView.showMatchTask();
            },
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    '',
                    // package: Security.security_app_common,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 4),
                  Text(Copywriting.security_get_30s_Free_Trial, style: TextStyle(color: Color(0xFFDCC3FF), fontSize: 13)),
                  const SizedBox(width: 4),
                  ImageView(Images.security_arrow_right_png, width: 16, height: 16, fit: BoxFit.cover, color: const Color(0xFFDCC3FF)),
                ],
              ),
            ),
          )
          : const SizedBox(height: 32);
    });
  }

  Widget _buildVideoBalanceView() {
    return GestureDetector(
      onTap: () {
        String url = Preferences.instance.callGiftUrl;
        if (url.isNotEmpty) {
          ReportManager.sendEvent(Security.security_click_match_call_offer, {});
          WebView.showWeb(url);
        } else {
          RH.toGems();
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(Copywriting.security_currently_owns_, style: TextStyle(color: Color(0xFFDCC3FF), fontSize: 13)),
          Obx(() {
            return Text(" x${CallManager.instance.freeCallMinutes}  ", style: const TextStyle(color: Color(0xFFDCC3FF), fontSize: 13));
          }),
        ],
      ).marginOnly(top: 20),
    );
  }
}
