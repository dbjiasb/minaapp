import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/create_center/character_service.dart';
import 'package:biz/shared/sheet.dart';

import '../../base/assets/image_view.dart';
import '../../base/router/route_helper.dart';
import '../../base/router/router_names.dart';
import '../../core/types.dart';
import '../../core/util/cached_image.dart';
import '../../core/util/es_helper.dart';
import '../../core/util/file_upload.dart';
import '../../shared/app_theme.dart';
import '../../shared/toast/toast.dart';

class BasicCore extends StatelessWidget {
  final _controller = Get.put(BasicController());
  final soundPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              spacing: 12,
              children: [
                _createBaseInfoSection(), // role image, name
                _createGenderSelectionSection(), // gender
                _buildShareArea(),
                _createSoundSelectionSection(), // sound
                _createSlidableSection(
                  title: Security.security_Age,
                  widgets: [_createSliderSection(leftLabel: '18', rightLabel: '60', value: _controller.characterAge, onChanged: _controller.adjustAge)],
                ),
                _createSlidableSection(
                  title: Security.security_Personality,
                  widgets: [
                    _createSliderSection(
                      leftLabel: Security.security_Shy,
                      rightLabel: Security.security_Flirty,
                      value: _controller.shynessLevel,
                      onChanged: _controller.adjustShynessLevel,
                    ),
                    _createSliderSection(
                      leftLabel: EncHelper.cr_pesi,
                      rightLabel: Security.security_Optimistic,
                      value: _controller.optimismLevel,
                      onChanged: _controller.adjustOptimismLevel,
                    ),
                    _createSliderSection(
                      leftLabel: Security.security_Ordinary,
                      rightLabel: Security.security_Mysterious,
                      value: _controller.mysteryLevel,
                      onChanged: _controller.adjustMysteryLevel,
                    ),
                  ],
                ),
                _createSlidableSection(
                  title: Security.security_Physique,
                  widgets: [
                    _createSliderSection(
                      leftLabel: Security.security_Slim,
                      rightLabel: Security.security_Curvy,
                      value: _controller.bodyType,
                      onChanged: _controller.adjustBodyType,
                    ),
                  ],
                ),
                _createPhysiqueDetailsSection(),
                _createPhysiqueToggleButton(),
                Obx(() => _controller.expandPhysiqueRotate.value == 2 ? _createCollapsedPhysiqueDetails() : Container()),
                SafeArea(top: false, child: SizedBox()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _selectProfilePicture() {
    showAppBottomSheet([
      ListTile(
        leading: Icon(Icons.photo_library),
        title: Text(Copywriting.security_select_from_the_album),
        onTap: () async {
          Get.back();
          _controller.pickImageFromSource(ImageSource.gallery);
        },
      ),
      ListTile(
        leading: Icon(Icons.photo_camera),
        title: Text(Copywriting.security_turn_on_the_camera),
        onTap: () async {
          Get.back();
          _controller.pickImageFromSource(ImageSource.camera);
        },
      ),
    ]);
  }

  Widget _createBaseInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _createInfoLabel(Security.security_Identify),
          const SizedBox(height: 12),
          _createRoleImageSection(),
          const SizedBox(height: 12),
          _createNameInputSection(),
        ],
      ),
    );
  }

  Widget _createInfoLabel(String label) {
    return Row(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        const Text('*', style: TextStyle(color: AppColors.ocMain, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _createRoleImageSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: Color(0xff1A181E)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Copywriting.security_role_image, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _selectProfilePicture();
                },
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                        child: Obx(() {
                          if (_controller.processingImage.value) {
                            return Center(child: CircularProgressIndicator(color: AppColors.ocMain));
                          }

                          if (_controller.referenceImageBytes.value.isNotEmpty) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _controller.referenceImageBytes.value,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          }

                          if (_controller.characterImageUrl.value.isNotEmpty) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedImage(
                                imageUrl: _controller.characterImageUrl.value,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          }

                          return Center(child: ImageView(Images.security_chat_add_png, height: 24, width: 24));
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      style: TextStyle(fontSize: 11, color: Color(0xffABABAD), fontWeight: FontWeight.w500),
                      maxLines: 2,
                      Copywriting.security_the_uploaded_image_serves_as_a_reference_for_facial_features_and_style_elements,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _createNameInputSection() {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: Color(0xff1A181E)),
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                Text(Security.security_Name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                Text(' (3-20 characters)', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.center,
                    _controller.nameValidationError.value,
                    style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            alignment: Alignment.center,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8)), color: Colors.white.withValues(alpha: 0.06)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller.nameInputController,
                    onChanged: _controller.updateCharacterName,
                    inputFormatters: _controller.nameInputRestrictions,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xff636268), fontSize: 11, height: 1.2, fontWeight: FontWeight.w500),
                      hintText: Copywriting.security_name_your_character,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2, fontWeight: FontWeight.w500),
                  ),
                ),
                Obx(() {
                  if (_controller.characterName.value.length < 20) {
                    return Text(_controller.characterName.value.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 11));
                  } else {
                    return Text(_controller.characterName.value.length.toString(), style: const TextStyle(color: Colors.red, fontSize: 11));
                  }
                }),
                const Text('/20', style: TextStyle(color: Color(0xFF9EA0A5), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createGenderSelectionSection() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          height: 90,
          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: Color(0xff1A181E)),
          child: Column(
            children: [
              Row(children: [Text(Security.security_Gender, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))]),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _controller.selectGender(Gender.female);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: _controller.selectedGender.value == Gender.female ? Border.all(width: 2, color: const Color(0xFFFF46A4)) : null,
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        height: 40,
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ImageView(width: 24, height: 24, Images.security_female_png),
                              const SizedBox(width: 4),
                              Text(
                                Security.security_Female,
                                style: TextStyle(
                                  color: _controller.selectedGender.value == Gender.female ? Color(0xFFF832B2) : Color(0xff636268),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _controller.selectGender(Gender.male);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: _controller.selectedGender.value == Gender.male ? Border.all(width: 2, color: const Color(0xFF4694FF)) : null,
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        height: 40,
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ImageView(width: 24, height: 24, Images.security_male_png),
                              const SizedBox(width: 4),
                              Text(
                                Security.security_Male,
                                style: TextStyle(
                                  color: _controller.selectedGender.value == Gender.male ? Color(0xFF339FF0) : Color(0xff636268),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  void playSelectedSound() {
    if (_controller.selectedSound[EncHelper.cr_eurl] != null && _controller.selectedSound[EncHelper.cr_eurl] != '' && _controller.soundPlaying.value == false) {
      _controller.soundPlaying.value = true;
      soundPlayer.play(UrlSource(_controller.selectedSound[EncHelper.cr_eurl]));
      soundPlayer.onPlayerComplete.listen((_) => _controller.soundPlaying.value = false);
    }
  }

  Widget _createSoundSelectionSection() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          spacing: 12,
          children: [
            _createInfoLabel(Security.security_Sound),
            Container(
              decoration: BoxDecoration(color: Color(0xff1A181E), borderRadius: BorderRadius.all(Radius.circular(12))),
              height: 48,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: playSelectedSound,
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Obx(() => _controller.soundPlaying.value ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.ocMain)).marginOnly(left: 8) : ImageView(Images.security_sound_play_png),),
                          const SizedBox(width: 8),
                          Text(Copywriting.security_click_to_play, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF999999))),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _controller.toVoiceLibrary();
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _controller.selectedSound[Security.security_name] != null
                                ? Text(
                                  _controller.selectedSound[Security.security_name],
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xffababad)),
                                )
                                : Container(),
                            SizedBox(width: 4),
                            ImageView(height: 16, width: 16, Images.security_arrow_right_png),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createSliderSection({
    required String leftLabel,
    required String rightLabel,
    required RxDouble value,
    required ValueChanged<double> onChanged,
    bool alignBetween = true,
  }) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xff1A181E), borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: alignBetween ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                if (!alignBetween)
                  Expanded(
                    child: Text(
                      textAlign: TextAlign.left,
                      leftLabel,
                      style: const TextStyle(color: Color(0xffababad), fontWeight: FontWeight.w500, fontSize: 11),
                    ),
                  )
                else
                  Text(leftLabel, style: const TextStyle(color: Color(0xffababad), fontWeight: FontWeight.w500, fontSize: 11)),
                if (!alignBetween)
                  Expanded(
                    child: Text(
                      textAlign: TextAlign.right,
                      rightLabel,
                      style: const TextStyle(color: Color(0xffababad), fontWeight: FontWeight.w500, fontSize: 11),
                    ),
                  )
                else
                  Text(rightLabel, style: const TextStyle(color: Color(0xffababad), fontWeight: FontWeight.w500, fontSize: 11)),
              ],
            ),
            Obx(
              () => Slider(activeColor: AppColors.ocMain, inactiveColor: Colors.white.withValues(alpha: 0.06), min: 0, max: 100, value: value.value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createSlidableSection({required String title, required List<Widget> widgets}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(spacing: 8, crossAxisAlignment: CrossAxisAlignment.start, children: [_createInfoLabel(title), ...widgets]),
    );
  }

  Widget _createBodyTypeSliderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: const BoxDecoration(color: Color(0xff1A181E), borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(Security.security_Slim, style: TextStyle(color: Color(0xffababad), fontWeight: FontWeight.w500, fontSize: 11)),
                  Text(Security.security_Curvy, style: TextStyle(color: Color(0xffababad), fontWeight: FontWeight.w500, fontSize: 11)),
                ],
              ),
              Obx(
                () => Slider(
                  activeColor: AppColors.ocMain,
                  inactiveColor: const Color(0xFF171425),
                  min: 0,
                  max: 100,
                  value: _controller.bodyType.value.toDouble(),
                  onChanged: _controller.adjustBodyType,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createPhysiqueToggleButton() {
    return GestureDetector(
      onTap: _controller.togglePhysiqueExpansion,
      child: Container(
        height: 32,
        width: 125,
        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20)), color: AppColors.secondPage),
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(Copywriting.security_more_Details, style: TextStyle(color: Color(0xffababad), fontSize: 11, fontWeight: FontWeight.w500)),
              SizedBox(width: 4),
              RotatedBox(quarterTurns: _controller.expandPhysiqueRotate.value, child: ImageView(Images.security_arrow_down_png, width: 16, height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createPhysiqueDetailsSection() {
    return Obx(() {
      final labels = _controller.physiqueLabels;
      return Column(
        children:
            labels.map((item) {
              String itemKey = item[Security.security_itemKey] as String? ?? '';
              List tags = item[Security.security_tags];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemKey, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            tags
                                .map(
                                  (tag) => GestureDetector(
                                    onTap: () => _controller.selectPhysiqueAttribute(itemKey, tag),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _controller.physiqueAttributes[itemKey] == tag ? Colors.white : Colors.white12,
                                          width: 2,
                                        ),
                                        color: _controller.physiqueAttributes[itemKey] == tag ? Colors.white : Colors.transparent,
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          color: Color(0xFFB8B7B4),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      );
    });
  }

  Widget _createCollapsedPhysiqueDetails() {
    return Obx(() {
      final labels = _controller.collapsedPhysiqueLabels;

      return Column(
        children:
            labels.map((item) {
              final itemKey = item[Security.security_itemKey] as String? ?? '';
              List tags = item[Security.security_tags];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemKey, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            tags
                                .map(
                                  (tag) => GestureDetector(
                                    onTap: () => _controller.selectPhysiqueAttribute(itemKey, tag),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: _controller.physiqueAttributes[itemKey] == tag ? Colors.white : Colors.transparent,
                                        border: Border.all(
                                          color: _controller.physiqueAttributes[itemKey] == tag ? Colors.white : Colors.white12,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          color: Color(0xffB8B7B4),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      );
    });
  }

  Widget _buildShareArea() {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: Color(0xff1A181E)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Copywriting.security_permission_settings, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            Row(children: [_buildShareItem(false), const SizedBox(width: 12), _buildShareItem(true)]).marginOnly(top: 12),
          ],
        ),
      );
    });
  }

  Widget _buildShareItem(bool isPublic) {
    return Expanded(
      child: InkWell(
        onTap: () {
          _controller.updateSharePermission(isPublic);
        },
        child: Container(
          height: 48,
          width: 156.w,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withValues(alpha: 0.06)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(!isPublic ? Security.security_private : Security.security_public, style: const TextStyle(fontSize: 11, color: Colors.white)),
              const Spacer(),
              Icon(
                _controller.isPublicShare.value == isPublic ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: _controller.isPublicShare.value == isPublic ? AppColors.primary : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BasicPage extends StatelessWidget {
  final _controller = Get.put(BasicController());

  @override
  Widget build(BuildContext context) {
    _controller.loadCharacterInfo(CharacterService.instance.createRoleConfigs);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xff07070A),
        leading: IconButton(
          onPressed: () {
            CharacterService.instance.save();
            Get.back();
          },
          icon: ImageView(Images.security_back_png, height: 24, width: 24),
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
                Text('1', style: TextStyle(color: AppColors.ocMain, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: Copywriting.security_sF_Pro_bold)),
                Text('/2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9, fontFamily: Copywriting.security_sF_Pro_bold)),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xff07070A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: CustomScrollView(slivers: [SliverFillRemaining(hasScrollBody: true, child: BasicCore())])),
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        Obx(
          () => GestureDetector(
            onTap: () {
              if (_controller.characterName.value.length < 3) {
                Toast.show(Copywriting.security_character_name_must_be_at_least_3_letters_);
                return;
              }
              if (_controller.canProceed.value) {
                CharacterService.instance.save();
                RH.toPage(Routers.createAdvance);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: _controller.canProceed.value ? AppColors.ocMain : Color(0xFF474D4C),
                ),
                child: Text(
                  Security.security_Next,
                  style: TextStyle(
                    color: _controller.canProceed.value ? Colors.black : Colors.black.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

class BasicController extends GetxController {
  late Map characterConfig;

  // Navigation control
  final canProceed = false.obs;

  // Profile image
  Rx<Uint8List> referenceImageBytes = Uint8List(0).obs;
  RxString characterImageUrl = ''.obs;
  RxBool processingImage = false.obs;

  // Character name
  RxString characterName = ''.obs;
  TextEditingController nameInputController = TextEditingController();
  RxString nameValidationError = ''.obs;
  List<LengthLimitingTextInputFormatter> nameInputRestrictions = [LengthLimitingTextInputFormatter(20)];

  // Character gender
  RxInt selectedGender = Gender.female.obs;

  // Character age
  RxDouble characterAge = 18.0.obs;

  // Voice settings
  RxList voiceConfigurations = [].obs;
  RxMap selectedSound = {}.obs;
  RxBool soundPlaying = false.obs;

  // Personality traits
  RxDouble shynessLevel = 0.0.obs;
  RxDouble optimismLevel = 0.0.obs;
  RxDouble mysteryLevel = 0.0.obs;
  RxDouble bodyType = 0.0.obs;

  // Physique attributes
  RxMap roleConfigMap = {}.obs;

  Map get displayConfig => roleConfigMap[Security.security_displayConfig] ?? {};

  Map get appearanceConfig => displayConfig[selectedGender.value.toString()]?[Security.security_appearance] ?? {};

  ///展开项目
  List get physiqueLabels => appearanceConfig[Security.security_expandItems] ?? [];

  ///收起项
  List get collapsedPhysiqueLabels => appearanceConfig[Security.security_foldItems] ?? [];

  RxMap physiqueAttributes = {}.obs;
  RxInt expandPhysiqueRotate = 0.obs;

  RxBool isPublicShare = false.obs;

  ImagePicker imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
  }

  void loadCharacterInfo(Map configs) {
    if ((configs[Security.security_gender] ?? 2) == 0) {
      configs[Security.security_gender] = Gender.female;
    }
    characterConfig = configs;
    _loadFromRoleInfo();
    _fetchCharacterConfiguration();
    canProceed.value = _validateForm();
  }

  void _loadFromRoleInfo() {
    // Profile image
    characterImageUrl.value = characterConfig[Security.security_personalImageurl] ?? '';

    // Name
    characterName.value = characterConfig[Security.security_nickName] ?? '';
    nameInputController.text = characterName.value;

    // Age
    int age = characterConfig[Security.security_age] ?? 18;
    if (age < 18 || age > 60) age = 18;
    characterAge.value = age.toDouble();

    // Gender
    selectedGender.value = characterConfig[Security.security_gender] ?? Gender.female;
    physiqueAttributes.value = characterConfig[Security.security_configItemMap] ?? {};

    if (physiqueAttributes[Security.security_shy] != null) {
      shynessLevel.value = double.parse(physiqueAttributes[Security.security_shy].toString());
    }

    if (physiqueAttributes[EncHelper.cr_pesi] != null) {
      optimismLevel.value = double.parse(physiqueAttributes[EncHelper.cr_pesi].toString());
    }

    if (physiqueAttributes[Security.security_ordinary] != null) {
      mysteryLevel.value = double.parse(physiqueAttributes[Security.security_ordinary].toString());
    }

    if (physiqueAttributes[Security.security_slim] != null) {
      bodyType.value = double.parse(physiqueAttributes[Security.security_slim].toString());
    }

    isPublicShare.value = (characterConfig[Security.security_shared] ?? 0) == 1;
  }

  Future<void> _fetchCharacterConfiguration() async {
    CharacterService.instance.getPhysiques().then((configMap) {
      if (configMap == null) {
        Toast.show(Copywriting.security_cannot_get_physique_details__please_retry_later);
        return;
      }
      roleConfigMap.value = configMap[Security.security_config] ?? {};
      voiceConfigurations.value = configMap[Security.security_config]?[Security.security_ttsConfig] ?? [];
      // Voice configurations
      Map? defaultVoice;
      for (var voice in voiceConfigurations) {
        if (voice[Security.security_vid] == characterConfig[Security.security_ttsVid]) {
          selectVoice(voice);
          break;
        }
        if (voice[Security.security_gender] == selectedGender.value && voice[Security.security_def] == 1) {
          defaultVoice = voice;
        }
      }
      if (selectedSound.isEmpty && defaultVoice != null) {
        selectVoice(defaultVoice);
      }
    });
  }

  void updateCharacterName(String input) {
    characterName.value = input;
    characterConfig[Security.security_nickName] = characterName.value;
    if (characterName.value.length >= 3) {
      nameValidationError.value = '';
    }
    canProceed.value = _validateForm();
  }

  void selectGender(int genderValue) {
    selectedGender.value = genderValue;
    characterConfig[Security.security_gender] = selectedGender.value;
  }

  void toVoiceLibrary() async {
    Map? selectedVoice = await RH.toPage(Routers.createVoice, args: voiceConfigurations);//await Get.toNamed(Routers.createVoice, arguments: voiceConfigurations);
    if (selectedVoice == null) return;
    selectVoice(selectedVoice);
  }

  void selectVoice(Map voice) async {
    selectedSound.value = voice;
    characterConfig[Security.security_ttsVid] = voice[Security.security_vid];
    characterConfig[Security.security_configItemMap]?[Security.security_mp3_url] = selectedSound[Security.security_exampleUrl];
    characterConfig[Security.security_configItemMap]?[Security.security_mp3_name] = selectedSound[Security.security_name];
  }

  void adjustAge(double newAge) {
    characterAge.value = newAge;
    characterConfig[Security.security_age] = characterAge.value.toInt();
  }

  void adjustShynessLevel(double level) {
    shynessLevel.value = level;
    characterConfig[EncHelper.cr_cfg][Security.security_shy] = level.toInt();
  }

  void adjustOptimismLevel(double level) {
    optimismLevel.value = level;
    characterConfig[EncHelper.cr_cfg][EncHelper.cr_pesi] = level.toInt();
  }

  void adjustMysteryLevel(double level) {
    mysteryLevel.value = level;
    characterConfig[EncHelper.cr_cfg][Security.security_ordinary] = level.toInt();
  }

  void adjustBodyType(double type) {
    bodyType.value = type;
    characterConfig[EncHelper.cr_cfg][Security.security_slim] = type.toInt();
  }

  void selectPhysiqueAttribute(String key, String value) {
    physiqueAttributes[key] = value;
    physiqueAttributes.refresh();
    characterConfig[Security.security_configItemMap][key] = value;
  }

  void togglePhysiqueExpansion() {
    expandPhysiqueRotate.value = expandPhysiqueRotate.value == 0 ? 2 : 0;
  }

  bool _validateForm() {
    if (characterImageUrl.value.isNotEmpty && nameInputController.text.length >= 3) return true;
    return false;
  }

  void updateSharePermission(bool isPublic) {
    isPublicShare.value = isPublic;
    characterConfig[Security.security_shared] = isPublic ? 1 : 0;
  }

  /// Update reference image
  Future<void> pickImageFromSource(ImageSource source) async {
    try {
      XFile? originFile = await imagePicker.pickImage(source: source);
      if (originFile == null) {
        processingImage.value = false;
        return;
      }
      CroppedFile? croppedFile = await cropImage(originFile.path);
      if (croppedFile == null) {
        processingImage.value = false;
        return;
      }

      processingImage.value = true;
      final imageData = await croppedFile.readAsBytes();
      referenceImageBytes.value = imageData;
      String? uploadedImageUrl = await FilePushService.instance.upload(imageData, FileType.profile);
      if (uploadedImageUrl?.isEmpty ?? true) {
        Toast.show(Copywriting.security_unknown_error__please_upload_again_);
        processingImage.value = false;
        return;
      }

      characterImageUrl.value = uploadedImageUrl!;
      characterConfig[Security.security_personalImageurl] = uploadedImageUrl;
      canProceed.value = _validateForm();
      processingImage.value = false;

      ///异步检查图片质量
      Map? validationResult = await CharacterService.instance.checkPic(uploadedImageUrl);
      CharacterService.instance.traceId = validationResult?[Security.security_statusInfo]?[Security.security_traceId] ?? '';

    } catch (e) {
      Toast.show('Upload image failed: $e');
      processingImage.value = false;
    }
  }

  Future<CroppedFile?> cropImage(String filePath) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(sourcePath: filePath, aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1));
    return croppedFile;
  }
}
