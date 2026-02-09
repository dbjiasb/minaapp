import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/business/account/account_view.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/user_manager/user_manager.dart';
import 'package:biz/shared/widget/keep_alive_wrapper.dart';

import '../base/router/route_helper.dart';
import '../business/chat/chat_session_handler.dart';
import '../business/home_page_lists/home_page.dart';
import '../business/theater/theater_history_list/logic.dart';
import '../business/theater/theater_history_list/view.dart';
import '../business/theater/theater_list/view.dart';
import '../shared/app_theme.dart';
import '../shared/formatters/date_formatter.dart';

class BottomBarItem {
  final String name;
  final Widget Function() pageBuilder;
  final Widget Function() selectedBuilder;
  final Widget Function() normalBuilder;

  const BottomBarItem({required this.name, required this.pageBuilder, required this.selectedBuilder, required this.normalBuilder});
}

final String kCachedKeyGoToPremiumFlag = Security.security_kCachedKeyGoToPremiumFlag;

// const int CREATE_OC_INDEX = 2;
const int MESSAGE_INDEX = 1;
const int MINE_INDEX = 2;

class SkeletonView extends StatelessWidget {
  SkeletonView({super.key});

  SkeletonViewController viewController = Get.put(SkeletonViewController());

  Widget _buildIconButton(BottomBarItem item, int index) {
    final normalIcon = item.normalBuilder();
    final selectedIcon = item.selectedBuilder();
    return Obx(
      () => Stack(
        children: [
          IconButton(
            onPressed: () {
              viewController.onTabClicked(index);
            },
            icon: normalIcon,
            selectedIcon: selectedIcon,
            isSelected: viewController.selectedIndex.value == index,
            highlightColor: Colors.transparent,
          ),
          if (index == 4)
            Positioned(
              top: 8,
              right: 8,
              child: Obx(() {
                bool needRedot = UserManager.instance.notificationReminder.value || UserManager.instance.taskReminder.value;
                if (!needRedot) return Container();
                return IgnorePointer(
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFFF84652), borderRadius: BorderRadius.circular(20))),
                );
              }),
            ),
          if (index == 3)
            Positioned(
              top: 5,
              right: 5,
              child: Obx(() {
                int count = viewController.unreadCount.value;
                if (count == 0) return Container();
                return IgnorePointer(
                  child: Container(
                    // constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    // padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF84652), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      viewController.unreadCount.toString(),
                      style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold, height: 1.5),
                      maxLines: 1,
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    BorderSide border = BorderSide(color: const Color(0xFF2E2E2E), width: 1);
    return Scaffold(
      backgroundColor: AppColors.base_background,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: viewController.pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewController.items.length,
              itemBuilder: (context, index) {
                return viewController.items[index].pageBuilder();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border(left: border, right: border, top: border),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              color: const Color(0xFF05030D),
            ),
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 29),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      viewController.items.asMap().entries.map((e) {
                        return _buildIconButton(e.value, e.key);
                      }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
    );
  }
}

class SkeletonViewController extends GetxController {
  var selectedIndex = 0.obs;
  final PageController pageController = PageController();
  RxInt unreadCount = 0.obs;

  List<BottomBarItem> items = <BottomBarItem>[
    BottomBarItem(
      name: Security.security_list,
      pageBuilder: () {
        return KeepAliveWrapper(child: HomePageView()); //TheaterListView()
      },
      selectedBuilder: () => Image.asset(ImagePath.bt_0_1, width: 28, height: 28),
      normalBuilder: () => Image.asset(ImagePath.bt_0_0, width: 28, height: 28),
    ),
    // BottomBarItem(
    //   name: Security.security_Discovery,
    //   pageBuilder: () {
    //     return KeepAliveWrapper(child: DiscoveryView());
    //   },
    //   selectedBuilder: () => Image.asset(ImagePath.explore_selected, width: 28, height: 28),
    //   normalBuilder: () => Image.asset(ImagePath.explore_normal, width: 28, height: 28),
    // ),
    // BottomBarItem(
    //   name: Security.security_createoc,
    //   pageBuilder: () {
    //     return Container();
    //   },
    //   selectedBuilder: () => Image.asset(ImagePath.create_oc, width: 28, height: 28),
    //   normalBuilder: () => Image.asset(ImagePath.create_oc, width: 28, height: 28),
    // ),
    BottomBarItem(
      name: Security.security_chat,
      pageBuilder: () {
        return KeepAliveWrapper(child: TheaterHistoryListView());
      },
      selectedBuilder: () => Image.asset(ImagePath.bt_1_1, width: 28, height: 28),
      normalBuilder: () => Image.asset(ImagePath.bt_1_0, width: 28, height: 28),
    ),
    BottomBarItem(
      name: Security.security_personal,
      pageBuilder: () {
        return KeepAliveWrapper(child: AccountView());
      },
      selectedBuilder: () => Image.asset(ImagePath.bt_2_1, width: 28, height: 28),
      normalBuilder: () => Image.asset(ImagePath.bt_2_0, width: 28, height: 28),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    EventCenter.instance.addListener(kEventCenterDidChangeSession, (event) => updateUnreadCount());
    EventCenter.instance.addListener(kEventCenterDidDeleteSession, (event) => updateUnreadCount());
    EventCenter.instance.addListener(kEventCenterDidClearSessionNumber, (event) => unreadCount.value = 0);
    updateUnreadCount();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onTabClicked(int index) {
    // if (index == CREATE_OC_INDEX) {
    //   CreateOcDialog.show();
    //   return;
    // }
    pageController.jumpToPage(index);
    selectedIndex.value = index;
    if (index == MESSAGE_INDEX) {
      // FcmService.instance.requestPermission();
      Get.find<TheaterHistoryListViewLogic>().getListData();

    } else if (index == MINE_INDEX) {
      try {
        Get.find<AccountViewController>().refreshDataIfNeed();
      } catch (e) {print(e);}
    }
  }

  Future updateUnreadCount() async {
    int count = await ChatSessionHandler().unreadCount();
    unreadCount.value = count > 99 ? 99 : count;
  }

}
