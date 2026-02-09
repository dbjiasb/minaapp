import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

showAppBottomSheet(List<Widget> widgets) {
  Get.bottomSheet(
    SafeArea(bottom: false, child: Container(color: Colors.white, child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [...widgets])))),
  );
}
