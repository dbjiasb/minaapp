import 'package:biz/base/crypt/routes.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:biz/core/util/log_util.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/route_helper.dart';

import '../../base/api_service/api_service_export.dart';
import '../../base/environment/environment.dart';
import '../../core/account/account_service.dart';
import '../../shared/alert.dart';
import '../../shared/toast/toast.dart';

String kCachedExceptionOrderKey = Security.security_kCachedErrorPurchase;

const kIapV1ItemId = -1;
String get curPayMethod => Platform.isAndroid ? '2' : '3';

extension IapMap on Map {

  ProductDetails? get iap => PurchaseManager.instance.productForId(iapId);
  String get iapCurrencySymbol {
    return iap?.currencySymbol ?? '\$';
  }
  double get iapPrice {
    return iap?.rawPrice ?? (this[Security.security_price] ?? 0) * 0.01;
  }
  String get iapPriceStr {
    return iap?.price ?? '\$${iapPrice.toStringAsFixed(2)}';
  }

  String get iapId {
    return this[Security.security_channelInfo]?[curPayMethod]?[Security.security_inAppProductId] ?? '';
  }

  String get iapName => this[Security.security_name] ?? '';
  int get iapValue => this[Security.security_score] ?? 0;
  int get iapExtra => this[Security.security_packageOffer]?[Security.security_score] ?? 0;
  int get iapItemId => this[Security.security_itemId] ?? 0;
  double get iapGiftRatio => this[Security.security_giftRatio] ?? 0.0;
  double get iapDiscount => this[Security.security_discount] ?? 0.0;
  String get iapDiscountText => (100 - (this[Security.security_discount] ?? 0) * 100).toStringAsFixed(0);

  set iapOurOrderId(String id) => this[Security.security_ourOrderId] = id;
  String get iapOurOrderId => this[Security.security_ourOrderId] ?? '';
  set iapReceipt(String receipt) => this[Security.security_receipt] = receipt;
  String get iapReceipt => this[Security.security_receipt] ?? '';
  set iapPurchaseId(String id) => this[Security.security_purchaseId] = id;
  String get iapPurchaseId => this[Security.security_purchaseId] ?? iapId;

  bool get iapVip => this[Security.security_rechargeItemType] == 1 || iapId.contains('week') || iapId.contains('month') || iapId.contains('year');
  bool get iapV1 => iapItemId == kIapV1ItemId;

  set iapFirstPurchase(bool isFirst) => this[Security.security_iapFirstPurchase] = isFirst;
  bool get iapFirstPurchase => this[Security.security_iapFirstPurchase] ?? false;

  String get flagText {
    List flagInfos = this[Security.security_flagInfoList] ?? [];
    if (flagInfos.isEmpty) return '';
    return flagInfos.first[Security.security_desc] ?? '';
  }

  static fromV1(Map v1) {
    return {
      Security.security_itemId: kIapV1ItemId,
      Security.security_name: v1.iapName,
      Security.security_price: v1[Security.security_price] ?? 0,
      Security.security_score: v1.iapValue,
      Security.security_desc: v1[Security.security_desc] ?? '',
      Security.security_discount: v1[Security.security_discount] ?? 0,
      Security.security_flagInfoList: [{
        Security.security_flag: 0,
        Security.security_desc: Copywriting.security_special_Offer,
      }],
      Security.security_currencyType: 1,
      Security.security_rechargeItemType: v1[Security.security_rechargeItemType] ?? 0,
      Security.security_channelInfo: {
        '3': {Security.security_inAppProductId: v1[Security.security_id] ?? ''},
      },
      Security.security_iapFirstPurchase: true
    };
  }
}

class FirstPurchaseTask {
  final RxMap _task = {}.obs;
  set task(Map task) {
    _task.value = task;
    _task.refresh();
    startTimer();
  }

  set leftTime(int leftTime) {
    _task[Security.security_leftTime] = leftTime * 1000;
    _task.refresh();
  }

