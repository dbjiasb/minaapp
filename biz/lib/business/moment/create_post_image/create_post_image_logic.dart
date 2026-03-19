import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/crypt/apis.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/push_service/push_service.dart';
import '../constant_state.dart';

class CreatePostImageLogic extends GetxController {
  TextEditingController controller = TextEditingController();

  final ScrollController scrollController = ScrollController();

  final Rx<String> inputText = "".obs;

  final FocusNode focusNode = FocusNode();

  final RxBool canLoadMore = true.obs;

  RxList<Map> createRecordList = RxList();

  final Rx<Map> costInfo = Rx<Map>({});

  final RxList<Map> rxResInfoList = RxList();

  int targetUid = 0;

  int fromId = 0;

  String? observerId;

  void getUserCreationRecord() async {
    Map req = {Security.security_targetUid: targetUid, Security.security_fromId: fromId, Security.security_size: 20};
    ApiRequest request = ApiRequest(Apis.security_getUserCreationRecord, params: req);
    ApiResponse getUserCreationRecordRsp = await ApiService.instance.sendRequest(request);
    Map data = getUserCreationRecordRsp.data;
    if (data[Security.security_statusInfo]?[Security.security_code] == 0) {
      fromId = data[Security.security_nextId] ?? 0;
      List<Map> listData = ((data[Security.security_records] ?? []) as List).cast<Map>();
      createRecordList.addAll(listData);
      canLoadMore.value = data[Security.security_hasMore] == 1;
    }
  }

  void getCreationResourceConfig() async {
    Map req = {Security.security_targetUid: targetUid};
    ApiRequest request = ApiRequest(Apis.security_getCreationResourceConfig, params: req);
    ApiResponse getCreationResourceConfigRsp = await ApiService.instance.sendRequest(request);
    Map data = getCreationResourceConfigRsp.data;

    if (data[Security.security_statusInfo]?[Security.security_code] == 0 || data[Security.security_config] != null) {
      if (data[Security.security_config]?[Security.security_createCostInfoMap]?["${ECreationType.IMAGE}"] != null) {
        costInfo.value = data[Security.security_config][Security.security_createCostInfoMap]!["${ECreationType.IMAGE}"]!;
      }
    }
  }

  void initArguments() {
    if (Get.arguments != null) {
      targetUid = Get.arguments[Security.security_targetUid] as int;
      rxResInfoList.value = Get.arguments[Security.security_resInfoList] as List<Map>;
    }
  }

  @override
  void onReady() {
    initArguments();
    getUserCreationRecord();
    getCreationResourceConfig();
    super.onReady();
  }

  @override
  void onInit() {
    PushService.instance.addObserver(PushId.kSecPackCreationResourceChangedNotice, (e) => onCreationRecordChange(e.data));
    super.onInit();
  }

  void onCreationRecordChange(Map record) {
    final index = createRecordList.indexWhere((e) => e[Security.security_id] == record[Security.security_id]);
    if (index != -1) {
      createRecordList[index] = record;
      createRecordList.refresh();
    }
  }

  @override
  void onClose() {
    controller.dispose();
    scrollController.dispose();
    PushService.instance.removeObserver(PushId.kSecPackCreationResourceChangedNotice, (e) => onCreationRecordChange(e.data));

    super.onClose();
  }

  void createResource(int costType, int costValue) {
    if (inputText.isEmpty) {
      return;
    }
    EasyLoading.show();

    Map req = {Security.security_targetUid: targetUid, Security.security_prompt: inputText.value, Security.security_creationType: ECreationType.IMAGE};
    ApiRequest request = ApiRequest(Apis.security_createResource, params: req);
    ApiService.instance
        .sendRequest(request)
        .then((value) {
          EasyLoading.dismiss();
          if (value.data[Security.security_statusInfo]?[Security.security_code] == 0) {
            inputText.value = "";
            controller.clear();
            focusNode.requestFocus();
            createRecordList.insert(0, value.data[Security.security_record] ?? {});
            // } else if (value.data[Security.security_tCommonRsp]?[Security.security_code] == RspCode.RC_PAY_BALANCE_NOT_ENOUGH) {
            //   BankUiUtils.handleInsufficient(
            //     costType,
            //     price: costValue,
            //     callback: () {
            //       createResource(costType, costValue);
            //     },
            //   );
          } else {
            EasyLoading.showToast(value.data[Security.security_statusInfo]?[Security.security_msg] ?? Copywriting.security_failed_Generate);
          }
        })
        .catchError((e) {
          // if (e is WupException) {
          //   if (e.code == RspCode.RC_PAY_BALANCE_NOT_ENOUGH) {
          //     BankUiUtils.handleInsufficient(
          //       costType,
          //       price: costValue,
          //       callback: () {
          //         createResource(costType, costValue);
          //       },
          //     );
          //   } else {
          EasyLoading.showToast(e.message);
          EasyLoading.dismiss();
          // }
          // } else {
          // EasyLoading.showToast(Copywriting.security_failed_Generate);
          // EasyLoading.dismiss();
          // }
        });
  }

  void reloadCreationResource(int createId, int costType, int costValue) {
    EasyLoading.show();

    Map req = {Security.security_creationId: createId};
    ApiRequest request = ApiRequest(Apis.security_reloadCreationResource, params: req);
    ApiService.instance
        .sendRequest(request)
        .then((value) {
          EasyLoading.dismiss();
          if (value.data[Security.security_statusInfo]?[Security.security_code] == 0) {
            if (value.data[Security.security_record] != null) {
              onCreationRecordChange(value.data[Security.security_record]);
            }
            EasyLoading.showToast("reload Successfully");
          } else {
            EasyLoading.showToast(value.data[Security.security_statusInfo]?[Security.security_msg] ?? Copywriting.security_failed_reload);
          }
        })
        .catchError((e) {
          // if (e is WupException) {
          // if (e.code == RspCode.RC_PAY_BALANCE_NOT_ENOUGH) {
          //   BankUiUtils.handleInsufficient(costType, price: costValue,
          //       callback: () {
          //     reloadCreationResource(createId, costType, costValue);
          //   });
          // } else {
          EasyLoading.showToast(e.message);
          EasyLoading.dismiss();
          // }
          // } else {
          //   EasyLoading.showToast(Copywriting.security_failed_reload);
          //   EasyLoading.dismiss();
          // }
        });
  }

  void loadOldMessage() {
    getUserCreationRecord();
  }

  void addOrRemove(String s) {
    bool contains = rxResInfoList.indexWhere((element) => element[Security.security_url] == s) >= 0;
    if (contains) {
      rxResInfoList.removeWhere((element) => element[Security.security_url] == s);
    } else {
      if (rxResInfoList.length >= 9) {
        EasyLoading.showToast(Copywriting.security_maximum_limit_exceeded);
        return;
      }
      rxResInfoList.add({Security.security_type: EMomentResType.IMAGE, Security.security_url: s});
    }
  }
}
