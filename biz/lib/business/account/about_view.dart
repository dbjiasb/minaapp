import 'package:biz/shared/app_brand.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:biz/base/app_info/app_manager.dart';
import 'package:biz/base/assets/image_path.dart';

import '../../base/crypt/security.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/cached_image.dart';
import '../../shared/app_theme.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(Security.security_about, style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: CachedImage(imageUrl: ImagePath.ic_arrow_left_circle, width: 32, height: 32), onPressed: () => RH.back()),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 100),
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(AppBrand.logoAsset, package: 'biz', width: 94, height: 94, semanticLabel: AppBrand.name)),
              const SizedBox(height: 12),
              const Text(AppBrand.fullName, style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'V ${AppManager.instance.appVersion} (${AppManager.instance.appBuild})',
                style: TextStyle(fontWeight: AppFonts.semiBold, fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
