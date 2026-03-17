import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/preferences/preferences.dart';

import '../../../base/assets/image_view.dart';
import '../../../base/crypt/security.dart';
import '../../../base/router/route_helper.dart';
import '../../../base/router/router_names.dart';
import 'chat_room_view.dart';

enum SideMenuItemType {
  store,
  mission,
  theater,
  mode,
  dating
}

class ChatSidebar extends StatelessWidget {
  RxBool showAdButton = true.obs;
  RxBool isMenuExpand = true.obs;

  final roomViewController = Get.find<ChatRoomViewController>();
  bool get isAi => roomViewController.session.isAiChat;
  bool get isPgcAiKind => roomViewController.session.isPGCAI;
  bool get isAIPlusChat => roomViewController.session.isAIPlusChat;
  bool get isGroup => roomViewController.session.isGroup;
  int get level => roomViewController.session.level.value;
  int get userId => roomViewController.userId;
  bool get supportAIDating {
    if (!isAIPlusChat) return false;
    return Preferences.instance.supportGame(userId);
  }
  bool get supportModeStore {
    if (!isPgcAiKind) return false;
    return Preferences.instance.supportGame(userId);
  }

  @override
  Widget build(BuildContext context) {
    isMenuExpand.value = Preferences.instance.getBool(Security.security_kChatSidebarExpand);
    return Positioned(
      right: 4,
      left: 4,
      top: ScreenUtil().statusBarHeight + kToolbarHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          12.verticalSpace,
          drawSideMenu(),
          20.verticalSpace,
        ],
      ),
    );
  }

  String imgNameFrom(int index) {
    if (SideMenuItemType.store.index == index) {
      return "chat_side_store.webp";
    }
    if (SideMenuItemType.mission.index == index) {
      return "chat_side_task.webp";
    }
    if (SideMenuItemType.dating.index == index) {
      return "chat_side_game.webp";
    }
    if (SideMenuItemType.mode.index == index) {
      return "chat_side_mod.webp";
    }
    // if (SideMenuItemType.theater.index == index) {
    //   return 'theater';
    // }
    return '';
  }

  drawSideMenu() {
    return Obx(() {

      List<int> supportItem = [
        if (supportAIDating) SideMenuItemType.dating.index,
        if (isPgcAiKind) SideMenuItemType.mode.index,
        SideMenuItemType.mission.index,
        if (supportModeStore) SideMenuItemType.store.index,
      ];

      List<int> showItems = isMenuExpand.value ? supportItem : [supportItem.first];

      List<Widget> actions = showItems.map((e) {
        return GestureDetector(
          onTap: () {
            onSideMenuItemClick(e);
          },
          child: ImageView(imgNameFrom(e), width: 44, height: 44).marginOnly(bottom: (e == supportItem.last || showItems.length == 1) ? 0 : 16),
        );
      }).toList();

      return Column(
        children: [
          SizedBox(
            width: 44,
            child: Stack(
              children: [
                Positioned(
                    left: 2, right: 2, top: 38, bottom: 0,
                    child: Container(
                        height: double.infinity,
                        color: Colors.black.withValues(alpha: 0.3)
                    )),
                Column(
                  children: actions,
                )
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              isMenuExpand.value = !isMenuExpand.value;
              Preferences.instance.setBool(Security.security_kChatSidebarExpand, isMenuExpand.value ? true : false);
            },
            child: Container(
              width: 40, height: 48,
              decoration: BoxDecoration(
                  image: DecorationImage(
                    image: ImageView.getImageProvider("chat_side_more_bg.webp"),
                  )
              ),
              child: ImageView(isMenuExpand.value ? "chat_side_more_co.webp" : "chat_side_more_xp.png",  width: 32, height: 32),
            ),
          )
        ],
      );
    });
  }

  void onSideMenuItemClick(int index) {
    if (SideMenuItemType.store.index == index) {
      RH.toPage(Routers.modeStore);
    } else if (SideMenuItemType.mission.index == index) {
      RH.toTask();
    } else if (SideMenuItemType.dating.index == index) {
      RH.toPage(Routers.datingList, params: {Security.security_tuid: '$userId'});
    } else if (SideMenuItemType.mode.index == index) {
      RH.toPage(Routers.modeList, params: {Security.security_uid: '$userId', Security.security_defaultId: '0'});
    } else if (SideMenuItemType.theater.index == index) {

    }
  }
}
