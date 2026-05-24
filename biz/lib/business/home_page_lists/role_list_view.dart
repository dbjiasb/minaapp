import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/business/home_page_lists/role_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../shared/app_theme.dart';
import 'role_card_widget.dart';
import 'role_list_logic.dart';

class RoleListView extends StatelessWidget {
  final RoleListType type;
  final refreshIndex;
  final ScrollController? scrollController;

  RoleListView({super.key, required this.type, this.refreshIndex, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RoleListLogic(type: type, externalScrollController: scrollController), tag: '${type}_$refreshIndex');

    return Obx(
      () =>
          controller.isLoading.value
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshConfiguration(
                springDescription: SpringDescription.withDampingRatio(
                  mass: 1.0,
                  stiffness: 200,
                  ratio: 1.0,
                ),
                child: SmartRefresher(
                  controller: controller.refreshController,
                  enablePullDown: true,
                  enablePullUp: true,
                  onRefresh: controller.onRefresh,
                  onLoading: controller.onLoading,
                  child:
                      controller.dataList.isEmpty
                          ? _emptyView(controller)
                          : CustomScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            controller: controller.scrollController,
                            slivers: [
                              SliverToBoxAdapter(child: buildBanners(controller)),
                              _buildGridView(controller),
                            ],
                          ),
                ),
              ),
    );
  }

  Widget _emptyView(RoleListLogic controller) {
    return GestureDetector(
      onTap: () {
        controller.initData();
      },
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 200.w),
          Center(child: Text(Copywriting.security_no_data, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.normal))),
        ],
      ),
    );
  }

  Widget buildBanners(RoleListLogic controller) {
    return Obx(
      () =>
          controller.banners.isNotEmpty
              ? AspectRatio(
                aspectRatio: 359 / 108,
                child: Swiper(
                  itemCount: controller.banners.length,
                  itemBuilder: (context, index) {
                    Map banner = controller.banners[index];
                    String coverUrl = banner[Security.security_coverUrl] ?? '';
                    String linkUrl = banner[Security.security_jumpUrl] ?? '';
                    return GestureDetector(
                      onTap: () {
                        RouteHelper.handleRoute(linkUrl);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                  pagination: SwiperPagination(
                    alignment: Alignment.bottomCenter,
                    builder: DotSwiperPaginationBuilder(
                      activeColor: Colors.white,
                      color: Color(0x66FFFFFF),
                      size: 6,
                      space: 2,
                      activeSize: 6,
                    ),
                  ),
                ),
              ).marginOnly(bottom: 8)
              : SizedBox.shrink(),
    );
  }

  Widget _buildGridView(RoleListLogic controller) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 11.w,
        mainAxisSpacing: 12.w,
        itemBuilder: (context, index) {
          return RoleCardWidget(
            item: controller.dataList[index],
            isRealType: type == RoleListType.real,
            onTap: () {
              final item = controller.dataList[index];
              RouteHelper.toChat(
                id: item[Security.security_uid].toString() ?? '',
                name: item[Security.security_nickname] ?? '',
                avatar: item[Security.security_avatarUrl] ?? '',
                coverUrl: item[Security.security_coverUrl] ?? item[Security.security_backgroundUrl] ?? '',
                accountType: item[Security.security_accountType] ?? 1,
                type: 3,
                bio: item[Security.security_bio] ?? '',
              );
            },
          );
        },
        childCount: controller.dataList.length,
      ),
    );
  }
}
