import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/shared/app_theme.dart';

import '../base/crypt/security.dart';
import '../core/util/cached_image.dart';

typedef AsyncContentWidgetBuilder<T> = Widget Function(T data, BuildContext context);

extension AppBarExt on AppBar {
  static Widget mainEmpty({String? tips}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // child: CachedImage(imageUrl: ImagePath.img_empty, width: 172, height: 146),
          Text(
            tips ?? Security.security_empty,
            // style: const TextStyle(color: SWColors.t1, fontSize: 16, fontWeight: FontWeight.normal),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  /// 异步body
  static Widget mainBody<T>(Future<T>? future, AsyncContentWidgetBuilder<T> builder, {Color loadColor = AppColors.accentText, WidgetBuilder? loadBuilder}) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadBuilder != null ? loadBuilder(context) : Center(child: CircularProgressIndicator(color: loadColor));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.normal)));
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
    SystemUiOverlayStyle? style = AppAppearance.overlayStyle,
    PreferredSizeWidget? bottom,
    Color backgroundColor = AppColors.background,
    Color? returnIconColor,
    bool? centerTitle = true,
    VoidCallback? onPressed,
    double? titleSpacing,
  }) {
    return AppBar(
      title:
          titleView ??
          (title != null ? Text(title, style: titleTextStyle ?? const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)) : null),
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
            child: IconButton(onPressed: onPressed ?? () => Get.back(), icon: Icon(Icons.arrow_back_ios_new_rounded, color: returnIconColor ?? AppColors.textPrimary, size: 22)),
          ),
    );
  }

  static PreferredSizeWidget buildCustomAppBar(Widget child, {List<Widget>? actions, double? leadingWidth, double titleSpacing = 10}) {
    return AppBar(
      backgroundColor: AppColors.background,
      title: child,
      titleSpacing: titleSpacing,
      elevation: 0,
      actions: actions,
      leadingWidth: leadingWidth,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 22), onPressed: Get.back),
    );
  }
}
