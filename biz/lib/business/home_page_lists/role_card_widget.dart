import 'package:biz/base/crypt/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/core/util/cached_image.dart';

import '../../base/assets/image_view.dart';
import '../../base/crypt/images.dart';
import '../../shared/widget/app_widgets.dart';
import 'list_item.dart';

class RoleCardWidget extends StatelessWidget {
  final Map item;
  final VoidCallback onTap;
  final bool isRealType; // 是否是真人类型

  const RoleCardWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.isRealType = false,
  });

  @override
  Widget build(BuildContext context) {
    String name = item[Security.security_nickname] ?? "";
    String coverUrl = item[Security.security_coverUrl] ?? "";
    String avatarUrl = item[Security.security_avatarUrl] ?? "";
    String bio = item[Security.security_bio] ?? "";

    int acType = item["accountType"];
    String masterName = item[Security.security_robotInfo]?[Security.security_masterInfo]?[Security.security_nickName] ?? '';
    if (masterName == 'Official') {
      masterName = 'Mina';
    }
    String linkNum = RoleItem.shortStringForCount(item[Security.security_heatInfo]?[Security.security_connectors] ?? 0);
    String heatNum = RoleItem.shortStringForCount(item[Security.security_heatInfo]?[Security.security_heatValue] ?? 0);

    // 如果是真人类型且 coverUrl 为空，使用 avatarUrl
    String imageUrl = coverUrl;
    if (isRealType && coverUrl.isEmpty && avatarUrl.isNotEmpty) {
      imageUrl = avatarUrl;
    }

    // Handle tags - they might be strings or maps
    List<String> tags = [];
    try {
      List rawTags = item[Security.security_tags] ?? [];
      for (var tag in rawTags) {
        if (tag is String) {
          tags.add(tag);
        } else if (tag is Map) {
          // If it's a map, try to get a name or title field
          String tagName = tag[Security.security_name] ?? tag[Security.security_title] ?? tag.toString();
          tags.add(tagName);
        }
      }
      if (tags.length > 2) {
        tags.removeAt(0);
      }
    } catch (e) {
      // If parsing fails, just use empty tags
      tags = [];
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 166.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Stack(
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetImage(
                imageUrl: imageUrl,
                width: 166.w,
                height: 260.w,
                fit: BoxFit.cover,
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 140.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.7, 0.9, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 1),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 8.w,
              left: 12.w,
              right: 12.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                      AppWidgets.userTag(acType),
                    ],
                  ),
                  SizedBox(height: 4.w),

                  // Brief description (only show if not empty)
                  if (bio.isNotEmpty)
                    Text(
                      bio,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                        height: 1.3
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                  if (bio.isNotEmpty)
                    SizedBox(height: 8.w),

                  // Tags
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.w,
                      children: tags.take(4).map((tag) => _buildTag(tag)).toList(),
                    ),

                  if (!isRealType) SizedBox(height: 8),
                  if (!isRealType)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            masterName.isEmpty ? '' : '@$masterName',
                            style: TextStyle(color: Color(0xFFBEBFC5), fontSize: 8, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Row(
                          children: [
                            ImageView(Images.security_linknum_webp, width: 12, height: 12).marginOnly(right: 2),
                            Text(linkNum, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                            SizedBox(width: 4),
                            ImageView(Images.security_heart_count_webp, width: 12, height: 12).marginOnly(right: 2),
                            Text(heatNum, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
