import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/shared/app_theme.dart';

import '../base/crypt/security.dart';

typedef AsyncContentWidgetBuilder<T> = Widget Function(T data, BuildContext context);

extension AppBarExt on AppBar {
  static Widget mainEmpty({String? tips}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image.asset(ImagePath.img_empty, width: 172, height: 146),
          Text(
            tips ?? Security.security_empty,
            // style: const TextStyle(color: SWColors.t1, fontSize: 16, fontWeight: FontWeight.normal),
            style: TextStyle(color: AppColors.main, fontSize: 16, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  /// 异步body
  static Widget mainBody<T>(Future<T>? future, AsyncContentWidgetBuilder<T> builder, {Color loadColor = AppColors.primary, WidgetBuilder? loadBuilder}) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadBuilder != null ? loadBuilder(context) : Center(child: CircularProgressIndicator(color: loadColor));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.main, fontSize: 16, fontWeight: FontWeight.normal)));
        } else if (snapshot.hasData && snapshot.data is T) {
          return builder(snapshot.data as T, context);
        } else {
          return mainEmpty();
        }
      },
    );
  }

  static AppBar darkAppBar({
    String? title,
    TextStyle? titleTextStyle,
    Widget? titleView,
    Widget? leading,
    List<Widget>? actions,
    SystemUiOverlayStyle? style = SystemUiOverlayStyle.light,
    PreferredSizeWidget? bottom,
    Color backgroundColor = AppColors.base_background,
    Color? returnIconColor,
    bool? centerTitle = true,
    VoidCallback? onPressed,
    double? titleSpacing,
  }) {
    return AppBar(
      title:
          titleView ??
          (title != null ? Text(title, style: titleTextStyle ?? const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)) : null),
      backgroundColor: backgroundColor,
      elevation: 0.0,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: style,
      actions: actions,
      bottom: bottom,
      leading:
          leading ??
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(onPressed: onPressed ?? () => Get.back(), icon: Image.asset(ImagePath.ic_arrow_left_circle, fit: BoxFit.cover, height: 24, width: 24)),
          ),
    );
  }

  static PreferredSizeWidget buildCustomAppBar(Widget child, {List<Widget>? actions, double? leadingWidth, double titleSpacing = 10}) {
    return AppBar(
      backgroundColor: AppColors.base_background,
      title: Theme(data: ThemeData(highlightColor: Colors.transparent, splashColor: Colors.transparent), child: child),
      titleSpacing: titleSpacing,
      elevation: 0,
      actions: actions,
      leadingWidth: leadingWidth,
      leading: IconButton(icon: Image.asset(ImagePath.ic_arrow_left_circle, fit: BoxFit.cover, height: 24, width: 24), onPressed: Get.back),
    );
  }
}
