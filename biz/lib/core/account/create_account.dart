import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/core/account/account_service.dart';

import '../../base/app_info/app_manager.dart';
import '../../base/router/router_names.dart';
import '../../shared/app_theme.dart';
import '../../shared/toast/toast.dart';

class CreateAccountView extends StatelessWidget {
  CreateAccountView({super.key});

  CreateAccountViewController viewController = Get.put(CreateAccountViewController());

  Widget _buildMailInputView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        height: 48,
        decoration: const BoxDecoration(color: Color(0xFF202026), borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                onChanged: viewController.onMailChange,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(style: BorderStyle.none)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(style: BorderStyle.none)),
                  hintText: Copywriting.security_entry_your_email,
                  hintStyle: TextStyle(color: Color(0x80FFFFFF), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyCodeView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        height: 48,
        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: Color(0xFF202026)),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                onChanged: viewController.onVerifyCodeChange,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  hintText: Copywriting.security_enter_verification_code,
                  hintStyle: TextStyle(color: Color(0x80FFFFFF), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: viewController.canSendCode.value ? viewController.onObtainCodeButtonClicked : null,
              child: Obx(
                    () => Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  width: 100,
                  height: 40,
                  child: Center(
                    child: Text(
                      viewController.countdown.value > 0 ? '${viewController.countdown.value}s' : Copywriting.security_obtain_code,
                      style:
                      viewController.countdown.value > 0
                          ? TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)
                          : (viewController.canSendCode.value
                          ? const TextStyle(color: Color(0xFFFFEF3B), fontSize: 13, fontWeight: FontWeight.w700)
                          : TextStyle(color: Colors.transparent, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: viewController.login,
      child: Obx(
            () => Container(
          height: 54,
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          decoration: BoxDecoration(
            color: viewController.canContinue.value ? AppColors.mainLightColor : AppColors.mainLightColor.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              Security.security_Continue,
              style: TextStyle(
                color: viewController.canContinue.value ? Color(0xFF0F0F0F) : const Color(0x800F0F0F),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreeText() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: GestureDetector(
        onTap: () {
          _onCheckButtonClicked();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          // children: [_buildCheckButton(), const SizedBox(width: 8), _buildBottomTips()],
        ),
      ),
    );
  }

  _onCheckButtonClicked() async {
    viewController.checked.value = !viewController.checked.value;
  }

  _onTermsOfServiceClicked() {
    Get.toNamed(
      Routers.webView,
      arguments: {Security.security_title: Copywriting.security_terms_of_service, Security.security_url: AppManager.instance.termsHtml},
    );
  }

  _onBackButtonClicked() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Image.asset(ImagePath.loginbg, height: double.infinity, width: double.infinity, fit: BoxFit.cover),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(140, 140, 140, 0),
                      child: SizedBox(width: 88, height: 88, child: Image.asset(ImagePath.apple_icon, fit: BoxFit.fill)),
                    ),
                    SizedBox(height: 40),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: Text("Create your account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        ),
                        SizedBox(height: 32),
                        _buildMailInputView(),
                        const SizedBox(height: 12),
                        _buildVerifyCodeView(),
                        _buildContinueButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                height: 44,
                child: GestureDetector(
                  onTap: _onBackButtonClicked,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Image.asset(ImagePath.ic_arrow_left_circle, width: 36, height: 36),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateAccountViewController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String account = "";
  String verifyCode = '';
  Timer? _timer;

  var countdown = 0.obs;
  var canSendCode = false.obs;
  var canContinue = false.obs;
  var checked = true.obs;

  void onMailChange(String text) {
    account = text;
    canSendCode.value = account.isNotEmpty && countdown.value == 0;
  }

  void onVerifyCodeChange(String text) {
    verifyCode = text;
    canContinue.value = account.isNotEmpty && verifyCode.isNotEmpty;
    if (verifyCode.length == 6) {
      login();
    }
  }

  void onObtainCodeButtonClicked() {
    _getVerifyCode();
  }

  void login() async {
    if (checked.value == false) {
      Toast.error(Copywriting.security_please_agree_to_the_terms_and_conditions);
      return;
    }

    if (verifyCode.isEmpty) {
      if (kDebugMode) {
        verifyCode = '385620';
      }
      return;
    }

    Toast.loading(status: Copywriting.security_logging_in___);
    ApiResponse response = await AccountService.instance.loginWithEmail(account, verifyCode);
    if (response.isSuccess) {
      Toast.dismiss();
      //弹出所有页面并进入主页
      Get.offAllNamed(Routers.root);
    } else {
      Toast.error(response.description);
    }
  }

  void _getVerifyCode() async {
    Toast.loading(status: Copywriting.security_sending___);
    ApiResponse response = await AccountService.instance.getVerifyCode(account, AccountType.email);
    if (response.isSuccess) {
      _startTimer();
      Toast.dismiss();
    } else {
      Toast.error(response.description);
    }
  }

  void _startTimer() {
    countdown.value = 60;
    canSendCode.value = account.isNotEmpty && countdown.value == 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value = countdown.value - 1;
      } else {
        countdown.value = 0;
        _stopTimer();
      }
      canSendCode.value = account.isNotEmpty && countdown.value == 0;
    });
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }
}
