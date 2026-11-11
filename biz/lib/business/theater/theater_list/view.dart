import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:biz/base/crypt/copywriting.dart';

import '../../../shared/app_theme.dart';
import 'logic.dart';
import 'story_card_widget.dart';

class TheaterListView extends StatelessWidget {
  final ScrollController? scrollController;

  TheaterListView({super.key, this.scrollController});

  late final controller = Get.put(
    StoryListViewLogic(externalScrollController: scrollController),
    tag: scrollController?.hashCode.toString(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        systemOverlayStyle: AppAppearance.overlayStyle,
        elevation: 0,
        toolbarHeight: 0,
      ),
      backgroundColor: AppColors.background,
      body: Obx(
        () => controller.isLoading.value
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  controller.refreshData();
                },
                child: controller.dataList.isEmpty
                    ? emptyView()
                    : CustomScrollView(
                        controller: controller.scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 4.w,
                            ),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 11.w,
                              mainAxisSpacing: 12.w,
                              childCount: controller.dataList.length,
                              itemBuilder: (context, index) => StoryCardWidget(
                                item: controller.dataList[index],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget emptyView() => GestureDetector(
    onTap: () {
      controller.initData();
    },
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Copywriting.security_no_data,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}
