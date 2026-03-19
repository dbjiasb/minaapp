import 'package:biz/base/crypt/routes.dart';
// import 'package:ns/ns.dart';
import 'package:get/get.dart';
import 'package:biz/base/preferences/preferences.dart';
import '../../base/api_service/api_service_export.dart';
import '../../base/crypt/apis.dart';
import '../../base/crypt/security.dart';

String kGetReportConfigRsp = Security.security_kGetReportConfigRsp;
String kPostMomentSuccess = Security.security_kPostMomentSuccess;
String kDeleteMomentSuccess = Security.security_kDeleteMomentSuccess;
String kUpdateMomentSuccess = Security.security_kUpdateMomentSuccess;

class MomentService extends GetxService {
  static MomentService get to => Get.find();
  Map reportStorage = Preferences.instance.getMap(kGetReportConfigRsp);

  static Future<Map> getMomentInfoList(
      {int listType = 0,
        int targetUid = 0,
        int fromId = 0,
        int size = 20}) async {
    Map req = {};
    req[Security.security_listType] = listType;
    req[Security.security_fromId] = fromId;
    req[Security.security_size] = size;
    req[Security.security_targetUid] = targetUid;

    ApiRequest request = ApiRequest(Apis.security_getMomentInfoList, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response.data;
  }

  static Future<ApiResponse> createMoment(Map momentInfo) async {
    Map req = {Security.security_momentInfo: momentInfo};
    ApiRequest request = ApiRequest(Apis.security_createMoment, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  static Future<Map> deleteMoment(int momentId) async {
    Map req = {Security.security_momentId: momentId};
    ApiRequest request = ApiRequest(Apis.security_deleteMoment, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response.data;
  }

  /// 修改后的代码
  static Future<ApiResponse> generatePostContent(
      int targetUid, List imageUrls) async {
    Map req = {Security.security_targetUid: targetUid, Security.security_imageUrls: imageUrls};
    ApiRequest request = ApiRequest(Apis.security_generatePostContent, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  static Future<ApiResponse> getUserCreationRecord(int targetUid,
      {int fromId = 0, int size = 20}) async {
    Map req = {Security.security_targetUid: targetUid, Security.security_fromId: fromId, Security.security_size: size};
    ApiRequest request = ApiRequest(Apis.security_getUserCreationRecord, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 1 image
  /// 2 video
  static Future<ApiResponse> createResource(int targetUid, String prompt,
      {int creationType = 1}) async {
    Map req = {
      Security.security_targetUid: targetUid,
      Security.security_prompt: prompt,
      Security.security_creationType: creationType
    };
    ApiRequest request = ApiRequest(Apis.security_createResource, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 修改后的代码
  static Future<ApiResponse> reloadCreationResource(int createId) async {
    Map req = {Security.security_creationId: createId};
    ApiRequest request = ApiRequest(Apis.security_reloadCreationResource, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 修改后的代码
  static Future<ApiResponse> getCreationResourceConfig(int targetUid) async {
    Map req = {Security.security_targetUid: targetUid};
    ApiRequest request = ApiRequest(Apis.security_getCreationResourceConfig, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 修改后的代码
  static Future<Map> getMomentDetail(int momentId) async {
    Map req = {Security.security_momentId: momentId};
    ApiRequest request = ApiRequest(Apis.security_getMomentDetail, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response.data;
  }

  static Future<ApiResponse> commentMoment(Map commentInfo) async {
    // 注意：此处假设 CommentInfo 可转换为 Map，或需要特殊处理
    Map req = {Security.security_commentInfo: commentInfo}; // 请根据 CommentInfo 的实际结构进行调整
    ApiRequest request = ApiRequest(Apis.security_commentMoment, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 修改后的代码
  Future<ApiResponse> report(int targetId, int type,
      {int reasonId = 0, String extraContent = ""}) async {
    Map req = {
      Security.security_targetId: targetId,
      Security.security_type: type,
      Security.security_reasonId: reasonId,
      Security.security_extraContent: extraContent
    };
    ApiRequest request = ApiRequest(Apis.security_report, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 修改后的代码
  static Future<Map> likeMomentAction(
      bool action, int momentId, {int authorUid = 0, int posterUid = 0}) async {
    Map req = {
      Security.security_action: action,
      Security.security_momentId: momentId,
      Security.security_authorUid: authorUid,
      Security.security_posterUid: posterUid
    };
    ApiRequest request = ApiRequest(Apis.security_likeMomentAction, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response.data;
  }

  ///CONTACT_LIST = 1;
  ///SELF_OC = 2;
  ///SEARCH = 3;
  ///MOMENT = 4;
  static Future<Map> getSelectCharacterList(
      {int listType = 4,
        int pageSize = 20,
        int pageIndex = 0,
        String keyword = ''}) async {
    Map req = {
      Security.security_keyword: keyword,
      Security.security_pageIndex: pageIndex,
      Security.security_pageSize: pageSize,
      Security.security_listType: listType
    };
    ApiRequest request = ApiRequest(Apis.security_getCharacterSelectList, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response.data;
  }

  Future<ApiResponse> getReportList() async {
    Map req = {};
    ApiRequest request = ApiRequest(Apis.security_getReportConfig, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 修改后的代码
  Future<ApiResponse> fetchReportList() async {
    // 注意：此方法因返回类型需要兼容历史逻辑，故暂未完全统一
    ApiResponse apiResponse = await getReportList();
    if (apiResponse.isSuccess) {
      Preferences.instance.setMap(kGetReportConfigRsp, apiResponse.data);
    }
    return apiResponse;
  }

  Future<Map> loadReportConfig() async {
    Map reportStorage = Preferences.instance.getMap(kGetReportConfigRsp);
    if (reportStorage.isNotEmpty) {
      return reportStorage;
    }
    ApiResponse rsp = await fetchReportList();
    return rsp.data;
  }
}