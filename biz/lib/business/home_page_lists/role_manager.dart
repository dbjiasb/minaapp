import 'package:get/get.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/core/account/account_service.dart';

enum RoleListType {
  ai_and_script(0),
  ai(1),
  script(2),
  real(3),
  custom_ai(4),
  share_ai(5),
  robot_and_real(6),
  role_play(8),
  ugc(9),
  dating(10),
  pro_only(11),
  theater(1000),
  realistic(20001),
  anime(20002),
  story(-9999);

  final int value;

  const RoleListType(this.value);
}

class RoleManager {
  static final RoleManager _instance = RoleManager._internal()..init();

  RoleManager._internal();

  factory RoleManager() => _instance;

  static RoleManager get instance => _instance;

  RxMap filterConfig = {}.obs;
  bool get hasFilter => (filterConfig[Security.security_gender] ?? 0) != 0  || (filterConfig[Security.security_tagIdList] ?? []).isNotEmpty;
  Function? onFilterChange;

  void applyFilter(int genger, List tagIdList) {
    filterConfig[Security.security_gender] = genger;
    filterConfig[Security.security_tagIdList] = tagIdList.cast<int>();
    filterConfig.refresh();
    onFilterChange?.call();
  }

  init() {
    Map tagConfig = Preferences.instance.getMap(Security.security_kCacheFilterTagKey);
    if (tagConfig.isNotEmpty && (tagConfig[Security.security_filterList] ?? []).isNotEmpty) {
      filterList = tagConfig[Security.security_filterList] ?? [];
      selectorList = tagConfig[Security.security_selectorList];
    }

    queryTagConfigs();
  }

  Future<ApiResponse> getRoleList({
    int version = 0,
    int pageIndex = 0,
    int targetUid = 0,
    RoleListType type = RoleListType.ai,
    int pageSize = 20,
  }) async {
    Map<String, dynamic> params = {};
    params[Security.security_version] = version;
    params[Security.security_index] = pageIndex;
    params[Security.security_length] = pageSize;
    params[Security.security_type] = type.value;
    params[Security.security_userId] = targetUid;
    if (type == RoleListType.ai_and_script) {
      params[Security.security_filterCondition] = filterConfig;
    }

    ApiRequest request = ApiRequest(Apis.security_fetchUsers, params: params);
    return await ApiService.instance.sendRequest(request);
  }

  Future<ApiResponse> getMyStars({int pageIndex = 0, int pageSize = 20}) async {
    Map<String, dynamic> params = {};
    params[Security.security_tId] = MyAccount.id;
    params[Security.security_pageIndex] = pageIndex;
    params[Security.security_pageSize] = pageSize;

    ApiRequest request = ApiRequest(Apis.security_getUserStarList, params: params);

    return await ApiService.instance.sendRequest(request);
  }

  List<dynamic>? selectorList;
  List<dynamic> filterList = [];

  Future queryTagConfigs() async {
    try {
      ApiRequest request = ApiRequest(Apis.security_getTagConfig, params: {});
      ApiResponse rsp = await ApiService.instance.sendRequest(request);

      if (rsp.isSuccess) {
        Preferences.instance.setMap(Security.security_kCacheFilterTagKey, rsp.data);
        filterList = rsp.data[Security.security_filterList] ?? [];
        selectorList = rsp.data[Security.security_selectorList];
      } else {
        return null;
      }
    } catch (e) {}
  }
}
