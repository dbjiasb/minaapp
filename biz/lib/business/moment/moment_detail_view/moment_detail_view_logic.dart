import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/business/moment/constant_state.dart';

import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/crypt/apis.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/report/report_manager.dart';
import '../../../base/router/router_names.dart';
import '../../../core/account/account_service.dart';
import '../moment_service.dart';
import 'moment_detail_view_state.dart';

class MomentDetailViewLogic extends GetxController {
  final MomentDetailViewState state = MomentDetailViewState();

  final Rx<Map> rxMomentInfo = Rx<Map>({});

  final RxList rxCommentList = RxList<Map>();

  final RxMap<int, String> translateMap = RxMap();

  final RxBool rxCollectStatus = false.obs;

  List<MapEntry<Map, List<Map>>> get groupCommentList {
    final List rootComments = rxCommentList.where((c) => c[Security.security_parentId] == 0).toList();
    // Step 2: 将所有评论按 id 建立映射，方便查找
    // final Map<int, Map> commentMap = {for (var c in rxCommentList) c[Security.security_id]: c};

    // Step 3: 创建结果 Map
    final Map<Map, List<Map>> grouped = {};

    for (final root in rootComments) {
      final List<Map> replies =
          rxCommentList
                  .where((c) => root[Security.security_id] != 0 && c[Security.security_parentId] == root[Security.security_id]) // 找出所有回复这条主评论的子评论
                  .toList()
              as List<Map>;
      grouped[root] = replies;
    }
    return grouped.entries.toList();
  }

  final RxBool isFollowed = true.obs;

  @override
  void onReady() async {
    if (Get.arguments != null) {
      rxMomentInfo.value = Get.arguments;
      Map? rsp = await MomentService.getMomentDetail(rxMomentInfo.value[Security.security_id]);
      if ((rsp[Security.security_statusInfo]?[Security.security_code] ?? -1) == 0) {
        rxMomentInfo.value = rsp[Security.security_momentInfo] ?? {};
        rxCommentList.value = rsp[Security.security_commentInfos] != null ? (rsp[Security.security_commentInfos] as List).cast<Map>() : [];
      }
      getCollectStatus();

      ReportManager.sendEvent(Security.security_pv_moment_detail, {Security.security_momentId: rxMomentInfo.value[Security.security_id].toString()});
    }
    super.onReady();
  }

  void getCollectStatus() async {
    Map req = {
      Security.security_type: ECollectType.MOMENT,
      Security.security_contents: [rxMomentInfo.value[Security.security_id].toString()],
    };
    ApiRequest request = ApiRequest(Apis.security_getCollectStatus, params: req);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    Map data = response.data;
    if ((data[Security.security_statusInfo]?[Security.security_code] ?? -1) == 0) {
      rxCollectStatus.value = (data[Security.security_collectInfoList] ?? []).isNotEmpty;
    }
  }

  void collectAction() async {
    int wantLikeAction = rxCollectStatus.value ? 0 : 1;
    rxCollectStatus.value = !rxCollectStatus.value;
    Map req = {Security.security_type: ECollectType.MOMENT, Security.security_content: rxMomentInfo.value[Security.security_id].toString(), Security.security_opt: wantLikeAction};
    ApiRequest request = ApiRequest(Apis.security_collectAction, params: req);
    await ApiService.instance.sendRequest(request);
  }

  void deleteMoment(int momentId) {
    EasyLoading.show();
    MomentService.deleteMoment(momentId)
        .then((value) {
          EasyLoading.dismiss();
          if (value[Security.security_statusInfo]?[Security.security_code] == 0) {
            Get.back();
            EventCenter.instance.sendEvent(kDeleteMomentSuccess, {Security.security_momentId: momentId});
          } else {
            EasyLoading.showToast(value[Security.security_statusInfo]?[Security.security_msg] ?? Copywriting.security_operation_failed);
          }
        })
        .catchError((e) {
          // if (e is WupException) {
          EasyLoading.showToast(e.message);
          EasyLoading.dismiss();
          // } else {
          //   EasyLoading.showToast(Copywriting.security_operation_failed);
          //   EasyLoading.dismiss();
          // }
        });
  }

