import 'package:biz/base/crypt/images.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:biz/base/assets/image_path.dart';

import '../../../../base/assets/image_view.dart';

class ModeWidget {

  static Widget wealthIcon(int type, {double width = 16, double height = 16}) {
    return ImageView(type == 0 ? Images.security_coin_png : Images.security_gem_png, width: width, height: height);
  }

  static Widget wealthView(int type, int value) {
    return
      Center(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white12,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                ImageView(type == 0 ? Images.security_coin_png : Images.security_gem_png, width: 16, height: 16),
                4.horizontalSpace,
                Text('$value', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
              ],
            ),
          )
      );
  }

  static Widget modeStarView(int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(
          5,
              (index) => ImageView(
            index < stars ? Images.security_mode_star_light_webp : Images.security_mode_star_unlight_webp,
            width: 18,
            height: 18,
          )
      ),
    );
  }
}