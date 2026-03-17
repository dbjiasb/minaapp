import 'package:get/get.dart';

import 'logic.dart';

class MyAIModeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MyAIModeLogic());
  }
}
