import 'package:get/get.dart';

import 'create_post_image_logic.dart';

class CreatePostImageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreatePostImageLogic());
  }
}
