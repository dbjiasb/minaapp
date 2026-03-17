import 'package:get/get.dart';

class ChatHistoryViewController extends GetxController {
  final RxInt currentTabIndex = 0.obs;

  void onTabChanged(int index) {
    currentTabIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
