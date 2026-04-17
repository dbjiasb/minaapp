import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:biz/base/app_info/app_manager.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/account/about_view.dart';
import 'package:biz/shared/app_theme.dart';

import '../../base/api_service/api_response.dart';
import '../../base/assets/image_view.dart';
import '../../base/router/route_helper.dart';
import '../../base/router/router_names.dart';
import '../../core/account/account_service.dart';
import '../../core/util/log_util.dart';
import '../../shared/alert.dart';
import '../../shared/toast/toast.dart';
import '../chat/setting/message_setting.dart';

class SettingItem {
  String title;
  Function() onTap;

  SettingItem({required this.title, required this.onTap});
}

class AccountSettings extends StatelessWidget {
  List<SettingItem> get items => <SettingItem>[
    if (!Preferences.instance.isRv) SettingItem(title: Copywriting.security_message_Settings, onTap: messageSettings),
    // SettingItem(title: Security.security_about, onTap: toAbout),
    SettingItem(title: Copywriting.security_terms_of_service, onTap: checkTermsOfService),
    SettingItem(title: Copywriting.security_privacy_policy, onTap: checkPrivacyPolicy),
    SettingItem(title: Copywriting.security_account_Deletion, onTap: deleteAccount),
    // SettingItem(title: Copywriting.security_feedback_Log, onTap: feedbackLog),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Security.security_Setting, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.base_background,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Get.back()),
      ),
      backgroundColor: AppColors.base_background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children:
                    items
                        .map(
                          (e) => GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: e.onTap,
                            child: Container(
                              height: 44,
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Text(e.title, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Spacer(),
                                  ImageView(Images.security_arrow_right_png, height: 16, width: 16),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),

            // log out
            GestureDetector(
              onTap: logout,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(Copywriting.security_log_out, style: TextStyle(color: Color(0xffF84652), fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void checkTermsOfService() {
    Get.toNamed(
      Routers.webView,
      arguments: {Security.security_title: Copywriting.security_terms_of_service, Security.security_url: AppManager.instance.termsHtml},
    );
  }

  void checkPrivacyPolicy() {
    Get.toNamed(
      Routers.webView,
      arguments: {Security.security_title: Copywriting.security_privacy_policy, Security.security_url: AppManager.instance.privacyHtml},
    );
  }

  void logout() {
    showConfirmAlert(
      Copywriting.security_log_out,
      Copywriting.security_are_you_sure_you_want_to_log_out_,
      onConfirm: () {
        AccountService.instance.logout();
        // Get.offAllNamed(Routers.login);
      },
      onCancel: () {},
    );
  }

  void deleteAccount() async {
    showConfirmAlert(
      Copywriting.security_delete_account_,
      Copywriting.security_are_you_sure_you_want_to_delete_your_account_,
      onConfirm: () async {
        Toast.loading(status: Copywriting.security_deleting___);
        ApiResponse response = await AccountService.instance.deleteAccount();
        Toast.dismiss();
        if (response.isSuccess) {
          RouteHelper.popAllAndToPage(Routers.loginChannel);
        } else {
          Toast.error(response.description);
        }
      },
    );
  }

  void messageSettings() {
    RH.toView(MessageSettingView());
  }

  void toAbout() {
    RH.toView(AboutView());
  }

  void feedbackLog() async {
    Toast.loading();
    await L.upload();
    Toast.show(Copywriting.security_upload_Log_success);
  }
}
