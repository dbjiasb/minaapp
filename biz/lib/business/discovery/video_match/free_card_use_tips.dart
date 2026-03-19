import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';

var kFreeCardTipKey = Security.security_kFreeCardTipKey;

class FreeCardUseTip extends StatelessWidget {
  FreeCardUseTip({super.key});

  RxBool isAgree = false.obs;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 44),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              Text(Copywriting.security_cost_Trial_Card, style: const TextStyle(color: Color(0xFF080E1B), fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                Copywriting.security_you_re_now_using_your_trial_card_or_available_call_time___whichever_applies_,
                style: TextStyle(fontSize: 14, color: Color(0xFF727272), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12), // 分隔符
              // 带项目符号的列表
              _buildBulletPointItem("- Trial Card:", Copywriting.security_grants_the_first_30_seconds_of_the_call_for_free__After_that__gems_will_be_charged_),
              const SizedBox(height: 12),
              _buildBulletPointItem("- Call Time:", Copywriting.security_lets_you_make_calls_without_spending_gems_),
              const SizedBox(height: 12), // 分隔符
              const Text(
                "1. If you hang up mid-minute or during a trial, used time or cards won't be refunded.",
                style: TextStyle(fontSize: 14, color: Color(0xFF727272), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "2. If both are used up and you don't have enough gems, the call will end automatically.",
                style: TextStyle(fontSize: 14, color: Color(0xFF727272), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Obx(() {
                return RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      WidgetSpan(
                        child: InkWell(
                          onTap: () {
                            isAgree.value = !isAgree.value;
                            Preferences.instance.setBool(kFreeCardTipKey, isAgree.value);
                          },
                          child: ImageView(isAgree.value ? "ic_check.png" : "ic_uncheck.png", height: 16, width: 16).marginOnly(right: 4),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Copywriting.security_don_t_remind_me_again, style: TextStyle(color: Color(0xFF9D9EA5), fontSize: 11)),
                    ],
                    style: const TextStyle(color: Color(0xFF9D9EA5), fontSize: 12, height: 1.3),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  Get.back(result: true);
                },
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B39FF), Color(0xFFFF56BB)],
                      begin: Alignment.centerLeft,
                      // 渐变起始点
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(Copywriting.security_i_understand, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.only(top: 8),
                  alignment: Alignment.center,
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFF7F7FA), borderRadius: BorderRadius.circular(16)),
                  child: Text(Security.security_cancel, style: TextStyle(color: Color(0xFFABABAD), fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPointItem(String bullet, String content) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: bullet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF080E1B))),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(text: content, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF727272))),
        ],
      ),
    );
  }

  Widget _buildOrderedListItem(String number, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(content, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  static Future<dynamic> show() async {
    return await Get.dialog(FreeCardUseTip());
  }
}
