import 'package:flutter/material.dart';

//@configurable
abstract interface class IToast {
  TransitionBuilder init();
  void show(String msg);
  void loading({String? status});
  void dismiss();
  void error(String msg);
  void success(String msg);
}