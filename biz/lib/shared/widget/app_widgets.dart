import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/material.dart';

import '../../base/assets/image_view.dart';
import '../../base/router/route_helper.dart';

class AppWidgets {
  static userTag(int type, {String? id, bool isGroup = false}) {
    if (isGroup) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          margin: const EdgeInsets.symmetric(horizontal: 8, ),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.purple),
          child: Text(
            'Group',
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800),
          )
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ImageView((id == '100000' || id == '100001') ? Images.security_tag_official_png : (type == 0 ? Images.security_tag_real_png : Images.security_tag_ai_png), height: 16, fit: BoxFit.fitHeight),
    );
  }

  static backBtn({VoidCallback? onPressed, Color? color}) {
    return IconButton(
      icon: ImageView(Images.security_back_png, height: 24, fit: BoxFit.fitHeight, color: color),
      onPressed: onPressed ?? RouteHelper.back,
    );
  }
}
