
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/shared/widget/list_status_view.dart';

import '../chat_manager.dart';
import 'chat_theater_room_view.dart';

class ChatMuseView extends StatelessWidget {
  Function? sendText;
  ChatMuseView({super.key, required this.sendText});

  ChatMuseViewController viewController = Get.put(ChatMuseViewController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SafeArea(
        bottom: true,
        child: Container(
          height: 200,
          padding: EdgeInsets.all(12),
          child: Obx(
            () => Stack(
              children: [
                ListView.separated(
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        sendText?.call(viewController.items[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(color: Color(0xff000000).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            viewController.items[index],
                            style: TextStyle(color: Color(0xFFC4AFFF), fontWeight: FontWeight.w600, fontSize: 11, height: 1.8),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  itemCount: viewController.items.length,
                ),
                ListStatusView(status: viewController.listStatus.value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMuseViewController extends GetxController {
  final items = <String>[].obs;
  var listStatus = ListStatus.idle.obs;

  @override
  void onInit() {
    super.onInit();
    getMuses();
    EventCenter.instance.addListener(kEventCenterDidReceivedNewMessages, onReceivedNewMessages);
  }

  void onReceivedNewMessages(event) {
    getMuses();
  }

  @override
  void onClose() {
    EventCenter.instance.removeListener(kEventCenterDidReceivedNewMessages, onReceivedNewMessages);
    super.onClose();
  }

  void getMuses() async {
    if (items.isEmpty && listStatus.value != ListStatus.loading) {
      listStatus.value = ListStatus.loading;
    }

    ApiRequest request = ApiRequest(
      Apis.security_queryInspirationWords,
      params: {
        Security.security_targetUid: Get.find<ChatRoomViewController>().userId,
        Security.security_sessionId: Get.find<ChatRoomViewController>().session.id,
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      List tips = response.data[Security.security_options] ?? [];
      items.value = tips.map((e) => e[Security.security_text] as String).toList();
      listStatus.value = items.isEmpty ? ListStatus.empty : ListStatus.success;
    } else {
      if (items.isEmpty) {
        listStatus.value = ListStatus.error;
      }
    }
  }
}
