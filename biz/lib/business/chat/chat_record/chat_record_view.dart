import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/shared/widget/keep_alive_wrapper.dart';
import 'package:biz/shared/widget/title_bar.dart';

import '../../../shared/app_theme.dart';
import '../chat_room_cells/chat_message.dart';
import './chat_category_view.dart';

class ChatHistoryModel {
  ChatMessageType type;
  String typeName;
  Widget Function() builder;

  ChatHistoryModel(this.type, this.typeName, this.builder);
}

class ChatRecordView extends StatelessWidget {
  ChatRecordView({super.key});

  final ChatRecordViewController controller = Get.put(ChatRecordViewController());

  List<ChatHistoryModel> models = [
    ChatHistoryModel(ChatMessageType.image, Security.security_Photos, () => KeepAliveWrapper(child: ChatCategoryView(category: ChatMessageType.image))),
    ChatHistoryModel(ChatMessageType.video, Security.security_Videos, () => KeepAliveWrapper(child: ChatCategoryView(category: ChatMessageType.video))),
  ];

  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final tabBars = StyleTabBars(
      titles: models.map((e) => e.typeName).toList(),
      onTabSelected: (index) {
        pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.linearToEaseOut);
      },
    );
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
              // color: Colors.blue,
              alignment: Alignment.center, child: ImageView("back.png", width: 24, height: 24)),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        // leadingWidth: 44,
        title: Container(
          alignment: Alignment.center,
          // color: Colors.red,
          child: SizedBox(width: 130, child: tabBars,),
        ),
        actions: [
          SizedBox(width: 44, height: 24)
        ],
      ),
      body: PageView.builder(
        itemBuilder: (context, index) {
          return models[index].builder();
        },
        itemCount: models.length,
        controller: pageController,
        onPageChanged: (int index) {
          tabBars.switchToTab(index);
        },
      ),
    );
  }
}

class ChatRecordViewController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
