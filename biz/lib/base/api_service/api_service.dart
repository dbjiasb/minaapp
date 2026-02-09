import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:biz/base/app_info/app_manager.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/environment/environment.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/util/device_util.dart';
import '../../core/util/log_util.dart';
import '../casual/casual.dart';
import '../crypt/crypt.dart';
import 'api_config.dart';
import 'api_request.dart';
import 'api_response.dart';

class ApiService {
  //生成单利
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  late final Dio _dio;
  late Map<String, dynamic> _headers;
  final Map<String, String> _tokens = {};

  ApiService._internal() {
    init();
  }

  static ApiService get instance => _instance;

  void init() {
    _headers = {Other.security_content_Type: Other.security_application_json, Security.security_Accept: Other.security_application_json};
    _dio = Dio(
      BaseOptions(baseUrl: ApiConfig.baseUrl, connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30), headers: _headers),
    );
  }

  //headers
  void addHeaders(Map<String, dynamic> headers) {
    _headers.addAll(headers);
  }

  addTokens(Map<String, String> tokens) {
    _tokens.addAll(tokens);
  }

  String _randomIP = '';

  String get randomIP {
    if (_randomIP.isEmpty) {
      _randomIP = Casual.randomIP();
    }
    return _randomIP;
  }

  String _randomTimeZone = '';

  String get randomTimeZone {
    if (_randomTimeZone.isEmpty) {
      _randomTimeZone = Casual.randomTimeZone();
    }
    return _randomTimeZone;
  }

  Map<String, dynamic> base() {
    return {
      ..._tokens,
      Security.security_did: DeviceUtil.deviceId,

      /// guid
      Security.security_platform: Platform.isIOS ? 1 : 0,

      /// platform
      Security.security_app: Platform.isAndroid ? "mina&google" : "mina&apple",

      ///channel
      Security.security_lang: Security.security_en,
      Security.security_ver: AppManager.instance.appVersion,
      Security.security_build: "1",

      /// versionname
      Security.security_sysVer: randomIP,
      Security.security_zone: randomTimeZone,

      /// timezone
      Security.security_deviceModel: Security.security_deviceName,
    };
  }

  static int requestIndex = 0;
  Future<ApiResponse> sendRequest(ApiRequest request) async {
    requestIndex++;
    bool isDebug = kDebugMode || Environment.instance.isDebug;
    try {
      Map<String, dynamic> body = {
        Security.security_method: request.method,
        Security.security_data: [
          {Security.security_base: base(), ...request.params},
          {Security.security_encode: true, Security.security_key: cryptKey},
        ],
      };

      if (isDebug) {
        L.i('[apiService] ${request.method} start sendRequest $body');
      } else {
        if (requestIndex % 10 == 0) {
          L.i('[apiService] ${request.method} start sendRequest $body');
        } else {
          L.d('[apiService] ${request.method} start sendRequest ${request.params}');
        }
      }

      Map data = {};
      data[Constants.apiName] = request.method;
      data[Security.security_body] = Encryptor.encryptMap(body);

      Dio dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          validateStatus: (status) => status! < 500,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            Other.security_content_Type: Other.security_application_json,
            Other.security_crypt_Tag: cryptTag,
            ..._tokens,
          }, // 默认 Header
        ),
      );

      final response = await dio.post(ApiConfig.path, data: data);
      ApiResponse apiResponse = ApiResponse.withResponse(response.data);
      if (isDebug) {
        L.i('[apiService] ${request.method} end, response: ${apiResponse.toString()}');
      } else {
        L.i('[apiService] ${request.method} end, netCode: ${apiResponse.statusCode}, biz code: ${apiResponse.bsnsCode}, description: ${apiResponse.description}');
      }
      return apiResponse;
    } catch (e) {
      L.i('[apiService] ${request.method} end error ${e.toString()}');
      return ApiResponse.withError({Security.security_code: -1, Security.security_description: Copywriting.security_network_error__please_try_again_later});
    }
  }
}
