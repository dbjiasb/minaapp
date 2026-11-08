import 'package:biz/base/assets/image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../base/assets/image_path.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/images.dart';
import '../../shared/app_theme.dart';

typedef SyncBuilder<T> = Widget Function(T data, BuildContext context);

class UiUtils {
  static Widget buildCommonEmptyView({String? tips}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageView(Images.mina_empty_list, width: 150, height: 150),
          Text(
            tips ?? Copywriting.security_no_data,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFutureView<T>(
    Future<T>? future,
    SyncBuilder<T> builder, {
    Color loadColor = AppColors.accentText,
        Widget? emptyView
  }) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: loadColor));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              textAlign: TextAlign.center,
              '${snapshot.error}',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          );
        } else if (snapshot.hasData && snapshot.data is T) {
          return builder(snapshot.data as T, context);
        } else {
          return emptyView ?? buildCommonEmptyView();
        }
      },
    );
  }


  static PreferredSizeWidget buildSAppBar(Widget child,
      {List<Widget>? actions, double? leadingWidth, double titleSpacing = 10}) {
    return AppBar(
        backgroundColor: AppColors.background,
        title: child,
        titleSpacing: titleSpacing,
        elevation: 0,
        actions: actions,
        leadingWidth: leadingWidth);
  }
}
