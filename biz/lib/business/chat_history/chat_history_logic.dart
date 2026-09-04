import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/localize/tab_labels.dart';

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
  final String Function() _labelBuilder;
  int type;

  SessionListTab(this._labelBuilder, this.type);

  String get name => _labelBuilder();
}

class ChatHistoryViewController extends GetxController with GetTickerProviderStateMixin {
  RxList<SessionListTab> tabs = RxList<SessionListTab>();
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

    EventCenter.instance.addListener(Preferences.kDicChangedAppConfig, (_) {
      setupTabs();
    });
  }

  setupTabs() {
    List<SessionListTab> ss = [
      // if (rv) SessionListTab(() => TabLabels.all, SessionListType.all),
      // if (!rv)
        SessionListTab(() => TabLabels.all, SessionListType.all),
      // if (!rv)
        SessionListTab(() => TabLabels.virtual, SessionListType.ai),
      // if (!rv)
        SessionListTab(() => TabLabels.real, SessionListType.real),
      // if (!rv)
        SessionListTab(() => TabLabels.groupChat, SessionListType.group),
      SessionListTab(() => TabLabels.story, SessionListType.theater),
    ];

    if (tabs.length == ss.length) {
      return;
    }

    tabController = TabController(length: ss.length, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        onTabChanged(tabController.index);
      }
    });
    tabs.value = ss;
  }

  @override
  void onClose() {
    super.onClose();
  }

  RxList recommendList = [].obs;
  RxBool showRecommend = true.obs;
  RxBool refreshingRecommend = false.obs;

  Future<void> queryRecommendList(bool isReload) async {
    if (!showRecommend.value) return;
    refreshingRecommend.value = true;
    ApiResponse response = await ApiService.instance.sendRequest(ApiRequest(Apis.security_getUserRecommendList, params: {Security.security_version: 2}));
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
