import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/character_card.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:biz/core/util/cached_image.dart';

import '../../base/preferences/preferences.dart';
import '../../shared/widget/app_widgets.dart';

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

    int acType = item[Security.security_accountType];
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
          String tagName =
              tag[Security.security_name] ??
              tag[Security.security_title] ??
              tag.toString();
          tags.add(tagName);
        }
      }
      if (tags.length > 2) {
        tags.removeAt(0);
      }
    } catch (e) {
      tags = [];
    }

    if (AppAppearance.isLight) {
      return CharacterCard(
        image: CachedNetImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        name: name,
        badge: CharacterCardBadge(
          label: acType == 0 ? Security.security_Real : Security.security_AI,
          backgroundColor: AppColors.chatAction,
          foregroundColor: AppColors.onColor,
        ),
        bio: bio,
        tags: Preferences.instance.showListCardTags ? tags : const [],
        onTap: onTap,
        footer: CharacterCardAction(
          label: Security.security_Chat,
          backgroundColor: AppColors.chatAction,
          foregroundColor: AppColors.onColor,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 166.w,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
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
                alignment: Alignment.topCenter,
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
                    stops: [0.0, 1.0],
                    colors: [
                      Colors.transparent,
                      AppColors.surfaceMuted.withValues(alpha: 1),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(top: 8, left: 8, child: AppWidgets.userTag(acType)),

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
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.w),

                  // Brief description (only show if not empty)
                  if (bio.isNotEmpty)
                    Text(
                      bio,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  if (bio.isNotEmpty) SizedBox(height: 8.w),

                  // Tags
                  if (tags.isNotEmpty && Preferences.instance.showListCardTags)
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.w,
                      children: tags
                          .take(4)
                          .map((tag) => _buildTag(tag))
                          .toList(),
                    ),

                  const SizedBox(height: 10),
                  CharacterCardAction(
                    label: Security.security_Chat,
                    backgroundColor: AppColors.chatAction,
                    foregroundColor: AppColors.onColor,
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
        color: AppColors.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.9),
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
