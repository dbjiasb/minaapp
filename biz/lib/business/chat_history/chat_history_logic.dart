import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/api_service/api_request.dart';
import '../../base/api_service/api_response.dart';
import '../../base/api_service/api_service.dart';
import '../../base/crypt/apis.dart';
import '../../base/crypt/security.dart';
import '../../shared/toast/toast.dart';

class SessionListType {
  static const int all = 0;
  static const int ai = 1;
  static const int real = 2;
  static const int group = 3;
  static const int theater = 4;
}

class SessionListTab {
  String name;
  int type;
  SessionListTab(this.name, this.type);
}


class ChatHistoryViewController extends GetxController with GetTickerProviderStateMixin {

  late List<SessionListTab> tabs;
  late TabController tabController;

  final RxInt currentTabIndex = 0.obs;

  void onTabChanged(int index) {
    currentTabIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    queryRecommendList(false);
    setupTabs();
  }

  setupTabs() {
      tabs = [
        SessionListTab(Copywriting.security_all_Chat, SessionListType.all),
        SessionListTab(Security.security_aI, SessionListType.ai),
        SessionListTab(Security.security_real, SessionListType.real),
        SessionListTab(Security.security_Group, SessionListType.group),
        SessionListTab(Security.security_story, SessionListType.theater),
      ];

      tabController = TabController(length: tabs.length, vsync: this);
      tabController.addListener(() {
        if (!tabController.indexIsChanging) {
          onTabChanged(tabController.index);
        }
      });
  }

  @override
  void onClose() {
    super.onClose();
  }

  RxList recommendList = [].obs;
  RxBool showRecommend = true.obs;
  RxBool refreshingRecommend = false.obs;

  void queryRecommendList(bool isReload) async {
    if (!showRecommend.value) return;
    refreshingRecommend.value = true;
    ApiResponse response = await ApiService.instance.sendRequest(ApiRequest(Apis.security_getUserRecommendList, params: {
      Security.security_version: 2
    }));
    refreshingRecommend.value = false;
    if (!response.isSuccess) {
      if (isReload) {
        Toast.show(response.description);
      }
      return;
    }
    recommendList.assignAll(response!.data[Security.security_list] ?? []);
  }

}
