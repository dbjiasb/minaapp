import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/shared/app_theme.dart';

showCustomDialog(Widget widget) {
  Get.dialog(Dialog(backgroundColor: AppColors.secondPage, child: SizedBox(width: 200, height: 200, child: widget)));
}
