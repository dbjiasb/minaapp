import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/routes.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:biz/core/util/log_util.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/business/create_center/character_service.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/alert.dart';

import '../../../base/router/router_names.dart';
import '../../../core/util/file_upload.dart';
import '../../base/api_service/api_response.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/cached_image.dart';
import '../../shared/app_theme.dart';
import '../../shared/toast/toast.dart';

class GenerationResult {
  String url = '';
  String avatar = '';
  Rx<Uint8List> avatarBytes = Rx<Uint8List>(Uint8List(0));
  RxBool uploadingAvatar = false.obs;

  Map avatarInfo = {};

  GenerationResult({required this.url, required this.avatar});
}

class GenPage extends StatelessWidget {
  GenPage({super.key});

  final _logic = Get.put(GenOcController());

  @override
  Widget build(BuildContext context) {
    Get.arguments != null ? _logic.initEditPage(Get.arguments as Map) : _logic.initCreatePage();
    return Scaffold(
      backgroundColor: AppColors.main,
      body: Obx(() => AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _logic.isGenPage.value ? generatingView() : resultBody())),
    );
  }

  // 生成中页面的 Widget
  Widget generatingView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 44),
      color: Color(0xFF07070A),
      // decoration: BoxDecoration(image: DecorationImage(image: ImageView.getImageProvider("oc_create_bg.png"), fit: BoxFit.fill)),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  showStopDialog();
                },
                icon: ImageView(Images.security_back_png, height: 24, width: 24),
              ),
            ],
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 44, width: 44, child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.primary)),
                SizedBox(height: 12),
                Text(Copywriting.security_generating___, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFFFFFFF))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 结果页面的 Widget
  Widget resultBody() {
    return Stack(
      key: ValueKey(Security.security_result), // 必须设置不同的 Key
      children: [
        Stack(
          children: [
            resultImageView(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SafeArea(bottom: false, child: SizedBox(height: Platform.isAndroid ? 10 : 0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      avatarView(),
                      GestureDetector(
                        onTap: () {
                          startRegeneration();
                        },
                        child: Icon(Icons.refresh, size: 32, color: Colors.white,),
                      ).marginOnly(bottom: 10),
                    ],
                  ),
                  const Spacer(),
                  Obx(() => Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 4, children: indicatorView())),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: _logic.createOrModifyAndToChat,
                    child: Container(
                      height: 52,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: AppColors.ocMain),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _logic.isEditPage ? Copywriting.security_modify_Now : Copywriting.security_create_Now,
                            style: TextStyle(color: Color(0xFF07070A), fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          if (_logic.isEditPage)
                            _logic.modifyCostInfo[Security.security_costValue] == 0
                                ? Text(
                                  (_logic.modifyCostInfo[Security.security_freeText] ?? '').isEmpty
                                      ? Security.security_free
                                      : _logic.modifyCostInfo[Security.security_freeText] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1),
                                )
                                : RichText(
                                  text: TextSpan(
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: ImageView(
                                          _logic.modifyCostInfo[Security.security_costType] == 1 ? Images.security_gem_png : Images.security_coin_png,
                                          width: 18,
                                          height: 18,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${_logic.modifyCostInfo[Security.security_costValue]}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      RH.back();
                    },
                    child: Text(
                      Security.security_quit,
                      style: TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.underline, decorationColor: Colors.white),
                    ),
                  ),
                  SafeArea(top: false, child: SizedBox(height: Platform.isAndroid ? 10 : 0)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void showStopDialog() {
    showConfirmAlert(
      Security.security_Tips,
      Copywriting
          .security_the_character_creation_is_still_ongoing__Leaving_at_this_moment_will_forfeit_the_progress_made_so_far__Are_you_sure_you_want_to_go_back_,
      confirmText: Security.security_Confirm,
      cancelText: Security.security_Cancel,
      onConfirm: () {
        _logic.forceReturn();
      },
      onCancel: () {},
    );
  }

  void startRegeneration() {
    _logic.isEditPage ? _logic.regenerateInEdition() : _logic.regenerateInCreation();
    //
    // showConfirmAlert(
    //   Copywriting.security_regeneration_Tips,
    //   Copywriting
    //       .security_following_the_regeneration_process__you_ll_receive_a_brand_new_image__You_are_also_welcome_to_revisit_the_images_you_created_earlier__Are_you_ready_to_move_forward_,
    //   confirmText: Security.security_Yes,
    //   cancelText: Security.security_Cancel,
    //   onConfirm: () {
    //     _logic.isEditPage ? _logic.regenerateInEdition() : _logic.regenerateInCreation();
    //   },
    //   onCancel: Get.back,
    // );
  }

  Widget avatarView() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        try {
          _logic.toCropAvatarView();
        } catch (e) {
          L.e('[CreateRole] avatarView onTap error: $e');
        }
      },
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          SizedBox(width: 78, height: 78),
          Obx(() {
            _logic.currentPage.value;
            if (_logic.resultImages.isEmpty) {
              return Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                  color: Colors.grey,
                ),
              );
            }
            Uint8List avatarBytes = _logic.curResult.avatarBytes.value;
            bool isUploading = _logic.curResult.uploadingAvatar.value;
            return Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(35))),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  avatarBytes.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(35), child: Image.memory(avatarBytes, width: 68, height: 68, fit: BoxFit.cover))
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: CachedImage(imageUrl: _logic.curResult.avatar, width: 68, height: 68, fit: BoxFit.cover),
                      ),
                  isUploading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.transparent, color: AppColors.primary),
                      )
                      : const SizedBox(),
                ],
              ),
            );
          }),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: AppColors.ocMain),
              child: Text(Security.security_focus, style: TextStyle(color: Color(0xFF07070A), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget resultImageView() {
    return Positioned.fill(
      child: Obx(
        () => PageView(
          controller: _logic.pageController,
          onPageChanged: (index) {
            _logic.switchToPage(index);
          },
          children: _logic.resultImages.map((results) => CachedImage(imageUrl: results.url, fit: BoxFit.cover)).toList(),
        ),
      ),
    );
  }

  List<Widget> indicatorView() {
    final indicators = <Container>[];
    final index = _logic.currentPage.value;
    for (int i = 0; i < _logic.resultImages.length; i++) {
      indicators.add(
        Container(
          decoration: BoxDecoration(color: i == index ? Colors.white : AppColors.ocMain, borderRadius: const BorderRadius.all(Radius.circular(3))),
          height: 6,
          width: 6,
        ),
      );
    }
    return indicators;
  }
}

class GenOcController extends GetxController {
  bool isEditPage = false;

  late Map config;
  late Map modifyCostInfo;

  RxBool isGenPage = false.obs;
  Timer? _resultTimer;
  RxBool interrupt = false.obs;
  PageController pageController = PageController();

  RxList resultImages = [].obs;
  RxInt currentPage = 0.obs;

  GenerationResult get curResult => resultImages[currentPage.value];

  GenerationResult get latestResult => resultImages.last;

  void initEditPage(Map editConfig) {
    isEditPage = true;
    config = editConfig[Security.security_customRoleInfo] ?? {};
    modifyCostInfo = editConfig[Security.security_modifyCostInfo] ?? {};
    // regenerateInEdition();
    String avatar = config[Security.security_chatBackground] ?? '';
    String bg = config[Security.security_chatBackground] ?? '';
    resultImages.add(GenerationResult(url: bg, avatar: avatar));
  }

  void initCreatePage() {
    config = CharacterService.instance.createRoleConfigs;
    isEditPage = false;
    regenerateInCreation();
  }

  Future<void> regenerateInEdition() async {
    isGenPage.value = true;
    ApiResponse rtn = await CharacterService.instance.editForBgRegeneration(config);
    if (rtn.isSuccess) {
      startTimer();
    } else {
      isGenPage.value = false;
      Toast.show(rtn.description);
    }
  }

  // 获取图片traceId
  Future<void> regenerateInCreation() async {
    isGenPage.value = true;
    ApiResponse ret = await CharacterService.instance.createForBgRegeneration();
    if (ret.isSuccess) {
      startTimer();
    } else {
      isGenPage.value = false;
      Toast.show(ret.description);
    }
  }

  int checkingCount = 0;

  // 开始定时器，定时任务为轮询结果
  void startTimer() {
    _resultTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      checkingCount++;
      queryGenerationResult();
    });
  }

  // 轮询结果，如果有结果则结束轮询，进行处理
  Future<void> queryGenerationResult() async {
    ApiResponse response = await CharacterService.instance.getGenResult(CharacterService.instance.traceId);
    String imageUrl = response.data[Security.security_imageUrl] ?? '';
    if (!response.isSuccess) {
      return;
    }
    if (imageUrl.isEmpty) {
      return;
    }
    await handleGenerationResult(response.data);
  }

  Future<void> handleGenerationResult(Map result) async {
    cancelTimer();

    String imageUrl = result[Security.security_imageUrl];
    Map avatarInfo = result[Security.security_positionInfo] ?? {};
    GenerationResult newResult = GenerationResult(url: imageUrl, avatar: imageUrl)..avatarInfo = avatarInfo;
    resultImages.add(newResult);
    resultImages.refresh();

    isGenPage.value = false;
    switchToPage(resultImages.length - 1, fromUser: false);

    if (avatarInfo.isEmpty) return;
    cropAndUploadAvatar(imageUrl, newResult, avatarInfo);
  }

  void cropAndUploadAvatar(String imageUrl, GenerationResult newResult, Map avatarInfo) async {
    try {
      newResult.uploadingAvatar.value = true;
      final response = await http.get(Uri.parse(imageUrl));
      String path = '${(await getTemporaryDirectory()).path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      File tempFile = File(path);
      await tempFile.writeAsBytes(response.bodyBytes);

      String croppedFilePath = await croppedAvatar(
        path,
        response.bodyBytes,
        Rect.fromLTWH(avatarInfo['x'].toDouble(), avatarInfo['y'].toDouble(), avatarInfo['w'].toDouble(), avatarInfo['h'].toDouble()),
      );
      if (croppedFilePath.isEmpty) {
        newResult.uploadingAvatar.value = false;
        return;
      }

      Uint8List imageBytes = await File(croppedFilePath).readAsBytes();
      newResult.avatarBytes.value = imageBytes;
      String uploadUrl = await FilePushService.instance.upload(imageBytes, FileType.im) ?? '';
      L.i('[CreateRole] uploadAvatarUrl: $uploadUrl');
      if (uploadUrl.isEmpty) {
        newResult.uploadingAvatar.value = false;
        return;
      }

      newResult.uploadingAvatar.value = false;
      String avatarUrl = CachedImage.processedImageUrl(uploadUrl);
      try {
        await DefaultCacheManager().putFileStream(avatarUrl, Stream.value(imageBytes));
      } catch (e) {
        L.e('[CreateRole] write cache error: $e');
      }
      newResult.avatar = avatarUrl;
    } catch (e) {
      curResult.uploadingAvatar.value = false;
      L.e('cropAndUploadAvatar error: $e');
    }
  }

  void cancelTimer() {
    _resultTimer?.cancel();
    _resultTimer = null;
  }

  void forceReturn() {
    cancelTimer();
    interrupt.value = true;
    Get.back();
  }

  void switchToPage(int index, {bool fromUser = true}) {
    if (index < 0) return;
    currentPage.value = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!fromUser) pageController.jumpToPage(index);
    });
  }

  // 图片裁剪
  Future<void> toCropAvatarView() async {
    if (curResult.url.isEmpty) {
      Toast.show(Copywriting.security_image_is_Not_ready__please_try_again_later_);
      return;
    }
    String imageUrl = CachedImage.processedImageUrl(curResult.url);
    File file = await DefaultCacheManager().getSingleFile(imageUrl);
    CroppedFile? croppedFile = await ImageCropper().cropImage(sourcePath: file.path);
    if (croppedFile == null) {
      return;
    }
    curResult.uploadingAvatar.value = true;

    Uint8List imageBytes = await croppedFile.readAsBytes();
    curResult.avatarBytes.value = imageBytes;

    String uploadUrl = await FilePushService.instance.upload(imageBytes, FileType.profile) ?? '';
    curResult.uploadingAvatar.value = false;
    if (uploadUrl.isEmpty) {
      return;
    }
    String avatarUrl = CachedImage.processedImageUrl(uploadUrl);
    try {
      await DefaultCacheManager().putFileStream(avatarUrl, Stream.value(imageBytes));
    } catch (e) {
      L.e('[CreateRole] write cache error: $e');
    }
    curResult.avatar = avatarUrl;
  }

  void createOrModifyAndToChat() async {
    Toast.loading();

    if (curResult.avatar.isEmpty) {
      String? avatarUrl = await FilePushService.instance.upload(curResult.avatarBytes.value, FileType.profile);
      if (avatarUrl?.isEmpty ?? true) {
        Toast.show(Copywriting.security_avatar_upload_failed__please_try_again_later_);
        return;
      }
      curResult.avatar = avatarUrl!;
    }

    late ApiResponse rsp;
    config[Security.security_chatBackground] = curResult.url;
    config[Security.security_avatarUrl] = curResult.avatar;

    if (isEditPage) {
      rsp = await CharacterService.instance.update(config);
    } else {
      rsp = await CharacterService.instance.createRole();
    }
    if (rsp.isSuccess) {
      Toast.dismiss();
      CharacterService.instance.clearDraft();
      EventCenter.instance.sendEvent(Security.security_kDidCreateRole, {});
      Get.until((route) => route.settings.name == Routers.root);

      AccountService.instance.getPremInfo();
      RH.toChat(
        id: rsp.data[Security.security_roleUid].toString(),
        name: config[Security.security_nickName] ?? '',
        avatar: config[Security.security_avatarUrl] ?? '',
        coverUrl: config[Security.security_chatBackground] ?? '',
        accountType: 4,
      );
    } else {
      Toast.show(rsp.description);
    }
  }

  Future<String> croppedAvatar(String path, Uint8List? bodyBytes, Rect rect) async {
    img.Image? originImage;
    if (bodyBytes != null) {
      originImage = img.decodeImage(bodyBytes);
    } else {
      final bytes = await File(path).readAsBytes();
      originImage = img.decodeImage(bytes);
    }
    if (originImage == null) return '';
    final croppedImage = img.copyCrop(originImage, x: rect.left.toInt(), y: rect.top.toInt(), width: rect.width.toInt(), height: rect.height.toInt());
    final ext = path.split('.').last;
    final croppedFilePath = path.replaceAll('.$ext', '_cropped.$ext');

    await File(croppedFilePath).writeAsBytes(ext.toLowerCase() == Security.security_png ? img.encodePng(croppedImage) : img.encodeJpg(croppedImage));
    return croppedFilePath;
  }
}