  int get leftTime => (_task[Security.security_leftTime] ?? 0) ~/ 1000;

  Timer? timer;
  void startTimer() {
    if (timer != null) {
      timer?.cancel();
      timer = null;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      leftTime = leftTime - 1;
      if (leftTime <= 0) {
        timer.cancel();
      }
    });
  }

  Map get rechargeItem => _task[Security.security_rechargeItem] ?? {};
  bool get isValid => leftTime > 0 && (rechargeItem[Security.security_id]?.isNotEmpty ?? false);

  double get discount => _task[Security.security_discount] ?? 0;
  String get discountText => '${discount * 100}%';
  int get awardCount => _task[Security.security_totalAwardCount] ?? 0;
  String get videoUrl => _task[Security.security_videoUrl] ?? '';
  int get finalPrice => _task[Security.security_rechargeItem]?[Security.security_price] ?? 10000;
  int get originalPrice => _task[Security.security_rechargeItem]?[Security.security_originalValue] ?? finalPrice;
}
FirstPurchaseTask get FRTask => PurchaseManager.instance.firstRechargeTask;

class PurchaseManager {
  static final PurchaseManager instance = PurchaseManager._internal();

  factory PurchaseManager() => instance;

  PurchaseManager._internal();

  Function(bool, String?)? rechargeEventCallback;
  List<ProductDetails> _products = [];
  Map<String, ProductDetails> productMap = {};

  ProductDetails? productForId(String productId) {
    return productMap[productId];
  }

  bool _initialized = false;

  Map<String, Map<String, String>> cachedReceipts = {};

  InAppPurchase get iap => InAppPurchase.instance;

  bool _isAvailable = false;

  Function(bool, String?)? completion;

  FirstPurchaseTask firstRechargeTask = FirstPurchaseTask();

  setup() async {
    if (_initialized) return;
    _initialized = true;
    _isAvailable = await iap.isAvailable();
    if (!_isAvailable) {
      L.e("[IAP] ⚠️  IAP Service not available");
    }
    EventCenter.instance.addListener(Security.security_kEventCenterUserDidLogin, onUserDidLogin);
    EventCenter.instance.addListener(Security.security_kEventCenterUserDidLogout, onUserDidLogout);
    // if (AccountService.instance.loggedIn) {
    //   getFirstRechargeTask();
    // }
    // getFirstRechargeTask();
    InAppPurchase.instance.purchaseStream.listen((List<PurchaseDetails> purchases) {
      for (var purchase in purchases) {
        onPurchaseEventCallback(purchase);
      }
    });
    if (AccountService.instance.loggedIn) {
      fixedExceptionOrdersIfNeeded();
    }
  }

  dispose() {
    EventCenter.instance.removeListener(Security.security_kEventCenterUserDidLogin, onUserDidLogin);
  }

  void onUserDidLogin(Event event) {
    // getFirstRechargeTask();
    fixedExceptionOrdersIfNeeded();
  }

  void onUserDidLogout(Event event) {
    // firstRechargeTask.task = {};
  }

  void fixedExceptionOrdersIfNeeded() async {
    await Future.delayed(const Duration(seconds: 5));

    var exceptionOrders = Preferences.instance.getMap(kCachedExceptionOrderKey);
    L.i('[IAP] fixedOrders: $exceptionOrders');
    if (exceptionOrders.isNotEmpty) {
      for (var key in exceptionOrders.keys) {
        var pair = exceptionOrders[key];
        var productId = pair[Security.security_pid];
        var receipt = pair[Security.security_receipt];
        verifyPurchasedToken(productId, receipt, key);
      }
    }
  }

