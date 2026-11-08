import 'dart:async';

import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../base/router/router_names.dart';
import '../../shared/app_brand.dart';
import '../../shared/app_theme.dart';
import '../../shared/toast/toast.dart';

class CreateAccountView extends StatelessWidget {
  CreateAccountView({super.key});

  final CreateAccountViewController viewController = Get.put(
    CreateAccountViewController(),
  );

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      filled: true,
      fillColor: AppColors.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentText),
      ),
    );
  }

  Widget _buildMailInputView() {
    return TextFormField(
      onChanged: viewController.onMailChange,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: _inputDecoration(Copywriting.security_entry_your_email),
    );
  }

  Widget _buildVerifyCodeView() {
    return TextFormField(
      onChanged: viewController.onVerifyCodeChange,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: _inputDecoration(Copywriting.security_enter_verification_code)
          .copyWith(
            suffixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Obx(
                () => TextButton(
                  onPressed: viewController.canSendCode.value
                      ? viewController.onObtainCodeButtonClicked
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentText,
                    disabledForegroundColor: AppColors.disabled,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(
                    viewController.countdown.value > 0
                        ? '${viewController.countdown.value}s'
                        : Copywriting.security_obtain_code,
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildContinueButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: viewController.canContinue.value
              ? viewController.login
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.accentForeground,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
            disabledForegroundColor: AppColors.textSecondary,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Text(Security.security_Continue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppAppearance.isLight
              ? const [
                  Color(0xFFFFF4C7),
                  AppColors.background,
                  AppColors.background,
                ]
              : const [AppColors.background, AppColors.background],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: BackButton(onPressed: () => Get.back()),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 56).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    AppBrand.logoAsset,
                                    package: 'biz',
                                    width: 88,
                                    height: 88,
                                    semanticLabel: AppBrand.name,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                AppBrand.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 48),
                              Text(
                                Copywriting.security_create_your_account,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildMailInputView(),
                              const SizedBox(height: 12),
                              _buildVerifyCodeView(),
                              const SizedBox(height: 24),
                              _buildContinueButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
    canContinue.value = account.isNotEmpty && verifyCode.isNotEmpty;
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
      Toast.error(
        Copywriting.security_please_agree_to_the_terms_and_conditions,
      );
      return;
    }

    if (verifyCode.isEmpty) {
      if (kDebugMode) {
        verifyCode = '752083';
      }
      return;
    }

    Toast.loading(status: Copywriting.security_logging_in___);
    ApiResponse response = await AccountService.instance.loginWithEmail(
      account,
      verifyCode,
    );
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
    ApiResponse response = await AccountService.instance.getVerifyCode(
      account,
      AccountType.email,
    );
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
