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

  final RechargeCurrencyViewController controller = Get.put(RechargeCurrencyViewController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        leading: InkWell(onTap: Get.back, child: Container(padding: EdgeInsets.all(16), child: ImageView("back.png", fit: BoxFit.fill))),
        centerTitle: true,
        backgroundColor: AppColors.base_background,
        title: Text(
          controller.rcgType == 0 ? EncHelper.rcg_titlCois : EncHelper.rcg_titlGms,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: GetBuilder<RechargeCurrencyViewController>(
        builder: (controller) {
          return _rechargeCurrencyView();
        },
      ),
    );
  }

  Widget _rechargeCurrencyView() {
    final rcgImage = controller.rcgType == 0 ? "coin.png" : "gem.png";
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 17, horizontal: 24),
              child: Column(
                spacing: 12,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ImageView(rcgImage, height: 44, width: 44),
                  Obx(() => Text(
                    '${controller.rcgType == 0 ? MyAccount.coins : MyAccount.gems}',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: AppFonts.medium),
                  )),
                ],
              ),
            ),

            SizedBox(height: 18),
            _buildProducts(rcgImage),
            GestureDetector(
              onTap: controller.onStartPurchase,
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: AppColors.ocMain, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() => Text(
                      controller.selectedPro.iapPriceStr,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: AppFonts.black),
                    )),
                    SizedBox(width: 4),
                    Text(Security.security_Recharge, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
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
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 110 / 120
        ),
        itemCount: controller.rechargeList.length,
        itemBuilder: (context, index) {
          Map product = controller.rechargeList[index];
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
                      color: Color(0xFF272533),
                      borderRadius: BorderRadius.circular(12),
                      border: controller.selectedPro == product ? Border.all(width: 2, color: isGem ? Color(0xffF84652) : Color(0xffFFEF3B)) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 24),
                        Image.asset(rcgImage, height: 24, width: 24),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${product.iapValue}', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: AppFonts.black)),
                            if (product.iapExtra > 0) SizedBox(width: 2),
                            if (product.iapExtra > 0) Text('+${product.iapExtra}', style: TextStyle(color: Color(0xffF84652), fontSize: 12, fontWeight: AppFonts.black)),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(product.iapPriceStr, style: TextStyle(color: Color(0xffABABAD), fontSize: 14, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (product.flagText.isNotEmpty) Container(
                          width: 86, height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xff8761F1).withValues(alpha: 0),
                                Color(0xff8761F1),
                                Color(0xff8761F1),
                                Color(0xff8761F1).withValues(alpha: 0),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight
                            )
                          ),
                          child: Text(product.flagText, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  if (product.iapGiftRatio > 0)
                    Positioned(
                      top: -6,
                      left: 0,
                      child: Container(
                        width: 76, height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: ImageView.getImageProvider(isGem ? "gem_extra_bg.webp" : "coin_extra_bg.webp"),
                            fit: BoxFit.fill
                          )
                        ),
                        child: Text(
                          'Extra ${(product.iapGiftRatio * 100).toInt()}%',
                          style: TextStyle(color: isGem ? Colors.white : Color(0xff070512), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
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
    List itemList = await PurchaseManager.instance.getRechargeItem(currencyType: rcgType);
    if (itemList.isEmpty) {
      Toast.show(Copywriting.security_no_recharge_item_available__try_again_later);
      return;
    }
    Toast.dismiss();

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