  void commentMoment(int momentId, String content) {
    EasyLoading.show();
    Map commentInfo = {};
    commentInfo[Security.security_sendUid] = MyAccount.userId;
    commentInfo[Security.security_avatarUrl] = MyAccount.avatar;
    commentInfo[Security.security_nickname] = MyAccount.name;
    commentInfo[Security.security_content] = content;
    commentInfo[Security.security_replyUid] = rxReplyCommentInfo.value[Security.security_sendUid] ?? 0;
    commentInfo[Security.security_parentId] = rxReplyCommentInfo.value[Security.security_id] ?? 0;
    commentInfo[Security.security_momentId] = momentId;
    commentInfo[Security.security_id] = 0;
    commentInfo[Security.security_createTime] = DateTime.now().millisecondsSinceEpoch;

    MomentService.commentMoment(commentInfo).then((value) {
      EasyLoading.dismiss();
      if (value.isSuccess) {
        rxCommentList.add(commentInfo);
        rxMomentInfo.value[Security.security_commentCount] = rxCommentList.length;
        rxMomentInfo.refresh();
        EventCenter.instance.sendEvent(kUpdateMomentSuccess, rxMomentInfo.value);
      } else {
        EasyLoading.showToast(value.description);
      }
    });
    //     .catchError((e) {
    //   if (e is WupException) {
    //     EasyLoading.showToast(e.message);
    //     EasyLoading.dismiss();
    //   } else {
    //     EasyLoading.showToast("Comment failed");
    //     EasyLoading.dismiss();
    //   }
    // });
  }

  final TextEditingController textController = TextEditingController();

  final FocusNode focusNode = FocusNode();

  final Rx<String> inputText = "".obs;

  final Rx<Map> rxReplyCommentInfo = Rx<Map>({});

  void replyComment(Map commentInfo) {
    rxReplyCommentInfo.value = commentInfo;
    focusNode.requestFocus();
  }

  void likeMomentAction(Map momentInfo) async {
    bool wantLikeAction = momentInfo[Security.security_isLike] != 1;
    if (wantLikeAction) {
      momentInfo[Security.security_isLike] = 1;
      momentInfo[Security.security_likeCount] = momentInfo[Security.security_likeCount] + 1;
    } else {
      momentInfo[Security.security_isLike] = 0;
      momentInfo[Security.security_likeCount] = momentInfo[Security.security_likeCount] - 1;
    }
    momentInfo[Security.security_likeCount] = momentInfo[Security.security_likeCount] < 0 ? 0 : momentInfo[Security.security_likeCount];
    rxMomentInfo.refresh();
    Map? rsp = await MomentService.likeMomentAction(wantLikeAction, momentInfo[Security.security_id], posterUid: momentInfo[Security.security_posterUid], authorUid: momentInfo[Security.security_authorUid]);
    if (rsp[Security.security_statusInfo]?[Security.security_code] == 0) {
      EventCenter.instance.sendEvent(kUpdateMomentSuccess, rxMomentInfo.value);
    }
  }

  void translateComment(Map commentInfo) async {
    if (translateMap.containsKey(commentInfo[Security.security_id])) {
      translateMap.remove(commentInfo[Security.security_id]);
      return;
    }
    translateMap[commentInfo[Security.security_id]] = "Translating…";

    ApiRequest request = ApiRequest(Apis.security_choseLangTranslateText, params: {Security.security_text: commentInfo[Security.security_content] ?? ''});
    ApiResponse response = await ApiService.instance.sendRequest(request);

    if (response.isSuccess) {
      translateMap[commentInfo[Security.security_id]] = response.data[Security.security_translatedText] ?? "";
      translateMap.refresh();
    } else {
      EasyLoading.showToast(Copywriting.security_translation_failure_);
    }
  }

  void viewImages(Map res) {
    // List<String> imageUrls = (rxMomentInfo.value.resInfos ?? [])
    //     .where((e) => (e.type == 0 || e.type == 1) && (e.url ?? "").isNotEmpty)
    //     .map((e) => e.url ?? "")
    //     .toList();
    // int index = imageUrls.indexWhere((entry) => entry == res.url);
    // if (index == -1) {
    //   index = 0;
    // }
    // ViewerRoute.toPhotoView(
    //   imageUrls,
    //   initialPage: index,
    // );
    Get.toNamed(Routers.imageBrowser, arguments: {Security.security_imageUrl: res[Security.security_url]});
  }
}
