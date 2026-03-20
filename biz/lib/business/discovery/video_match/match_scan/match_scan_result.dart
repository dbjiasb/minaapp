import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/report/report_manager.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../base/crypt/security.dart';
import '../../../../base/router/route_helper.dart';
import 'match_scan_logic.dart';

class MatchScanResultPage extends GetView<MatchScanLogic> {
  MatchScanResultPage({Key? key}) : super(key: key);

  late Map callNotice;

  @override
  Widget build(BuildContext context) {
    initArguments();
    ReportManager.sendEvent(Security.security_pv_user_user_video_match_result, {});
    return WillPopScope(
      onWillPop: () async {
        await controller.cancelAndRejectVideoMatch(callNotice[Security.security_callId]);
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFF12151C),
        appBar: AppBar(
          backgroundColor: Color(0xFF12151C),
          elevation: 0,
          leading: IconButton(
            icon: ImageView(Images.security_back_png, fit: BoxFit.fill),
            onPressed: () {
              controller.cancelAndRejectVideoMatch(callNotice[Security.security_callId]);
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  void initArguments() {
    if (Get.arguments is Map) {
      callNotice = (Get.arguments as Map);
    }
  }

  Widget _buildBody() {
    return _buildMatchResult();
  }

  Widget _buildMatchResult() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8FDF), Color(0xFFFF56BB)],
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
            child: Stack(
              children: [
                Positioned.fill(child: CachedImage(imageUrl: callNotice[Security.security_backgroudUrl] ?? '', borderRadius: BorderRadius.circular(12))),
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Text(
                    callNotice[Security.security_fromNick] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Get.back();
            ReportManager.sendEvent(Security.security_click_user_match_video, {Security.security_action: Security.security_acceptMatch});
            RH.toCall({
              Security.security_targetUid: callNotice[Security.security_fromUid],
              Security.security_targetName: callNotice[Security.security_fromNick] ?? '',
              Security.security_targetAvatar: callNotice[Security.security_fromAvatar] ?? '',
              Security.security_isCallOut: true,
              Security.security_type: callNotice[Security.security_audio] ?? 1,
              Security.security_autoAnswer: false,
            });
          },
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(left: 16, right: 16, top: 20),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Color(0xFFFF56BB), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  // child: SVGAEasyPlayer(
                  //   assetsName:
                  //       'packages/app_common/assets/svga/match_video.svga',
                  // ),
                ),
                SizedBox(width: 8),
                Text(Security.security_accept, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            ReportManager.sendEvent(Security.security_click_user_match_video, {Security.security_action: Security.security_nextMatch});
            controller.rejectAndStartMatch(callNotice[Security.security_callId]);
          },
          child: Text(Security.security_next, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)).marginOnly(bottom: 40, top: 20),
        ),
      ],
    );
  }
}
