import 'package:get/get.dart';
import 'package:biz/business/crowd/create_crowed_logic.dart';

class CreateCrowedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateCrowedLogic());
  }
}