  Future<List<ProductDetails>> getIapProducts(Set<String> ids) async {
    // final Set<String> ids = productConfig.keys.toSet();
    L.i("[IAP] query products, ids: $ids");
    try {
      final ProductDetailsResponse response = await iap.queryProductDetails(ids);
      if (response.notFoundIDs.isNotEmpty) {
        L.e("[IAP] query products not found ids: ${response.notFoundIDs}");
      }
      _products = response.productDetails;
      productMap = Map.fromEntries(_products.map((e) => MapEntry(e.id, e)));
      L.i("[IAP] query products count:  ${_products.length}");
    } catch (e) {
      L.e("[IAP] query products error: $e");
    }
    return _products;
  }

  Future<void> onPurchaseEventCallback(PurchaseDetails purchase) async {
    debugPrint("[IAP]  purchase callback: ${purchase.productID} pid ${purchase.purchaseID} status: ${purchase.status} error: ${purchase.error}");

    bool verified = false;

    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // if (!purchase.productID.contains(Security.security_weekly) && !purchase.productID.contains(Security.security_monthly) && !purchase.productID.contains(Security.security_yearly)) {
        //   Preferences.instance.setMap(
        //       iapCachedKey, {Security.security_pid: purchase.productID, Security.security_receipt: purchase.verificationData.serverVerificationData});
        // }
        L.i("[IAP] ✅ 购买成功: ${purchase.productID}, status: ${purchase.status} pid ${purchase.purchaseID} 开始验证Receipt");

        /// 存在正在购买的商品，走订单验证逻辑
        if (purchasingItem?.iapId == purchase.productID) {
          purchasingItem!.iapReceipt = purchase.verificationData.serverVerificationData;
          purchasingItem!.iapPurchaseId = purchase.purchaseID ?? '';
          verified = await rechargeCallback(purchasingItem!);
        } else {
          /// 其他商品，走通用的createAndCallback
          verified = await verifyPurchase(purchase);
          completion?.call(verified, verified ? null : Copywriting.security_receipt_Not_Available);
        }
        break;
      case PurchaseStatus.error:
        if (purchasingItem != null) {
          Toast.show('Purchase Failed: ${purchase.error}');
        }
        purchasingItem = null;
        completion?.call(false, "Purchase Fail: ${purchase.error}");
        L.e("[IAP] ❌ Purchase Fail: ${purchase.error}");
        break;
      case PurchaseStatus.pending:
        L.i("[IAP]⌛ Pending: ${purchase.productID}");
        break;
      case PurchaseStatus.canceled:
        Toast.dismiss();
        L.i("[IAP] ⌛ canceled: ${purchase.productID}");
        purchasingItem = null;
        break;
    }

