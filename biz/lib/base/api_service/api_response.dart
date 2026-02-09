import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';

import '../crypt/crypt.dart';

enum ApiError {
  notEnoughBalance(2000),
  notEnoughGems(2008),
  verifyTokenDuplicate(2010);

  final int v;
  const ApiError(this.v);
}



class ApiResponse {
  final Map<String, dynamic> response;
  ApiResponse({required this.response});

  late final String description;
  late final int statusCode;
  late final String trunk;
  Map data = {};

  int get bsnsCode => data[Constants.statusData]?[Security.security_code] ?? -1;

  bool get isSuccess => statusCode == 200 && bsnsCode == 0;

  static withResponse(Map<String, dynamic> response) {
    ApiResponse apiResponse =
        ApiResponse(response: response)
          ..statusCode = int.tryParse(response[Security.security_code]) ?? 0
          ..trunk = response[Security.security_body] ?? '{}';
    try {
      final string = Decryptor.decrypt(apiResponse.trunk);
      JsonDecoder decoder = const JsonDecoder();

      apiResponse.data = decoder.convert(string);
      apiResponse.description = apiResponse.data[Constants.statusData]?[Security.security_msg] ?? '';
    } catch (e) {
      apiResponse.description = Copywriting.security_network_error__please_try_again_later;
      debugPrint('ApiResponse withData error: $e');
    }
    return apiResponse;
  }

  static withError(Map<String, dynamic> error) {
    return ApiResponse(response: error)
      ..statusCode = error[Security.security_code] ?? 0
      ..description = error[Security.security_description] ?? {};
  }

  dynamic valueForKey(String key) {
    return data[key];
  }

  @override
  String toString() {
    return 'ApiResponse{content: $data, describe: $description, statusCode: $statusCode}';
  }
}
