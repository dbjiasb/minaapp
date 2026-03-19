import 'package:biz/base/preferences/preferences.dart';
import 'package:get/get.dart';

import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/crypt/apis.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/push_service/push_service.dart';
import '../../../core/util/log_util.dart';
import '../../../shared/alert.dart';

class ETaskFinishStatus {
  static const int NOT_FINISH = 0;
  static const int HAS_FINISHED = 1;
  static const int HAS_RECEIVED_AWARD = 2;
}

String kStorageGetMatchTaskRsp = Security.security_kStorageGetMatchTaskRsp;

class MatchService extends GetxService {
  static MatchService get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    addObservers();

    Future.delayed(Duration(milliseconds: 3000), () {
      getMatchTaskProcess();
      getVideoCallMatchConfig();
    });
  }

  ///匹配过滤请求
  Map? _filterReq;

  set setFilterReq(Map? req) {
    _filterReq = req;
  }

  Map? get getFilterReq => _filterReq;

  /// 右滑列表
  Future<ApiResponse> rightSlideList({int offset = 0, int limit = 0}) async {
    Map req = {Security.security_offset: offset, Security.security_limit: limit};
    ApiRequest request = ApiRequest(Apis.security_rightSlideList, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 滑动列表
  Future<ApiResponse> slidePendingList(int pageNumber, {bool useCache = false}) async {
    Map req = {Security.security_limit: 30, Security.security_pageNum: pageNumber};
    ApiRequest request = ApiRequest(Apis.security_slidePendingList, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  Future<ApiResponse> slidePendingListWithReq(Map? req, {bool useCache = false}) async {
    req ??= {};
    ApiRequest request = ApiRequest(Apis.security_slidePendingList, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  Future<ApiResponse> getMainUserList({int poolVersion = 0, int pageIndex = 0, int pageSize = 20, int listType = 0}) async {
    Map req = {
      Security.security_poolVersion: poolVersion,
      Security.security_pageIndex: pageIndex,
      Security.security_pageSize: pageSize,
      Security.security_listType: listType,
    };
    ApiRequest request = ApiRequest(Apis.security_getMainUserList, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 获取collect列表
  Future<ApiResponse> getUserStarList({int pageIndex = 0, int pageSize = 50}) async {
    Map req = {Security.security_pageIndex: pageIndex, Security.security_pageSize: pageSize};
    ApiRequest request = ApiRequest(Apis.security_getUserStarList, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 左滑
  Future<ApiResponse> slideLeft(int otherUid) async {
    Map req = {Security.security_otherUid: otherUid};
    ApiRequest request = ApiRequest(Apis.security_slideLet, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  /// 右滑
  Future<ApiResponse> slideRight(int otherUid) async {
    Map req = {Security.security_otherUid: otherUid};
    ApiRequest request = ApiRequest(Apis.security_slideRight, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  // Future<ApiResponse> star(int otherUid, {bool wantCollect = true}) async {
  //   L.i('star $otherUid $wantCollect');
  //   int star = wantCollect ? 1 : 2;
  //   Map req = {Security.security_otherUid: otherUid, Security.security_action: star};
  //   ApiRequest request = ApiRequest('star', params: req);
  //   ApiResponse response = await ApiService.instance.sendRequest(request);
  //   EventCenter.instance.sendEvent('kStarNotification', otherUid);
  //   return response;
  // }

  Future<ApiResponse> startVideoCallMatch() async {
    Map req = {};
    ApiRequest request = ApiRequest(Apis.security_startVideoCallMatch, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  Future<ApiResponse> cancelVideoCallMatch() async {
    Map req = {};
    ApiRequest request = ApiRequest(Apis.security_cancelVideoCallMatch, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  Future<ApiResponse> getVideoCallMatchInfo() async {
    Map req = {};
    ApiRequest request = ApiRequest(Apis.security_getVideoCallMatchInfo, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  static Map matchTaskProcessRsp = Preferences.instance.getMap(kStorageGetMatchTaskRsp);
  RxMap matchTaskCache = matchTaskProcessRsp.obs;

  bool get isShowMatchTask =>
      (matchTaskCache[Security.security_childrenTaskProcesses] ?? []).isNotEmpty &&
      (matchTaskCache[Security.security_mainTaskProcesses]?.finishStatus ?? 0) != ETaskFinishStatus.HAS_RECEIVED_AWARD;

  Future<ApiResponse> getMatchTaskProcess() async {
    Map req = {};
    ApiRequest request = ApiRequest(Apis.security_getMatchTaskProcess, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      matchTaskCache.value = response.data;
      Preferences.instance.setMap(kStorageGetMatchTaskRsp, response.data);
    }
    return response;
  }

  void addObservers() {
    PushService.instance.addObserver(PushId.kVideoMatchSuccessMessageId, (event) async {
      Map data = event.data;
      L.i('VideoCallMatchSuccessNotice matchId ${data[Security.security_matchId]}');
      if (data[Security.security_matchId] != 0) {
        ApiResponse apiResponse = await confirmVideoCallMatchResult(data[Security.security_matchId]);
        if (apiResponse.isSuccess) {
          showConfirmAlert(
            Security.security_tips,
            Copywriting.security_the_user_has_been_matched__and_the_other_party_accepts_and_enters_the_video_call,
            cancelText: Security.security_cancel,
            confirmText: Security.security_confirm,
            onConfirm: () {},
          );
        }
      }
    });
  }

  Future<ApiResponse> confirmVideoCallMatchResult(int matchId, {int accept = 1}) async {
    Map req = {Security.security_matchId: matchId, Security.security_accept: accept};
    ApiRequest request = ApiRequest(Apis.security_confirmVideoCallMatchResult, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  RxMap videoCallConfigCache = Preferences.instance.getMap(Security.security_videoCallMatchConfig).obs;

  bool get canUseUserMatchFunction => videoCallConfigCache[Security.security_canUseUserMatchFunction] == 1;

  bool get canUseAnchorMatchFunction => videoCallConfigCache[Security.security_canUseAnchorMatchFunction] == 1;

  Map? get userMatchTrialOriginalCostInfo => videoCallConfigCache[Security.security_userMatchTrialOriginalCostInfo];

  List get avatarUrlPlaceHolders => videoCallConfigCache[Security.security_avatarUrlPlaceHolders] ?? [];

  Future<ApiResponse> getVideoCallMatchConfig() async {
    Map<String, dynamic> req = {};
    ApiRequest request = ApiRequest(Apis.security_getVideoCallMatchConfig, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);

    if (response.isSuccess) {
      Map responseData = response.data;
      Map? configData = responseData[Security.security_config];
      if (configData?.isNotEmpty ?? false) {
        videoCallConfigCache.value = configData!;
        Preferences.instance.setMap(Security.security_videoCallMatchConfig, configData);
      }
    }
    return response;
  }
}
