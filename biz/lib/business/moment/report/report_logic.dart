import 'package:biz/base/crypt/routes.dart';
import 'package:get/get.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../moment.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ReportLogic extends GetxController {
  RxMap currentReason = {}.obs;

  void updateReason(Map value) {
    currentReason.value = value;
    update();
  }

  void report(int targetId, int type, String extraContent) async {
    if (extraContent.isEmpty) {
      extraContent = currentReason[Security.security_desc] ?? '';
    }
    MomentService.to.report(targetId, type,
        reasonId: currentReason[Security.security_id], extraContent: extraContent);
    Get.back();
    EasyLoading.showToast(Copywriting.security_report_Success_);
  }

  Future<Map> loadReportConfig() {
    return MomentService.to.loadReportConfig();
  }
}
