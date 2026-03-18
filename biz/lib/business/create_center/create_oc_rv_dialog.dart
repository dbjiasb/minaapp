import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/app_info/app_manager.dart';
import '../../base/assets/image_view.dart';

import '../../base/router/router_names.dart';
import '../../shared/app_theme.dart';
import 'create_oc_dialog.dart';

class CreateOcRvDialog extends StatelessWidget {
  CreateOcRvDialog({super.key});

  final CreateAiDialogLogic _logic = Get.put(CreateAiDialogLogic());

  static Future show() async {
    return await Get.dialog(useSafeArea: false, Container(alignment: Alignment.bottomCenter, child: CreateOcRvDialog())).then((_) {
      Get.delete<CreateAiDialogLogic>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 375,
      decoration: const BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Stack(children: [Positioned(top: 0, left: 0, right: 0, child: _buildHeaderSection()), _buildFooterSection()]),
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
        ImageView("oc_dialog_rv_bg.png", width: double.infinity),
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Row(
            children: [
              IconButton(onPressed: Get.back, icon: ImageView(width: 32, height: 32, "ic_close.png")),
              Spacer(),
              IconButton(
                onPressed: () {
                  _showCopyrightAgreement();
                },
                icon: ImageView(width: 32, height: 32, "ic_question.png"),
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
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: 16),
          margin: EdgeInsets.only(bottom: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _logic.consent.value ? Color(0xFF07070A) : Color(0xFFCCCCCC), borderRadius: BorderRadius.circular(26)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _logic.canContinue ? Security.security_Continue : "Start Create",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (!_logic.canContinue)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  // decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(9)),
                  child:
                      _logic.costValue == 0
                          ? RichText(
                            text: TextSpan(
                              children: [
                                if (_logic.premiumFree == 1) WidgetSpan(child: ImageView("premium.png", width: 18, height: 18).marginOnly(right: 4)),
                                WidgetSpan(
                                  child: Text(
                                    _logic.freeText,
                                    style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : RichText(
                            text: TextSpan(
                              children: [
                                WidgetSpan(child: ImageView(_logic.costType == 0 ? "coin.png" : "gem.png", width: 18, height: 18)),
                                TextSpan(
                                  text: ' ${_logic.costValue}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      margin: EdgeInsets.only(top: 127),
      height: 170,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topRight: Radius.circular(16), topLeft: Radius.circular(16))),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCreateOcView(),
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
                    child: ImageView(_logic.consent.value == true ? "ic_check.png" : "ic_uncheck.png"),
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
                        text: "Before creation, please review ",
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
                      // TextSpan(
                      //   text: " and provide your consent",
                      //   style: TextStyle(color: const Color(0xFFABABAD), fontSize: 11, fontWeight: AppFonts.medium),
                      // ),
                    ],
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ).marginSymmetric(vertical: 8),
          SafeArea(bottom: true, top: false, child: Container()),
        ],
      ),
    );
  }
}

