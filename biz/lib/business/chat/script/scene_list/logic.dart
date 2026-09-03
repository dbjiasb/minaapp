import 'package:biz/base/crypt/routes.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:biz/shared/toast/toast.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../service/servce.dart';

class SceneListController extends GetxController {
  List<dynamic> sceneList = [];

  int tuid = 0;

  @override
  void onInit() {
    super.onInit();
    try {
      tuid = int.parse(Get.parameters[Security.security_tuid] ?? '0');
    } catch (e) {}
  }

  Future<void> querySceneList() async {
    Map rsp = await ScriptPlayService.instance.querySceneList(uid: tuid);
    if (rsp.isNotEmpty) {
      sceneList = rsp[Security.security_datings] ?? [];
    }

    if (sceneList.isEmpty) {
      Toast.show(Copywriting.security_some_error_occurred__try_again_later_);
    }
  }
}
