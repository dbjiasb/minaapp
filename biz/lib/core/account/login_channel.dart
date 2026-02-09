import 'dart:core';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/app_info/app_manager.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/environment/environment.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/core/account/account_service.dart';

import '../../shared/app_theme.dart';
import '../../shared/toast/toast.dart';

class LoginChannel {
  LoginChannel(this.channel, this.channelName, this.channelIcon, this.channelColor, this.channelTextColor, this.onTap);

  final String channel;
  final String channelName;
  Widget channelIcon;
  final Color channelColor;
  final Color channelTextColor;
  final Function onTap;
}

class LoginChannelView extends StatelessWidget {
  LoginChannelView({super.key});

  LoginChannelViewController viewController = Get.put(LoginChannelViewController());

  _onCheckButtonClicked() async {
    viewController.checked.value = !viewController.checked.value;
  }

  _onPrivacyPolicyClicked() {
    Get.toNamed(
      Routers.webView,
      arguments: {Security.security_title: Copywriting.security_privacy_policy, Security.security_url: AppManager.instance.privacyHtml},
    );
  }

  _onTermsOfServiceClicked() {
    Get.toNamed(
      Routers.webView,
      arguments: {Security.security_title: Copywriting.security_terms_of_service, Security.security_url: AppManager.instance.termsHtml},
    );
  }

  Widget _buildCheckButton() {
    return Obx(
          () => SizedBox(
        width: 14,
        height: 14,
        child: IconButton(
          padding: const EdgeInsets.all(0),
          onPressed: null,
          icon: Image.asset(ImagePath.selecet_0),
          selectedIcon: Image.asset(ImagePath.selecet_1),
          iconSize: 12,
          isSelected: viewController.checked.value,
        ),
      ),
    );
  }

  Widget _buildBottomTips() {
    const TextStyle linkStyle = TextStyle(color: AppColors.mainLightColor, fontSize: 12, decoration: TextDecoration.underline);
    const TextStyle normalStyle = TextStyle(color: Color(0xFF999999), fontSize: 12, fontWeight: FontWeight.w500);

    return RichText(
      text: TextSpan(
        style: normalStyle,
        children: [
          TextSpan(text: Copywriting.security_if_you_sign_in__you_agree_to),
          TextSpan(
            text: Copywriting.security_privacy_Policy,
            style: linkStyle,
            recognizer:
            TapGestureRecognizer()
              ..onTap = () {
                _onPrivacyPolicyClicked();
              },
          ),
          const TextSpan(text: ' '),
          const TextSpan(text: 'and '),
          TextSpan(
            text: Copywriting.security_terms_of_Service,
            style: linkStyle,
            recognizer:
            TapGestureRecognizer()
              ..onTap = () {
                _onTermsOfServiceClicked();
              },
          ),
        ],
      ),
    );
  }

  Widget _buildAgreeText() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 46),
      child: GestureDetector(
        onTap: () {
          _onCheckButtonClicked();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [_buildCheckButton(), const SizedBox(width: 8), Expanded(child: _buildBottomTips())],
        ),
      ),
    );
  }

  Widget _buildLoginChannels() {
    LoginChannel email = LoginChannel(
      Security.security_email,
      Copywriting.security_sign_in_with_E_mail,
      Image.asset(IMGP.email_icon, width: 24, height: 24),
      Color(0xFF333333),
      Colors.white,
          () {
        Get.toNamed(Routers.login);
      },
    );
    LoginChannel apple = LoginChannel(
      Security.security_apple,
      Copywriting.security_sign_in_with_Apple,
      Image.asset(IMGP.apple_icon, width: 24, height: 24),
      Color(0xFF333333),
      Colors.white,
          () async {
        Toast.loading(status: Copywriting.security_signing_in___);
        ApiResponse response = await AccountService.instance.loginWithApple();
        if (response.isSuccess) {
          Toast.dismiss();
          //弹出所有页面并进入主页
          Get.offAllNamed(Routers.root);
        } else {
          Toast.error(response.description);
        }
      },
    );
    List<LoginChannel> channels = [if (Platform.isIOS) apple, email];

    return Column(children: [for (var channel in channels) Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildLoginChannel(channel))]);
  }

  Widget _buildLoginChannel(LoginChannel channel) {
    return GestureDetector(
      onTap: () {
        channel.onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 48),
        child: Container(
          height: 54,
          decoration: BoxDecoration(color: channel.channelColor, borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(left: 16, top: 15, child: channel.channelIcon),
              Container(
                alignment: Alignment.center,
                child: Text(
                  channel.channelName,
                  style: TextStyle(color: channel.channelTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showNetworkSheet() {
    Get.bottomSheet(
      Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.base_background),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children:
          NetworkType.values.map((e) {
            return TextButton(
              onPressed: () {
                Environment.instance.updateNetworkType(e);
              },
              child: Text(
                e.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: e == Environment.instance.networkType ? Colors.red : Colors.white),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNetworkEnvMode() {
    return Environment.instance.isDebug
        ? GestureDetector(
      onTap: () {
        showNetworkSheet();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(Environment.instance.networkType.name, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    )
        : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(ImagePath.loginbg, height: double.infinity, width: double.infinity, fit: BoxFit.cover),
        Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: SizedBox(width: 88, height: 88, child: Image.asset(ImagePath.logo512, fit: BoxFit.fill)),
                  ),
                ),
                _buildNetworkEnvMode(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildLoginChannels(), SizedBox(height: 65), _buildAgreeText(), if (Platform.isAndroid) SizedBox(height: 24)],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LoginChannelViewController extends GetxController {
  var checked = true.obs;
}
