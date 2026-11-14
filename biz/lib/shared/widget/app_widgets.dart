import 'package:biz/base/crypt/images.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:flutter/material.dart';

import '../../base/assets/image_view.dart';
import '../../base/router/route_helper.dart';

class AppWidgets {
  static Widget userTag(int type, {String? id, bool isGroup = false}) {
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
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    final isOfficial = ChatSession.isOfficialAccount(id);
    final tagImage = isOfficial
        ? Images.security_tag_official_png
        : (type == 0 ? Images.security_tag_real_png : Images.security_tag_ai_png);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ImageView(tagImage, height: 16, fit: BoxFit.fitHeight),
    );
  }

  static backBtn({VoidCallback? onPressed, Color? color}) {
    return IconButton(
      icon: ImageView(Images.security_back_png, height: 24, fit: BoxFit.fitHeight, color: color),
      onPressed: onPressed ?? RouteHelper.back,
    );
  }
}
