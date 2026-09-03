import 'package:biz/base/crypt/routes.dart';
import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../../../base/api_service/api_response.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../core/util/cached_image.dart';
import '../../../../core/util/log_util.dart';
import '../../ai_mode/widget/ai_mode_popup.dart';
import '../service/servce.dart';
import '../service/res_downloader.dart';

extension ModeExt on Map {
  bool get isValid => this[Security.security_id]?.isNotEmpty ?? false;
}

bool isValidNode(dynamic node) => (node[Security.security_id] ?? '').isNotEmpty;

extension MapExt on Map {
  bool get isMyNode => this[ES.pa] == 1;

  bool get isNarrator => this[Security.security_type] == 1;
  bool get isUserAction => this[Security.security_type] == 6;

  bool get isValid =>
      this[Security.security_id] > 0 &&
      this[Security.security_type] > 0 &&
      this[Security.security_type] <= 6;

  bool get needCost {
    if (isEmpty) return false;
    if ((this[Security.security_values] ?? []).isEmpty) return false;
    for (var value in this[Security.security_values]) {
      if ((value[Security.security_cost] ?? 0) > 0) return true;
    }
    return false;
  }
}

/// 约会场景页
class ScenePlayLogic extends GetxController {
  ScenePlayLogic();

  String resUrl = '';
  String resMd5 = '';

  late String cName;
  int scId = 0;
  int nId = 0;
  late String tAvatar;
  late String tName;
  late int tuid;

  List<dynamic> sceneNodes = [];
  RxMap currentNode = {}.obs;
  Map? selectedAction;

  bool isEnd = false;
  bool querying = false;
  RxBool isReady = false.obs;

  ///是否拉到nodes
  RxBool isResPrepared = false.obs;

  ///是否下载到资源

  RxString currentNodeBg = ''.obs;
  RxInt progress = 0.obs;
  int clickTime = 0;

  @override
  void onInit() {
    super.onInit();
    setupParams();
    init();
  }

  @override
  onReady() {
    super.onReady();
  }

  void setupParams() {
    Map params = Get.parameters;
    cName = params[Security.security_sceneName] ?? '';
    tAvatar = params[Security.security_targetAvatar] ?? '';
    tName = params[Security.security_targetName] ?? '';
    scId = int.parse(params[Security.security_sceneId] ?? '0');
    nId = int.parse(params[Security.security_nextId] ?? '0');
    tuid = int.parse(params[Security.security_targetUid] ?? '0');
    resUrl = params[Security.security_resourceUrl] ?? '';
    resMd5 = params[Security.security_resourceMd5] ?? '';
  }

  void startGame() async {
    SPS.startGame(tuid, scId);
  }

  void init() async {
    startGame();
    await downloadRes();
    querySceneGameNodes();
  }

  //下一句
  void goNext() async {
    int nowTimeMs = DateTime.now().millisecondsSinceEpoch;
    if (nowTimeMs - clickTime < 500) {
      return;
    }
    clickTime = nowTimeMs;
    if (currentNode.isUserAction) return;

    SPS.querySceneGameNodes(scId, cName, currentNode[Security.security_id]);
    L.i('[Chat][Date] isEnd: $isEnd, left node count: ${sceneNodes.length}');
    if (isEnd && sceneNodes.isEmpty) {
      back();
    } else {
      updateCurrentNodeContent();
    }
  }

  void back() {
    Get.back();
  }

  Future downloadRes() async {
    if (resUrl.isEmpty) return;
    if (await ResDownloader.singleton.isDownloaded(url: resUrl, md5: resMd5)) {
      isResPrepared.value = true;
      return;
    }

    await ResDownloader.singleton.download(
      url: resUrl,
      md5: resMd5,
      callback: (String url, ResDownloadStatus status, int pg) {
        progress.value = pg;
        if (status == ResDownloadStatus.success) {
          isResPrepared.value = true;
        } else if (status == ResDownloadStatus.fail) {
          Toast.show(Copywriting.security_download_failed__please_retry_later_);
          Get.back();
        }
      },
    );
  }

  Future querySceneGameNodes() async {
    if (querying) {
      return;
    }

    querying = true;

    dynamic rsp = await SPS.querySceneGameNodes(scId, cName, nId);
    if (rsp != null &&
        rsp[Security.security_nodes] != null &&
        rsp[Security.security_nodes]!.isNotEmpty) {
      nId = rsp[Security.security_nodes]!.last[Security.security_nextId];
      sceneNodes.addAll(rsp[Security.security_nodes]!);
      isReady.value = true;
      isEnd =
          rsp[Security.security_over] == 1 ||
          nId == 0 ||
          rsp[Security.security_nodes]!.length < 50;
      L.i(
        '[Chat][Date] next list count: ${rsp[Security.security_nodes]?.length}, isEnd: $isEnd',
      );
    } else if (sceneNodes.isEmpty) {
      Toast.show(Copywriting.security_some_error_occur__please_retry_later_);
      Get.back();
      return;
    } else {
      L.e('[Chat][Date] other error');
    }

    querying = false;
    await updateCurrentNodeContent();
  }

