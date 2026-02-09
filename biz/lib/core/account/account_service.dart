import 'package:biz/base/crypt/routes.dart';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/push_service/push_service.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/shared/toast/toast.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../base/api_service/api_service_export.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/preferences/preferences.dart';
import '../../base/report/report_manager.dart';
import '../../core/util/log_util.dart';
import '../user_manager/user_manager.dart';

String kEventCenterUserDidLogout = Security.security_kEventCenterUserDidLogout;
String kEventCenterUserDidLogin = Security.security_kEventCenterUserDidLogin;
String kEventCenterRefreshCurrency = Security.security_kEventCenterRefreshCurrency;

//生成一个账户类型的枚举，包含email, google, apple.其中email的值是11, apple是4，google是7
enum AccountType {
  email(11),
  apple(4),
  google(7);

  final int value;

  const AccountType(this.value);
}

extension BalanceNum on int {
  String get toFixString => this > 999 ? '${(this / 1000).toStringAsFixed(1)}k' : toString();
}

class Account {
  // 账户信息
  String get id => userId.toString();

  int get userId => userBase[Security.security_uid] ?? 0;

  bool get isLoggedIn => userId > 0;

  String token;
  RxMap _userInfo = {}.obs;

  Map get userInfo => _userInfo;
  UserProfileInfo? _myProfile;

  set myProfile(UserProfileInfo? profile) {
    if (profile == null) return;
    _myProfile = profile;
    _updateUserInfo(profile.user.data);
  }

  UserProfileInfo? get myProfile => _myProfile;

  Map get userBase => userInfo[Security.security_baseInfo] ?? {};

  String get name => userBase[Security.security_nickName] ?? '';

  String get avatar => userBase[Security.security_avatarUrl] ?? '';

  String get bio => userInfo[Security.security_bio] ?? '';

  String get gender {
    switch (userInfo[Security.security_baseInfo]?[Security.security_gender] ?? 0) {
      case 1:
        return Security.security_Male;
      case 2:
        return Security.security_Female;
      default:
        return Security.security_unknown;
    }
  }

  int get birthday => userInfo[Security.security_birthday] ?? 0;

  RxInt followingNum = 0.obs;
  RxInt followerNum = 0.obs;

  // RxInt collectionCount = (-1).obs;

  Account(this.token, Map user) {
    _userInfo.value = user;
  }

  Account.fromJson(Map<String, dynamic> json) : token = json[Security.security_token] ?? '' {
    _userInfo.value = (json[Security.security_userInfo] ?? {});
  }

  String toJson() {
    return JsonEncoder().convert({Security.security_token: token, Security.security_userInfo: userInfo});
  }

  void _updateUserInfo(Map userInfo) {
    _userInfo.value = userInfo;
  }

  void refreshUserInfo() async {
    _userInfo.refresh();
  }

  Account.none() : token = '', _userInfo = {}.obs;

  // 钱包信息
  RxMap wealthInfo = {}.obs;

  int get coins => wealthInfo['0'] ?? 0;

  int get gems => wealthInfo['1'] ?? 0;

  // 会员权限
  RxMap premInfo = {}.obs;

  int get premStatus => premInfo[Security.security_status] ?? 0;

  int get premEdTm => premInfo[Security.security_endTime] ?? 0;

  int get premCdType => premInfo[Security.security_premiumCardType] ?? 0;

  List get premBenfs => premInfo[Security.security_premiums] ?? [];

  Map get premUsedInfo => premInfo[Security.security_usedInfo] ?? {};

  bool get isSubscribed => premStatus == 1;

  bool get isWkPrem => isSubscribed && premCdType == 1;

  bool get isMthPrem => isSubscribed && premCdType == 2;

  bool get isYrPrem => isSubscribed && premCdType == 12;

  bool get isSuperPrem => isMthPrem || isYrPrem;

  String get premName {
    switch (premCdType) {
      case 1:
        return Copywriting.security_weekly_Premium;
      case 2:
        return Copywriting.security_monthly_Premium;
      case 12:
        return Copywriting.security_yearly_Premium;
      default:
        return '';
    }
  }

  int get freeImgUsedTimes => isSubscribed ? premUsedInfo['1'][Security.security_useTimes] : 0;

  int get freeImgLeftTimes => isSubscribed ? premUsedInfo['1'][Security.security_leftTimes] : 0;

  bool get hasFreeImgForAI => isSuperPrem || freeImgLeftTimes > 0;

