import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/business/moment/moment.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../base/router/router_names.dart';
import '../../shared/app_theme.dart';
import '../../shared/widget/keep_alive_wrapper.dart';
import '../moment/moment_list_view/moment_list_view_view.dart';
import 'explore_view.dart';
import 'video_match/video_match_view.dart';

enum DisTabType { character, match, moment }

class DisTab {
  DisTab(this.type, this.name);

  DisTabType type;
  String name;
}

class DiscoveryView extends GetView<DiscoveryController> {
  DiscoveryView({super.key});

  @override
  DiscoveryController get controller => Get.put(DiscoveryController());

  Widget _buildItemView(int index, dynamic tab) {
    if (tab.type == DisTabType.character) {
      return KeepAliveWrapper(child: ExploreView());
    }

    if (tab.type == DisTabType.match) {
      // return KeepAliveWrapper(child: MatchNewView());
      return KeepAliveWrapper(child: VideoMatchView());
    }
    return KeepAliveWrapper(child: MomentListViewPage());
  }

  Widget _buildTab(int index, dynamic tab) {
    return Obx(() {
      bool isSelected = controller.currentIndex.value == index;
      return Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.3), Colors.black.withValues(alpha: 0)],
              ),
            ),
            child: Text(
              tab.name,
              style:
                  isSelected
                      ? TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)
                      : TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            bottom: -8,
            child:
                isSelected
                    // ? Image.asset(ImagePath.tab_selected, width: 40, height: 10)
                    ? SizedBox()
                    : SizedBox(),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.base_background,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent, elevation: 0, systemOverlayStyle: SystemUiOverlayStyle.light),
      body: Stack(
        children: [
          TabBarView(controller: controller.tabController, children: controller.tabs.mapIndexed(_buildItemView).toList()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x82000000), Color(0x00000000)]),
              ),
              padding: const EdgeInsets.only(left: 4, right: 16),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Obx(() {
                        return TabBar(
                          tabs: controller.tabs.mapIndexed(_buildTab).toList(),
                          controller: controller.tabController,
                          tabAlignment: TabAlignment.start,
                          isScrollable: true,
                          labelStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          unselectedLabelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
                          onTap: (index) {
                            controller.currentIndex.value = index;
                          },
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                          indicatorColor: Colors.transparent,
                          indicator: const BoxDecoration(),
                          indicatorPadding: EdgeInsets.zero,
                          indicatorWeight: 0,
                          dividerHeight: 0,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.label,
                        );
                      }),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          Get.toNamed(Routers.search);
                        },
                        child: Icon(Icons.search, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ).marginOnly(bottom: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoveryController extends GetxController with GetTickerProviderStateMixin {
  RxList tabs = [].obs;
  late TabController tabController;
  bool isRv = Preferences.instance.isRv;
  RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();

    setupTabs(isInit: true);
    EventCenter.instance.addListener(Preferences.kDicChangedAppConfig, (event) {
      setupTabs();
    });
  }

  setupTabs({bool isInit = false}) {
    bool rv = Preferences.instance.isRv;
    if (isRv == rv && !isInit) return;
    isRv = rv;
    List newTabs = [];
    if (!rv) {
      newTabs = [
        DisTab(DisTabType.character, Security.security_Discovery),
        DisTab(DisTabType.moment, Security.security_moment),
        DisTab(DisTabType.match, Security.security_match),
      ];
    } else {
      newTabs = [DisTab(DisTabType.character, Security.security_Discovery), DisTab(DisTabType.moment, Security.security_moment)];
    }
    tabController = TabController(vsync: this, length: newTabs.length, initialIndex: currentIndex.value);
    tabController.addListener(() {
      currentIndex.value = tabController.index;
    });
    tabs.value = newTabs;
    update();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
