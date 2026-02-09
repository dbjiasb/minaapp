import 'package:get/get.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';
import 'dart:convert';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/toast/toast.dart';

class UserInfo {
  Map<String, dynamic> data;

  Map<String, dynamic> get userBase => data[Security.security_baseInfo];

  UserInfo(this.data);

  String get coverImageUrl {
    return data[Security.security_coverUrl] ?? '';
  }

  String get avatarUrl => userBase[Security.security_avatarUrl] ?? '';

  String get nickName => userBase[Security.security_nickName] ?? '';

  String get intro => data[Security.security_bio] ?? '';

  UserInfo.none() : data = {}; // 修复构造函数语法

  bool isNone() {
    return data.isEmpty;
  }

  @override
  String toString() {
    return jsonEncode(data);
  }
}

class UserProfileInfo {
  Map<String, dynamic> data;
  late UserInfo user;

  Map<String, dynamic> get userBase => user.userBase;

  UserProfileInfo(this.data) : user = UserInfo(data[Security.security_userInfo]);

  String get coverImageUrl => data[Security.security_coverUrl] ?? '';

  String get chatBgUrl => data[Security.security_chatBackground] ?? '';

  String get avatarUrl => user.avatarUrl;

  String get nickName => user.nickName;

  String get intro => user.intro;

  int get level => data[Security.security_intimacyLevel] ?? 1;

  set level(int value) => data[Security.security_intimacyLevel] = value;

  double get nextLevelRatio => data[Security.security_nextIntimacyLevelRatio] ?? 0.0;

  UserProfileInfo.none() : data = {}; // 修复构造函数语法
  bool isNone() => data.isEmpty;

  @override
  String toString() {
    return jsonEncode(data);
  }
}

class UserManager {
  //生成单利
  static final UserManager _instance = UserManager._internal();

  UserManager._internal();

  factory UserManager() => _instance;

  static UserManager get instance => _instance;
  RxMap userSetting = {}.obs;

  bool isBlocked(int userId) {
    return userSetting[userId]?[Security.security_isInBlack] == 1;
  }

  Future<UserProfileInfo?> getUserInfo(int userId) async {
    ApiRequest request = ApiRequest(Apis.security_fetchUserData, params: {Security.security_userId: userId});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      return UserProfileInfo(response.data[Security.security_param]);
    } else {
      return null;
    }
  }

  Future<ApiResponse> getUserSettings(int userId) async {
    ApiRequest request = ApiRequest(Apis.security_getUserMoreSettings, params: {Security.security_targetUid: userId});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      Map info = response.data[Security.security_info] ?? {};
      if (info.isNotEmpty) {
        userSetting[userId] = info;
        userSetting.refresh();
      }
    }
    return response;
  }

  Future<ApiResponse> blockUser(int userId, bool isBlock) async {
    Toast.loading();
    ApiRequest request = ApiRequest(Apis.security_blockUserAction, params: {Security.security_targetUid: userId, Security.security_action: isBlock ? 1 : 0});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      Toast.dismiss();
      userSetting[userId] ??= {};
      userSetting[userId][Security.security_isInBlack] = isBlock ? 1 : 0;
      userSetting.refresh();
    } else {
      Toast.error(response.description);
    }
    return response;
  }

  RxBool taskReminder = false.obs;
  RxBool notificationReminder = false.obs;

  Future queryUserReminders() async {
    if (!AccountService.instance.loggedIn) return null;

    ApiRequest request = ApiRequest(Apis.security_getUserRedPointCount);
    ApiResponse response = await ApiService.instance.sendRequest(request);

    if (response.isSuccess) {
      int taskNum = response.data[Security.security_param]?['0'] ?? 0;
      taskReminder.value = taskNum > 0;

      int notificationNum = response.data[Security.security_param]?['1'] ?? 0;
      notificationReminder.value = notificationNum > 0;
    }
  }

  Future<ApiResponse> followAction({int targetUid = 0, int opt = 0}) async {
    ApiRequest request = ApiRequest(Apis.security_followUserAction, params: {Security.security_targetUid: targetUid, Security.security_opt: opt});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      if (opt == 1) {
        MyAccount.followingNum.value ++;
      } else {
        MyAccount.followingNum.value --;
      }
    } else {
      Toast.show(response.description);
    }
    return response;
  }

  ///0: FOLLOW, 1: FANS
  ///ApiResponse.data[Security.security_users]=>UserBase
  Future<ApiResponse> getUserRelationList({int listType = 0, int pageIndex = 0, int pageSize = 20}) async {
    ApiRequest request = ApiRequest(Apis.security_getUserRelationList, params: {Security.security_listType: listType, Security.security_pageIndex: pageIndex, Security.security_pageSize: pageSize});
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }
}