  int get freeVdoUsedTimes => isSubscribed ? premUsedInfo['3'][Security.security_useTimes] : 0;

  int get freeVdoLeftTimes => isSubscribed ? premUsedInfo['3'][Security.security_leftTimes] : 0;

  bool get hasFreeVdoForAI => isSuperPrem || freeVdoLeftTimes > 0;

  int get freeAdoUsedTimes => isSubscribed ? premUsedInfo['2'][Security.security_useTimes] : 0;

  int get freeAdoLeftTimes => isSubscribed ? premUsedInfo['2'][Security.security_leftTimes] : 0;

  int get freeOcUsedTimes => isSubscribed ? premUsedInfo['10'][Security.security_useTimes] : 0;

  int get freeOcLeftTimes => isSubscribed ? premUsedInfo['10'][Security.security_leftTimes] : 0;

  bool get isFreeUnlockScriptSleep => isSuperPrem || scriptSleepUnlockRemainTimes > 0;

  int get scriptSleepUnlockRemainTimes => isSubscribed ? premUsedInfo['6'][Security.security_leftTimes] : 0;

  int get freeCrowedUsedTimes => isSubscribed ? premUsedInfo['12'][Security.security_useTimes] : 0;

  int get freeCrowedLeftTimes => isSubscribed ? premUsedInfo['12'][Security.security_leftTimes] : 0;

  int get premiumFreeReloadVideoTimes => isSubscribed ? premUsedInfo['20'][Security.security_leftTimes] : 0;

  void setPremInfo(data) {
    if (data == null) return;
    premInfo.value = data;
    premInfo.refresh();
    AccountService.instance.isSubscribeCache = MyAccount.isSubscribed;
  }
}

Account get MyAccount => AccountService.instance.account;

class AccountService {
  static String kAccountKey = Security.security_kUser;

  //生成单利
  AccountService._internal();

  static final AccountService _instance = AccountService._internal();

  factory AccountService() {
    return _instance;
  }

  static AccountService get instance => _instance;

  bool get loggedIn => account.isLoggedIn;

  Account account = Account.none();

  init() {
    //从本地获取账户信息
    account = getAccount();
    if (loggedIn) {
      handleLoggedIn();
      refreshBalance();
      getPremInfo();
      queryMyInfo();
    }

    //监听登录、注销事件
    EventCenter.instance.addListener(kEventCenterKickOff, (data) {
      logout();
    });

    EventCenter.instance.addListener(kEventCenterRefreshCurrency, (_) {
      refreshBalance();
    });
  }

  Future<ApiResponse> getVerifyCode(String account, AccountType type) async {
    ApiRequest request = ApiRequest(Apis.security_fetchVerificationCode, params: {Security.security_account: account, Security.security_type: type.value});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }

