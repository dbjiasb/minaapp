import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/core/util/cached_image.dart';
import 'chat_theater_room_view.dart';

// 私聊底部栏状态枚举
enum PrivateChatBottomBarState {
  normal, // 普通输入状态
  voice, // 语音输入状态
  longPress, // 长按状态
  gift, // 礼物面板状态
  keyboard, // 键盘可见状态
  template, // 模板文本状态
  muse, // Muse状态
  empty, // 空状态
}

class ChatPrivateBottomBar extends StatelessWidget {
  final Function(String)? onSendText;

  const ChatPrivateBottomBar({super.key, this.onSendText});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatPrivateBottomBarController());
    controller.onSendTextCallback = onSendText;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F0F0F).withOpacity(0.0),
            const Color(0xFF0F0F0F).withOpacity(0.9),
          ],
        ),
      ),
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // 模板文本区域（快速回复）
            Obx(() => controller.state.value == PrivateChatBottomBarState.template
                ? _buildTemplateTexts(controller)
                : const SizedBox.shrink()),

            // 输入栏
            _buildInputBar(controller),

            SizedBox(height: 12.w),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ChatPrivateBottomBarController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      child: Container(
        height: 44.w,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: const Color(0xFF999999).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Row(
          children: [
            // 加号按钮（更多功能）
            GestureDetector(
              onTap: controller.onPlusButtonTapped,
              child: CachedImage(
                imageUrl: ImagePath.ic_send_theater, // 临时使用，后续替换为加号图标
                height: 24.w,
                width: 24.w,
              ),
            ),
            SizedBox(width: 8.w),

            // 文本输入框
            Expanded(
              child: TextField(
                cursorColor: Colors.white,
                onChanged: controller.onTextChanged,
                onSubmitted: controller.sendText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                controller: controller.textController,
                focusNode: controller.focusNode,
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                  fillColor: Colors.transparent,
                  filled: true,
                  hintText: Copywriting.security_send_message__reply_by_AI,
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: TextInputAction.send,
              ),
            ),

            SizedBox(width: 8.w),

            // 语音/发送按钮
            GestureDetector(
              onTap: () {
                if (controller.textController.text.isNotEmpty) {
                  controller.sendText(controller.textController.text);
                } else {
                  controller.onVoiceButtonTapped();
                }
              },
              child: CachedImage(
                imageUrl: controller.textController.text.isEmpty
                    ? ImagePath.ic_send_theater // 临时使用，后续替换为麦克风图标
                    : ImagePath.ic_send_theater,
                height: 28.w,
                width: 28.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateTexts(ChatPrivateBottomBarController controller) {
    return Column(
      children: controller.templateTexts.map((text) {
        return GestureDetector(
          onTap: () => controller.sendText(text),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.w),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF30292D).withOpacity(0.6),
              borderRadius: BorderRadius.circular(28.w),
              border: Border.all(width: 1, color: const Color(0xFFFFFBA3)),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFFFCFACD),
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ChatPrivateBottomBarController extends GetxController {
  late ChatTheaterRoomViewController roomViewController;
  late TextEditingController textController;
  final FocusNode focusNode = FocusNode();

  final Rx<PrivateChatBottomBarState> state = PrivateChatBottomBarState.normal.obs;
  final RxList<String> templateTexts = RxList();
  final RxBool isKeyboardVisible = false.obs;

  Function(String)? onSendTextCallback;

  @override
  void onInit() {
    super.onInit();
    try {
      roomViewController = Get.find<ChatTheaterRoomViewController>();
      textController = TextEditingController(text: roomViewController.session.draft.value);
    } catch (e) {
      textController = TextEditingController();
    }

    focusNode.addListener(() {
      isKeyboardVisible.value = focusNode.hasFocus;
      if (focusNode.hasFocus) {
        state.value = PrivateChatBottomBarState.keyboard;
      } else {
        state.value = PrivateChatBottomBarState.normal;
      }
    });
  }

  @override
  void onClose() {
    focusNode.dispose();
    textController.dispose();
    super.onClose();
  }

  void sendText(String text) {
    if (text.isEmpty) return;

    textController.clear();
    onTextChanged('');

    // 优先使用外部传入的回调
    if (onSendTextCallback != null) {
      onSendTextCallback!(text);
      return;
    }

    // 否则尝试使用roomViewController
    try {
      if (roomViewController.isGenerating()) {
        return;
      }
      roomViewController.sendText(text, specifyRepliers: null, bannedRepliers: null);
    } catch (e) {
      print('发送消息失败: $e');
    }
  }

  void onTextChanged(String text) {
    try {
      ChatSession s = roomViewController.session;
      s.draft.value = text;
      ChatManager.instance.updateChatSession(s);
    } catch (e) {
      // Session not available
    }
  }

  void onPlusButtonTapped() {
    // TODO: 显示更多功能面板（图片、礼物等）
    print(Copywriting.security_plus_button_tapped);
  }

  void onVoiceButtonTapped() {
    // TODO: 切换到语音输入状态
    state.value = PrivateChatBottomBarState.voice;
    print(Copywriting.security_voice_button_tapped);
  }
}
