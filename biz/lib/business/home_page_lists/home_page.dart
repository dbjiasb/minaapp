import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../base/preferences/preferences.dart';
import '../create_center/create_oc_dialog.dart';
import '../create_center/create_oc_rv_dialog.dart';
import '../theater/theater_list/view.dart';
import 'category_tabs_widget.dart';
import 'role_list_logic.dart';
import 'role_list_view.dart';

class HomePageView extends StatelessWidget {
  HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomePageViewController(), tag: 'home_page_controller');

    return Scaffold(
      backgroundColor: Color(0xFF07070a),
      appBar: AppBar(backgroundColor: Color(0xFF07070a), systemOverlayStyle: SystemUiOverlayStyle.light, elevation: 0, toolbarHeight: 0),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                _buildTopBar(),

                // Category tabs
                Obx(
                  () => CategoryTabsWidget(
                    categories: controller.categories,
                    selectedIndex: controller.selectedCategoryIndex.value,
                    onTap: (index) => controller.onCategoryChanged(index),
                  ),
                ),

                SizedBox(height: 8.w),

                // Content area with TabBarView
                Expanded(
                  child: TabBarView(
                    controller: controller.tabController,
                    children: [
                      // Story tab - linear list
                      TheaterListView(scrollController: controller.scrollController),
                      // Discovery tab - waterfall grid
                      RoleListView(type: RoleListType.ai, scrollController: controller.scrollController),
                      // Real tab - waterfall grid
                      RoleListView(type: RoleListType.real, scrollController: controller.scrollController),
                      // OC tab - waterfall grid
                      RoleListView(type: RoleListType.ugc, scrollController: controller.scrollController),
                      // Pro only tab - waterfall grid
                      RoleListView(type: RoleListType.proOnly, scrollController: controller.scrollController),
                    ],
                  ),
                ),
              ],
            ),

            // Floating Create button
            Positioned(
              bottom: 16.w,
              left: 0,
              right: 0,
              child: Obx(
                () => AnimatedOpacity(
                  opacity: controller.showCreateButton.value ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: AnimatedSlide(
                    offset: controller.showCreateButton.value ? Offset.zero : Offset(0, 0.5),
                    duration: Duration(milliseconds: 200),
                    child: _buildCreateButton(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 44.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Recommend', style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'HYPangDunDun')),
          Icon(Icons.search, color: Colors.white, size: 24.w),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          if (Preferences.instance.isRv) {
            CreateOcRvDialog.show();
          } else {
            CreateOcDialog.show();
          }
        },
        child: Container(
          width: 86.w,
          height: 36.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFffee6b), Color(0xFFfff8bf)], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [BoxShadow(color: Color(0xFFffee6b).withValues(alpha: 0.3), blurRadius: 8.w, offset: Offset(0, 2.w))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/ic_add_create.png', width: 20.w, height: 20.w, package: 'biz'),
              SizedBox(width: 4.w),
              Text('Create', style: TextStyle(color: Color(0xFF07070a), fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePageViewController extends GetxController with GetSingleTickerProviderStateMixin {
  final List<String> categories = ['Story', 'Discovery', 'Real', 'OC', 'Pro only'];
  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool showCreateButton = true.obs;
  final ScrollController scrollController = ScrollController();
  Timer? _scrollTimer;
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: categories.length, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        selectedCategoryIndex.value = tabController.index;
      }
    });
    _setupScrollListener();
  }

  @override
  void onClose() {
    _scrollTimer?.cancel();
    scrollController.dispose();
    tabController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (showCreateButton.value) {
        showCreateButton.value = false;
      }

      _scrollTimer?.cancel();

      _scrollTimer = Timer(Duration(milliseconds: 150), () {
        if (!isClosed) {
          showCreateButton.value = true;
        }
      });
    });
  }

  void onCategoryChanged(int index) {
    if (isClosed) return;
    if (!tabController.indexIsChanging && tabController.index != index) {
      selectedCategoryIndex.value = index;
      tabController.animateTo(index);
    }
  }
}
