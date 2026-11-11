import 'package:biz/shared/app_theme.dart';
import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/material.dart';

import '../../base/assets/image_view.dart';
import '../../base/router/route_helper.dart';
import 'app_back_button.dart';
import 'character_card.dart';

class AppWidgets {
  static userTag(int type, {String? id, bool isGroup = false}) {
    if (isGroup) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.purple,
        ),
        child: Text(
          'Group',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    final isOfficial = id == '100000' || id == '100001';
    if (!isOfficial && type != 0) {
      return CharacterCardBadge(
        label: Security.security_AI,
        backgroundColor: AppColors.chatAction,
        foregroundColor: AppColors.onColor,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ImageView(
        isOfficial
            ? Images.security_tag_official_png
            : Images.security_tag_real_png,
        height: 16,
        fit: BoxFit.fitHeight,
      ),
    );
  }

  static backBtn({VoidCallback? onPressed, Color? color}) {
    return AppBackButton(
      color: color,
      onPressed: onPressed ?? RouteHelper.back,
    );
  }
}
