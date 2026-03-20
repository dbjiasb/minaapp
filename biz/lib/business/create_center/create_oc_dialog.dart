import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/create_center/character_service.dart';
import 'package:biz/business/crowd/crowd_manager.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/api_service/api_response.dart';
import '../../base/app_info/app_manager.dart';
import '../../base/assets/image_view.dart';
import '../../base/report/report_manager.dart';
import '../../base/router/route_helper.dart';
import '../../base/router/router_names.dart';
import '../../shared/app_theme.dart';
import '../../shared/toast/toast.dart';

class CreateOcDialog extends StatelessWidget {
  CreateOcDialog({super.key});

  final CreateAiDialogLogic _logic = Get.put(CreateAiDialogLogic());

  static Future show() async {
    return await Get.dialog(useSafeArea: false, Container(alignment: Alignment.bottomCenter, child: CreateOcDialog())).then((_) {
      Get.delete<CreateAiDialogLogic>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 528,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Stack(children: [_buildHeaderSection(), Positioned(bottom: 0, left: 0, right: 0, child: _buildFooterSection())]),
    );
  }

  void _showCopyrightAgreement() {
    Get.toNamed(
      Routers.webView,
      arguments: {Security.security_title: Copywriting.security_copyright_Agreement, Security.security_url: AppManager.instance.createOcHtml},
    );
  }

  Widget _buildHeaderSection() {
    return Stack(
      children: [
        ImageView(Images.security_oc_dialog_bg_png, width: double.infinity),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Row(
            children: [
              IconButton(onPressed: Get.back, icon: ImageView(width: 32, height: 32, Images.security_ic_close_png)),
              Spacer(),
              IconButton(
                onPressed: () {
                  _showCopyrightAgreement();
                },
                icon: ImageView(width: 32, height: 32, Images.security_ic_question_png),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateOcView() {
    return Obx(
      () => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _logic.preCreateOCAndToCreate,
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Color(0xFFFFF0E9), borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ImageView(Images.security_oc_moment_door_webp, width: 36, height: 36),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          _logic.canContinue ? Security.security_Continue : Security.security_character,
                          style: TextStyle(color: AppColors.base_background, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 16),
                        if (!_logic.canContinue)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(9)),
                            child:
                                _logic.costValue == 0
                                    ? RichText(
                                      text: TextSpan(
                                        children: [
                                          if (_logic.premiumFree == 1) WidgetSpan(child: ImageView(Images.security_premium_png, width: 18, height: 18).marginOnly(right: 4)),
                                          WidgetSpan(
                                            child: Text(
                                              _logic.freeText,
                                              style: TextStyle(fontSize: 14, color: AppColors.base_background, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : RichText(
                                      text: TextSpan(
                                        children: [
                                          WidgetSpan(child: ImageView(_logic.costType == 0 ? Images.security_coin_png : Images.security_gem_png, width: 18, height: 18)),
                                          TextSpan(
                                            text: ' ${_logic.costValue}',
                                            style: const TextStyle(color: AppColors.base_background, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                          ),
                        Spacer(),
                        ImageView(Images.security_arrow_right_png, width: 16, height: 16),
                      ],
                    ),
                    SizedBox(height: 3),
                    Text(Copywriting.security_design_your_own_unique_character_and_bring_it_to_life_, style: TextStyle(color: Color(0xFFABABAD), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatGpView() {
    return Obx(
      () => GestureDetector(
        onTap: () {
          Get.back();
          if (CrowedManager.instance.onlyForPremium == 1 && !MyAccount.isSubscribed) {
            RH.toPremium();
            return;
          }
          RH.toPage(Routers.createCrowed);
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          alignment: Alignment.center,
          height: 74,
          decoration: BoxDecoration(color: Color(0xFFFFF2D8), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              ImageView(Images.security_oc_create_door_webp, width: 36, height: 36),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(Copywriting.security_group_Chat, style: TextStyle(color: AppColors.base_background, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        (CrowedManager.instance.onlyForPremium == 1 && !MyAccount.isSubscribed)
                            ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Color(0xFFF1BD8D), Color(0xFFF43F7C)],
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ImageView(Images.security_premium_png, width: 18, height: 18).marginOnly(right: 4),
                                  Text(Copywriting.security_premium_Only, style: TextStyle(color: Colors.white, fontSize: 8)),
                                ],
                              ),
                            )
                            : Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(9)),
                              child:
                                  (CrowedManager.instance.createCostValue == 0
                                      ? Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          if (MyAccount.isSubscribed) ImageView(Images.security_premium_png, width: 18, height: 18).marginOnly(right: 4),
                                          Text(
                                            MyAccount.isSubscribed
                                                ? (MyAccount.freeCrowedLeftTimes == -1
                                                    ? "∞"
                                                    : "(${MyAccount.freeCrowedUsedTimes}/${(MyAccount.freeCrowedLeftTimes + MyAccount.freeCrowedUsedTimes)})")
                                                : Security.security_free,
                                            style: TextStyle(color: AppColors.base_background, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      )
                                      : RichText(
                                        text: TextSpan(
                                          children: [
                                            WidgetSpan(
                                              child: ImageView(
                                                CrowedManager.instance.createCostType == 0 ? Images.security_coin_png : Images.security_gem_png,
                                                width: 18,
                                                height: 18,
                                              ).marginOnly(right: 4),
                                            ),
                                            TextSpan(
                                              text: ' ${CrowedManager.instance.createCostValue}',
                                              style: const TextStyle(color: AppColors.base_background, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      )),
                            ),
                        Spacer(),
                        ImageView(Images.security_arrow_right_png, width: 16, height: 16),
                      ],
                    ),
                    SizedBox(height: 3),
                    Text(Copywriting.security_connect_with_everyone_in_one_place, style: TextStyle(color: Color(0xFFABABAD), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentView() {
    return GestureDetector(
      onTap: () {
        Get.back();
        ReportManager.sendEvent(Security.security_click_moment, {});
        Get.toNamed(Routers.createMoment);
      },
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        height: 74,
        decoration: BoxDecoration(color: Color(0xFFF8E9FF), borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ImageView(Images.security_oc_group_door_webp, width: 36, height: 36),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Security.security_moment, style: TextStyle(color: AppColors.base_background, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 3),
                  Text(
                    Copywriting.security_post_updates_for_your_character_and_bring_every_moment_of_their_story_to_life_,
                    style: TextStyle(color: Color(0xFFABABAD), fontSize: 10),
                  ),
                ],
              ),
            ),
            ImageView(Images.security_arrow_right_png, width: 16, height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return SafeArea(
      bottom: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildCreateOcView(),
            _buildChatGpView(),
            _buildMomentView(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Obx(
                    () => GestureDetector(
                      onTap: () {
                        _logic.consent.value = !_logic.consent.value;
                      },
                      child: ImageView(_logic.consent.value == true ? Images.security_ic_check_png : Images.security_ic_uncheck_png),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: Copywriting.security_prior_to_the_creation_process__please_review_our,
                          style: TextStyle(color: const Color(0xFFABABAD), fontSize: 11, fontWeight: AppFonts.medium),
                        ),
                        TextSpan(
                          text: Copywriting.security_copyright_Agreement,
                          style: TextStyle(
                            color: Color(0xFFB86AFF),
                            fontWeight: AppFonts.medium,
                            fontSize: 11,
                            fontFamily: Copywriting.security_sF_Pro,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  _showCopyrightAgreement();
                                },
                        ),
                        TextSpan(
                          text: Copywriting.security_and_indicate_your_consent_,
                          style: TextStyle(color: const Color(0xFFABABAD), fontSize: 11, fontWeight: AppFonts.medium),
                        ),
                      ],
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ).marginSymmetric(vertical: 8),
          ],
        ),
      ),
    );
  }
}

class CreateAiDialogLogic extends GetxController {
  final consent = true.obs;

  int get costValue => ocCreateCostInfo[Security.security_costValue] ?? 400;

  int get costType => ocCreateCostInfo[Security.security_costType] ?? 0;

  int get premiumFree => ocCreateCostInfo[Security.security_premiumFree] ?? 0;

  String get freeText => costValue == 0 ? (ocCreateCostInfo[Security.security_freeText] ?? '') : '';

  bool get canContinue => ocEntryInfo.isNotEmpty && ocEntryInfo[Security.security_status] == 1;

  Map get ocEntryInfo => CharacterService.instance.ocCreateDraft;

  Map get ocCreateCostInfo => ocEntryInfo[Security.security_createRoleCostInfo] ?? {};

  @override
  void onInit() {
    super.onInit();
    CharacterService.instance.getOCDraft();
    CrowedManager.instance.getCrowdConfigInfo();
    AccountService.instance.getPremInfo();
  }

  Future preCreateOCAndToCreate() async {
    if (!consent.value) {
      Toast.show(Copywriting.security_please_agree_to_the_terms_below_first_);
      return;
    }

    if (!canContinue) {
      Toast.loading();
      ApiResponse rsp = await CharacterService.instance.createOCDraft();
      if (!rsp.isSuccess) {
        if (rsp.bsnsCode == ApiError.notEnoughBalance.v) {
          RouteHelper.back();
          RouteHelper.toPremium();
        }
        Toast.error(rsp.description);
        return;
      }
    }

    Toast.dismiss();
    RouteHelper.back();
    RouteHelper.toPage(Routers.createBasic);
  }
}
