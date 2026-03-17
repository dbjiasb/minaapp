import 'package:biz/base/crypt/routes.dart';
import 'dart:async';

import 'package:get/get.dart';

import '../../../../base/crypt/security.dart';
import '../service/ai_mode_service.dart';
import '../widget/ai_mode_card.dart';
import '../widget/ai_mode_popup.dart';
import '../utils/utils.dart';

class BT
{
  static const int mode = 2;
}


class AIModeStoreController extends GetxController {

  int curPage = 0;

  RxInt noticeIndex = 0.obs;
  Timer? noticeTimer;

  List<dynamic> personalities = [];

  void init() async {


    AIModeService.instance.onPayModeSuccess = (Map mode) {
      update(['StoreObj_${mode.id}']);
    };

    AIModeService.instance.queryModeStoreNotices().then((value) {
      if (value?[Security.security_data]?.isNotEmpty ?? false) {
        // notices.value = value![Security.security_data]!;
        // startNoticeTimer();
      }
    }).catchError((e) {});
  }

  Future refresh({arguments}) async {
    curPage = 0;
    try {
      List<dynamic> res = await queryMallModes(curPage);
      personalities = res;
 
    } catch (e) {
      print('$e');
    }
  }

  Future<List<dynamic>> queryNext({arguments}) {
    curPage++;
    return queryMallModes(curPage);
  }

  Future<List<dynamic>> queryMallModes(int page) async {
    Map? rsp = await AIModeService.instance.queryMallModes(page);

    if (rsp == null) {
      return [];
    }

    if (rsp[ES.modes]?.isEmpty ?? true) {
      return [];
    }
    return rsp[ES.modes]!;
  }

  Future pay(Map mode, {bool confirm = false}) async {
    bool ret = await AIModeService.instance.payForAIMode(mode, confirm: confirm);

    if (ret) {
      AIModePopup.show(mode);
    }
  }

  void showDetail(Map info) async {

    info[Security.security_type] = BT.mode;

    if (info[Security.security_type] == BT.mode) {
      Map aiPersonality = AIModeUtils.fromUrl(info[Security.security_jumpUrl]!);
      AiModeCard(aiPersonality, needUpdate: true, isAutoPlay: true).show();
    } else {
      // if (info[Security.security_jumpUrl]?.isNotEmpty ?? false) AppRouteUtils.handleRoute(info[Security.security_jumpUrl]!);
    }
  }

  void onClickCard(Map aiPersonality) {
    if (!aiPersonality.isOwn) {
      AiModeCard(aiPersonality, isAutoPlay: true).show();
    } else {
      AIModePopup.show(aiPersonality, isNew: false);
    }
  }
}
