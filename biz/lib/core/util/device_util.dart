import 'dart:io';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../base/crypt/security.dart';
import '../../base/preferences/preferences.dart';
import 'log_util.dart';


class DeviceUtil {
  static bool deviceInChina = false;
  static String _deviceId = '';
  static FlutterSecureStorage storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true,));

  static get didStorageKey => Security.security_kPhoneId;
  static get keyChainKey => Security.security_kPhoneId;

  static Future init() async {
    String tz = DateTime.now().timeZoneName;
    Locale? deviceLocale = Get.deviceLocale;

    if (tz == Security.security_cST
        || deviceLocale?.languageCode == Security.security_zh
        || deviceLocale?.countryCode == Security.security_cN) {
      deviceInChina = true;
    }
    await initDeviceId();
  }

  static Future initDeviceId() async {
    String? did = Preferences.instance.getString(didStorageKey);
    did ??= await storage.read(key: keyChainKey);
    if (did != null) {
      _deviceId = did;
      return;
    }
    _deviceId = (const Uuid().v4()).replaceAll('-', '');
    try {
      Preferences.instance.setString(didStorageKey, _deviceId);
      storage.write(key: keyChainKey, value: _deviceId);
      L.i('[BizRequest] [deviceId] write deviceId success: $_deviceId');
    } catch (e) {
      L.e('[BizRequest] [deviceId] write deviceId error: $e');
    }
  }

  static String get deviceId {
    if (_deviceId.isEmpty) {
      /// 正常不会走到这里，initDeviceId已经初始化过了，但是为了安全考虑，再次初始化
      L.e('[BizRequest] [deviceId] deviceId is empty, gen a new one');
      _deviceId = (const Uuid().v4()).replaceAll('-', '');
      Preferences.instance.setString(didStorageKey, _deviceId);
      storage.write(key: keyChainKey, value: _deviceId);
    }
    return _deviceId;
  }

  static String _model = '';
  static String _deviceTypeName = '';

  static DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> get model async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo info = await _deviceInfo.androidInfo;
      _model = info.model;
      _deviceTypeName = info.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo info = await _deviceInfo.iosInfo;
      _model = info.utsname.machine;
      _deviceTypeName = info.model;
    }

    return _model;
  }

  static Future<bool> get isPad async {
    await model;
    return _deviceTypeName.contains('iPad');
  }
}