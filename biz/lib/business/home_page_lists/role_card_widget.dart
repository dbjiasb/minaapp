import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:biz/core/util/cached_image.dart';

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
    String name = item['nickname'] ?? "";
    String coverUrl = item['coverUrl'] ?? "";
    String avatarUrl = item['avatarUrl'] ?? "";
    String bio = item['bio'] ?? "";

    // 如果是真人类型且 coverUrl 为空，使用 avatarUrl
    String imageUrl = coverUrl;
    if (isRealType && coverUrl.isEmpty && avatarUrl.isNotEmpty) {
      imageUrl = avatarUrl;
    }

    // Handle tags - they might be strings or maps
    List<String> tags = [];
    try {
      List rawTags = item['tags'] ?? [];
      for (var tag in rawTags) {
        if (tag is String) {
          tags.add(tag);
        } else if (tag is Map) {
          // If it's a map, try to get a name or title field
          String tagName = tag['name'] ?? tag['title'] ?? tag.toString();
          tags.add(tagName);
        }
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
                height: 120.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 12.w,
              left: 12.w,
              right: 12.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Role name
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.w),

                  // Brief description (only show if not empty)
                  if (bio.isNotEmpty)
                    Text(
                      bio,
                      style: TextStyle(
                        color: Color(0xFFb8b7b4),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  if (bio.isNotEmpty)
                    SizedBox(height: 8.w),

                  // Tags
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.w,
                      children: tags.take(2).map((tag) => _buildTag(tag)).toList(),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFFb8b7b4),
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
