import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/base/crypt/security.dart';
import '../../shared/app_theme.dart';
import 'role_card_widget.dart';
import 'role_list_logic.dart';

class RoleListView extends StatelessWidget {
  final RoleListType type;
  final ScrollController? scrollController;

  RoleListView({
    super.key,
    required this.type,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      RoleListLogic(type: type, externalScrollController: scrollController),
      tag: type.toString(),
    );

    return Obx(
      () => controller.isLoading.value
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SmartRefresher(
              controller: controller.refreshController,
              enablePullDown: true,
              enablePullUp: true,
              onRefresh: controller.onRefresh,
              onLoading: controller.onLoading,
              child: controller.dataList.isEmpty
                  ? _emptyView(controller)
                  : MasonryGridView.count(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
                      crossAxisCount: 2,
                      crossAxisSpacing: 11.w,
                      mainAxisSpacing: 12.w,
                      controller: controller.scrollController,
                      itemBuilder: (context, index) => RoleCardWidget(
                        item: controller.dataList[index],
                        isRealType: type == RoleListType.real,
                        onTap: () {
                          final item = controller.dataList[index];
                          // 路由到私聊（type = 3）
                          RouteHelper.toChat(
                            id: item[Security.security_uid].toString() ?? '',
                            name: item[Security.security_nickname] ?? '',
                            avatar: item[Security.security_avatarUrl] ?? '',
                            coverUrl: item[Security.security_coverUrl] ?? item[Security.security_backgroundUrl] ?? '',
                            accountType: item[Security.security_accountType] ?? 1,
                            type: 3, // 私聊
                            bio: item[Security.security_bio] ?? '',
                          );
                        },
                      ),
                      itemCount: controller.dataList.length,
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
          Center(
            child: Text(
              Copywriting.security_no_data,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
