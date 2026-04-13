import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/crypt/routes.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:uuid/uuid.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/util/log_util.dart';
import '../../shared/alert.dart';
import '../crypt/copywriting.dart';
import '../crypt/security.dart';
import 'ad_service.dart';

typedef AdFinishCallback = void Function(Map adConfig);

typedef AdEventCallback = void Function(RewardedAd ad);

class AdsUtils {
  static Future<void> adModInit() async {
    await MobileAds.instance.initialize();
    return;
  }

  final Map _adConfig;
  final String assetId;

  final Function(Map? adAwardRsp)? grantAdCallback;

  AdsUtils(this._adConfig, {this.assetId = "", this.grantAdCallback});

  RewardedAd? _rewardedAd;

  Future<void> loadAd({AdEventCallback? adEventCallback}) async {
    await RewardedAd.load(
        adUnitId: Preferences.instance.adUId ?? _adConfig[Security.security_adUnit],
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
              // Called when the ad showed the full screen content.
              onAdShowedFullScreenContent: (ad) {
            L.i(Security.security_fullScreen);
          },
              // Called when an impression occurs on the ad.
              onAdImpression: (ad) {
            EasyLoading.dismiss();
            L.i(Security.security_impression);
          },
              // Called when the ad failed to show full screen content.
              onAdFailedToShowFullScreenContent: (ad, err) {
            EasyLoading.dismiss();
            L.i(Security.security_failedToShowFull);
            releaseAd();
          },
              // Called when the ad dismissed full screen content.
              onAdDismissedFullScreenContent: (ad) {
            EasyLoading.dismiss();
            L.i(Security.security_dismissedFull);
            releaseAd();
          },
              // Called when a click is recorded for an ad.
              onAdClicked: (ad) {
            L.i(Security.security_clicked);
          });
          // Keep a reference to the ad so you can show it later.
          adEventCallback?.call(ad);
        }, onAdFailedToLoad: (LoadAdError error) {
          // ignore: avoid_print
          EasyLoading.dismiss();
          L.i('failed load: $error');
        }));
  }

  Future<void> _showAdInner(RewardedAd rewardedAd,
      {AdFinishCallback? adCompleteCallback}) async {
    String clientId = const Uuid().v4().toString();
    Map<String, dynamic> customJson = {
      Security.security_clientId: clientId,
    };
    rewardedAd.setServerSideOptions(ServerSideVerificationOptions(
        userId: MyAccount.userId.toString(),
        customData: json.encode(customJson)));
    await rewardedAd.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
      // ignore: avoid_print
      L.i('ad amount: ${rewardItem.amount}');
      adCompleteCallback?.call(_adConfig);
      onCompleteAd(_adConfig, clientId);
    });
  }

  Future<void> showAd({AdFinishCallback? adCompleteCallback}) async {
    L.i(Security.security_showAd);
    EasyLoading.show();
    await loadAd(adEventCallback: (ad) {
      _rewardedAd = ad;
      _showAdInner(ad, adCompleteCallback: adCompleteCallback);
    });
  }

  Future<void> releaseAd() async {
    L.i(Security.security_releaseAd);
    if (_rewardedAd != null) {
      await _rewardedAd!.dispose();
      _rewardedAd = null;
    }
  }

  void onCompleteAd(Map adConfig, String clientId) {
    if (adConfig[Security.security_awardType] == 0) {
      grantCoinAdAward(adConfig, clientId);
    } else if (adConfig[Security.security_awardType] == 5 || adConfig[Security.security_awardType] == 6) {
      grantLockAdAward(adConfig, clientId);
    }
  }

  void grantLockAdAward(Map adConfig, String clientId) {
    L.i('[AD] unlock, uuid: $assetId');
    AdsManager.grantAdAward(
      adConfig[Security.security_awardType],
      clientId,
      assetId: assetId,
    ).then((value) {
      AdsManager.getBalanceAdAward();
      grantAdCallback?.call(value);
    }).onError((error, stackTrace) {
      EasyLoading.showToast(Copywriting.security_failed_to_unlock_resource__Please_try_again_later_);
    });
  }

  void grantCoinAdAward(Map adConfig, String clientId) {
    EasyLoading.show();
    AdsManager.grantAdAward(0, clientId).then((value) {
      AccountService.instance.refreshBalance();
      AdsManager.getBalanceAdAward();
      grantAdCallback?.call(value);
      EasyLoading.dismiss();
      showRewardDialog(adConfig[Security.security_awardValue] ?? "");
    }).onError((error, stackTrace) {
      EasyLoading.showToast(Copywriting.security_failed_to_grant_coin__Please_try_again_later_);
      EasyLoading.dismiss();
    });
  }

  void showRewardDialog(String count) async {
    showConfirmAlert(Security.security_rewards, 'You have received $count coins.');
  }
}
