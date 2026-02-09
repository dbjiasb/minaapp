import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/core/util/cached_image.dart';

import '../../../base/assets/image_path.dart';
import '../../../base/router/route_helper.dart';
import '../../../shared/app_theme.dart';
import 'logic.dart';

class TheaterHistoryListView extends StatelessWidget {
  TheaterHistoryListView({super.key});

  final controller = Get.put(TheaterHistoryListViewLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.w),
              child: Text("History", style: TextStyle(color: Color(0xFFFFE407), fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20.w),
            Expanded(
              child: Obx(
                () =>
                    controller.isLoading.value
                        ? Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          child:
                              controller.dataList.isEmpty
                                  ? emptyView()
                                  : MasonryGridView.count(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8.w,
                                    mainAxisSpacing: 12.w,
                                    controller: controller.scrollController,
                                    itemBuilder: (context, index) => _buildListItem(controller.dataList[index]),
                                    itemCount: controller.dataList.length,
                                  ),
                          onRefresh: () async {
                            controller.refreshData();
                          },
                        ),
              ),
            ),
          ],
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
          // Image.asset(ImagePath.img_empty, width: 172, height: 146),
          Text(Copywriting.security_no_data, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal)),
        ],
      ),
    ),
  );

  Widget _buildListItem(Map item) {
    String imageUrl = item["coverUrl"] ?? "";
    String name = item["name"] ?? "";
    return GestureDetector(
      onTap: () {
        RouteHelper.toChatTheater(item);
      },
      child: Column(
        children: [
          SizedBox(
            height: 180.w,
            width: 112.w,
            child: Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetImage(imageUrl: imageUrl, width: 112.w, height: 180.w, fit: BoxFit.cover)),
                Positioned(bottom: 6.w, right: 6.w, child: Image.asset(ImagePath.ic_film, height: 16.w, width: 16.w)),
              ],
            ),
          ),
          SizedBox(height: 4.w),
          Text(name, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.normal, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