  Future updateCurrentNodeContent() async {
    if (!isEnd && sceneNodes.length < 50) {
      L.i('[Chat] roundNodes.length < 50, return');
      await querySceneGameNodes();
      return;
    }

    int nextId = currentNode[Security.security_nextId] ?? 0;
    if (currentNode.isUserAction && selectedAction != null) {
      for (var element in currentNode[Security.security_values]!) {
        if (element[Security.security_id] ==
            selectedAction![Security.security_id]) {
          nextId = element[Security.security_nextId];
        }
      }
    }

    dynamic node;
    int endIndex = 0;
    if (nextId > 0) {
      for (int i = 0; i < sceneNodes.length; i++) {
        if (sceneNodes[i][Security.security_id] == nextId) {
          node = sceneNodes[i];
          endIndex = i;
          break;
        }
      }
    }
    node ??= sceneNodes.first;
    sceneNodes.removeRange(0, endIndex + 1);

    if (node[Security.security_id] <= 0) {
      updateCurrentNodeContent();
      return;
    }

    L.i(
      '[Chat] cur msg, msgId:${node[Security.security_id]}, type: ${node[Security.security_type]}, content: ${node[Security.security_value]}, ci: ${node[Security.security_ci]}',
    );
    currentNode.value = node;
    modifyBG(node);
  }

  void modifyBG(Map node) {
    String bgi = node[Security.security_bgi] ?? '';
    bgi = bgi.isEmpty
        ? (node.isUserAction
              ? (node[Security.security_first][Security.security_bgi] ?? '')
              : '')
        : bgi;
    if (bgi.isNotEmpty && currentNodeBg.value != bgi) {
      currentNodeBg.value = bgi;
    }
  }

  Widget imageAsset(
    String fileName, {
    BoxFit? fit,
    double? width,
    double? height,
  }) {
    if (fileName.startsWith(Security.security_http)) {
      return CachedImage(
        imageUrl: fileName,
        fit: fit ?? BoxFit.cover,
        width: width ?? 44,
        height: height ?? 44,
      );
    }

    File file = File(
      '${ResDownloader.singleton.folderPath(url: resUrl, md5: resMd5)}/$fileName',
    );
    return file.existsSync()
        ? Image.file(file, fit: fit, width: width, height: height)
        : Container(color: Colors.black);
  }

  void onSelectAction(Map action) async {
    int cost = action[Security.security_cost] ?? 0;
    int disCost = action[Security.security_disCost] ?? -1;
    int realCost = disCost >= 0
        ? disCost
        : (action[Security.security_cost] ?? 0);
    bool selectBefore = action[Security.security_selectBefore] == 1;
    if (!selectBefore &&
        realCost > 0 &&
        await SPS.checkOptionUnlock(
              payType: action[Security.security_costType],
              cost: cost,
            ) ==
            false) {
      return;
    }

    selectedAction = action;

    if (cost > 0 ||
        (action[Security.security_aiPersonality]?[Security.security_id] ?? '')
            .isNotEmpty) {
      Toast.loading();
      ApiResponse rsp = await SPS.selectOption(
        scId,
        cName,
        action[Security.security_id],
      );
      Toast.dismiss();
      if (!rsp.isSuccess) {
        Toast.show(rsp.description);
        return;
      } else {
        // EasyLoading.dismiss();
        action[Security.security_selectBefore] = 1;
        if (rsp.data[Security.security_aiPersonality] != null &&
            (rsp.data[Security.security_aiPersonality]?[Security.security_id] ??
                    '')
                .isNotEmpty) {
          // await AwardMode.show(rsp!.aiPersonality!, false);
          AIModePopup.show(
            rsp.data[Security.security_aiPersonality]!,
            isNew: true,
            showToChat: false,
          );
        }
      }
    } else {
      SPS.selectOption(scId, cName, action[Security.security_id]);
      action[Security.security_selectBefore] = 1;
    }
    AccountService.instance.refreshBalance();
    updateCurrentNodeContent();
  }

  void showModePreview(Map personality) {
    // toDetailModePage(personality);
    // AwardMode.show(personality, true);
  }
}
