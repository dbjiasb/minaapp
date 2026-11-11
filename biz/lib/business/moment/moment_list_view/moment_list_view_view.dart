import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../base/crypt/security.dart';
import '../../../base/report/report_manager.dart';
import '../../../base/router/router_names.dart';
import '../../../shared/app_theme.dart';
import 'moment_item_view.dart';

class MomentListViewPage extends StatelessWidget {
  const MomentListViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      primary: false,
      body: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: AppAppearance.isLight ? 8 : 40,
        ),
        child: const MomentItemView(0),
      ),
      floatingActionButton: _buildPostButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPostButton() {
    return FloatingActionButton.extended(
      heroTag: 'createMoment',
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textPrimary,
      shape: const StadiumBorder(),
      onPressed: () {
        ReportManager.sendEvent(Security.security_click_post_bnt, {
          Security.security_type: "2",
        });

        Get.toNamed(Routers.createMoment);
      },
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(
        Security.security_post,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
