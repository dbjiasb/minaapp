import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/router/route_helper.dart';

import '../../../../base/assets/image_view.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../base/router/router_names.dart';
import '../my_mode/binding.dart';
import 'ai_mode_card.dart';
import '../service/ai_mode_service.dart';

class AIModePopup extends StatelessWidget {

  Map curMode;
  bool showDetail;
  bool isNew;
  bool showToChat;

  AIModePopup(this.curMode, {this.showDetail = false, this.isNew = true, this.showToChat = true, super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: IntrinsicHeight(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () {
                      Get.back();
                    },
                  ).marginOnly(left: 24)
                ],
              ),
              if (isNew) ImageView(Images.security_mode_get_new_webp, height: 60, fit: BoxFit.fitHeight),
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(30))
                  ),
                  child: AiModeCard(
                    curMode,
                    isAutoPlay: true,
                    needBuyBtn: false,
                  )
              ),
              if (showToChat) InkWell(
                  onTap: () {
                    // logic.switchAiPersonality(aiPersonality);
                    changeMode();
                  },
                  child: drawChangeButton(curMode).marginOnly(top: 12)
              ),
              if (showToChat) InkWell(
                onTap: () {
                  RouteHelper.back();
                  RouteHelper.toPage(Routers.modeList, params: {Security.security_uid: '${curMode[ES.tuid]}', Security.security_defaultId: '${curMode[Security.security_id]}'});
                  // toModePage(aiPersonality.targetUid, selectedId: aiPersonality.id ?? "");
                },
                child: Text(curMode[Security.security_selected] == 0 ? Copywriting.security_take_a_look__ : Copywriting.security_try_it,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      decoration: TextDecoration.underline),
                ).marginOnly(top: 16),
              )
            ],
          ),
        ),
      ),
    );
  }

  static Widget drawChangeButton(Map aiPersonality) {
    return Stack(
      alignment: Alignment.center,
      children: [
        aiPersonality[Security.security_selected] == 0 ?  ImageView(
          Images.security_mode_buy_webp,
          width: 184.w,
          height: 44.w
        ) : Container(
          width: 168.w,
          height: 44.w,
          decoration: BoxDecoration(
              color: Color(0xFF351355),
              borderRadius: BorderRadius.circular(8.w),
            ),
        ),
        Text(
          aiPersonality[Security.security_selected] == 1 ? Copywriting.security_in_Use.tr : Copywriting.security_switch_to_Chat.tr,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        )
      ],
    );
  }

  static Future<void> show(Map curMode, {bool showDetail = false, bool isNew = true, bool showToChat = true}) {
    return Get.dialog(
        AIModePopup(curMode, showDetail: showDetail, isNew: isNew, showToChat: showToChat),
        barrierColor: Colors.black.withValues(alpha: 0.8),
    );
  }

  void changeMode() async {
    /// 暂时不跳转聊天界面，会有bug
    if (curMode[Security.security_selected] == 1) return;
    await AIModeService.instance.changeAIMode(curMode);
  }
}
