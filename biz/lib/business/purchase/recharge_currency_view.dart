import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/util/es_helper.dart';
import 'package:biz/shared/app_theme.dart';

import '../../base/crypt/copywriting.dart';
import '../../base/crypt/security.dart';
import '../../shared/toast/toast.dart';
import 'payment_service.dart';

class RechargeCurrencyView extends StatelessWidget {
  RechargeCurrencyView({super.key});

  final RechargeCurrencyViewController controller = Get.put(
    RechargeCurrencyViewController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      extendBody: true,
      appBar: AppBar(
        leading: InkWell(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          onTap: Get.back,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(left: 16),
            child: ImageView(
              Images.security_back_png,
              fit: BoxFit.cover,
              height: 24,
              width: 24,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text(
          controller.rcgType == 0
              ? EncHelper.rcg_titlCois
              : EncHelper.rcg_titlGms,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBgDecoration(),
          GetBuilder<RechargeCurrencyViewController>(
            builder: (controller) {
              return _rechargeCurrencyView();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBgDecoration() {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 右上角旋转矩形装饰
          Positioned(
            right: -134,
            top: -95,
            child: Transform.rotate(
              angle: -60 * 3.14159265 / 180,
              child: Container(
                width: 243,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color(0xFFFCC8FF).withValues(alpha: 0.6),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [0.355, 0.962],
                    colors: [
                      Color(0xFFFF89EB).withValues(alpha: 0),
                      Color(0xFFE888FF).withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rechargeCurrencyView() {
    final rcgImage = controller.rcgType == 0
        ? Images.security_coin_png
        : Images.security_gem_png;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 17, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.rcgType == 0
                            ? Copywriting.security_coins_balance
                            : Copywriting.security_gems_balance,
                        style: TextStyle(
                          color: Color(0xFFA19C9A),
                          fontSize: 14,
                          fontWeight: AppFonts.medium,
                        ),
                      ),
                      Obx(
                        () => Text(
                          '${controller.rcgType == 0 ? MyAccount.coins : MyAccount.gems}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: AppFonts.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  ImageView(rcgImage, height: 56, width: 56),
                ],
              ),
            ),

            SizedBox(height: 18),
            _buildProducts(rcgImage),
            SizedBox(height: 16),
            GestureDetector(
              onTap: controller.onStartPurchase,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF37C),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Obx(
                  () => Text(
                    _purchaseButtonText(),
                    style: TextStyle(
                      color: const Color(0xFF07070A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts(String rcgImage) {
    bool isGem = controller.rcgType == 1;
    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 110 / 90,
        ),
        itemCount: controller.rechargeList.length,
        itemBuilder: (context, index) {
          Map product = controller.rechargeList[index];
          final hasBonus = isGem && product.iapExtra > 0;
          return GestureDetector(
            onTap: () {
              controller.selectedPro.value = product;
            },
            child: Obx(
              () => Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A23),
                      borderRadius: BorderRadius.circular(8),
                      border: controller.selectedPro == product
                          ? Border.all(width: 1, color: Color(0xffFFF37C))
                          : null,
                    ),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ImageView(rcgImage, height: 24, width: 24),
                            SizedBox(width: 4),
                            Text(
                              '${product.iapValue}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        SizedBox(
                          height: 14,
                          child: hasBonus
                              ? Text(
                                  '+${product.iapExtra}',
                                  style: TextStyle(
                                    color: Color(0xffF84652),
                                    fontSize: 12,
                                    fontWeight: AppFonts.black,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(height: 8),
                        Text(
                          product.iapPriceStr,
                          style: TextStyle(
                            color: controller.selectedPro == product
                                ? Color(0xffFFF37C)
                                : Color(0xFFA19C9A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _purchaseButtonText() {
    if (controller.rcgType != 1 || controller.selectedPro.isEmpty) {
      return Security.security_Recharge;
    }

    final product = controller.selectedPro;
    return 'Purchase for ${product.iapValue + product.iapExtra} Gems';
  }
}

class RechargeCurrencyViewController extends GetxController {
  int rcgType = 1;

  RxList rechargeList = [].obs;
  RxMap selectedPro = {}.obs;

  @override
  void onInit() {
    super.onInit();
    rcgType = Get.arguments[Security.security_rcgType] ?? 1;
    AccountService.instance.refreshBalance();
    PurchaseManager.instance.setup();
    getRechargeList();
  }

  void getRechargeList() async {
    Toast.loading();
    List itemList = await PurchaseManager.instance.getRechargeItem(
      currencyType: rcgType,
    );
    if (itemList.isEmpty) {
      Toast.show(
        Copywriting.security_no_recharge_item_available__try_again_later,
      );
      return;
    }

    /// 如果有缓存的时候loading立刻dismiss不生效
    Future.delayed(const Duration(milliseconds: 100), () {
      Toast.dismiss();
    });

    rechargeList.value = itemList;
    selectedPro.value = rechargeList.first;
    update();

    Set<String> ids = rechargeList.map((e) => (e as Map).iapId).toSet();
    await PurchaseManager.instance.getIapProducts(ids);
    update();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onStartPurchase() {
    PurchaseManager.instance.purchaseItem(selectedPro);
  }
}
