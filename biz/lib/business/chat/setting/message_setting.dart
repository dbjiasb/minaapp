import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/shared/toast/toast.dart';
import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/assets/image_path.dart';
import '../../../base/crypt/security.dart';
import '../../../base/preferences/preferences.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/widget/title_bar.dart';

final String kCachedKeyReceiveRealMsg =
    Security.security_kCachedKeyReceiveRealMsg;
final String kCachedKeyReceivePushMsg =
    Security.security_kCachedKeyReceivePushMsg;

class MessageSettingView extends GetView<SettingController> {
  const MessageSettingView({super.key});

  @override
  SettingController get controller => Get.put(SettingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        title: Text(Copywriting.security_message_Setting, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.base_background,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: Obx(() {
        return controller.isLoading.value
            ? Container(
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.primary),
            )
            : Column(
              children: [
                _buildItem(
                  controller.rxReceiveMsgTitle.value,
                  controller.rxReceiveMsg.value,
                  (value) {
                    controller.updateReceiveRealMsg(value);
                  },
                ),
                // _buildItem('In App Message Notice', controller.rxMsgPush.value, (
                //   value,
                // ) {
                //   controller.updatePushSetting(value);
                // }),
              ],
            );
      }),
    );
  }

  Widget _buildItem(
    String title,
    bool selected,
    ValueChanged<bool>? onChanged,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          CupertinoSwitch(
            thumbColor: Colors.white,
            inactiveTrackColor: Color(0x29D2C0FF),
            activeTrackColor: AppColors.primary,
            value: selected,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class SettingController extends GetxController {
  RxBool rxReceiveMsg =
      Preferences.instance.getBool(kCachedKeyReceiveRealMsg).obs;
  RxString rxReceiveMsgTitle = Copywriting.security_bock_Messages_from_Strangers.obs;

  RxBool rxMsgPush =
      Preferences.instance
          .getBool(kCachedKeyReceivePushMsg, defaultVale: true)
          .obs;

  RxBool isLoading = false.obs;

  Future<void> getSettings() async {
    isLoading.value = true;
    ApiRequest request = ApiRequest(Apis.security_getUserSettings);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      Map realMsgSetting = response.data[Security.security_configs]?['1'] ?? {};
      bool flag = realMsgSetting[Security.security_isOpen] == 1;
      rxReceiveMsg.value = flag;
      if (realMsgSetting[Security.security_title]?.isNotEmpty == true) {
        rxReceiveMsgTitle.value = realMsgSetting[Security.security_title];
      }
      Preferences.instance.setBool(kCachedKeyReceiveRealMsg, flag);
    }
    isLoading.value = false;
    return;
  }

  void updateReceiveRealMsg(bool flag) async {
    rxReceiveMsg.value = flag;
    ApiRequest request = ApiRequest(
      Apis.security_updateUserSettings,
      params: {
        Security.security_type: 1,
        Security.security_action: flag ? 1 : 0,
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      Preferences.instance.setBool(kCachedKeyReceiveRealMsg, flag);
    }
  }

  void updatePushSetting(bool flag) {
    rxMsgPush.value = flag;
    Preferences.instance.setBool(kCachedKeyReceivePushMsg, flag);
  }

  @override
  void onInit() {
    getSettings();
    super.onInit();
  }
}
