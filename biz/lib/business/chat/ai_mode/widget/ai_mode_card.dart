import 'package:biz/base/crypt/routes.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:biz/base/assets/image_path.dart';

import '../../../../base/assets/image_view.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../core/util/cached_image.dart';
import '../service/ai_mode_service.dart';
import 'package:flip_card/flip_card.dart';
import 'ai_mode_popup.dart';

class AiModeCard extends StatefulWidget {
  Map curMode;
  bool isAutoPlay;
  bool needUpdate;
  bool needBuyBtn;

  AiModeCard(this.curMode, {super.key, this.isAutoPlay = false, this.needUpdate = false, this.needBuyBtn = true});

  Future show() {
    return Get.dialog(this, barrierColor: Colors.black.withOpacity(0.8));
  }

  @override
  State<StatefulWidget> createState() {
    return AiModeCardState();
  }
}

class AiModeCardState extends State<AiModeCard> {
  Map get curMode => widget.curMode;

  bool get isAutoPlay => widget.isAutoPlay;

  Widget _buildFontAiItem(Map aiPersonality, FlipCardController controller) {
    return GestureDetector(
      onTap: () {
        controller.toggleCard();
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            child: CachedImage(imageUrl: aiPersonality[ES.sb] ?? aiPersonality[ES.cb] ?? "", height: double.infinity, width: double.infinity),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 32.w, top: 16.w),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
                gradient: LinearGradient(
                  colors: [Color(0x002D2D2F), Color(0xFF2D2D2F)],
                  // 渐变色数组
                  begin: Alignment.topCenter,
                  // 渐变起始点
                  end: Alignment.bottomCenter,
                  // 渐变结束点
                  stops: [0.0, 1.0],
                  // 渐变颜色的分布位置
                  tileMode: TileMode.clamp, // 渐变模式
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    aiPersonality[Security.security_name] ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, decoration: TextDecoration.none),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => ImageView(index < (aiPersonality[Security.security_star]?[Security.security_star] ?? 1) ? "mode_star_light.webp" : "mode_star_unlight.webp", width: 18, height: 18)),
                  ),
                  Text(
                    aiPersonality[Security.security_desc] ?? "",
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
                  ).marginOnly(top: 8),
                ],
              ),
            ),
          ),
          Positioned.fill(child: ImageView("mode_frame.webp", fit: BoxFit.fill)),
          Positioned(top: 32, left: 20, child: ImageView("mode_flip.webp", height: 32, width: 32, fit: BoxFit.cover)),
          if ((aiPersonality[ES.tagURL] ?? '').isNotEmpty)
            Positioned(
              right: 5,
              top: 5,
              width: 108,
              height: 54,
              child: CachedImage(imageUrl: aiPersonality[ES.tagURL]!, fit: BoxFit.fitWidth, width: 60, height: 30),
            ),
        ],
      ),
    );
  }

  Widget _buildBackAiItem(Map aiPersonality, FlipCardController controller) {
    return GestureDetector(
      onTap: () {
        controller.toggleCard();
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(color: Color(0xFF5F2F80), borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          Positioned.fill(child: ImageView("mode_frame.webp", fit: BoxFit.fill)),
          Positioned(
            top: 40,
            left: 24.w,
            right: 24.w,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(image: DecorationImage(image: ImageView.getImageProvider("mode_about_bg.webp"))),
                  child: Text(
                    Copywriting.security_about_Me,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.none),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  aiPersonality[Security.security_name] ?? "",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, decoration: TextDecoration.none),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => ImageView(index < (aiPersonality[Security.security_star]?[Security.security_star] ?? 1) ? "mode_star_light.webp" : "mode_star_unlight.webp", width: 18, height: 18)),
                ),
                SizedBox(height: 12),
                Text(
                  aiPersonality[ES.dd] ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
                ).marginOnly(top: 8),
              ],
            ),
          ),
          Positioned(top: 32, left: 20, child: ImageView("mode_flip.webp", height: 32, width: 32, fit: BoxFit.cover)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.needUpdate) updateMode();
    final FlipCardController controller = FlipCardController();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 450.w,
          width: 252.w,
          child: FlipCard(
            fill: Fill.fillBack,
            // Fill the back side of the card to make in the same size as the front.
            direction: FlipDirection.HORIZONTAL,
            // default
            side: isAutoPlay ? CardSide.BACK : CardSide.FRONT,
            autoFlipDuration: isAutoPlay ? const Duration(milliseconds: 500) : null,
            controller: controller,
            // The side to initially display.
            front: _buildFontAiItem(curMode, controller),
            back: _buildBackAiItem(curMode, controller),
          ),
        ),
        const SizedBox(height: 20),
        Text(curMode[ES.cName] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.none)),
        if (widget.needBuyBtn) const SizedBox(height: 20),
        if (widget.needBuyBtn) buildActionBtn(),
      ],
    );
  }

  Widget buildActionBtn() {
    bool hasDiscount = curMode[ES.dp] > 0 && curMode[ES.dp] < curMode[Security.security_price];
    return GestureDetector(
      onTap: () {
        buyMode(curMode);
      },
      child: Container(
        alignment: Alignment.center,
        height: 44,
        width: 200,
        decoration: curMode[Security.security_own] == 0 ? BoxDecoration(image: DecorationImage(image: ImageView.getImageProvider("mode_buy.webp"), fit: BoxFit.fill)) : null,
        child:
            curMode[Security.security_own] == 0
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ImageView(curMode[Security.security_currencyType] == 0 ? "coin.png" : "gem.png", width: 10, height: 10),
                        const SizedBox(width: 2),
                        Text(
                          '${hasDiscount ? curMode[ES.dp] : curMode[Security.security_price]}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                        ),
                      ],
                    ),
                    if (hasDiscount)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ImageView(curMode[Security.security_currencyType] == 0 ? "coin.png" : "gem.png", width: 10, height: 10),
                          const SizedBox(width: 1),
                          Text(
                            '${curMode[Security.security_price]}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, decoration: TextDecoration.lineThrough, height: 1),
                          ),
                        ],
                      ),
                  ],
                )
                : Text(Security.security_owned, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
      ),
    );
  }

  Future buyMode(Map mode) async {
    bool ret = await AIModeService.instance.payForAIMode(mode);
    if (ret) {
      mode[Security.security_own] = 1;

      Get.back();

      AIModePopup.show(mode);
      // setState(() {
      //   mode.own = 1;
      // });
    }
  }

  Future updateMode() async {
    widget.needUpdate = false;
    AIModeService.instance
        .batchQueryModes(curMode.uid, curMode[Security.security_id] ?? '')
        .then((rsp) {
          setState(() {
            if (rsp?[ES.modes]?.first != null) widget.curMode = rsp![ES.modes]!.first;
          });
        })
        .catchError((e) {});
  }
}
