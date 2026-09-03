import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/api_service/api_request.dart';
import 'package:biz/base/api_service/api_service.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/shared/alert.dart';

import '../../../../base/api_service/api_response.dart';
import '../../../../base/crypt/apis.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../base/preferences/preferences.dart';
import '../../../../core/util/log_util.dart';
import 'res_downloader.dart';

class ScriptPlayAPI {
  static String get querySceneList => Security.security_getDatingList;
  static String get querySceneGameNodes => Security.security_getSceneScript;
  static String get selectOption => Security.security_sceneScriptAction;
  static String get startGame => Security.security_enterDating;
}

class ES {
  ///EncodedString
  static String get mode => Security.security_aiPersonality;
  static String get tuid => Security.security_targetUid;
  static String get sb => Security.security_selectBefore;
  static String get pa => Security.security_playerAction;
}

ScriptPlayService SPS = ScriptPlayService.instance;

class ScriptPlayService {
  static ScriptPlayService? _single;
  ScriptPlayService._();

  static ScriptPlayService get instance {
    _single ??= ScriptPlayService._()..init();
    return _single!;
  }

  void init() {
    ResDownloader.singleton;
  }

  Future<Map> querySceneList({int uid = 0}) async {
    ApiRequest req = ApiRequest(
      ScriptPlayAPI.querySceneList,
      params: {ES.tuid: uid},
    );
    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response.data;
  }

  Future<Map?> startGame(int tuid, int sceneId) async {
    ApiRequest req = ApiRequest(
      ScriptPlayAPI.startGame,
      params: {
        Security.security_aiUid: tuid,
        Security.security_datingId: sceneId,
        Security.security_fake: true,
        Security.security_abs: '1',
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response.data;
  }

  Future<Map?> querySceneGameNodes(int sceneId, sceneName, int nextId) async {
    ApiRequest req = ApiRequest(
      ScriptPlayAPI.querySceneGameNodes,
      params: {
        'ff@@lag': 1,
        Security.security_id: sceneId,
        Security.security_name: sceneName,
        Security.security_nextId: nextId,
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response.data;
  }

  Future<ApiResponse> selectOption(
    int sceneId,
    String sceneName,
    int nodeId,
  ) async {
    ApiRequest req = ApiRequest(
      ScriptPlayAPI.selectOption,
      params: {
        Security.security_id: sceneId,
        Security.security_name: sceneName,
        Security.security_nodeId: nodeId,
        'fa&&ke': '0',
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response;
  }

  Future<bool> checkOptionUnlock({int payType = 0, int cost = 0}) async {
    bool didShow = Preferences.instance.getBool(
      Security.security_optionUnlockAlert,
    );
    if (didShow) {
      return true;
    }

    bool didConfirm = await showConfirmAlert(
      Copywriting.security_unlock_tips,
      'Unlock will spend $cost ${payType == 1 ? 'diamonds' : 'coins'}, continue?',
    );
    if (didConfirm) {
      Preferences.instance.setBool(Security.security_optionUnlockAlert, true);
    }
    return didConfirm;
  }

  /// 剧本
  /// 获取剧本消息列表
  /// - [playId] 剧本ID
  /// - [nextId] 更新的id
  Future<ApiResponse> getChatScript(int scriptId, int nextId) async {
    ApiRequest req = ApiRequest(
      Apis.security_getChatScript,
      params: {
        Security.security_id: scriptId,
        Security.security_nextId: nextId,
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response;
  }

  Future<ApiResponse> chatScriptAction(
    int scriptId,
    int nodeId,
    String clientId,
  ) async {
    ApiRequest req = ApiRequest(
      Apis.security_chatScriptAction,
      params: {
        Security.security_id: scriptId,
        Security.security_nodeId: nodeId,
        Security.security_clientId: clientId,
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(req);
    return response;
  }
}
