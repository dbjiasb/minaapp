import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/preferences/preferences.dart';

// import 'package:jce/tudou/CharacterSelectInfo.dart';
// import 'package:jce/tudou/MomentInfo.dart';
// import 'package:jce/tudou/ResInfo.dart';
// import 'package:jce/tudou/UserBase.dart';
// import 'package:jce/tudou/EMomentResType.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../core/account/account_service.dart';
import '../../../shared/alert.dart';
import '../moment_service.dart';

String kStoragePostCharacterInfo = "kStoragePostCharacterInfo_${MyAccount.userId}";

class CreateMomentViewLogic extends GetxController {
  Map characterSelectInfoStorage = Preferences.instance.getMap(kStoragePostCharacterInfo);
  RxMap? characterInfo;

  @override
  void onInit() {
    characterInfo = characterSelectInfoStorage.obs;
    super.onInit();
  }

  final TextEditingController textController = TextEditingController();

  final List<TextInputFormatter> inputFormatters = [
    LengthLimitingTextInputFormatter(500), // 限制最大字符数为 5
  ];

  final FocusNode focusNode = FocusNode();

  final Rx<String> inputPostText = "".obs;

  int get characterUid => characterInfo?[Security.security_userBase]?[Security.security_uid] ?? 0;

  void updateCharacterInfo(Map selectInfo) async {
    if (characterUid != 0 && characterUid != (selectInfo[Security.security_userBase]?[Security.security_uid] ?? 0)) {
      bool ret = await showConfirmAlert(
        Copywriting.security_are_you_sure_,
        Copywriting.security_switching_characters_will_clear_the_current_content,
        cancelText: Security.security_cancel,
        confirmText: Security.security_confirm,
        onConfirm: () {},
      );
      if (!ret) return;
      characterInfo?.value = selectInfo;
      Preferences.instance.setMap(kStoragePostCharacterInfo, selectInfo);
      inputPostText.value = "";
      selectImage.value = RxList();
    } else {
      characterInfo?.value = selectInfo;
      Preferences.instance.setMap(kStoragePostCharacterInfo, selectInfo);
    }
  }

  @override
  void onReady() {
    if (Get.arguments != null && Get.arguments is Map) {
      characterInfo?.value = {Security.security_userBase: Get.arguments};
      Preferences.instance.setMap(kStoragePostCharacterInfo, characterInfo ?? {});
    }
    super.onReady();
  }

  final RxList<Map> selectImage = RxList();

  bool get canPost => characterInfo?[Security.security_userBase]?[Security.security_uid] != 0 && (inputPostText.isNotEmpty || selectImage.isNotEmpty);

  void createMoment() {
    focusNode.unfocus();
    if (canPost) {
      EasyLoading.show();
      Map momentInfo = {};
      final userBase = characterInfo?[Security.security_userBase];
      momentInfo[Security.security_authorUid] = MyAccount.userId;
      momentInfo[Security.security_posterUid] = userBase?[Security.security_uid] ?? 0;
      momentInfo[Security.security_avatarUrl] = userBase?[Security.security_avatarUrl];
      momentInfo[Security.security_nickname] = userBase?[Security.security_nickName];
      momentInfo[Security.security_content] = inputPostText.value;
      if (selectImage.isNotEmpty) {
        momentInfo[Security.security_resInfos] = selectImage;
      }
      MomentService.createMoment(momentInfo).then((value) {
        EasyLoading.dismiss();
        if (value.isSuccess) {
          momentInfo[Security.security_createTime] = DateTime.now().millisecondsSinceEpoch;
          EventCenter.instance.sendEvent(kPostMomentSuccess, momentInfo);
          EasyLoading.showToast(Copywriting.security_post_successful);
          Get.back();
        } else {
          EasyLoading.showToast(value.description);
        }
      });
      //     .catchError((e) {
      //   if (e is WupException) {
      //     EasyLoading.showToast(e.message);
      //     EasyLoading.dismiss();
      //   } else {
      //     EasyLoading.showToast("Failed Post");
      //     EasyLoading.dismiss();
      //   }
      // });
    }
  }

  void generatePostContent() {
    List imageUrl = selectImage.where((e) => e[Security.security_type] != 2).map((e) => e[Security.security_url] ?? "").toList();
    if (imageUrl.isEmpty) {
      return;
    }
    EasyLoading.show();
    MomentService.generatePostContent(characterUid, imageUrl).then((value) {
      EasyLoading.dismiss();
      inputPostText.value = value.data[Security.security_content] ?? "";
      textController.text = value.data[Security.security_content] ?? "";
    });
    // .catchError((e) {
    //   if (e is WupException) {
    //     EasyLoading.showToast(e.message);
    //     EasyLoading.dismiss();
    //   } else {
    //     EasyLoading.showToast(Copywriting.security_failed_Generate);
    //     EasyLoading.dismiss();
    //   }
    // });
  }
}
