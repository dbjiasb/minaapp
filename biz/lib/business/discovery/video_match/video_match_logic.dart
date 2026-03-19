import 'dart:async';

import 'package:biz/base/report/report_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../base/crypt/security.dart';
import '../../../base/preferences/preferences.dart';
import '../../../base/router/route_helper.dart';
import '../../../base/router/router_names.dart';
import '../../../core/util/log_util.dart';
import '../../../core/util/permission_util.dart';
import '../../chat/call/call_manager.dart';
import '../services/match_service.dart';
import 'free_card_use_tips.dart';

class VideoMatchLogic extends GetxController {
  void startMatch() async {
    if (!await PermissionUtil.checkCallPermission(0)) {
      L.i('[Chat][Call] startMatch call Permission is not support');
      return;
    }
    EasyLoading.show();
    ReportManager.sendEvent(Security.security_click_user_match_video, {Security.security_action: Security.security_startMatch});
    MatchService.to.startVideoCallMatch().then((value) {
      if (value.isSuccess) {
        RH.toPage(Routers.matchScan);
      } else {
        EasyLoading.showToast(value.description);
      }
      EasyLoading.dismiss();
    });
    // .catchError((error) {
    //   EasyLoading.dismiss();
    //   if (error is WupException &&
    //       error.code == RspCode.RC_PAY_BALANCE_NOT_ENOUGH) {
    //     TopupAlert.showTopUpDialog(type: ECurrencyType.GEMS);
    //   } else {
    //     EasyLoading.showToast("Failed Match");
    //   }
    // });
  }

  void tryStartMatch() async {
    bool hasFreeCall = CallManager.instance.isFreeCall;
    bool hasMatchCard = false;

    ///UserInfoService.to.freeMatchCard > 0;

    if ((hasFreeCall || hasMatchCard) && !Preferences.instance.getBool(Security.security_kFreeCardTipKey)) {
      dynamic result = await FreeCardUseTip.show();
      if (result is bool && result) {
        startMatch();
      }
    } else {
      startMatch();
    }
  }

  Timer? _timer;

  @override
  void onReady() {
    MatchService.to.getMatchTaskProcess();
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      currentIndex.value = (currentIndex.value + 1) % MatchService.to.avatarUrlPlaceHolders.length;
    });
    // TaskService.to.queryRealReward();
    super.onReady();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  RxInt currentIndex = 0.obs;
}
