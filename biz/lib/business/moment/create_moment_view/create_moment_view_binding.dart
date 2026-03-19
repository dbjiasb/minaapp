import 'package:get/get.dart';

import 'create_moment_view_logic.dart';

class CreateMomentViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateMomentViewLogic());
  }
}
