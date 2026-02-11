import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/core/util/collections_util.dart';

import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/crypt/security.dart';
import 'chat_theater_room_view.dart';

enum ChatRoomBottomBarState { simple, detailed, muse, gift }

class ChatTheaterBottomBar extends StatelessWidget {
  ChatTheaterBottomBar({super.key, this.sendText});

  final Function? sendText;

  ChatTheaterBottomBarController viewController = Get.put(ChatTheaterBottomBarController());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F0F0F).withValues(alpha: 0.0), Color(0xFF0F0F0F).withValues(alpha: 0.9)],
            ),
          ),
          child: SafeArea(
            bottom: true,
            child: Column(
              children: [
                buildTemplateTexts(),
                Obx(() => viewController.isShowInputBar ? buildInputBar() : SizedBox.shrink()),
                buildFunctionRow().marginOnly(top: 8, bottom: 12),
                if (Platform.isAndroid) SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTemplateTexts() {
    return Obx(
      () =>
          viewController.isShowTemplateText
              ? Column(spacing: 10, children: viewController.templateTexts.map((text) => buildTemplateTextItem(text)).toList())
              : SizedBox.shrink(),
    );
  }

  Widget buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onLongPressMoveUpdate: null,
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Color(0xFF999999).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.white,
                        onChanged: (value) {
                          viewController.onTextChanged(value);
                        },
                        onSubmitted: (value) {
                          viewController.sendText(value);
                        },
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        controller: viewController.textController,
                        focusNode: viewController.focusNode,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                          fillColor: Colors.transparent,
                          filled: true,
                          hintText: Copywriting.security_send_message__reply_by_AI,
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600, fontSize: 11),
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        viewController.sendText(viewController.textController.text);
                      },
                      child: Image.asset(ImagePath.ic_send_theater, height: 28, width: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTemplateTextItem(String text) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            viewController.sendText(text);
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF30292D).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(width: 1, color: Color(0xFFFFFBA3)),
            ),
            height: 56,
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(width: 0.5, color: Color(0xFFFFFBA3).withValues(alpha: 0.3)),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerLeft,
                child: Text(text, style: TextStyle(color: Color(0xFFFCFACD), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        Positioned(left: 12, child: Image.asset(ImagePath.ic_theater_template_text_star, height: 24, width: 24)),
        Positioned(bottom: 0, right: 12, child: Image.asset(ImagePath.ic_theater_template_text_star, height: 24, width: 24)),
      ],
    );
  }

  Widget buildFunctionItem(String name, String? icon, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) Image.asset(icon, height: 16, width: 16),
          if (icon != null) SizedBox(width: 4),
          Text(name, style: TextStyle(color: Color(0xFFB1AEAC), fontSize: 12)),
        ],
      ),
    );
  }

  Widget buildFunctionRow() {
    return Obx(
      () => Row(
        children: [
          SizedBox(width: 16),

          buildFunctionItem(viewController.isHideView.value ? "Show" : "Hide", ImagePath.ic_theater_hide, viewController.toggleHide),

          SizedBox(width: 24),

          if (!viewController.isHideView.value)
            buildFunctionItem(viewController.isReview.value ? "Back" : "Review", ImagePath.ic_theater_review, viewController.toggleReview),

          Spacer(),

          if (viewController.isShowEnter)
            viewController.isEnter.value
                ? buildFunctionItem("Quick", ImagePath.ic_theater_quick, viewController.toggleEnter)
                : buildFunctionItem("Enter", ImagePath.ic_theater_enter, viewController.toggleEnter),

          if (viewController.isShowContinue) buildFunctionItem("Tap to continue...", null, viewController.tapContinue),

          SizedBox(width: 16),
        ],
      ),
    );
  }
}

class ChatTheaterBottomBarController extends GetxController {
  final roomViewController = Get.find<ChatRoomViewController>();
  late TextEditingController textController;
  final FocusNode focusNode = FocusNode();

  final RxList<String> templateTexts = RxList();
  final RxBool isReview = false.obs;
  final RxBool isEnter = false.obs;
  final RxBool isHideView = false.obs;
  final RxBool isKeyboardVisible = false.obs;

  bool get isShowContinue => roomViewController.storyMessageIndex.value > 0 && !isReview.value;

  bool get isShowTemplateText => !isEnter.value && !isHideView.value && templateTexts.isNotEmpty && !isReview.value && !isShowContinue;

  bool get isShowInputBar => isEnter.value && !isHideView.value && !isReview.value && !isShowContinue;

  bool get isShowEnter => !isHideView.value && !isReview.value && !isShowContinue;

  @override
  void onInit() {
    super.onInit();
    textController = TextEditingController(text: roomViewController.session.draft.value);
    focusNode.addListener(() {
      isKeyboardVisible.value = focusNode.hasFocus;
    });
    requestTemplateText();
  }

  @override
  void onClose() {
    focusNode.dispose();
    textController.dispose();
    super.onClose();
  }

  void sendText(String text) {
    if (text.isEmpty) return;
    if (roomViewController.isGenerating()) {
      return;
    }
    textController.clear();
    onTextChanged('');
    roomViewController.sendText(text, specifyRepliers: null, bannedRepliers: null);
  }

  void onTextChanged(String text) {
    ChatSession s = roomViewController.session;
    s.draft.value = text;
    ChatManager.instance.updateChatSession(s);
  }

  void toggleHide() => isHideView.value = !isHideView.value;

  void toggleReview() => isReview.value = !isReview.value;

  void toggleEnter() => isEnter.value = !isEnter.value;

  Future<void> requestTemplateText() async {
    Map params = {"targetUid": roomViewController.userId, "chatTo": roomViewController.userId, "targetAccountStatus": 2};
    ApiResponse rsp = await ApiService.instance.sendRequest(ApiRequest(Apis.security_queryInspirationWords, params: params));
    List rawData = rsp.data[Security.security_options] ?? [];
    List<Map> dataList = rawData.cast<Map>().safeSublist(0, 2);
    if (dataList.isNotEmpty) {
      templateTexts.clear();
    }
    for (var item in dataList) {
      String text = item["text"] ?? "";
      if (text.isNotEmpty) {
        templateTexts.add(text);
      }
    }
  }

  void tapContinue() {
    if (roomViewController.storyMessageIndex.value > 0) {
      roomViewController.storyMessageIndex.value--;
    }
  }
}
