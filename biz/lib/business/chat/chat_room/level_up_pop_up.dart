import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:get/get.dart';

import '../../../base/assets/image_path.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/crypt/copywriting.dart';

class LevelUpPopUp extends StatelessWidget {
  final int level;
  String avatar = '';
  int rewardCoin = 0;
  int rewardGem = 0;
  Map? rewardMode;

  LevelUpPopUp({
    Key? key,
    required this.level,
    this.avatar = '',
    this.rewardCoin = 0,
    this.rewardGem = 0,
    this.rewardMode,
}) : super(key: key);

  static show({
    required int level,
    required String avatar,
    required int rewardCoin,
    required int rewardGem,
    required Map rewardMode,
  }) {
    Get.dialog(LevelUpPopUp(level: level, avatar: avatar, rewardCoin: rewardCoin, rewardGem: rewardGem, rewardMode: rewardMode), barrierDismissible: false, useSafeArea: false, barrierColor: Colors.black.withValues(alpha: 0.8));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.back();
      },
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 300, width: double.infinity, child: Stack(
              alignment: Alignment.center,
              children: [
                // Positioned.fill(child: SizedBox()),
                Positioned(
                    top: 0,
                    child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ImageView(
                      Images.security_level_up_webp,
                      width: 115,
                      height: 120,
                    ),
                    /// 字体渐变色
                    Positioned(
                        bottom: 20,
                        child: Text(
                          'Lv.$level',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: <Color>[
                                  Colors.white,
                                  Color(0xFFFDDD64),
                                ],
                              ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                          ),
                        )),
                  ],
                )),
                Positioned(
                    top: 108, left: 0, right: 0, height: 36,
                    child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFBD46).withValues(alpha: 0),
                        Color(0xFFFFBD46),
                        Color(0xFFFFBD46).withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Text(Copywriting.security_level_Up_, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                )),
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 254,
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    // height: 254, width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: ImageView.getImageProvider(Images.security_level_up_bg_webp),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ImageView(
                          Images.security_level_up_avatar_frame_webp,
                          width: 172,
                          height: 142,
                        ),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: CachedImage(imageUrl: avatar, width: 72, height: 72, fit: BoxFit.cover)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
            Text(Copywriting.security_your_reward, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 12,),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.withValues(alpha: 0.4),
                    // gradient: LinearGradient(
                    //   colors: [
                    //     Color(0xFFFFBD46).withValues(alpha: 0),
                    //     Color(0xFFFFBD46),
                    //     Color(0xFFFFBD46).withValues(alpha: 0),
                    //   ],
                    // ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ImageView(Images.security_coin_png, width: 36, height: 36,),
                    Text('x$rewardCoin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}