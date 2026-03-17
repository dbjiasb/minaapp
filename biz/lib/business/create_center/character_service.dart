import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/api_service/api_request.dart';
import 'package:biz/base/api_service/api_service.dart';
import 'package:biz/core/account/account_service.dart';

import '../../base/crypt/apis.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/preferences/preferences.dart';
import '../../core/types.dart';
import '../../core/util/es_helper.dart';
import '../../core/util/log_util.dart';
import 'package:get/get.dart';

import '../../shared/toast/toast.dart';

final account = AccountService.instance.account;

final String kCachedKeyCreateOcConfig = Security.security_kCachedKeyCreateOcConfig;

class CharacterService {
  CharacterService._internal();
  static final CharacterService _instance = CharacterService._internal();
  static CharacterService get instance => _instance;
  factory CharacterService() {
    return _instance;
  }

  RxMap ocCreateDraft = Preferences.instance.getMap(kCachedKeyCreateOcConfig).obs;
  Map createRoleConfigs = {}; /// 创建流程使用，值是：CustomRoleInfo
  String traceId = ''; // 换脸id

  Future<Map?> getOCDraft() async {
    ApiRequest req = ApiRequest(Security.security_queryOcDraft, params: {});
    ApiResponse rsp = await ApiService.instance.sendRequest(req);
    if (rsp.isSuccess) {
      createRoleConfigs = rsp.data[Security.security_info]?[Security.security_roleInfo] ?? {};

      ocCreateDraft.value = rsp.data;
      Preferences.instance.setMap(kCachedKeyCreateOcConfig, rsp.data);
      return rsp.data;
    }
    return null;
  }

  void clearDraft() {
    try {
      Preferences.instance.setMap(kCachedKeyCreateOcConfig, {});
      createRoleConfigs = {};
      traceId = '';
      ocCreateDraft.value = Map<String, dynamic>.from({});
    } catch (e) {
      L.e('clearDraft error: $e');
    }
  }

  Future<Map?> getPhysiques() async {
    ApiRequest req = ApiRequest(Security.security_queryPhysiqueDetails, params: {});
    ApiResponse rsp = await ApiService.instance.sendRequest(req);
    if (rsp.isSuccess) {
      return rsp.data;
    }
    return null;
  }

  Future<Map?> checkPic(String url) async {
    ApiRequest req = ApiRequest(
      EncHelper.cr_ckpic,
      params: {EncHelper.cr_img_url: url},
    );
    ApiResponse rsp = await ApiService.instance.sendRequest(req);
    if (rsp.isSuccess) {
      return rsp.data;
    }
    return null;
  }

  Future<ApiResponse> customRole(
    Map<dynamic, dynamic> info,
    int optType,
    int? roleUid,
  ) async {

    // bool needGallery = Preferences.instance.needGalleryWhileCreateOC;

    bool needGallery = Preferences.instance.getBool(Security.security_kGeneratingGallery);
    final args = {
      Security.security_ocData: info,
      Security.security_opCode: optType,
      Security.security_pics: needGallery ? [Security.security_gallery] : [],
      Security.security_replaceId: traceId,
    };
    ApiRequest req = ApiRequest(Security.security_operateOc, params: args);
    return await ApiService.instance.sendRequest(req);
  }

  // 发送到服务器预保留
  Future<void> save() async {
    customRole(createRoleConfigs, 3, null);
  }

  // 发送到服务器更新
  Future<ApiResponse> update(Map config) async {
    return await customRole(config, 1, null);
  }

  Future<ApiResponse> createOCDraft() async {
    return await CharacterService.instance.customRole({}, 2, null);
  }

  // 发送到服务器创建
  Future<ApiResponse> createRole() async {
    return await customRole(createRoleConfigs, 0, null);
  }

