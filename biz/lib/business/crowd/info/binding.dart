import 'package:get/get.dart';

import 'controller.dart';

class CrowedInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CrowedInfoController());
  }
}
