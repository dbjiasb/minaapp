import 'package:get/get.dart';
import 'logic.dart';

/// 约会场景页
class ScenePlayBinding extends Bindings {
  ScenePlayBinding();

  @override
  void dependencies() {
    Get.lazyPut(() => ScenePlayLogic());
  }
}
