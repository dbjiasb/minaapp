import 'package:biz/base/crypt/images.dart';
import 'dart:math';

import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../../base/api_service/api_response.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/report/report_manager.dart';
import '../../../core/account/account_service.dart';
import '../chat_room/chat_room_view.dart';

class GenerateVideoDialog extends StatelessWidget {
  GenerateVideoDialog({super.key});

  static Future show(int? cost, int? costType, List<Map>? settingTags, {String? prompt, int? msgId, String? imageUrl}) async {
    if (cost == null || costType == null) return;

    Get.put(
      GenerateVideoController()
        ..cost.value = cost
        ..costType.value = costType
        ..settingTags = settingTags ?? []
        ..promptTextFileController.text = prompt ?? ""
        ..msgId = msgId
        ..imageUrl = imageUrl
        ..showSettingsPart = settingTags?.isNotEmpty ?? false,
    );
    return await Get.dialog(
      Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Container(alignment: Alignment.bottomCenter, child: GenerateVideoDialog()),
      ),
    ).then((_) {
      Get.delete<GenerateVideoController>();
    });
  }

  final GenerateVideoController controller = Get.find<GenerateVideoController>();

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Container(
      width: 375.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(24.w), topRight: Radius.circular(24.w)), color: Color(0xFF202028)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Center(child: Text(Copywriting.security_generate_Video, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.w)))),
              GestureDetector(onTap: Get.back, child: ImageView(Images.security_ic_close_png, width: 22, height: 22)),
            ],
          ),
          16.w.verticalSpace,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            width: double.infinity,
            height: 132.w,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withValues(alpha: 0.05)),
            child: TextField(
              controller: controller.promptTextFileController,
              maxLines: 10,
              onSubmitted: (value) {
                try {
                  FocusScope.of(Get.context!).unfocus();
                } catch (e) {}
              },
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: Preferences.instance.generateVideoPromptHints,
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Color(0xFF636268), fontSize: 11, fontWeight: FontWeight.w500),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          12.w.verticalSpace,
          InkWell(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            onTap: () {
              controller.aiWriterPrompt();
            },
            child: Row(
              children: [
                ImageView(Images.security_tip_on_png, width: 16.w, height: 16.w),
                4.w.horizontalSpace,
                Text(
                  Copywriting.security_aI_Writer,
                  style: TextStyle(fontSize: 11.w, color: Color(0xFFABABAD), fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),

          if (controller.showSettingsPart)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                24.w.verticalSpace,

                Text(Security.security_settings, style: TextStyle(fontSize: 14.w, color: Colors.white, fontWeight: FontWeight.bold)),

                for (var selectItem in controller.settingTags) _buildSettingSelector(selectItem).marginOnly(top: 10),
              ],
            ),

          80.w.verticalSpace,

          Spacer(),
          GestureDetector(
            onTap: () async {
              controller.generateVideo();
            },
            child: Container(
              width: double.infinity,
              height: 56.w,
              decoration: BoxDecoration(color: Color(0xFF8761F1), borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Security.security_generate, style: TextStyle(fontSize: 16.w, fontWeight: FontWeight.bold, color: Colors.white)),
                  Obx(() => Text(controller.costString, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11.sp, color: Colors.white))),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSettingSelector(Map tag) {
    String selectKey = Security.security_selectItem;
    RxMap rxTag = tag.obs;
    String fristTagDes = tag[Security.security_subGroups][0][Security.security_tags][0][Security.security_desc];
    rxTag[selectKey] = fristTagDes; //默认选第一个
    tag[selectKey] = fristTagDes;

    return Row(
      children: [
        Text(tag[Security.security_typeDesc], style: TextStyle(fontSize: 12.w, color: const Color(0xFFABABAD), fontWeight: FontWeight.bold)),
        const Spacer(),
        Obx(
          () => CupertinoSlidingSegmentedControl<String>(
            padding: EdgeInsets.all(4.w),
            thumbColor: const Color(0xFF8761F1),
            groupValue: rxTag[selectKey],
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            onValueChanged: (value) {
              if (value != null) {
                rxTag[selectKey] = value;
                tag[selectKey] = value;
              }
            },
            children: {
              for (var subItem in tag[Security.security_subGroups][0][Security.security_tags])
                subItem[Security.security_desc]: Container(
                  height: 36.w,
                  width: 70.w,
                  alignment: Alignment.center,
                  child: Text("${subItem[Security.security_desc]}", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                ),
            },
          ),
        ),
      ],
    );
  }
}

class GenerateVideoController extends GetxController {
  final promptTextFileController = TextEditingController();
  final roomViewController = Get.find<ChatRoomViewController>();
  String reportKey = Security.security_video_generate_click;

  int get userId => roomViewController.userId;

  RxInt cost = 15.obs;
  RxInt costType = 0.obs;

  List<Map> settingTags = [];
  bool showSettingsPart = true;
  int? msgId;
  String? imageUrl;

  String get costString => "$cost ${costType.value == 0 ? Security.security_Coins : Security.security_Gems}";

  generateVideo() async {
    List tags = [];
    for (var tag in settingTags) {
      String selectSubTagDes = tag[Security.security_selectItem];
      for (var childItem in tag[Security.security_subGroups][0][Security.security_tags]) {
        if (childItem[Security.security_desc] == selectSubTagDes) {
          tags.add(childItem);
        }
      }
    }

    Map params = {Security.security_tId: "${MyAccount.userId}", Security.security_toUid: userId};
    var prompt = promptTextFileController.text;
    if (prompt.isEmpty) {
      Toast.show(Copywriting.security_please_input_description);
      return;
    }

    params[Security.security_prompt] = prompt;

    // if (msgId != null) {
    //   params[Security.security_msgId] = msgId;
    // }

    if (imageUrl != null) {
      params[Security.security_url] = imageUrl;
    }

    if (tags.isNotEmpty) {
      params[Security.security_tags] = tags;
    }

    Toast.loading();

    if (msgId != null) {
      ReportManager.sendEvent(reportKey, {Security.security_type: Security.security_message, Security.security_msgId: "$msgId"});
    } else if (imageUrl != null) {
      ReportManager.sendEvent(reportKey, {Security.security_type: Security.security_image});
    } else {
      ReportManager.sendEvent(reportKey, {Security.security_type: Security.security_text});
    }

    ApiResponse rsp = await roomViewController.requestGenerateVideo(params);
    EventCenter.instance.sendEvent(Security.security_kRequestGenerateVideoSuccess,{});
    Toast.dismiss();

    if (rsp.data[Security.security_statusInfo]?[Security.security_code] == 0) {
      roomViewController.getAskVideoConfig();

      Get.until((route) => route.settings.name == Routers.chat);
    } else {
      Toast.show(rsp.data[Security.security_statusInfo]?[Security.security_msg]);
    }
  }

  void aiWriterPrompt() {
    List prompts = Preferences.instance.generateVideoPrompts;
    int index = Random().nextInt(prompts.length);
    promptTextFileController.text = prompts[index];
  }
}
