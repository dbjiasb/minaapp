import 'package:get/get.dart';
import 'package:biz/shared/alert.dart';

import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../base/report/report_manager.dart';
import '../../../../base/router/route_helper.dart';
import '../../../../base/router/router_names.dart';
import '../../../chat/call/call_manager.dart';
import '../../services/match_service.dart';
import 'match_scan_state.dart';
import 'match_exit_guard.dart';
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

  final _exitGuard = MatchExitGuard();

  Future<bool> cancelVideoMatch() => _cancelMatch();

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
      if (value.isSuccess || value.bsnsCode == 8) {
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

  Future<bool> cancelAndRejectVideoMatch(int callId) =>
      _cancelMatch(callId: callId);

  Future<bool> _cancelMatch({int? callId}) async {
    MatchExitOutcome outcome;
    try {
      outcome = await _exitGuard.run(
        confirm: () async =>
            await showConfirmAlert(
              Security.security_tips,
              Copywriting.security_exit_Video_Matching_,
              cancelText: Security.security_cancel,
              confirmText: Security.security_confirm,
            ) ==
            true,
        cancel: () async {
          EasyLoading.show();
          String? error;
          try {
            final response = await MatchService.to.cancelVideoCallMatch();
            if (!response.isSuccess) {
              error = response.description;
              return false;
            }
            if (callId != null) {
              final response = await CallManager.instance.refuse(
                callId: callId,
              );
              if (!response.isSuccess) {
                error = response.description;
                return false;
              }
              CallManager.instance.curCall = null;
            }
            return true;
          } finally {
            await EasyLoading.dismiss();
            if (error != null) EasyLoading.showToast(error);
          }
        },
        leave: RH.back,
      );
    } catch (_) {
      outcome = MatchExitOutcome.failed;
      EasyLoading.showToast(
        Copywriting.security_network_error__please_try_again_later,
      );
    }
    if (outcome == MatchExitOutcome.busy) return false;
    final String action;
    if (callId == null) {
      action = outcome == MatchExitOutcome.exited
          ? Security.security_confirmExitMatch
          : outcome == MatchExitOutcome.cancelled
          ? Security.security_cancelExitMatch
          : Security.security_failedExitMatch;
    } else {
      action = outcome == MatchExitOutcome.exited
          ? Security.security_confirmExitMatchResult
          : outcome == MatchExitOutcome.cancelled
          ? Security.security_cancelExitMatchResult
          : Security.security_failedExitMatch;
    }
    ReportManager.sendEvent(Security.security_click_user_match_video, {
      Security.security_action: action,
    });
    return outcome == MatchExitOutcome.exited;
  }
}
