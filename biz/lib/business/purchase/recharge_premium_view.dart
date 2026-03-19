import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/business/purchase/payment_service.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/util/calendar_helper.dart';
import 'package:biz/core/util/es_helper.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:bordered_text/bordered_text.dart';

import '../../base/assets/image_view.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/security.dart';
import '../../base/environment/environment.dart';
import '../../base/router/router_names.dart';
import '../../core/util/cached_image.dart';
import '../../shared/toast/toast.dart';

class RechargePremiumView extends StatelessWidget {
  const RechargePremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RechargePremiumViewController>(
      init: RechargePremiumViewController(),
      builder: (controller) {
        return Scaffold(body: Stack(children: [
          ImageView("premium_buy_bg.png", fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          _buildBackButton(controller),
          _buildContent(controller)
        ]));
      },
    );
  }

  Widget _buildBackButton(RechargePremiumViewController controller) {
    return SafeArea(
      child: GestureDetector(
        onTap: controller.navigateBack,
        child: Padding(padding: EdgeInsets.only(left: 18, top: 10), child: ImageView("back.png", height: 24, width: 24)),
      ),
    );
  }

  Widget _buildContent(RechargePremiumViewController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingIndicator();
          } else if (controller.isError.value) {
            return _buildErrorView();
          } else {
            return MyAccount.isSubscribed ? _buildSubscribedView(controller) : _buildSubscriptionPlans(controller);
          }
        }),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.limeAccent))),
    );
  }

  Widget _buildErrorView() {
    return Center(child: Text(EncHelper.rcg_errLoData, style: TextStyle(color: Colors.white)));
  }

  Widget _buildSubscribedView(RechargePremiumViewController controller) {
    return Column(
      children: [
        const Spacer(),
        _buildSuccessHeader(),
        const SizedBox(height: 32),
        _buildUserSubscriptionCard(controller),
        const SizedBox(height: 82)
      ],
    );
  }

  Widget _buildSuccessHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(EncHelper.rcg_fuAces, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.premMain)),
      ],
    );
  }

  Widget _buildUserSubscriptionCard(RechargePremiumViewController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff232015),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1, color: Color(0xFFFFF1C0).withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(children: [
          _buildUserProfileSection(controller),
          const SizedBox(height: 12),
          ..._buildActiveFeatures(controller)
        ]),
      ),
    );
  }

  Widget _buildUserProfileSection(RechargePremiumViewController controller) {
    return Row(
      children: [
        SizedBox(
          height: 76,
          width: 76,
          child: Stack(
            children: [
              ImageView("premium_avatar_bg.png", fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: CachedImage(imageUrl: MyAccount.avatar, height: 64, width: 64, fit: BoxFit.cover),
                )
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text(MyAccount.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 4),
            Row(
              spacing: 4,
              children: [
                Text(EncHelper.rcg_expOn, style: TextStyle(color: Color(0xFFAD9BAF), fontSize: 13, fontWeight: FontWeight.w400)),
                Text(
                  CalendarHelper.formatDate(date: MyAccount.premEdTm) ?? EncHelper.rcg_err,
                  style: const TextStyle(color: AppColors.premMain, fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildActiveFeatures(RechargePremiumViewController controller) {
    if (MyAccount.premBenfs.isEmpty) return [];
    return MyAccount.premBenfs.map((e) {
      String type = (e[Security.security_premiumItemType] ?? 0).toString();
      int totalTimes = e[Security.security_times] ?? 0;
      String name = e[Security.security_name] ?? '';
      Map usedInfo = MyAccount.premUsedInfo[type] ?? {};
      int leftTime = usedInfo[Security.security_leftTimes] ?? -1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageView("premium_benefit_head.png", height: 16, width: 16),
            const SizedBox(width: 4),
            Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500))),
            // const Spacer(),
            Text(leftTime == -1 ? usedInfo[Security.security_desc] ?? '' :'$leftTime/$totalTimes', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(feature, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500))),
          const SizedBox(width: 4),
          ImageView("premium_item_right.png", height: 16, width: 16),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans(RechargePremiumViewController controller) {
    return Column(spacing: 12, children: [
      const Spacer(),
      _buildFeatureList(controller),
      _buildPlanOptions(controller),
      ..._buildFooter(controller)]
    );
  }

  Widget _buildFeatureList(RechargePremiumViewController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() => Column(children: controller.selectedPlanFeatures.map((e) => _buildFeatureItem(e)).toList())),
    );
  }

  Widget _buildPlanOptions(RechargePremiumViewController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controller.allPlans.map<Widget>((plan) => Expanded(child: _buildPlanOption(plan, controller))).toList(),
      ),
    );
  }

  double calculateDailyPay(dynamic cardType, dynamic price) {
    try {
      var days = 1.0;
      switch (cardType) {
        case 1:
          days = 7.0;
          break;
        case 2:
          days = 31.0;
          break;
        case 4:
          days = 365.0;
          break;
        default:
          break;
      }
      double result = price / days;
      return double.parse(result.toStringAsFixed(2));
    } catch (e) {
      return 0.00;
    }
  }

  double calculateSave(dynamic originValue, dynamic price) {
    try {
      double original = originValue is String ? double.parse(originValue) : originValue.toDouble();
      double current = price is String ? double.parse(price) : price.toDouble();

      double savings = (original - current) / original;

      return double.parse(savings.toStringAsFixed(2));
    } catch (e) {
      return 0.00;
    }
  }

  // 没用
  double parseToDouble(dynamic value) {
    if (value == null) {
      return 0.00;
    }
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.parse(value);
    }
    return 0.00;
  }

  Widget _buildPlanOption(Map plan, RechargePremiumViewController controller) {
    final isSelected = controller.selectedPlan == plan;

    Map rcgItem = plan[Security.security_rechargeItem] ?? {};
    final prodName = rcgItem.iapName;
    final cdType = rcgItem[Security.security_premiumPeriodType] ?? 1;
    final dailyPay = calculateDailyPay(cdType, rcgItem.iapPrice);
    final dscnt = rcgItem[EncHelper.rcg_dsct];
    final hasSave = dscnt != null && (dscnt as num) > 0;
    // 原价（未折扣价）
    final origPrice = rcgItem[Security.security_originalValue];
    final hasOrig = origPrice != null && origPrice != 0;

    return GestureDetector(
      onTap: () => controller.selectPlan(plan),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 104,
                width: 110,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2A2A23) : const Color(0xFF19191E),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(width: 2, color: const Color(0xFFFFF37C))
                      : Border.all(width: 1, color: const Color(0x4DFFFFFF)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      prodName,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rcgItem.iapCurrencySymbol}$dailyPay/day',
                      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rcgItem.iapPriceStr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFFFFF37C) : const Color(0xFF999999),
                      ),
                    ),
                    if (hasOrig) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${rcgItem.iapCurrencySymbol}${(origPrice * 0.01).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0x66FFFFFF),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Color(0x66FFFFFF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasSave)
                Positioned(
                  right: 0,
                  top: -10,
                  child: BorderedText(
                    strokeWidth: 2,
                    strokeColor: Color(0xFFFFF37C),
                    child: Text(
                      'Save ${(dscnt * 100).toInt()}%',
                      style: const TextStyle(color: Color(0xFF07070A), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
          ),
        ),
    );
  }

  List<Widget> _buildFooter(RechargePremiumViewController controller) {
    return [
      Text(Copywriting.security_by_clicking_subscribe__you_will_be_charged__and_your_subscription_will_automatically_renew_at_the_same_price_and_duration_until_canceled_through_App_Store_settings__By_proceeding__you_agree_to_our_terms_, style: TextStyle(color: Color(0x66FFFFFF), fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.left),
      _buildSubscribeButton(controller),
      _buildLegalLinks(),
    ];
  }

  Widget _buildSubscribeButton(RechargePremiumViewController controller) {
    return GestureDetector(
      onTap: () {
        controller.processSubscription();
      },
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.premMain, borderRadius: BorderRadius.circular(24)),
        child: Text(EncHelper.rcg_btnSubs, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => launchUrl(EncHelper.rcg_urlTrms),
          child: Text(EncHelper.rcg_trms, style: TextStyle(color: Color(0xFFD5D4D3), fontSize: 10, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => launchUrl(EncHelper.rcg_urlPrivacy),
          child: Text(EncHelper.rcg_privacy, style: TextStyle(color: Color(0xFFD5D4D3), fontSize: 10, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  void launchUrl(String url) {
    if (url == EncHelper.rcg_urlPrivacy) {
      Get.toNamed(Routers.webView, arguments: {EncHelper.rcg_titl: EncHelper.rcg_privacy, EncHelper.rcg_url: url});
    } else if (url == EncHelper.rcg_urlTrms) {
      Get.toNamed(Routers.webView, arguments: {EncHelper.rcg_titl: EncHelper.rcg_trms, EncHelper.rcg_url: url});
    }
  }
}

class RechargePremiumViewController extends GetxController {
  final isLoading = true.obs;
  final isError = false.obs;

  // 未开通时的数据
  RxMap selectedPlan = {}.obs;
  RxList allPlans = [].obs;


  List get selectedPlanFeatures {
    for (var plan in allPlans) {
      if (plan == selectedPlan.value) {
        return plan[Security.security_benefitsDesc];
      }
    }
    return [];
  }

  @override
  void onInit() {
    super.onInit();
    initIap();
    loadSubscriptionData();
  }

  void initIap() async {
    if (Environment.instance.isRelease) {
      await PurchaseManager.instance.setup();
      PurchaseManager.instance.rechargeEventCallback = (bool ok, String? msg) {};
    }
  }

  setupPlan() {
    allPlans.value = AccountService.instance.premiumConfig.map((e) => e).toList();
    if (allPlans.isNotEmpty) {
      selectedPlan.value = allPlans.first;
      Set<String> ids = allPlans.map((e) => ((e[Security.security_rechargeItem] as Map?)?.iapId ?? '')).toSet();
      PurchaseManager.instance.getIapProducts(ids);

      isLoading.value = false;
    }
  }

  Future<void> loadSubscriptionData() async {
    setupPlan();
    if (allPlans.isEmpty) {
      await AccountService.instance.getPremInfo();
      setupPlan();
    } else {
      AccountService.instance.getPremInfo();
    }
  }

  void selectPlan(Map plan) {
    selectedPlan.value = plan;
  }

  void navigateBack() {
    Get.back();
  }

  Future<void> processSubscription() async {
    try {
      final rcgItm = selectedPlan[Security.security_rechargeItem];
      PurchaseManager.instance.purchaseItem(rcgItm);
    } catch (e) {
      Toast.show(Copywriting.security_failed_to_process_subscription__please_try_again_later_);
    }
  }
}
