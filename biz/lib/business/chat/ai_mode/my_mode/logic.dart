import 'package:biz/base/crypt/routes.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../../../base/api_service/api_response.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../service/ai_mode_service.dart';
import 'state.dart';

String kModeAppBarTitleId = Security.security_kModeAppBarTitleId;
String kMyAIModeObjId = Security.security_kMyAIModeObjId_;
String kMyAIModeObjButtonId = Security.security_kMyAIModeObjButtonId_;

class MyAIModeLogic extends GetxController {
  final MyAIModeState state = MyAIModeState();

  // late LoopPageController pageController;

  late List<dynamic> aiModes;

  late int uid;

  RxMap curMode = {}.obs;

  String selectedId = '';

  late bool canScroll;

  RxBool expand = false.obs;

  late int curIndex;

  void init(ApiResponse rsp) {
    aiModes = rsp.data[ES.modes]!;
    canScroll = aiModes.length > 1;
    int index = aiModes.indexWhere((element) => selectedId.isNotEmpty ? element[Security.security_id] == selectedId : element[Security.security_selected] != 0);
    index = index >= 0 ? index : 0;
    curIndex = index;
    curMode.value = aiModes[index];
  }

  void resetCurAIMode(Map aiPersonality) {
    curMode.value = aiPersonality;
    update([kModeAppBarTitleId]);
  }

  void switchToCur() {
    if (curMode[Security.security_selected] == 1) {
      return;
    }
    Toast.loading();
    AIModeService.instance.changeAIModeWithId(uid, curMode[Security.security_id] ?? '', value: curMode).then((value) {
      List<String> updateIds = [];
      for (var element in aiModes) {
        if (element[Security.security_id] == curMode[Security.security_id]) {
          curMode[Security.security_selected] = 1;
          element[Security.security_selected] = 1;
          updateIds.add('$kMyAIModeObjId${element[Security.security_id]}');
          updateIds.add('$kMyAIModeObjButtonId${element[Security.security_id]}');
        } else {
          if (element[Security.security_selected] == 1) {
            updateIds.add('$kMyAIModeObjId${element[Security.security_id]}');
          }
          element[Security.security_selected] = 0;
        }
      }
      update(updateIds);
      Toast.show(ES.switchTips);
      update();
    }).catchError((e) {
      Toast.show(Copywriting.security_error_occurred__please_try_again);
    });
  }

  pay() async {
    bool ret = await AIModeService.instance.payForAIMode(curMode);
    if (ret) {
      curMode[Security.security_own] = 1;
      List<String> updateIds = [
        '$kMyAIModeObjId${curMode.id}',
        '$kMyAIModeObjButtonId${curMode.id}',
      ];
      update(updateIds);
      Toast.show(Copywriting.security_congratulations__You_got_a_new_MODE__enjoy_it_.tr);
    }
  }
}
