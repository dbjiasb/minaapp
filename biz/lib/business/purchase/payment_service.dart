import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import '../../base/database/data_center.dart';
import 'purchase_journal.dart';
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
import 'package:biz/base/router/route_helper.dart';

import '../../base/api_service/api_service_export.dart';
import '../../base/environment/environment.dart';
import '../../core/account/account_service.dart';
import '../../shared/alert.dart';
import '../../shared/toast/toast.dart';

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

  PurchaseJournal get _journal => PurchaseJournal(DataCenter.instance.database);
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _retryTimer;
  Future<void> _work = Future.value();
  final Map<String, PurchaseDetails> _storePurchases = {};
  Account? _purchasingAccount;

  String _key(PurchaseDetails purchase) => sha256.convert(utf8.encode(
      '${purchase.productID}:${purchase.purchaseID?.isNotEmpty == true ? purchase.purchaseID : purchase.verificationData.serverVerificationData}')).toString();

  Future<void> _enqueue(Future<void> Function() task) {
    _work = _work.then((_) => task()).catchError((Object error, StackTrace stack) {
      // Receipts remain in the encrypted journal for the next retry.
      L.e('[IAP] recovery deferred: ${error.runtimeType}');
    });
    return _work;
  }

  InAppPurchase get iap => InAppPurchase.instance;

  bool _isAvailable = false;

  Function(bool, String?)? completion;

  FirstPurchaseTask firstRechargeTask = FirstPurchaseTask();

  Future<void> setup() async {
    if (_initialized) return;
    _initialized = true;
    EventCenter.instance.addListener(Security.security_kEventCenterUserDidLogin, onUserDidLogin);
    EventCenter.instance.addListener(Security.security_kEventCenterUserDidLogout, onUserDidLogout);
    // Subscribe before querying availability so an early transaction isn't lost.
    _subscription = iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        onPurchaseEventCallback(purchase);
      }
    }, onError: (Object error) => L.e('[IAP] purchase stream: ${error.runtimeType}'));
    try {
      _isAvailable = await iap.isAvailable();
    } catch (error) {
      L.e('[IAP] store unavailable: ${error.runtimeType}');
    }
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) => fixedExceptionOrdersIfNeeded());
    fixedExceptionOrdersIfNeeded();
  }

  void dispose() {
    _retryTimer?.cancel();
    _subscription?.cancel();
    EventCenter.instance.removeListener(Security.security_kEventCenterUserDidLogin, onUserDidLogin);
    EventCenter.instance.removeListener(Security.security_kEventCenterUserDidLogout, onUserDidLogout);
    _initialized = false;
  }

  void onUserDidLogin(Event event) {
    if (!identical(_purchasingAccount, MyAccount)) {
      purchasingItem = null;
      _purchasingAccount = null;
    }
    fixedExceptionOrdersIfNeeded();
  }

  void onUserDidLogout(Event event) {
    purchasingItem = null;
    _purchasingAccount = null;
  }

  bool _recovering = false;
  void fixedExceptionOrdersIfNeeded() {
    if (_recovering || !MyAccount.isLoggedIn) return;
    _recovering = true;
    _enqueue(() async {
      try {
        final account = MyAccount;
        if (!account.isLoggedIn) return;
        if (Platform.isAndroid) {
          // Query without consuming. This also recovers transactions whose
          // purchase callback was interrupted by process termination.
          final result = await iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>().queryPastPurchases();
          if (!identical(account, MyAccount)) return;
          if (result.error == null) {
            for (final purchase in result.pastPurchases) {
              await _handlePurchase(purchase);
              if (!identical(account, MyAccount)) return;
            }
          }
        }
        if (!Platform.isAndroid) {
          for (final purchase in _storePurchases.values.toList()) {
            await _handlePurchase(purchase);
            if (!identical(account, MyAccount)) return;
          }
        }
        final records = await _journal.all();
        for (final record in records) {
          if (!identical(account, MyAccount)) return;
          if (record['kind'] == 'purchase' && record['ownerId'] == account.userId && record['finished'] != true) {
            await _recoverRecord(record, account);
          }
        }
      } finally {
        _recovering = false;
      }
    });
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

  Future<void> onPurchaseEventCallback(PurchaseDetails purchase) =>
      _enqueue(() => _handlePurchase(purchase));

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final key = _key(purchase);
    _storePurchases[key] = purchase;
    if (purchase.status == PurchaseStatus.pending) return;
    if (purchase.status == PurchaseStatus.error || purchase.status == PurchaseStatus.canceled) {
      _storePurchases.remove(key);
      if (identical(_purchasingAccount, MyAccount) &&
          (purchase.productID.isEmpty || purchasingItem?.iapId == purchase.productID)) {
        purchasingItem = null;
        _purchasingAccount = null;
        Toast.dismiss();
        completion?.call(false, purchase.error?.message);
      }
      return;
    }
    final account = MyAccount;
    if (!account.isLoggedIn) return;
    var record = await _journal.read(key);
    if (!identical(account, MyAccount)) return;
    if (record == null) {
      Map<String, dynamic>? intent;
      final storeOrder = purchase is GooglePlayPurchaseDetails
          ? purchase.billingClientPurchase.obfuscatedAccountId
          : purchase is AppStorePurchaseDetails
              ? purchase.skPaymentTransaction.payment.applicationUsername : null;
      if (storeOrder != null && storeOrder.isNotEmpty) {
        intent = await _journal.read('intent:$storeOrder');
      }
      if (intent == null && (storeOrder == null || storeOrder.isEmpty || storeOrder == purchasingItem?.iapOurOrderId) && identical(account, _purchasingAccount) && purchasingItem?.iapId == purchase.productID) {
        intent = await _journal.read('intent:${purchasingItem!.iapOurOrderId}');
      }
      if (!identical(account, MyAccount)) return;
      // Known transactions always retain the original account, even if their
      // callback arrives while a different account is signed in.
      if (intent != null && intent['transactionKey'] != null && intent['transactionKey'] != key) {
        intent = {...intent, 'orderId': ''}; // Keep ownership, but verify the renewal independently.
      }
      final catalogItem = allRechargeItems.cast<Map>().firstWhereOrNull((item) => item.iapId == purchase.productID);
      final isVip = intent?['vip'] as bool? ?? catalogItem?.iapVip;
      // Unknown restored products are classified from store metadata before
      // settlement; never infer consumability from a product ID's spelling.
      record = {
        'kind': 'purchase', 'key': key,
        'ownerId': intent?['ownerId'] ?? account.userId,
        'productId': purchase.productID,
        'purchaseId': purchase.purchaseID ?? '',
        'receipt': purchase.verificationData.serverVerificationData,
        'orderId': intent?['orderId'] ?? '',
        'verificationOrder': '${intent?['ownerId'] ?? account.userId}_${DateTime.now().millisecondsSinceEpoch}',
        'vip': isVip, 'verified': false, 'finished': false,
      };
      await _journal.savePurchase(record, intent);
    }
    final latestReceipt = purchase.verificationData.serverVerificationData;
    if (record['verified'] != true && latestReceipt.isNotEmpty && record['receipt'] != latestReceipt) {
      record['receipt'] = latestReceipt;
      await _journal.save(key, record);
    }
    if (record['ownerId'] != account.userId || !identical(account, MyAccount)) return;
    if (record['finished'] == true) {
      _storePurchases.remove(key);
      return;
    }
    await _recoverRecord(record, account);
  }

  Future<void> _recoverRecord(Map<String, dynamic> record, Account account) async {
    final key = record['key'] as String;
    bool active() => identical(account, MyAccount) && account.isLoggedIn;
    final done = await PurchaseRecovery.recover(
      record: record,
      save: (value) => _journal.save(key, value),
      isCurrentAccount: active,
      verify: () async {
        final orderId = record['orderId'] as String;
        final request = orderId.isNotEmpty
            ? ApiRequest(Apis.security_rechargeCallback, params: {
                Security.security_ourOrderId: orderId,
                Security.security_purchaseToken: record['receipt'],
              })
            : ApiRequest(Apis.security_fullConfirmPurchase, params: {
                Security.security_receipt: record['receipt'],
                Security.security_id: record['productId'],
                Security.security_store: '1',
                Security.security_order: record['verificationOrder'],
                Security.security_channel: Platform.isIOS ? 2 : 1,
              });
        final response = await ApiService.instance.sendRequest(request);
        return response.statusCode == 200 && (response.bsnsCode == 0 || response.bsnsCode == 2010);
      },
      settle: () async {
        final purchase = _storePurchases[key];
        if (Platform.isAndroid && record['vip'] == null) {
          final products = await iap.queryProductDetails({record['productId'] as String});
          if (!active()) return false;
          final product = products.productDetails.firstWhereOrNull((p) => p.id == record['productId']);
          if (product is! GooglePlayProductDetails) return false;
          record['vip'] = product.productDetails.productType == ProductType.subs;
          await _journal.save(key, record);
          if (!active()) return false;
        }
        if (Platform.isAndroid && record['vip'] == false) {
          final details = purchase ?? PurchaseDetails(
            productID: record['productId'], purchaseID: record['purchaseId'],
            verificationData: PurchaseVerificationData(localVerificationData: '',
                serverVerificationData: record['receipt'], source: 'google_play'),
            transactionDate: null, status: PurchaseStatus.purchased,
          );
          final result = await iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>().consumePurchase(details);
          // If a previous consume succeeded before the app could checkpoint,
          // Play reports itemNotOwned on retry. Delivery was already verified.
          return result.responseCode == BillingResponse.ok || result.responseCode == BillingResponse.itemNotOwned;
        }
        if (purchase == null) return false;
        if (purchase.pendingCompletePurchase) {
          if (Platform.isAndroid) {
            final result = await (InAppPurchasePlatform.instance as InAppPurchaseAndroidPlatform).completePurchase(purchase);
            return result.responseCode == BillingResponse.ok;
          }
          await iap.completePurchase(purchase);
        }
        return true;
      },
    );
    if (!active()) return;
    if (purchasingItem?.iapId == record['productId'] && purchasingItem?.iapOurOrderId == record['orderId']) {
      purchasingItem = null;
      _purchasingAccount = null;
      Toast.dismiss();
      completion?.call(done, done ? null : Copywriting.security_receipt_Not_Available);
    }
    if (record['verified'] == true) {
      AccountService.instance.refreshBalance();
      AccountService.instance.getPremInfo();
    }
    if (done) {
      _storePurchases.remove(key);
      Toast.show(Copywriting.security_purchase_successful);
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

    final account = MyAccount;
    _purchasingAccount = account;
    purchasingItem = item;

    Map? order = await createRechargeOrder(id: item.iapItemId);
    if (!identical(account, MyAccount)) return;
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
      purchasingItem = null;
      Toast.show(Copywriting.security_iAP_Service_Not_Available);
      return;
    }

    ProductDetails? product = productMap[item.iapId];
    if (product == null) {
      L.e("[IAP] error, ${item.iapId} not found, will load again.");
      product = (await getIapProducts({item.iapId})).firstOrNull;
      if (product == null) {
        L.e("[IAP] error, ${item.iapId} not found");
        purchasingItem = null;
        Toast.show('Product not found for ${item.iapId}, please try again later');
        return;
      }
    }

    // if (kDebugMode) {
    //   item.iapReceipt = Security.security_test_absasdkjhakjsdhjkashdkjashdjkahsdasdasdas;
    //   item.iapPurchaseId = '20251721212';
    //   verifyOrder(item);
    // }
    if (!identical(account, MyAccount)) return;
    try {
      if (item.iapOurOrderId.isEmpty) throw StateError('Missing order id');
      await _journal.save('intent:${item.iapOurOrderId}', {
        'kind': 'intent', 'orderId': item.iapOurOrderId,
        'ownerId': account.userId, 'productId': item.iapId, 'vip': item.iapVip,
      });
      if (!identical(account, MyAccount)) return;
      String verifyId = item.iapOurOrderId.isNotEmpty ? item.iapOurOrderId : MyAccount.id;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product, applicationUserName: verifyId);
      if (item.iapVip) {
        final started = await iap.buyNonConsumable(purchaseParam: purchaseParam);
        if (!started) {
          purchasingItem = null;
          Toast.show('Unable to start purchase, please try again');
        }
      } else {
        final started = await iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: !Platform.isAndroid);
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
