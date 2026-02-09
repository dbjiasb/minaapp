import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/cupertino.dart';

import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/shared/alert.dart';

import '../../shared/toast/toast.dart';
import './report_manager.dart';
import './report_view.dart';

class ReportHelper {
  static void showReportDialog(int reportedUserId) async {
    await ReportManager.instance.getReportOptions();
    var view = ReportContentView(reportedUserId: reportedUserId);
    showAlert(
      Padding(
        padding: EdgeInsets.only(left: 24, top: 22, right: 24, bottom: 7),
        child: Text(Security.security_Report, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF160518), fontSize: 16)),
      ),
      view,
      confirmText: Security.security_Submit,
      onConfirm: () {
        submitReport(reportedUserId, view.selectedItem, view.extra);
      },
    );
  }

  static void submitReport(int reportedUserId, ReportItem? item, String extra) async {
    ApiResponse response = await ReportManager.instance.submitReport(reportedUserId, item?.id ?? 0, extra: extra);
    if (response.isSuccess) {
      Toast.success(Copywriting.security_submitted_successfully);
    } else {
      Toast.error(response.description ?? Copywriting.security_network_error);
    }
  }
}
