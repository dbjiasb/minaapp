import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/core/util/cached_image.dart';

import '../../../base/assets/image_path.dart';
import '../../../shared/app_theme.dart';
import 'logic.dart';

class TheaterListView extends StatelessWidget {
  TheaterListView({super.key});

  final controller = Get.put(StoryListViewLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.w),
            Expanded(
              child: Obx(
                () =>
                    controller.isLoading.value
                        ? Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          child:
                              controller.dataList.isEmpty
                                  ? emptyView()
                                  : Expanded(child: ListView.builder(
                                controller: controller.scrollController,
                                itemBuilder: (context, index) => _buildListItem(controller.dataList[index]),
                                itemCount: controller.dataList.length,
                              )),
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
          Text(Copywriting.security_no_data, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal)),
        ],
      ),
    ),
  );

  Widget _buildTagItem(String name) => Container(
    // margin: EdgeInsets.only(right: 6.w),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(9.r)),
    // alignment: Alignment.center,
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    // height: 18.w,
    child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.sp, color: Color(0xFFF9627A))),
  );

  Widget _buildListItem(Map item) {
    String name = item["name"] ?? "";
    String coverUrl = item["coverUrl"] ?? "";
    List<String> tags = ((item["tags"] ?? []) as List).cast<String>();
    String brief = item["brief"] ?? "";
    return GestureDetector(
      onTap: () {
        RouteHelper.toChatTheater(item);
      },
      child: Container(
        margin: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 12.w),
        height: 184.w,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 14.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Color(0xFF3E3A55), width: 1.w),
                gradient: LinearGradient(colors: [Color(0xFF231938), Color(0xFF211E32)]),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 124.w, right: 12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.w),
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.white)),
                    SizedBox(height: 12.w),
                    Text(
                      brief,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: Color(0xFF999999)),
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(alignment: WrapAlignment.start, runAlignment: WrapAlignment.start, spacing: 4.w, runSpacing: 4.w, children: tags.map((e) => _buildTagItem(e)).toList()),
                        ),

                        SizedBox(width: 4.w),
                        Container(
                          alignment: Alignment.center,
                          height: 28.w,
                          width: 52.w,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r), color: Color(0xFFFFE407)),
                          child: Text("GO", style: TextStyle(color: Color(0xFF0F0F0F), fontWeight: FontWeight.bold, fontSize: 13.sp)),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.w),
                  ],
                ),
              ),
            ),
            ClipRRect(borderRadius: BorderRadius.circular(16.w), child: CachedNetImage(imageUrl: coverUrl, height: 184.w, width: 112.w, fit: BoxFit.cover)),
          ],
        ),
      ),
    );
  }
}