  Future<ApiResponse> loginWithApple() async {
    AuthorizationCredentialAppleID appleCredential;
    String? name;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
      String? name = appleCredential.givenName;
      if (appleCredential.familyName != null) {
        name = '$name ${appleCredential.familyName}';
      }
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException && e.code == AuthorizationErrorCode.canceled) {
        return ApiResponse.withError({Security.security_code: -1, Security.security_description: Security.security_canceled});
      }
      return ApiResponse.withError({Security.security_code: -1, Security.security_description: 'Sign in failed, $e'});
    }

    return await login(appleCredential.email ?? '', appleCredential.identityToken ?? '', AccountType.apple, thirdName: name ?? '');
  }

  Future<ApiResponse> loginWithEmail(String email, String password) async {
    return login(email, password, AccountType.email);
  }

  //登录
  Future<ApiResponse> login(String account, String password, AccountType accountType, {String thirdName = ''}) async {
    ApiRequest request = ApiRequest(
      Apis.security_signIn,
      params: {
        Security.security_account: account,
        Security.security_token: password,
        Security.security_type: accountType.value,
        Constants.adUpdate: 1,
        Constants.adSetupInfo: ReportManager.instance.data,
        Constants.adDevice: await ReportManager.instance.platformAdId,
        Constants.adKey: await ReportManager.instance.adId,
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(request);
    debugPrint('login response is ${response.data}');
    if (response.isSuccess) {
      analyseResponse(response);
    }
    return response;
  }

  void analyseResponse(ApiResponse response) {
    Map<String, dynamic> userInfo = response.data[Security.security_userInfo] ?? {};
    String token = response.data[Security.security_token] ?? '';

    account = Account(token, userInfo);
    saveAccount();
    if (loggedIn) {
      handleLoggedIn();
      refreshBalance();
      getPremInfo();
      queryMyInfo();
    }
  }

  void saveAccount() {
    //保存账户信息
    Preferences.instance.setString(kAccountKey, account.toJson());
  }

  Account getAccount() {
    //获取账户信息
    String json = Preferences.instance.getString(kAccountKey) ?? '{}';
    return Account.fromJson(jsonDecode(json));
  }

  void handleLoggedIn() {
    ApiService.instance.addTokens({Security.security_token: account.token, Security.security_uid: account.id});
    EventCenter.instance.sendEvent(kEventCenterUserDidLogin, null);
    PushService.instance.secretKey = account.id;
  }

  void logout() {
    account = Account.none();
    Preferences.instance.remove(kAccountKey);
    Preferences.instance.remove(kIsSubscribeCache);
    ApiService.instance.addTokens({Security.security_token: account.token, Security.security_uid: account.id});
    EventCenter.instance.sendEvent(kEventCenterUserDidLogout, null);
    PushService.instance.secretKey = '0';
    RouteHelper.toLoginPage();
  }

  Future<ApiResponse> deleteAccount() async {
    ApiRequest request = ApiRequest(Apis.security_deleteAccount, params: {});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      logout();
    }
    return response;
  }

  Future<bool> updateMyInfo({String? name, String? birthday, int? gender, String? bio, String? avatar}) async {
    int flag = 0;
    if (name != null) flag |= 1;
    if (avatar != null) flag |= 2;
    if (gender != null) flag |= 4;
    if (birthday != null) flag |= 8;
    if (bio != null) flag |= 16;

    final req = ApiRequest(
      Apis.security_updateUserInfo,
      params: {
        Security.security_flag: flag,
        Security.security_nickName: name ?? '',
        Security.security_birthday: birthday ?? '',
        Security.security_gender: gender ?? 0,
        Security.security_bio: bio ?? '',
        Security.security_avatarUrl: avatar ?? '',
      },
    );
    final rsp = await ApiService.instance.sendRequest(req);
    if (!rsp.isSuccess) return false;

    if (flag & 1 != 0) {
      account.userBase[Security.security_nickName] = name;
    } else if (flag & 2 != 0) {
      account.userBase[Security.security_avatarUrl] = avatar;
    }
    account.refreshUserInfo();
    return true;
  }

  Future<void> updateMyAvatar(String avatarUrl) async {
    updateMyInfo(avatar: avatarUrl);
  }

  /// balance
  Future refreshBalance() async {
    final req = ApiRequest(Apis.security_fetchBalance, params: {Security.security_uid: account.id});
    final rsp = await ApiService.instance.sendRequest(req);

    if (rsp.statusCode != 200 || rsp.bsnsCode != 0) return;

    if ((rsp.data[Security.security_balance] ?? {}).isEmpty) return;
    account.wealthInfo.value = rsp.data[Security.security_balance];
  }

  RxList premiumConfig = [].obs;

  Future getPremInfo() async {
    try {
      final request = ApiRequest(Security.security_queryPremiumCards, params: {});
      final response = await ApiService.instance.sendRequest(request);
      Map rspData = response.data;
      if (response.isSuccess && rspData.isNotEmpty) {
        account.premInfo.value = rspData[Security.security_ownPremium] ?? {};
        isSubscribeCache = MyAccount.isSubscribed;
        premiumConfig.value = rspData[Security.security_config] ?? [];
      }
    } catch (e) {
      L.e("[Payment] fetchPremiumCards error, $e");
    }
  }

  //是否是订阅会员的缓存
  static String kIsSubscribeCache = Security.security_kIsSubscribeCache;
  set isSubscribeCache(bool isSubscribe) => Preferences.instance.setBool(kIsSubscribeCache, isSubscribe);
  bool get isSubscribeCache => Preferences.instance.getBool(kIsSubscribeCache);

  Future<void> queryMyInfo() async {
    UserProfileInfo? profileInfo = await UserManager.instance.getUserInfo(account.userId);
    if (profileInfo != null && !profileInfo.isNone()) {
      account.myProfile = profileInfo;
      account.followerNum.value = profileInfo.data[Security.security_fansCount] ?? 0;
      account.followingNum.value = profileInfo.data[Security.security_followCount] ?? 0;
    }
  }
}
