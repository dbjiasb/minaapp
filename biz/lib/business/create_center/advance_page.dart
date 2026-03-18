import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/create_center/character_service.dart';
import 'package:biz/shared/alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../base/assets/image_view.dart';
import '../../base/preferences/preferences.dart';
import '../../base/router/router_names.dart';
import '../../core/util/es_helper.dart';
import '../../shared/app_theme.dart';
import '../../shared/toast/toast.dart';

class AdvanceCore extends StatelessWidget {
  final _logic = Get.put(AdvanceController());
  final masterNameFormatter = [LengthLimitingTextInputFormatter(24)];
  final imagePromptsFormatter = [LengthLimitingTextInputFormatter(300)];
  final scenarioFormatter = [LengthLimitingTextInputFormatter(500)];
  final introductionFormatter = [LengthLimitingTextInputFormatter(500)];
  final initialMessageFormatter = [LengthLimitingTextInputFormatter(300)];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildTextFieldTemplate(
                  Copywriting.security_what_should_AI_call_you,
                  Copywriting.security_the_OC_will_address_you_by_the_name_you_enter_,
                  //'Al will call you by the name you enter',
                  24,
                  masterNameFormatter,
                  _logic.onInputMasterName,
                  1,
                  _logic.masterNameController,
                  _logic.masterName,
                  titleTrailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(16)), border: Border.all(color: AppColors.primary, width: 1)),
                    child: GestureDetector(
                      onTap: () {
                        _logic.doAIWriter();
                      },
                      child: Row(
                        children: [
                          Icon(Icons.draw, size: 12, color: AppColors.primary),
                          SizedBox(width: 2),
                          Text(Copywriting.security_aI_Writer, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildTextFieldTemplate(
                  EncHelper.cr_img_prp,
                  Copywriting
                      .security_supply_detailed_information_about_the_image__such_as_the_clothing_worn__facial_features__and_actions__For_example___On_the_moonlit_balcony_of_a_neo___Victorian_mansion__an_ethereal_woman_with_bright_blue_hime___cut_hair_leans_against_the_railing__Her_khaki_backless_sweater_flutters_gently_in_the_breeze_as_she_turns_to_look_at_the_viewer_with_an_otherworldly_serenity__,
                  300,
                  imagePromptsFormatter,
                  _logic.onInputImagePrompts,
                  6,
                  _logic.picPromptsController,
                  _logic.picPrompts,
                  titleTrailing: Obx(
                    () => CupertinoSlidingSegmentedControl(
                      padding: EdgeInsets.zero,
                      thumbColor: AppColors.primary,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      groupValue: _logic.imagePromptsGlobal.value,
                      onValueChanged: (value) {
                        _logic.resetImagePromptsGlobal(value ?? false);
                      },
                      children: {
                        false: Text(
                          Security.security_background,
                          style: TextStyle(
                            color: !_logic.imagePromptsGlobal.value ? Color(0xFF07070A) : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        true: Text(
                          Security.security_global,
                          style: TextStyle(
                            color: _logic.imagePromptsGlobal.value ? Color(0xFF07070A) : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      },
                    ),
                  ),
                ),
                _buildTextFieldTemplate(
                  Copywriting.security_scenario,
                  Copywriting.security_describe_the_conversation_scenario_and_involved_characters_,
                  //'The current circumstances and context of the conversation and the characters.',
                  500,
                  scenarioFormatter,
                  _logic.onInputScenario,
                  5,
                  _logic.sceneController,
                  _logic.scene,
                ),
                _buildTextFieldTemplate(
                  Copywriting.security_introduction,
                  Copywriting
                      .security_appears_exclusively_in_your_character__s_public_profile_This_biographical_information_will_not_be_utilized_in_generation_prompts_or_influence_behavioral_patterns_,
                  500,
                  introductionFormatter,
                  _logic.onInputIntroduction,
                  5,
                  _logic.bioController,
                  _logic.bio,
                ),

                _buildTextFieldTemplate(
                  Copywriting.security_initial_Message,
                  Copywriting.security_first_message_from_your_character__It_will_help_the_chat_get_off_to_a_better_start_,
                  300,
                  initialMessageFormatter,
                  _logic.onInputInitialMessage,
                  5,
                  _logic.initialMessageController,
                  _logic.initialMessage,
                ),
                _buildGeneratingGallery(),
                _buildStyleBox(Copywriting.security_dialogue_Style),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGeneratingGallery() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Copywriting.security_generating_Gallery, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
              Obx(() {
                return CupertinoSlidingSegmentedControl(
                  padding: EdgeInsets.zero,
                  thumbColor: AppColors.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  groupValue: _logic.generatingGallery.value,
                  onValueChanged: (value) {
                    _logic.generatingGallery.value = value ?? false;
                    Preferences.instance.setBool(Security.security_kGeneratingGallery, value ?? false);
                  },
                  children: {
                    false: Text(
                      Security.security_off,
                      style: TextStyle(color: !_logic.generatingGallery.value ? Color(0xFF07070A) : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    true: Text(
                      Security.security_on,
                      style: TextStyle(color: _logic.generatingGallery.value ? Color(0xFF07070A) : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  },
                );
              }),
            ],
          ),
          SizedBox(height: 8),
          Text(
            Copywriting.security_enable_this_option_to_allow_the_AI_to_generate_image_galleries_based_on_your_information_,
            style: TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.w500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldTemplate(
    String title,
    String hintText,
    int limited,
    List<LengthLimitingTextInputFormatter> formatters,
    void Function(String input) onInput,
    int maxLines,
    TextEditingController controller,
    RxString curString, {
    Widget? titleTrailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
              if (titleTrailing != null) titleTrailing,
            ],
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: Color(0xFF1A181E)),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  inputFormatters: formatters,
                  onSubmitted: (value) {
                    try {
                      FocusScope.of(Get.context!).unfocus();
                    } catch (e) {}
                  },
                  onChanged: (value) {
                    if (value.endsWith('\n')) {
                      controller.text = value.substring(0, value.length - 1);
                      try {
                        FocusScope.of(Get.context!).unfocus();
                      } catch (e) {}
                      return;
                    }
                    onInput(value);
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: const TextStyle(color: Color(0xFF636268), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  maxLines: maxLines,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(curString.value.length.toString(), style: const TextStyle(color: Color(0xFF636268), fontSize: 11, fontWeight: FontWeight.w500)),
                      Text('/$limited', style: const TextStyle(color: Color(0xFF636268), fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleBox(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
          Container(
            height: 356,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: AppColors.ocBox),
            child: Obx(
              () => Column(
                spacing: 8,
                children: [
                  Text(
                    Copywriting
                        .security_defines_the_conversational_patterns_between_you_and_your_character__This_crucial_setting_determines_how_your_character_formulates_responses_and_maintains_personality_consistency_,
                    style: TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.w500, fontSize: 11),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 8,
                        children:
                            _logic.dialogStyle.map((e) {
                              String from = e[Security.security_msgFrom] ?? '';
                              bool isUser = from == Security.security_user;
                              int i = _logic.dialogStyle.indexOf(e);

                              return Row(
                                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 200),
                                    child: IntrinsicHeight(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isUser ? Colors.white : AppColors.ocMain,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                            bottomLeft: isUser ? Radius.circular(12) : Radius.circular(4),
                                            bottomRight: isUser ? Radius.circular(4) : Radius.circular(12),
                                          ),
                                        ),
                                        child: TextField(
                                          style: TextStyle(color: isUser ? Colors.black : Colors.black, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                                          controller: _logic.controllers[i],
                                          onChanged: (value) {
                                            _logic.onInputDialog(isUser ? Security.security_user : Security.security_bot, value, i);
                                          },
                                          maxLines: null,
                                          minLines: 1,
                                          keyboardType: TextInputType.multiline,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            hintText: '${Copywriting.security_click_to_add} $from’s message',
                                            hintStyle: TextStyle(
                                              color: isUser ? Colors.black54 : Colors.black54,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _logic.addRound,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8)), color: Color(0xff2F3031)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Wrap(
                            runAlignment: WrapAlignment.center,
                            spacing: 4,
                            children: [
                              ImageView("chat_add.png", height: 16, width: 16),
                              Text(Copywriting.security_add_rounds, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(
                                '(${_logic.dialogStyle.length ~/ 2}/5）',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 11, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdvancePage extends StatelessWidget {
  final masterNameFormatter = [LengthLimitingTextInputFormatter(24)];
  final imagePromptsFormatter = [LengthLimitingTextInputFormatter(300)];
  final scenarioFormatter = [LengthLimitingTextInputFormatter(500)];
  final introductionFormatter = [LengthLimitingTextInputFormatter(500)];
  final _logic = Get.put(AdvanceController());

  @override
  Widget build(BuildContext context) {
    _logic.loadCharacterInfo(CharacterService.instance.createRoleConfigs);
    return Scaffold(
      backgroundColor: Color(0xff07070A),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xff07070A),
        leading: IconButton(
          onPressed: () {
            CharacterService.instance.save();
            Get.back();
          },
          icon: ImageView("back.png", height: 24, width: 24),
        ),
        title: Text(
          textAlign: TextAlign.center,
          Copywriting.security_create_My_Character,
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Copywriting.security_sF_Pro_bold, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text('2', style: TextStyle(color: AppColors.ocMain, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: Copywriting.security_sF_Pro_bold)),
                Text('/2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9, fontFamily: Copywriting.security_sF_Pro_bold)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 可滑动中间部分
            Expanded(child: CustomScrollView(slivers: [SliverFillRemaining(hasScrollBody: true, child: AdvanceCore())])),

            // 固定底部
            _buildGenBtn(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenBtn() {
    return Column(
      children: [
        Obx(
          () => GestureDetector(
            onTap: _logic.toGen.value ? _logic.toGeneratePage : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: _logic.toGen.value ? AppColors.ocMain : Color(0xFF2F3031),
                ),
                // 禁用状态颜色
                child: Text(
                  Security.security_Generate,
                  style: TextStyle(color: _logic.toGen.value ? Colors.white : Colors.white.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTitleLine() {
    return Container(
      alignment: Alignment.topCenter,
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 32),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                CharacterService.instance.save();
                Get.back();
              },
              icon: ImageView("back.png", height: 24, width: 24),
            ),
            Expanded(
              child: Text(
                textAlign: TextAlign.center,
                Copywriting.security_create_My_Character,
                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Copywriting.security_sF_Pro_bold, fontWeight: FontWeight.bold),
              ),
            ),
            Text('2', style: TextStyle(color: AppColors.ocMain, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: Copywriting.security_sF_Pro_bold)),
            Text('/2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9, fontFamily: Copywriting.security_sF_Pro_bold)),
          ],
        ),
      ),
    );
  }
}

class AdvanceController extends GetxController {
  late Map config;

  final toGen = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  // 角色对创建者的称呼
  RxString masterName = ''.obs;
  RxString masterNameError = ''.obs;
  final masterNameController = TextEditingController();

  // 生图提示词
  RxString picPrompts = ''.obs;
  RxBool imagePromptsGlobal = true.obs;
  final picPromptsController = TextEditingController();

  RxBool generatingGallery = Preferences.instance.getBool(Security.security_kGeneratingGallery).obs;

  // 场景信息
  RxString scene = ''.obs;
  final sceneController = TextEditingController();

  // 简介信息
  RxString bio = ''.obs;
  final bioController = TextEditingController();

  RxString initialMessage = ''.obs;
  final initialMessageController = TextEditingController();

  // 对话框
  RxList dialogStyle = [].obs;
  RxList<TextEditingController> controllers = <TextEditingController>[].obs;

  ///接口方法
  void _loadFromRoleInfo() {
    bioController.text = config[Security.security_introduction] ?? '';
    sceneController.text = config[Security.security_scenario] ?? '';
    picPromptsController.text = config[Security.security_imagePrompts] ?? '';
    masterNameController.text = config[Security.security_masterName] ?? '';
    initialMessageController.text = config[Security.security_firstMessage] ?? '';
    imagePromptsGlobal.value = (config[Security.security_chatBackgroundPromptsUseChat] ?? 1) == 1;

    bio.value = bioController.text;
    scene.value = sceneController.text;
    picPrompts.value = picPromptsController.text;
    masterName.value = masterNameController.text;
    initialMessage.value = initialMessageController.text;

    toGen.value = _checkFormGenValid();
    loadDialogStyle();
  }

  void loadDialogStyle() {
    List diaConfig = config[Security.security_dialogueStyle] ?? [];
    if (diaConfig.isEmpty) return;

    for (int i = 0; i < diaConfig.length; i++) {
      controllers.add(TextEditingController());
      controllers[i].text = diaConfig[i][Security.security_content];
      dialogStyle.add(diaConfig[i]);
    }
  }

  void onInputMasterName(String input, {bool fromAuto = false}) {
    masterName.value = input;
    if (fromAuto) masterNameController.text = input;
    config[Security.security_masterName] = input;
    toGen.value = _checkFormGenValid();
    if (input.length >= 3) {
      masterNameError.value = '';
    }
  }

  void onInputImagePrompts(String input, {bool fromAuto = false}) {
    picPrompts.value = input;
    if (fromAuto) picPromptsController.text = input;
    config[Security.security_imagePrompts] = input;
  }

  void onInputScenario(String input, {bool fromAuto = false}) {
    scene.value = input;
    if (fromAuto) sceneController.text = input;
    config[Security.security_scenario] = input;
  }

  void onInputIntroduction(String input, {bool fromAuto = false}) {
    bio.value = input;
    if (fromAuto) bioController.text = input;
    config[Security.security_introduction] = input;
  }

  void onInputInitialMessage(String input, {bool fromAuto = false}) {
    initialMessage.value = input;
    if (fromAuto) initialMessageController.text = input;
    config[Security.security_firstMessage] = input;
  }

  void onInputDialog(String msgFrom, String content, int index) {
    dialogStyle[index][Security.security_content] = content;
    config[Security.security_dialogueStyle] = dialogStyle;
    dialogStyle.refresh();
  }

  @override
  void dispose() {
    masterNameController.dispose();
    picPromptsController.dispose();
    sceneController.dispose();
    bioController.dispose();
    initialMessageController.dispose();
    super.dispose();
  }

  void addRound() {
    if (dialogStyle.length < 10) {
      dialogStyle.add({Security.security_msgFrom: Security.security_bot, Security.security_content: '${EncHelper.cr_caa} OC\'s message'});
      controllers.add(TextEditingController());
      dialogStyle.add({Security.security_msgFrom: Security.security_user, Security.security_content: '${EncHelper.cr_caa} user\'s message'});
      controllers.add(TextEditingController());
      config[Security.security_dialogueStyle] = dialogStyle;
    }
  }

  void toGeneratePage() async {
    if (masterName.value.isNotEmpty && (masterName.value.length < 3 || masterName.value.length > 24)) {
      Toast.show(Copywriting.security_master_name_must_be_2_24_characters_in_length);
      return;
    }
    CharacterService.instance.save();
    Get.toNamed(Routers.createGen);
  }

  bool _checkFormGenValid() {
    if (masterNameController.text.length >= 3) return true;
    return false;
  }

  void loadCharacterInfo(Map configs) {
    config = configs;
    _loadFromRoleInfo();
  }

  void resetImagePromptsGlobal(bool value) {
    imagePromptsGlobal.value = value;
    config[Security.security_chatBackgroundPromptsUseChat] = value ? 1 : 0;
  }

  void doAIWriter() async {
    showConfirmAlert(
      Security.security_tips,
      Copywriting.security_the_existing_filled_content_will_be_replaced_by_the_template_content_and_cannot_be_undone_,
      confirmText: Security.security_continue,
      onConfirm: () async {
        ApiResponse ret = await CharacterService.instance.aiWriter(config);
        if (ret.isSuccess) {
          Map aiConfig = ret.data[Security.security_template] ?? {};
          if (aiConfig.isEmpty) {
            return;
          }

          String name = aiConfig[Security.security_masterName] ?? '';
          if (name.isNotEmpty) onInputMasterName(name, fromAuto: true);
          onInputImagePrompts(aiConfig[Security.security_imagePrompts] ?? '', fromAuto: true);
          onInputScenario(aiConfig[Security.security_scenario] ?? '', fromAuto: true);
          onInputIntroduction(aiConfig[Security.security_introduction] ?? '', fromAuto: true);
          onInputInitialMessage(aiConfig[Security.security_firstMessage] ?? '', fromAuto: true);

          config[Security.security_dialogueStyle] = aiConfig[Security.security_dialogueStyle] ?? [];
          loadDialogStyle();
        }
      },
    );
  }
}
