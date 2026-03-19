import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../base/crypt/security.dart';
import '../../../base/report/report_manager.dart';
import '../../../base/router/router_names.dart';
import '../../../base/ui/lazy_indexed_stack.dart';
import '../../../core/util/cached_image.dart';
import '../../../shared/app_theme.dart';
import '../constant_state.dart';
import 'moment_item_view.dart';
import 'moment_list_view_logic.dart';

class MomentListViewPage extends GetView<MomentListViewLogic> {
  @override
  MomentListViewLogic get controller => Get.put(MomentListViewLogic());

  const MomentListViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    return Scaffold(
      backgroundColor: Color(0xFF12151C),
      appBar: AppBar(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, toolbarHeight: 0),
      body: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 40),
        child: Column(
          children: [
            Row(
              children: [...controller.titleList.asMap().entries.map((entry) => _buildItemTab(entry.key, entry.value)), const Spacer(), _buildPostBnt()],
            ).paddingSymmetric(vertical: 6),
            Expanded(
              child: Obx(() {
                return LazyIndexedStack(
                  index: controller.currentIndex.value,
                  children: controller.titleList.asMap().entries.map((entry) => _buildPageView(entry.key, entry.value)).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTab(int index, String title) {
    return GestureDetector(
      onTap: () {
        controller.currentIndex.value = index;
      },
      child: Obx(() {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: index == controller.currentIndex.value ? const Color(0x1AFF56BB) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: index == controller.currentIndex.value ? AppColors.primary : const Color(0xFFABABAD),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPostBnt() {
    return GestureDetector(
      onTap: () {
        ReportManager.sendEvent(Security.security_click_post_bnt, {Security.security_type: "2"});

        Get.toNamed(Routers.createMoment);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(100)),
        child: Row(
          children: [
            CachedImage(imageUrl: '${MomentRes.base}iic_add.webp', width: 16, height: 16),
            const SizedBox(width: 4),
            Text(Security.security_post, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  IndexedStackChild _buildPageView(int index, String title) {
    return IndexedStackChild(child: MomentItemView(index));
  }
}
