import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/business/chat/chat_room_cells/chat_image_message.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../../base/assets/image_path.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../shared/app_theme.dart';
import '../chat_manager.dart';
import '../chat_room_cells/chat_message.dart';

class ChatHistoryImageSelectView extends GetView<ChatHistoryImageSelectController> {
  const ChatHistoryImageSelectView({super.key});

  static Future<dynamic> toChatImgHistorySelect(String sessionId, List<Map> resInfoList) async {
    return await Get.to(() => ChatHistoryImageSelectView(), binding: ChatHistoryImageSelectBinding(sessionId, resInfoList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            // color: Colors.blue,
            alignment: Alignment.center,
            child: ImageView(Images.security_back_png, width: 24, height: 24),
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        // leadingWidth: 44,
        title: Text(Security.security_photo, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                if (!controller.selectedImageEmpty) {
                  Get.back(result: controller.selectedResInfoList);
                }
              },
              child: Obx(
                () => Text(
                  Security.security_select,
                  style: TextStyle(color: controller.selectedImageEmpty ? Colors.white : AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(
        () => GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: controller.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 109 / 168,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            // crossAxisSpacing: double.infinity
          ),
          itemBuilder: (BuildContext context, int index) {
            ChatImageMessage msg = controller.items[index];
            return Obx(() {
              return GestureDetector(
                onTap: () async {
                  controller.toggleSelect(msg.imageUrl);
                },
                child: _buildImageItem(msg),
              );
            });
          },
        ),
      ),
    );
  }

  _buildImageItem(ChatImageMessage msg) => Stack(
    alignment: Alignment.topRight,
    children: [
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetImage(imageUrl: msg.imageUrl, height: 300, width: 204, fit: BoxFit.cover)),
      ),
      ImageView(
        controller.selectedResInfoList.indexWhere((element) => element[Security.security_url] == msg.imageUrl) >= 0
            ? Images.security_ic_check_png : Images.security_ic_uncheck_png,
        height: 24,
        width: 24,
      ),
    ],
  );
}

class ChatHistoryImageSelectBinding extends Bindings {
  final String sessionId;
  final List<Map> resInfoList;

  ChatHistoryImageSelectBinding(this.sessionId, this.resInfoList);

  @override
  void dependencies() {
    Get.lazyPut<ChatHistoryImageSelectController>(() => ChatHistoryImageSelectController(sessionId, resInfoList));
  }
}

class ChatHistoryImageSelectController extends GetxController {
  String sessionId;
  List<Map> initResInfoList;
  RxList selectedResInfoList = RxList<Map>();
  RxList items = RxList<ChatImageMessage>();

  bool get selectedImageEmpty => selectedResInfoList.isEmpty;

  ChatHistoryImageSelectController(this.sessionId, this.initResInfoList);

  @override
  void onInit() {
    selectedResInfoList = initResInfoList.obs;
    getMessages();
    super.onInit();
  }

  toggleSelect(String imageUrl) {
    bool isContain = selectedResInfoList.firstWhereOrNull((e) => imageUrl == e[Security.security_url]) != null;
    if (isContain) {
      selectedResInfoList.removeWhere((e) => imageUrl == e[Security.security_url]);
    } else {
      if (selectedResInfoList.length >= 9) {
        Toast.show(Copywriting.security_maximum_limit_exceeded);
      } else {
        selectedResInfoList.add({Security.security_type: 1, Security.security_url: imageUrl});
      }
    }
  }

  void getMessages() async {
    List<ChatMessage> messages = await ChatManager.instance.messageHandler.queryMessages(sessionId, types: [ChatMessageType.image.value]);
    items.value = messages.cast<ChatImageMessage>();
  }
}