    // Billing 8 requires non-consumable purchases and subscriptions to be
    // acknowledged. Complete only after the server has granted entitlement so
    // a failed verification can be delivered again by Google Play.
    if (verified && purchase.pendingCompletePurchase) {
      try {
        await iap.completePurchase(purchase);
        L.i("[IAP] ✅ completePurchase 已调用: ${purchase.productID}");
      } catch (e) {
        L.e("[IAP] completePurchase failed for ${purchase.productID}: $e");
      }
    }
  }

  Map? purchasingItem;

  Future<void> purchaseItemV1(Map item) async {
    return await purchaseItem(IapMap.fromV1(item));
  }

  Future<void> purchaseItem(Map item) async {
    bool isDebug = kDebugMode || Environment.instance.isDebug;
    if (isDebug) {
      Toast.show(Copywriting.security_purchasing___);
      Future.delayed(const Duration(seconds: 1), () {
        showConfirmAlert(Copywriting.security_payment_successful, '${item.iapName} purchased successfully');
        completion?.call(true, null);
      });
      return;
    }

    L.e("[IAP] buy product, item $item, iap config: $productMap");

    if (purchasingItem != null) {
      L.e("[IAP] buy product, another purchase is in processing");
      Toast.loading(status: Copywriting.security_purchasing___);
      return;
    }

    if (item.iapId.isEmpty || item.iapItemId == 0) {
      L.e("[IAP] buy product, item error");
      Toast.show(Copywriting.security_item_info_error);
      return;
    }

    Toast.loading(status: Copywriting.security_purchasing___);

    purchasingItem = item;

    Map? order = await createRechargeOrder(id: item.iapItemId);
    if (order == null) {
      /// 创建订单失败，在上面的流程已经提示错误了。
      purchasingItem = null;
      return;
    }
    item.iapOurOrderId = order[Security.security_ourOrderId] ?? '';
    String verifyUrl = order[Security.security_developerPayload] ?? '';
    if (verifyUrl.isNotEmpty && verifyUrl.startsWith(Security.security_http)) {
      purchasingItem = null;
      L.i('[IAP] detect risk order, will verify');
      await RouteHelper.toWeb(verifyUrl, title: '');
      if (item.iapVip) {
        AccountService.instance.getPremInfo();
      } else {
        AccountService.instance.refreshBalance();
      }
      return;
    }


    if (!_isAvailable) {
      L.e("[IAP] IAP Not Available");
      Toast.show(Copywriting.security_iAP_Service_Not_Available);
      return;
    }

    ProductDetails? product = productMap[item.iapId];
    if (product == null) {
      L.e("[IAP] error, ${item.iapId} not found, will load again.");
      product = (await getIapProducts({item.iapId})).firstOrNull;
      if (product == null) {
        L.e("[IAP] error, ${item.iapId} not found");
        Toast.show('Product not found for ${item.iapId}, please try again later');
        return;
      }
    }

    // if (kDebugMode) {
    //   item.iapReceipt = Security.security_test_absasdkjhakjsdhjkashdkjashdjkahsdasdasdas;
    //   item.iapPurchaseId = '20251721212';
    //   verifyOrder(item);
    // }
    try {
      String verifyId = item.iapOurOrderId.isNotEmpty ? item.iapOurOrderId : MyAccount.id;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product, applicationUserName: verifyId);
      if (item.iapVip) {
        final started = await iap.buyNonConsumable(purchaseParam: purchaseParam);
        if (!started) {
          purchasingItem = null;
          Toast.show('Unable to start purchase, please try again');
        }
      } else {
        final started = await iap.buyConsumable(purchaseParam: purchaseParam);
        if (!started) {
          purchasingItem = null;
          Toast.show('Unable to start purchase, please try again');
        }
      }
    } catch (e) {
      L.e("[IAP] buy error for ${item.iapId}, $e");
      Toast.show('Purchase failed, ${e.toString()}');
      purchasingItem = null;
      // Toast.dismiss();
    }
  }

  // Future<void> getFirstRechargeTask() async {
  //   ApiRequest request = ApiRequest('getFirstRechargeTask', params: {Security.security_targetUid: MyAccount.id, Security.security_payChannel: 1});
  //   ApiResponse response = await ApiService.instance.sendRequest(request);
  //   if (response.isSuccess) {
  //     firstRechargeTask.task = response.data[Security.security_task] ?? {};
  //   }
  // }

  List allRechargeItems = [];

  Future getRechargeItem({int? rechargeItemType, int currencyType = 0}) async {
    items() =>
        allRechargeItems.where((e) {
          if (rechargeItemType != null) return e[Security.security_type] == rechargeItemType;
          return e[Security.security_currencyType] == currencyType;
        }).toList();
    if (allRechargeItems.isNotEmpty) {
      fetchRechargeItem();
      return items();
    }

    await fetchRechargeItem();
    return items();
  }

  Future fetchRechargeItem() async {
    ApiRequest request = ApiRequest(Apis.security_getRechargeItemV2, params: {});
    ApiResponse rsp = await ApiService.instance.sendRequest(request);
    if (rsp.isSuccess == true && rsp.data.isNotEmpty) {
      allRechargeItems = rsp.data[Security.security_rechargeItems] ?? [];
    } else {
      L.e("[IAP] fetchRechargeItem error, ${rsp.bsnsCode}, ${rsp.description}");
      if (allRechargeItems.isEmpty) {
        Toast.show(rsp.description);
      }
    }
  }

  Future createRechargeOrder({required int id}) async {
    Map<String, dynamic> arg = {Security.security_id: id.toString(), Security.security_payMethod: curPayMethod, Security.security_payChannel: 0};

    ApiRequest request = ApiRequest(Apis.security_recharge, params: arg);
    ApiResponse rsp = await ApiService.instance.sendRequest(request);
    if (rsp.isSuccess == true) {
      return rsp.data[Security.security_order];
    } else {
      L.i("[IAP] createRechargeOrder failed, ${rsp.bsnsCode}, ${rsp.description}");
      Toast.show(rsp.description);
      return null;
    }
  }

  String iapCachedKey = Security.security_kCachedIAPOrders;

  /// 验单
  Future<bool> rechargeCallback(Map item, {bool isRetry = false}) async {
    Map<String, dynamic> arg = {Security.security_ourOrderId: item.iapOurOrderId, Security.security_purchaseToken: item.iapReceipt};

    ApiRequest request = ApiRequest(Apis.security_rechargeCallback, params: arg);
    ApiResponse rsp = await ApiService.instance.sendRequest(request);
    int code = rsp.bsnsCode;
    if (rsp.isSuccess == true || code == 2010) {
      completion?.call(true, null);
      cachedReceipts.remove(purchasingItem?.iapPurchaseId ?? '');
      Preferences.instance.setMap(iapCachedKey, cachedReceipts);
      if (item.iapVip) {
        AccountService.instance.getPremInfo();
      } else {
        AccountService.instance.refreshBalance();
      }
      Preferences.instance.queryRPConfig();

      purchasingItem = null;
      Toast.dismiss();
      showConfirmAlert(Copywriting.security_payment_successful, '${item.iapName} purchased successfully');
      return true;
    } else {
      L.e('[IAP] rechargeCallback failed, $code, ${rsp.description}');
      if (!isRetry) {
        /// 重试一次
        return await rechargeCallback(item, isRetry: true);
      } else {
        purchasingItem = null;
        completion?.call(false, rsp.description);

        L.uploadIfNeed();
        showConfirmAlert(Copywriting.security_payment_failed, rsp.description, cancelText: Security.security_cancel, confirmText: Copywriting.security_contact_us, onConfirm: () {
          RouteHelper.toSupportChat();
        });
        return false;
      }
    }
  }

  /// 旧接口流程，createAndCallback

  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    return await verifyPurchasedToken(purchase.productID, purchase.verificationData.serverVerificationData, purchase.purchaseID ?? '');
  }

  Future<bool> verifyPurchasedToken(String pid, String receipt, String cacheKey) async {
    final req = ApiRequest(
      Apis.security_fullConfirmPurchase,
      params: {
        Security.security_receipt: receipt,
        Security.security_id: pid,
        Security.security_store: "1",
        Security.security_order: '${MyAccount.id}_${DateTime
            .now()
            .millisecondsSinceEpoch}',
        Security.security_channel: Platform.isIOS ? 2 : 1,
      },
    );

    var rsp = await ApiService.instance.sendRequest(req);

    if (rsp.statusCode == 200 && (rsp.bsnsCode == 0 || rsp.bsnsCode == 2010)) {
      AccountService.instance.refreshBalance();
      Toast.show(Copywriting.security_purchase_successful);
      if (cachedReceipts.containsKey(cacheKey)) {
        cachedReceipts.remove(cacheKey);
        Preferences.instance.setMap(kCachedExceptionOrderKey, cachedReceipts);
      }
      return true;
    }

    return false;
  }

  Future<Map?> fetchPremiumCards() async {
    try {
      final request = ApiRequest(Security.security_queryPremiumCards, params: {});
      final response = await ApiService.instance.sendRequest(request);
      if (response.isSuccess && response.data.isNotEmpty) {
        return response.data;
      }
    } catch (e) {
      L.e("[IAP] fetchPremiumCards error, $e");
    }
    return null;
  }
}
