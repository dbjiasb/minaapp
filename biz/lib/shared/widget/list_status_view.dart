import 'package:flutter/material.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/shared/app_theme.dart';

enum ListStatus { idle, loading, success, empty, error }

class ListStatusView extends StatelessWidget {
  final ListStatus status;
  String? emptyDesc;
  String? errorDesc;

  ListStatusView({super.key, required this.status, this.emptyDesc, this.errorDesc});

  Widget buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image.asset(ImagePath.img_empty, width: 180, height: 180),
          // Text(emptyDesc ?? Copywriting.security_no_data, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9EA1A8))),
          // Text(description ?? Copywriting.security_no_data, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9EA1A8))),
          // >>>>>>> feature/feature_1.0.0
        ],
      ),
    );
  }

  Widget buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image.asset(ImagePath.img_empty, width: 156, height: 156),
          Text(
            errorDesc ?? Copywriting.security_network_exception__please_try_again_later,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9EA1A8)),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingView() {
    return CircularProgressIndicator(color: AppColors.mainLightColor);
  }

  Widget buildSuccessView() {
    return const SizedBox.shrink();
  }

  Widget buildView(ListStatus status) {
    switch (status) {
      case ListStatus.idle:
        return buildSuccessView();
      case ListStatus.loading:
        return buildLoadingView();
      case ListStatus.empty:
        return buildEmptyView();
      case ListStatus.error:
        return buildErrorView();
      case ListStatus.success:
        return buildSuccessView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: buildView(status));
  }
}

// class ListStatusViewController extends GetxController {
//   var status = ListStatus.idle.obs;
// }
