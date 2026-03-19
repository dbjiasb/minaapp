import 'package:get/get.dart';

import 'match_scan_logic.dart';

class MatchScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MatchScanLogic());
  }
}
