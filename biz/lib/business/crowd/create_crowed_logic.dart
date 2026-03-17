import 'package:biz/base/crypt/routes.dart';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/business/crowd/crowd_manager.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/toast/toast.dart';
import 'dart:typed_data';
import '../../base/api_service/api_request.dart';
import '../../base/api_service/api_response.dart';
import '../../base/api_service/api_service.dart';
import '../../base/crypt/apis.dart';
import '../../base/crypt/security.dart';
import '../../base/event_center/event_center.dart';
import '../../core/util/file_upload.dart';
import 'crowd_utils.dart';

class CreateCrowedLogic extends GetxController {
  final FocusNode nameFocusNode = FocusNode();

  final TextEditingController nameTextController = TextEditingController();

  final TextEditingController scenarioTextController = TextEditingController();

  final scenarioFocusNode = FocusNode();

  final Rx<String> rxNameText = "".obs;

  final Rx<String> rxScenarioText = "".obs;

  final RxSet<dynamic> rxSelectRoleList = RxSet();

  bool get canCreate =>
      rxNameText.isNotEmpty &&
      rxScenarioText.isNotEmpty &&
      rxSelectRoleList.isNotEmpty;

  void createGroup() async {
    if (!canCreate) {
      return;
    }
    List<String> urls =
        rxSelectRoleList
            .map(
              (element) =>
                  (element[Security.security_userBase]?[Security.security_avatarUrl] ?? "")
                      as String,
            )
            .toList();
    Uint8List? bytes = await generateGroupAvatarBytes(urls);
    if (bytes == null) {
      return;
    }
    Toast.loading();
    final imgUrl = await FilePushService.instance.upload(
      bytes,
      FileType.profile,
    );
    ApiRequest request = ApiRequest(Apis.security_createGroup,
      params: {
        Security.security_info: {
          Security.security_avatar: imgUrl,
          Security.security_scenario: rxScenarioText.value,
          Security.security_name: rxNameText.value,
          Security.security_members:
              rxSelectRoleList
                  .map((element) => {Security.security_userbase: element[Security.security_userBase]})
                  .toList(),
        },
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      Get.back();
      RouteHelper.toChat(
        id:
            (response.data[Security.security_info]?[Security
                    .security_sessionId] ??
                ""),
        name:
            (response.data[Security.security_info]?[Security.security_name] ??
                ""),
        avatar:
            (response.data[Security.security_info]?[Security.security_avatar] ??
                ""),
        coverUrl:
            (response.data[Security.security_info]?[Security
                    .security_chatBackground] ??
                ""),
        type: 2,
      );
      AccountService.instance.refreshBalance();
      CrowedManager.instance.getCrowdConfigInfo();
      AccountService.instance.getPremInfo();
      EventCenter.instance.sendEvent(Security.security_kDidGroupInfoChange, {});
    } else {
      Toast.show(response.description);
    }
    Toast.dismiss();
  }

  void addOrRemoveRoleItem(Map<dynamic, dynamic> roleItem) {
    bool isSelect = rxSelectRoleList.any(
      (element) =>
          (element[Security.security_userBase]?[Security.security_uid] ?? 0) ==
          (roleItem[Security.security_userBase]?[Security.security_uid] ?? 0),
    );
    if (isSelect) {
      rxSelectRoleList.removeWhere(
        (element) =>
            (element[Security.security_userBase]?[Security.security_uid] ?? 0) ==
            (roleItem[Security.security_userBase]?[Security.security_uid] ?? 0),
      );
    } else {
      rxSelectRoleList.add(roleItem);
    }
  }
}
