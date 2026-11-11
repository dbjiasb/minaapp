import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/localize/tab_labels.dart';

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

class ChatHistoryViewController extends GetxController
    with GetTickerProviderStateMixin {
  RxList<SessionListTab> tabs = RxList<SessionListTab>();
  late TabController tabController;

  final RxInt currentTabIndex = 0.obs;

  void onTabChanged(int index) {
    currentTabIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    setupTabs();

    EventCenter.instance.addListener(Preferences.kDicChangedAppConfig, (_) {
      setupTabs();
    });
  }

  setupTabs() {
    List<SessionListTab> ss = [
      SessionListTab(() => TabLabels.character, SessionListType.all),
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
    tabController.dispose();
    super.onClose();
  }
}
