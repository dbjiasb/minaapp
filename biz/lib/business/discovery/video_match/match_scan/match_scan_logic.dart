import 'package:biz/base/crypt/routes.dart';
import 'dart:ffi';

import 'package:get/get.dart';
import 'package:biz/shared/alert.dart';

import '../../../../base/api_service/api_response.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/routes.dart';
import '../../../../base/crypt/security.dart';
import '../../../../base/report/report_manager.dart';
import '../../../../base/router/route_helper.dart';
import '../../../../base/router/router_names.dart';
import '../../../chat/call/call_manager.dart';
import '../../services/match_service.dart';
import 'match_scan_state.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:utils/alerts.dart';
// import 'package:common/common.dart';
// import 'package:match/services/match_service.dart';
// import 'package:jce/tudou/CancelVideoCallMatchRsp.dart';
// import 'package:message/services/call_service.dart';
// import 'package:utils/app_report.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MatchScanLogic extends GetxController {
  final MatchScanState state = MatchScanState();

  Future<bool> cancelVideoMatch() async {
    int status = 0;
    await showConfirmAlert(Security.security_tips, Copywriting.security_exit_Video_Matching_, cancelText: Security.security_cancel, confirmText: Security.security_confirm, onConfirm: () async {

      EasyLoading.show();
      ApiResponse rsp = await MatchService.to.cancelVideoCallMatch();
      if (rsp.isSuccess) {
        status = 1;
      } else {
        EasyLoading.showToast(rsp.description);
      }
      EasyLoading.dismiss();
      status = 2;
    });

    String action = status == 1 ? Security.security_confirmExitMatch : (status == 0 ? Security.security_cancelExitMatch : Security.security_failedExitMatch);
    ReportManager.sendEvent(Security.security_click_user_match_video, {Security.security_action: action});

    RH.back();
    return status == 1;
  }

  @override
  void onClose() {
    WakelockPlus.disable();
    CallManager.instance.curCall = null;
    super.onClose();
  }

  @override
  void onInit() {
    WakelockPlus.enable();
    super.onInit();
  }

  void rejectAndStartMatch(int callId) async {
    EasyLoading.show();
    CallManager.instance.curCall = null;
    await CallManager.instance.refuse(callId: callId);
    MatchService.to.startVideoCallMatch().then((value) {
      if (value.isSuccess) {
        Get.offNamed(Routers.matchScan);
      } else {
        EasyLoading.showToast(value.description);
      }
      EasyLoading.dismiss();
    });
    // .catchError((error) {
    //   EasyLoading.showToast("Failed Match");
    //   EasyLoading.dismiss();
    // });
  }

  Future<bool> cancelAndRejectVideoMatch(int callId) async {

    int status = 0;

    await showConfirmAlert(Security.security_tips, Copywriting.security_exit_Video_Matching_, cancelText: Security.security_cancel, confirmText: Security.security_confirm, onConfirm: () async {

      EasyLoading.show();
      ApiResponse rsp = await MatchService.to.cancelVideoCallMatch();
      if (rsp.isSuccess) {
        status = 1;
      } else {
        EasyLoading.showToast(rsp.description);
      }
      EasyLoading.dismiss();
      status = 2;
    });

    String action = status == 1 ? Security.security_confirmExitMatchResult : (status == 0 ? Security.security_cancelExitMatchResult : Security.security_failedExitMatch);
    ReportManager.sendEvent(Security.security_click_user_match_video, {Security.security_action: action});
    return status == 1;
  }
}
