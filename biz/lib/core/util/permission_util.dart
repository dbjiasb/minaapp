import 'package:biz/base/crypt/routes.dart';
import 'package:biz/shared/alert.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:biz/core/util/log_util.dart';

import '../../base/crypt/copywriting.dart';
import '../../base/crypt/security.dart';

class PermissionUtil {
  static Future<bool> checkCallPermission(int type) async {
    /// 录音权限获取
    if (!await Permission.microphone.isGranted) {
      final permissionStatus = await Permission.microphone.request();
      if (!permissionStatus.isGranted) {
        showConfirmAlert(Copywriting.security_permission_required, Copywriting.security_please_allow_access_to_the_microphone_in_the_settings, confirmText: Copywriting.security_go_Setting, cancelText: Security.security_cancel, onConfirm: () {
          openAppSettings();
        });
        L.e('[Call] microphone permission denied');
        return false;
      }
    }

    /// 拍照权限获取
    if (type == 0 && !await Permission.camera.isGranted) {
      final permissionStatus = await Permission.camera.request();
      if (!permissionStatus.isGranted) {

        showConfirmAlert(Copywriting.security_permission_required, Copywriting.security_please_allow_access_to_the_camera_in_the_settings, confirmText: Copywriting.security_go_Setting, cancelText: Security.security_cancel, onConfirm: () {
          openAppSettings();
        });
        L.e('[Call] camera permission denied');
        return false;
      }
    }

    return true;
  }
}
