import 'package:biz/base/crypt/apis.dart';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/privacy/ai_consent_service.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/report/report_manager.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/crypt/images.dart';
import '../../../base/router/route_helper.dart';
import '../../../shared/app_theme.dart';
import '../chat_room/chat_room_view.dart';
import '../chat_room_cells/chat_video_message.dart';

const int _kPremiumFreeReason = 3;

Map _asMap(dynamic value) {
  if (value is Map) {
    return Map.of(value);
  }
  return {};
}

List<Map> _asMapList(dynamic value) {
  if (value is List) {
    return value.whereType<Map>().map((e) => Map.of(e)).toList();
  }
  return [];
}

String _asString(dynamic value) => value?.toString() ?? '';

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_asString(value)) ?? 0;
}

List<Map> _tagItems(Map tag) {
  final subGroups = _asMapList(tag[Security.security_subGroups]);
  if (subGroups.isEmpty) return [];
  return _asMapList(subGroups.first[Security.security_tags]);
}

Map _firstTag(Map tag) {
  final tags = _tagItems(tag);
  return tags.isNotEmpty ? tags.first : {};
}

String _currencyText(int costType) =>
    costType == 0 ? Security.security_Coins : Security.security_Gems;

class VideoCreateManager {
  static RxMap askVideoConfig = {}.obs;

  static int get cost => _asInt(askVideoConfig[Security.security_cost]);

  static int get costType => _asInt(askVideoConfig[Security.security_costType]);

  static bool get genAudioNeedCost =>
      _asInt(
        _asMap(askVideoConfig[Security.security_generateAudioConfig])[Security
            .security_needExtraCost],
      ) >
      0;

  static bool get hasVideoConfig =>
      askVideoConfig[Security.security_cost] != null;

  static bool get isPremiumFree =>
      _asInt(
        _asMap(askVideoConfig[Security.security_groupsV2])[_kPremiumFreeReason],
      ) >
      0;
  static bool get isFree => cost == 0;

  static List<Map> get videoConfigSettingTags => _asMapList(
    askVideoConfig[Security.security_groupsV2] ??
        askVideoConfig[Security.security_groups],
  );

  static void getVideoConfig(int sid) async {
    Map params = {
      Security.security_tId: "${MyAccount.userId}",
      Security.security_targetUid: "$sid",
    };
    ApiResponse rsp = await ApiService.instance.sendRequest(
      ApiRequest(Apis.security_getGenerateVideoConfig, params: params),
    );
    if (!rsp.isSuccess) {
      return;
    }
    askVideoConfig.value = rsp.data;
  }

  static Future<ApiResponse> requestGenerateVideo({
    String url = '',
    String prompt = '',
    int sid = 0,
    int msgId = 0,
    List<Map>? tags,
    bool generateAudio = false,
  }) async {
    final params = <String, dynamic>{
      Security.security_tId: '${MyAccount.userId}',
      Security.security_toUid: sid,
      Security.security_prompt: prompt,
    };

    if (msgId != 0) {
      params[Security.security_msgId] = msgId;
    }

    if (url.isNotEmpty) {
      params[Security.security_url] = url;
    }

    if (tags?.isNotEmpty == true) {
      params[Security.security_tags] = tags;
    }

    if (generateAudio) {
      params[Security.security_audioInfo] = {Security.security_enabled: 1};
    }

    Toast.loading();
    ApiResponse rsp = await ApiService.instance.sendRequest(
      ApiRequest(
        Apis.security_generateVideoV2,
        params: {Security.security_params: params},
      ),
    );
    if (!rsp.isSuccess) {
      Toast.error(rsp.description);
      if (rsp.bsnsCode == 2000) {
        RH.toCoins();
      }
    } else {
      Toast.dismiss();
    }
    return rsp;
  }
}

class GenerateVideoDialog extends StatelessWidget {
  GenerateVideoDialog({super.key});

