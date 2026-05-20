import 'package:biz/base/crypt/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/core/util/collections_util.dart';
import 'package:biz/core/util/ui_util.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/router/route_helper.dart';
import '../../../base/router/router_names.dart';
import '../../../base/ui/timer_count_down.dart';
import '../../../core/account/account_service.dart';
import '../../../shared/app_theme.dart';

class ChatModeView extends StatelessWidget {
  ChatModeView({super.key});

  Rx<int> rxModelId = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.base_background,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          topLeft: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            Copywriting.security_switch_the_Model,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ).marginOnly(bottom: 12),
          Flexible(
            child: Container(
              alignment: Alignment.center,
              child: UiUtils.buildFutureView<List<dynamic>?>(
                getChatModelList(),
                (data, context) {
                  if (data == null || data.isNullOrEmpty()) {
                    return UiUtils.buildCommonEmptyView();
                  } else {
                    rxModelId.value =
                        data.firstWhere(
                          (element) => element[Security.security_selected] == 1,
                        )[Security.security_id] ??
                        0;
                    return _buildModeList(data);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeList(List<dynamic> chatModelList) {
    return Column(
      children: [
        Flexible(
          child: ListView.builder(
            itemBuilder: (context, index) {
              return _buildItem(chatModelList.safeGet(index, {}));
            },
            itemCount: chatModelList.length,
          ),
        ),
        _buildSwitchButton(),
      ],
    );
  }

  void switchModel() async {
    if (rxModelId.value == 0) {
      return;
    }
    Toast.loading();
    ApiRequest request = ApiRequest(
      Apis.security_switchChatModel,
      params: {Security.security_modelId: rxModelId.value},
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    Toast.dismiss();
    if (!response.isSuccess) {
      Toast.show(Copywriting.security_switch_Succeed_enjoy_your_chat);
    } else {
      Toast.show(Copywriting.security_switch_Failed);
    }
  }

  Widget _buildSwitchButton() {
    return InkWell(
      onTap: () {
        switchModel();
      },
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          Security.security_switch,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(Map<dynamic, dynamic> chatModel) {
    return InkWell(
      onTap: () {
        if (chatModel[Security.security_premiumOnly] == 1 &&
            !MyAccount.isSubscribed &&
            chatModel[Security.security_remaining] <= 0) {
          RH.toPremium();
          return;
        }
        rxModelId.value = chatModel[Security.security_id] ?? 0;
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors:
                    chatModel[Security.security_premiumOnly] == 1
                        ? [const Color(0x1affdb42), const Color(0x00ffffff)]
                        : [const Color(0x0dffffff), const Color(0x00ffffff)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      chatModel[Security.security_name] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (chatModel[Security.security_premiumOnly] == 1)
                      ImageView(
                        Images.security_premium_png,
                        width: 16,
                        height: 16,
                      ).marginOnly(left: 4),
                    const Spacer(),
                    Obx(() {
                      return ImageView(
                        chatModel[Security.security_id] == rxModelId.value
                            ? Images.security_ic_check_png
                            : Images.security_ic_uncheck_png,
                        height: 24,
                        width: 24,
                      );
                    }),
                  ],
                ),
                Text(
                  chatModel[Security.security_desc] ?? "",
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ).marginOnly(top: 12),
              ],
            ),
          ),
          if ((chatModel[Security.security_remaining]) > 0)
            Positioned(
              top: 6,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF7D5EFF),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      Copywriting.security_limited_Free,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TimerDownView(
                      endTime: DateTime.now().add(
                        Duration(
                          milliseconds: chatModel[Security.security_remaining],
                        ),
                      ),
                      format: CountDownTimerFormat.hoursMinutesSeconds,
                      enableDescriptions: false,
                      colonsTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      timeTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      spacerWidth: 0,
                      onEnd: () {},
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<List<dynamic>?> getChatModelList() async {
    ApiRequest request = ApiRequest(Apis.security_getChatModelList);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      return response.data[Security.security_param] ?? [];
    }
    return [];
  }
}
