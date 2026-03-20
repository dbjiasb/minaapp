import 'package:biz/base/crypt/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/core/account/account_service.dart';

import '../../base/assets/image_view.dart';
import '../../base/router/route_helper.dart';

enum BalanceType { coin, gem }

class BalanceViewStyle {
  final Color color; // 添加final
  final Color bgColor;
  final double height;
  final double borderRadius;
  final double padding;

  const BalanceViewStyle({
    // 添加const构造函数
    required this.color,
    required this.bgColor,
    required this.height,
    required this.borderRadius,
    required this.padding,
  });

  static const defaultStyle = BalanceViewStyle(
    // 改为const常量
    color: Colors.white,
    bgColor: Color(0x1AFFFFFF),
    height: 20,
    borderRadius: 10,
    padding: 4,
  );
}

class BalanceView extends StatelessWidget {
  final BalanceType type;
  final BalanceViewStyle style;

  const BalanceView({
    super.key,
    required this.type,
    this.style = BalanceViewStyle.defaultStyle, // 使用const常量
  });

  String get icon => type == BalanceType.coin ? Images.security_coin_png : Images.security_gem_png;

  String get addIcon => Images.security_chat_add_png;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RH.toRecharge(type == BalanceType.coin ? 0 : 1);
      },
      child: Container(
        height: style.height,
        decoration: BoxDecoration(color: style.bgColor, borderRadius: BorderRadius.all(Radius.circular(style.borderRadius))),
        padding: EdgeInsets.symmetric(horizontal: style.padding),
        child: Row(
          children: [
            ImageView(icon, width: 16, height: 16),
            SizedBox(width: 4),
            Obx(
              () => Text(
                type == BalanceType.coin ? MyAccount.coins.toString() : MyAccount.gems.toString(),
                style: TextStyle(fontSize: 11, color: style.color, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 4),
            ImageView(
              addIcon,
              width: 16,
              height: 16,
              color: style.color, // 使用style中的颜色
            ),
          ],
        ),
      ),
    );
  }
}