  /// prompt 和 imageUrl 来源于图生视频
  /// reloadMessage 来源于视频 reload
  static Future show({
    String? prompt,
    String? imageUrl,
    ChatVideoMessage? reloadMessage,
    int? msgId,
  }) async {
    final agreed = await AIConsentService.ensureConsent(
      feature: AIConsentFeature.videoGeneration,
    );
    if (!agreed) {
      return;
    }

    int cost = VideoCreateManager.cost;
    int costType = VideoCreateManager.costType;
    List<Map>? settingTags =
        VideoCreateManager.videoConfigSettingTags.map((e) => e).toList();
    bool genAudioNeedCost = VideoCreateManager.genAudioNeedCost;

    Get.put(
      GenerateVideoController()
        ..cost.value = cost
        ..costType.value = costType
        ..genAudioNeedCost = genAudioNeedCost
        ..settingTags = settingTags
        ..promptTextFileController.text = prompt ?? ''
        ..msgId = msgId
        ..imageUrl = imageUrl
        ..showSettingsPart = settingTags.isNotEmpty
        ..reloadMessage = reloadMessage,
    );

    return Get.bottomSheet(
      GenerateVideoDialog(),
      useRootNavigator: false,
      persistent: false,
      isScrollControlled: true,
    ).then((_) {
      Get.delete<GenerateVideoController>();
    });
  }

  final GenerateVideoController controller =
      Get.find<GenerateVideoController>();

