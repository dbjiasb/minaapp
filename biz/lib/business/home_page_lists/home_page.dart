import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/home_page_lists/role_manager.dart';
import 'package:biz/shared/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../base/router/route_helper.dart';
import '../chat/chat_session.dart';
import '../theater/theater_list/story_card_widget.dart';
import 'home_feed_logic.dart';
import 'role_card_widget.dart';
import 'package:biz/localize/tab_labels.dart';

class HomePageView extends StatelessWidget {
  HomePageView({super.key});

  final HomePageViewController controller = Get.put(
    HomePageViewController(),
    tag: Security.security_home_page_controller,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        systemOverlayStyle: AppAppearance.overlayStyle,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    TabLabels.discovery,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: Security.security_hYPangDunDun,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildFeed()),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() => Obx(() {
    if (controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentText),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (controller.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: TextButton(
                  onPressed: controller.refreshData,
                  child: Text(
                    controller.hasError.value
                        ? Copywriting
                              .security_network_error__please_try_again_later
                        : Copywriting.security_no_data,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 16.w),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 11.w,
                mainAxisSpacing: 12.w,
                childCount: controller.items.length,
                itemBuilder: (context, index) {
                  final entry = controller.items[index];
                  if (entry.isStory) return StoryCardWidget(item: entry.data);
                  final item = entry.data;
                  return RoleCardWidget(
                    item: item,
                    onTap: () => RouteHelper.toChat(
                      id: item[Security.security_uid].toString(),
                      name: item[Security.security_nickname] ?? '',
                      avatar: item[Security.security_avatarUrl] ?? '',
                      coverUrl:
                          item[Security.security_coverUrl] ??
                          item[Security.security_backgroundUrl] ??
                          '',
                      accountType: item[Security.security_accountType] ?? 1,
                      type: SessionType.private,
                      bio: item[Security.security_bio] ?? '',
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  });
}

class Category {
  final String Function() _labelBuilder;
  RoleListType type;
  Category(this._labelBuilder, this.type);

  String get name => _labelBuilder();
}

class HomePageViewController extends HomeFeedLogic {
  final ScrollController scrollController = ScrollController();

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
