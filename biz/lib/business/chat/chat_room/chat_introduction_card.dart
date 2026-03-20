import 'package:biz/base/crypt/copywriting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/core/util/cached_image.dart';

class ChatIntroductionCard extends StatelessWidget {
  final ChatSession session;

  const ChatIntroductionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ChatIntroductionCardController(),
      tag: session.id,
    );

    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：头像和名称
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.w),
                child: CachedImage(
                  imageUrl: session.avatar,
                  width: 40.w,
                  height: 40.w,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (session.isAiChat)
                      Text(
                        Copywriting.security_aI_Character,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
              ),
              // 折叠/展开按钮（仅在有 bio 时显示）
              if (session.bio.isNotEmpty)
                GestureDetector(
                  onTap: controller.toggleExpanded,
                  child: Icon(
                    controller.isExpanded.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 24.w,
                  ),
                ),
            ],
          ),
          // 简介内容（可折叠）
          if (session.bio.isNotEmpty) ...[
            SizedBox(height: 12.w),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Text(
                session.bio,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14.sp,
                  height: 1.5,
                ),
                maxLines: controller.isExpanded.value ? null : 2,
                overflow: controller.isExpanded.value ? null : TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    ));
  }
}

class ChatIntroductionCardController extends GetxController {
  final RxBool isExpanded = false.obs;

  void toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }
}