  Future<ApiResponse> generateImageBg(
    Map<dynamic, dynamic> info,
    int generateOptType,
  ) async {
    final req = ApiRequest(
      Security.security_requestGen,
      params: {
        Security.security_ocData: info,
        Security.security_genCode: generateOptType,
      },
    );
    ApiResponse rsp = await ApiService.instance.sendRequest(req);
    // if (rsp.isSuccess) {
    //   return rsp.data;
    // }
    return rsp;
  }

  Future<ApiResponse> getGenResult(String traceId) async {
    ApiRequest req = ApiRequest(
      Security.security_requestGenResult,
      params: {Security.security_genId: traceId},
    );
    ApiResponse rsp = await ApiService.instance.sendRequest(req);
    return rsp;
  }

  Future<Map?> getEditRoleInfo(int uid) async {
    ApiRequest req = ApiRequest(Security.security_queryEditInfo, params: {Security.security_cid: uid});
    ApiResponse rsp = await ApiService.instance.sendRequest(req);
    if (rsp.isSuccess) {
      return rsp.data;
    }
    return null;
  }

  // 生成角色背景图
  Future<ApiResponse> createForBgRegeneration() async {
    ApiResponse ret = await CharacterService.instance.generateImageBg(createRoleConfigs, 0);
    if (ret.isSuccess && ret.data[Security.security_traceId] != null) {
      traceId = ret.data[Security.security_traceId];
    }
    return ret;
  }

  // 编辑时重新生成背景图
  Future<ApiResponse> editForBgRegeneration(Map config) async {
    ApiResponse rtn = await CharacterService.instance.generateImageBg(config, 1);
    if (rtn.isSuccess && rtn.data[Security.security_traceId] != null) {
      traceId = rtn.data[Security.security_traceId];
    }
    return rtn;
  }

  Future<ApiResponse> deleteOC(String uid) async {
    final req = ApiRequest(Apis.security_deleteCustomRole,
      params: {
        Security.security_roleUid: uid,
      },
    );
    Toast.loading();
    ApiResponse rsp = await ApiService.instance.sendRequest(req);
    if (!rsp.isSuccess) {
      Toast.show(rsp.description);
    } else {
      Toast.dismiss();
    }
    return rsp;
  }

  ///ai自动补齐
  Future<ApiResponse> aiWriter(Map roleInfo) async {
    final req = ApiRequest(Apis.security_generateCustomRoleTemplate,
      params: {
        Security.security_info: roleInfo,
      },
    );
    Toast.loading();
    ApiResponse rsp = await ApiService.instance.sendRequest(req);
    if (!rsp.isSuccess) {
      Toast.show(rsp.description);
    } else {
      Toast.dismiss();
    }
    return rsp;
  }

  // static const int AUDITING = 0;
  // static const int PASS = 1;
  // static const int NOT_PASS = 2;

  static Widget auditTextWidget(int? shared, int? audit, {bool isUserPage = false}) {
    List? shareAndAudit = auditText(shared, audit);
    if (shareAndAudit != null) {
      return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          padding: EdgeInsets.symmetric(vertical: isUserPage ? 4 : 3, horizontal: isUserPage ? 8 : 6),
          child: Text(shareAndAudit[0], style: TextStyle(
              color: shareAndAudit[1],
              fontSize: isUserPage ? 9 : 8,
              height: 1.1
              // fontWeight: FontWeight.bold
          ))
      );
    } else {
      return SizedBox.shrink();
    }
  }

  static List? auditText(int? shared, int? audit) {
    if (shared == null || audit == null) {
      return null;
    }
    if (shared == 0) {
      return [Security.security_private, Colors.white];
    } else {
      if (audit == 0) {
        return [Copywriting.security_under_review, const Color(0xFFFE56BB)];
      } else if (audit == 2) {
        return [Copywriting.security_not_approved, const Color(0xFFFE3A3A)];
      } else if (audit == 1){
        return [Security.security_public, Colors.white];
      } else {
        return null;
      }
    }
  }
}