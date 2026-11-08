import 'package:biz/shared/app_theme.dart';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

showAppBottomSheet(List<Widget> widgets) {
  Get.bottomSheet(
    SafeArea(bottom: false, child: Container(color: AppColors.surface, child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [...widgets])))),
  );
}
