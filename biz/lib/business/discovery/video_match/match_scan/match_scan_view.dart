import 'package:biz/base/assets/image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';

import '../../../../base/crypt/copywriting.dart';
import '../../../../core/util/cached_image.dart';
import '../match_const.dart';
import 'match_scan_logic.dart';

class MatchScanPage extends GetView<MatchScanLogic> {
  const MatchScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await controller.cancelVideoMatch();
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedImageProvider('${MatchRes.base}ic_match_bg.png'), // 替换为你的图片路径
            fit: BoxFit.cover, // 图片填充整个屏幕
          ),
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: ImageView("back.png", fit: BoxFit.cover, width: 24, height: 24),
              onPressed: () {
                controller.cancelVideoMatch();
              },
            ),
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return _buildScanView();
  }

  Widget _buildScanView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: double.infinity, height: 375, child: SVGAEasyPlayer(resUrl: "${MatchRes.base}match_scan.svga", fit: BoxFit.fitHeight)),
        Text(Copywriting.security_invites_you_to_video_calling_, style: TextStyle(fontSize: 13, color: Colors.white)).marginOnly(top: 130),
      ],
    );
  }
}