  @override
  Widget build(BuildContext context) => Container(
    width: 375.w,
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24.w),
        topRight: Radius.circular(24.w),
      ),
      color: const Color(0xFF202028),
    ),
    child: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      Copywriting.security_generate_Video,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.w,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: Get.back,
                  child: ImageView(
                    Images.security_ic_close_png,
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ),
            16.w.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              width: double.infinity,
              height: 132.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: TextField(
                controller: controller.promptTextFileController,
                maxLines: 10,
                onSubmitted: (value) {
                  try {
                    FocusScope.of(Get.context!).unfocus();
                  } catch (_) {}
                },
                decoration: InputDecoration(
                  hintText: Preferences.instance.generateVideoPromptHints,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    color: Color(0xFF636268),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            12.w.verticalSpace,
            InkWell(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              onTap: controller.aiWriterPrompt,
              child: Row(
                children: [
                  ImageView(
                    Images.security_tip_off_png,
                    width: 16.w,
                    height: 16.w,
                  ),
                  4.w.horizontalSpace,
                  Text(
                    Copywriting.security_aI_Writer,
                    style: TextStyle(
                      fontSize: 11.w,
                      color: const Color(0xFFABABAD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (controller.showSettingsPart)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  24.w.verticalSpace,
                  Text(
                    Security.security_settings,
                    style: TextStyle(
                      fontSize: 14.w,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  for (final selectItem in controller.settingTags)
                    _buildSettingSelector(selectItem).marginOnly(top: 10),
                ],
              ),
            24.w.verticalSpace,
            _buildAudioSetting(),
            24.w.verticalSpace,
            _buildCostEstimated(),
            GestureDetector(
              onTap: () async {
                if (controller.reloadMessage != null) {
                  controller.reloadVideo();
                } else {
                  controller.generateVideo();
                }
              },
              child: Container(
                width: double.infinity,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    controller.reloadMessage != null
                        ? Security.security_reload
                        : Security.security_generate,
                    style: TextStyle(
                      fontSize: 16.w,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildSettingSelector(Map tag) {
    final typeDesc = _asString(tag[Security.security_typeDesc]);
    final subTags = _tagItems(tag);
    final firstTagDes =
        subTags.isNotEmpty
            ? _asString(subTags.first[Security.security_desc])
            : '';
    final defaultTag =
        _asString(
              controller.selectedTags[typeDesc]?[Security.security_desc],
            ).isNotEmpty
            ? _asString(
              controller.selectedTags[typeDesc]?[Security.security_desc],
            )
            : firstTagDes;
    final selectTagDesc = defaultTag.obs;
    return Row(
      children: [
        Text(
          typeDesc,
          style: TextStyle(
            fontSize: 12.w,
            color: const Color(0xFFABABAD),
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Obx(
          () => CupertinoSlidingSegmentedControl<String>(
            padding: EdgeInsets.all(4.w),
            thumbColor: const Color(0xFF8761F1),
            groupValue: selectTagDesc.value,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            onValueChanged: (value) {
              if (value == null) return;
              selectTagDesc.value = value;
              final selected = subTags.firstWhereOrNull(
                (e) => _asString(e[Security.security_desc]) == value,
              );
              if (selected != null) {
                controller.selectedTags[typeDesc] = Map.of(selected);
                controller.calcCost();
              }
            },
            children: {
              for (final subItem in subTags)
                _asString(subItem[Security.security_desc]): Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.w),
                  // height: 36.w,
                  // width: 72.w,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _asString(subItem[Security.security_desc]),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // if (_asInt(subItem[Security.security_needExtraCost]) > 0)
                      //   Image.asset(
                      //     controller.costType.value == 0
                      //         ? ImagePath.coin
                      //         : ImagePath.gem,
                      //     width: 12,
                      //     height: 12,
                      //   ).marginOnly(left: 2),
                    ],
                  ),
                ),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSetting() {
    final audioTitle = 'Generate ${Security.security_Audio}';

    return Row(
      children: [
        Text(
          audioTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        // if (controller.genAudioNeedCost)
        //   Image.asset(
        //     controller.costType.value == 0 ? ImagePath.coin : ImagePath.gem,
        //     width: 12,
        //     height: 12,
        //   ).marginOnly(left: 2),
        const Spacer(),
        Obx(
          () => SizedBox(
            width: 48.w,
            height: 24.w,
            child: CupertinoSwitch(
              thumbColor: Colors.white,
              inactiveTrackColor: const Color(
                0xFFD2C0FF,
              ).withValues(alpha: 0.16),
              activeTrackColor: const Color(0xFF8761F1),
              value: controller.generateAudio.value,
              onChanged: (select) {
                controller.generateAudio.value = select;
                controller.calcCost();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostEstimated() {
    return GetBuilder<GenerateVideoController>(
      id: GenerateVideoController.estimatedRefreshId,
      builder: (logic) {
        return Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                controller.expand.value = !controller.expand.value;
              },
              child: Row(
                children: [
                  Text(
                    'estimated Cost',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Obx(() {
                    if (controller.calculateResult.value == 1) {
                      return const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE962F6),
                        ),
                      ).marginOnly(left: 2);
                    }
                    return Text(
                      '${controller.estimatedCost} ${_currencyText(controller.costType.value)}',
                      style: const TextStyle(
                        color: Color(0xFFFFEF3B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  const Spacer(),
                  Text(
                    Security.security_Detail,
                    style: TextStyle(
                      color: Color(0xFFFFEF3B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Obx(
                    () => Transform.rotate(
                      angle: controller.expand.value ? 0 : pi,
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: Color(0xFFFFEF3B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              if (!controller.expand.value || controller.costItems.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  for (int i = 0; i < controller.costItems.length; i++)
                    extraCostItem(
                      controller.costItems[i],
                    ).marginOnly(top: i == 0 ? 12 : 8),
                ],
              );
            }),
          ],
        );
      },
    ).marginOnly(bottom: 16);
  }

  Widget extraCostItem(Map item) {
    final text = _asString(item[Security.security_type]);
    final cost = _asInt(item[Security.security_costValue]);
    final freeReason = _asInt(item[Security.security_freeReason]);

    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: const Color(0xFFABABAD),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (cost == 0 && freeReason != 0)
          Row(
            children: [
              if (freeReason == _kPremiumFreeReason)
                ImageView(Images.security_premium_png, width: 16, height: 16),
              if (freeReason == _kPremiumFreeReason) const SizedBox(width: 7),
              Text(
                freeReason == _kPremiumFreeReason
                    ? Copywriting.security_premium_Free
                    : Security.security_Free,
                style: TextStyle(
                  color: const Color(0xFFFFE96F),
                  fontSize: 12,
                  fontWeight: AppFonts.medium,
                ),
              ),
            ],
          )
        else
          Text(
            '$cost ${_currencyText(controller.costType.value)}',
            style: const TextStyle(
              color: Color(0xFFFFEF3B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class GenerateVideoController extends GetxController {
  final promptTextFileController = TextEditingController();
  final roomViewController = Get.find<ChatRoomViewController>();
  String reportKey = Security.security_video_generate_click;

  int get userId => roomViewController.userId;

  static String estimatedRefreshId =
      Security.security_generateVideoEstimatedRefreshId;

  RxInt cost = 15.obs;
  RxInt costType = 0.obs;
  int estimatedCost = 0;
  bool genAudioNeedCost = false;
  ChatVideoMessage? reloadMessage;
  RxBool expand = false.obs;
  RxBool generateAudio = false.obs;
  RxInt calculateResult = 0.obs;

  List<Map> settingTags = [];
  List costItems = [];
  bool showSettingsPart = true;
  int? msgId;
  String? imageUrl;
  Map audioConfig = {};

  Map<String, Map> selectedTags = {};

  @override
  void onInit() {
    super.onInit();
    estimatedCost = cost.value;
    initParams();
    calcCost();
  }

  void initParams() {
    for (final tag in settingTags) {
      final typeDesc = _asString(tag[Security.security_typeDesc]);
      final defaultTag = _firstTag(tag);
      if (typeDesc.isNotEmpty && defaultTag.isNotEmpty) {
        selectedTags[typeDesc] = defaultTag;
      }
    }
  }

  void calcCost() async {
    List<Map> tags = selectedTags.entries.map((e) => e.value).toList();
    calculateResult.value = 1;
    var prompt = promptTextFileController.text;

    ApiResponse rsp = await ApiService.instance.sendRequest(
      ApiRequest(
        Apis.security_calculateGenerateVideoCost,
        params: {
          Security.security_params: {
            Security.security_url: imageUrl ?? '',
            Security.security_prompt: prompt,
            Security.security_toUid: userId,
            Security.security_tags: tags,
            Security.security_audioInfo: {
              Security.security_enabled: generateAudio.value ? 1 : 0,
            },
          },
          Security.security_reloadMsgId: reloadMessage?.id ?? 0,
        },
      ),
    );

    if (rsp.isSuccess) {
      calculateResult.value = 0;
      estimatedCost =
          rsp.data[Security.security_costDetail]?[Security
              .security_totalCostValue] ??
          0;
      costItems =
          rsp.data[Security.security_costDetail]?[Security.security_costItems];
    } else {
      calculateResult.value = 2;
      // costItems = null;
      // expand.value = false;
    }

    update([estimatedRefreshId]);
  }

  Future<void> generateVideo() async {
    final agreed = await AIConsentService.ensureConsent(
      feature: AIConsentFeature.videoGeneration,
    );
    if (!agreed) {
      return;
    }

    final tags = selectedTags.values.map((e) => Map.of(e)).toList();
    final prompt = promptTextFileController.text;

    if (prompt.isEmpty) {
      Toast.show(Copywriting.security_please_input_description);
      return;
    }

    Toast.loading();

    if (msgId != null) {
      ReportManager.sendEvent(reportKey, {
        Security.security_type: Security.security_message,
        Security.security_msgId: '$msgId',
      });
    } else if (imageUrl != null) {
      ReportManager.sendEvent(reportKey, {
        Security.security_type: Security.security_image,
      });
    } else {
      ReportManager.sendEvent(reportKey, {
        Security.security_type: Security.security_text,
      });
    }

    final ApiResponse rsp = await VideoCreateManager.requestGenerateVideo(
      sid: userId,
      msgId: msgId ?? 0,
      url: imageUrl ?? '',
      prompt: prompt,
      tags: tags,
      generateAudio: generateAudio.value,
    );
    EventCenter.instance.sendEvent(
      Security.security_requestGenerateVideoSuccess,
      {},
    );
    Toast.dismiss();

    if (rsp.data[Security.security_statusInfo]?[Security.security_code] == 0) {
      VideoCreateManager.getVideoConfig(userId);
      Get.until((route) => route.settings.name == Routers.chat);
    } else {
      Toast.show(
        rsp.data[Security.security_statusInfo]?[Security.security_msg] ??
            rsp.description,
      );
    }
  }

  void reloadVideo() {
    if (reloadMessage == null) return;
    Get.back();
    roomViewController.reloadMessage(reloadMessage!);
  }

  void aiWriterPrompt() {
    final prompts = Preferences.instance.generateVideoPrompts;
    final index = Random().nextInt(prompts.length);
    promptTextFileController.text = prompts[index];
  }
}
