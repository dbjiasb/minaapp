import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/business/home_page_lists/role_manager.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../base/assets/image_view.dart';
import '../../base/preferences/preferences.dart';
import '../../base/router/router_names.dart';
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
    final controller = Get.put(HomePageViewController(), tag: Security.security_home_page_controller);

    return Scaffold(
      backgroundColor: Color(0xFF07070a),
      appBar: AppBar(backgroundColor: Color(0xFF07070a), systemOverlayStyle: SystemUiOverlayStyle.light, elevation: 0, toolbarHeight: 0),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
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
                  child: Obx(() => TabBarView(
                    controller: controller.tabController,
                    children: controller.categories.map((e) => e.type == RoleListType.story
                        ? TheaterListView(scrollController: controller.scrollController)
                        : RoleListView(type: e.type, scrollController: controller.scrollController)).toList(),
                  )),
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
      margin: EdgeInsets.only(top: 4.w, bottom: 4.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: GestureDetector(
            onTap: () {
              Get.toNamed(Routers.search);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.w),
              decoration: BoxDecoration(
                  color: Color(0xFF171C29),
                  borderRadius: BorderRadius.circular(32.w),
                  border: Border.all(color: Color(0xFF2A3144), width: 1)
              ),
              child: Row(
                children: [
                  ImageView(Images.mina_search, width: 14.w, height: 14.w),
                  SizedBox(width: 6.w),
                  Text(Copywriting.security_Search_by_ID__name__tag___, style: TextStyle(color: Color(0xFFAEB6C7), fontSize: 12.sp)),
                ],
              ),
            ),
          )),
          SizedBox(width: 12.w,),
          // Text(Security.security_recommend, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: Security.security_hYPangDunDun)),
          InkWell(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            onTap: () {
              // Get.toNamed(Routers.search);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.w),
              decoration: BoxDecoration(
                  color: Color(0xFF171C29),
                  borderRadius: BorderRadius.circular(32.w),
                  border: Border.all(color: Color(0xFF2A3144), width: 1)
              ),
              child: Row(
                children: [
                  ImageView(Images.mina_filter, width: 14.w, height: 14.w),
                  SizedBox(width: 6.w),
                  Text(Security.security_Filter, style: TextStyle(color: Color(0xFFF2F4F8), fontSize: 13.sp)),
                ],
              ),
            ),
          ),
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
              ImageView(Images.security_ic_add_create_png, width: 20.w, height: 20.w),
              SizedBox(width: 4.w),
              Text(Security.security_create, style: TextStyle(color: Color(0xFF07070a), fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class Category {
  String name;
  RoleListType type;
  Category(this.name, this.type);
}

class HomePageViewController extends GetxController with GetSingleTickerProviderStateMixin {
  late RxList<Category> categories = RxList<Category>();
  // final List<String> categories = [Security.security_story, Security.security_discovery, Security.security_real, Security.security_oC, Copywriting.security_pro_only];
  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool showCreateButton = true.obs;
  final ScrollController scrollController = ScrollController();
  Timer? _scrollTimer;
  late TabController tabController;

  late RxBool isRv = true.obs;

  @override
  void onInit() {
    super.onInit();
    isRv = Preferences.instance.isRv.obs;
    setupCategories();
    EventCenter.instance.addListener(Preferences.kDicChangedAppConfig, (Event event) {
      handleAppConfigChanged(event);
    });
  }

  void handleAppConfigChanged(Event event) {
    if (isRv.value == Preferences.instance.isRv) return;
    isRv.value = Preferences.instance.isRv;
    setupCategories();
  }

  void setupCategories() {
    categories.value = isRv.value ? [
      Category(Security.security_recommend, RoleListType.ai_and_script),
      Category(Security.security_story, RoleListType.story),
      // Category(Security.security_real, RoleListType.real),
      // Category(Security.security_oC, RoleListType.ugc),
      // Category(Copywriting.security_pro_only, RoleListType.pro_only),
    ] : [
      Category(Security.security_recommend, RoleListType.ai_and_script),
      Category(Security.security_real, RoleListType.real),
      Category(Security.security_oC, RoleListType.ugc),
      Category(Security.security_featured, RoleListType.dating),
      Category(Security.security_anime, RoleListType.anime),
      Category(Security.security_realistic, RoleListType.realistic),
      Category(Copywriting.security_pro_only, RoleListType.pro_only),
      Category(Security.security_story, RoleListType.story),
    ];

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
