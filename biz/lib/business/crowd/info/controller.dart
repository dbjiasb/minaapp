import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/business/crowd/crowd_manager.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/crypt/apis.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/event_center/event_center.dart';
import '../../../base/router/router_names.dart';
import '../../../shared/alert.dart';

class CrowedInfoController extends GetxController {
  RxBool editing = false.obs;

  RxBool canSaveInfo = false.obs;

  Rx<CrowdInfo> rxCrowInfo = CrowdInfo.none().obs;

  final TextEditingController nameController = TextEditingController();

  final TextEditingController scenarioController = TextEditingController();

  final Rx<String> rxNameText = "".obs;

  final Rx<String> rxScenarioText = "".obs;

  final RxSet<dynamic> rxSelectRoleList = RxSet();

  void updateCrowInfo() async {
    rxCrowInfo.value.data[Security.security_name] = rxNameText.value;
    rxCrowInfo.value.data[Security.security_scenario] = rxScenarioText.value;
    Toast.loading();
    ApiRequest request = ApiRequest(Apis.security_updateGroupInfo,
      params: {Security.security_groupInfo: rxCrowInfo.value.data, Security.security_flag: 1 | 4 | 16},
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      Get.back(result: rxCrowInfo.value);
      EventCenter.instance.sendEvent(Security.security_kDidGroupInfoChange, {});
    } else {
      Toast.show(response.description);
    }
    Toast.dismiss();
  }

  @override
  void onReady() {
    CrowdInfo crowdInfo = CrowdInfo(Get.arguments);
    nameController.text = crowdInfo.name;
    scenarioController.text = crowdInfo.scenario;
    rxCrowInfo.value = crowdInfo;
    rxSelectRoleList.value =
        crowdInfo.members
            .map(
              (element) => {
                Security.security_userBase: element[Security.security_userbase],
                Security.security_premiumOnly: element[Security.security_premiumOnly],
              },
            )
            .toSet();
    super.onReady();
  }

  void tryRemoveMember(dynamic member) {
    rxCrowInfo.value.members.removeWhere(
      (element) =>
          element[Security.security_userbase][Security.security_uid] ==
          member[Security.security_userbase][Security.security_uid],
    );
    rxCrowInfo.refresh();
  }

  void tryDisband() {
    showConfirmAlert(
      Copywriting.security_disband_Group_,
      Copywriting.security_are_you_sure_you_want_to_disband_this_group__This_action_cannot_be_undone__and_all_members_will_be_removed_,
      onConfirm: () async {
        Toast.loading();
        ApiRequest request = ApiRequest(Apis.security_disbandGroup,
          params: {Security.security_groupId: rxCrowInfo.value.groupId},
        );
        ApiResponse response = await ApiService.instance.sendRequest(request);
        if (response.isSuccess) {
          ChatManager.instance.sessionHandler.deleteSessionById(
            rxCrowInfo.value.sessionId,
          );
          Get.until((route) => Get.currentRoute == Routers.root);
          EventCenter.instance.sendEvent(Security.security_kDidGroupInfoChange, {});
        } else {
          Toast.show(response.description);
        }
        Toast.dismiss();
      },
    );
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
    rxCrowInfo.value.data[Security.security_members] =
        rxSelectRoleList
            .map(
              (element) => {
                Security.security_userbase: element[Security.security_userBase],
                Security.security_premiumOnly: element[Security.security_premiumOnly],
              },
            )
            .toList();
    rxCrowInfo.refresh();
  }
}
