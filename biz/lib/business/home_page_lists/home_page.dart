import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widget/keep_alive_wrapper.dart';
import '../theater/theater_list/view.dart';

class RoleListItem {
  String title;
  final Widget Function() builder;

  RoleListItem(this.title, this.builder);
}

class HomePageView extends StatelessWidget {
  HomePageView({super.key});

  HomePageViewController viewController = Get.put(HomePageViewController());

  @override
  Widget build(BuildContext context) {
    // return Obx((){
      viewController.initTabs();
      final selectedStyle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900);
      final unselectedStyle = TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.bold);

      final tabBar = TabBar(
          padding: EdgeInsets.only(right: 16),
          tabAlignment: TabAlignment.start,
          isScrollable: true,
          labelPadding: EdgeInsets.symmetric(horizontal: 8),
          controller: viewController.tabController,
          onTap: (index) {
            viewController.onTabClicked(index);
          },
          labelStyle: selectedStyle,
          labelColor: Colors.white,
          unselectedLabelStyle: unselectedStyle,
          unselectedLabelColor: const Color(0xFFBBC1CA),
          dividerColor: Colors.transparent,
          indicator: const BoxDecoration(), indicatorPadding: EdgeInsets.zero, indicatorWeight: 0,
          tabs: viewController.items.map((e) {
            final index  = viewController.items.indexOf(e);
            return Tab(
              child: Obx(() {
                bool isSelected = viewController.currentIndex.value == index;
                return Stack(
                  alignment: Alignment.bottomRight,
                  clipBehavior: Clip.none,
                  children: [
                    Text(e.title, style: isSelected ? selectedStyle : unselectedStyle),
                    // Positioned(
                    //     bottom: -8,
                    //     child: isSelected
                    //         ? Image.asset(ImagePath.tab_selected, width: 40, height: 10)
                    //         : SizedBox()
                    // )
                  ],
                );
              }),
            ).marginOnly(left: 8);
          }).toList());

      return Scaffold(
        backgroundColor: const Color(0xFF0A0B12),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(height: 40,child: tabBar,).marginOnly(bottom: 8),
              Expanded(
                child: PageView.builder(
                  itemBuilder: (context, index) {
                    return viewController.items[index].builder();
                  },
                  itemCount: viewController.items.length,
                  controller: viewController.pageController,
                  onPageChanged: (int index) {
                    viewController.onPageChanged(index);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    // });
  }
}

class HomePageViewController extends GetxController with GetTickerProviderStateMixin {
  @override
  void onInit() {
    super.onInit();
    initTabs();
  }

  PageController pageController = PageController();
  late TabController tabController;
  bool isTabClicking = false;
  RxInt currentIndex = 0.obs;

  late List<RoleListItem> items;

  void initTabs() {
    items = [
      RoleListItem('Story', () => KeepAliveWrapper(child: TheaterListView())),
      // RoleListItem('Character', () => KeepAliveWrapper(child: RoleListView(type: RoleListType.ai_and_script))),
      // RoleListItem(Security.security_community, () => KeepAliveWrapper(child: RoleListView(type: RoleListType.ugc))),
      // RoleListItem(Security.security_anime, () => KeepAliveWrapper(child: RoleListView(type: RoleListType.anime))),
      // RoleListItem(Security.security_featured, () => KeepAliveWrapper(child: RoleListView(type: RoleListType.dating))),
      // RoleListItem(Copywriting.security_premium_Only, () => KeepAliveWrapper(child: RoleListView(type: RoleListType.pro_only))),
    ];
    tabController = TabController(vsync: this, length: items.length);
    currentIndex.value = 0;
  }

  void onTabClicked(int index) async {
    isTabClicking = true;
    currentIndex.value = index;
    await pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.linearToEaseOut);
    isTabClicking = false;
  }

  void onPageChanged(int index) {
    if (!isTabClicking) {
      tabController.animateTo(index);
      currentIndex.value = index;
    }
  }
}
