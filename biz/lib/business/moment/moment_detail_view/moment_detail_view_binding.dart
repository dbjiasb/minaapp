import 'package:get/get.dart';

import 'moment_detail_view_logic.dart';

class MomentDetailViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MomentDetailViewLogic());
  }
}
