import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:biz/base/api_service/api_response.dart';
import '../../base/crypt/security.dart';
import 'role_manager.dart' as rm;

enum RoleListType {
  ai,
  real,
  ugc,
  proOnly,
}

class RoleListLogic extends GetxController {
  final RoleListType type;
  final ScrollController? externalScrollController;

  RoleListLogic({required this.type, this.externalScrollController});

  late final ScrollController scrollController;
  final RefreshController refreshController = RefreshController(initialRefresh: false);
  final RxBool isLoading = true.obs;
  final RxList dataList = RxList<Map>();
  bool isLoadingMore = false;
  bool _hasMore = true;
  int page = 0;
  int pageSize = 20;

  @override
  void onInit() {
    scrollController = externalScrollController ?? ScrollController();
    super.onInit();
    initData();
  }

  @override
  void onClose() {
    if (externalScrollController == null) {
      scrollController.dispose();
    }
    refreshController.dispose();
    super.onClose();
  }

  void initData() {
    isLoading.value = true;
    getListData();
  }

  void onRefresh() async {
    page = 0;
    _hasMore = true;
    await getListData();
    refreshController.refreshCompleted();
  }

  void onLoading() async {
    if (!_hasMore) {
      refreshController.loadNoData();
      return;
    }
    page++;
    await getListData();
    if (_hasMore) {
      refreshController.loadComplete();
    } else {
      refreshController.loadNoData();
    }
  }

  rm.RoleListType _mapToRoleManagerType() {
    switch (type) {
      case RoleListType.ai:
        return rm.RoleListType.ai;
      case RoleListType.real:
        return rm.RoleListType.real;
      case RoleListType.ugc:
        return rm.RoleListType.ugc;
      case RoleListType.proOnly:
        return rm.RoleListType.pro_only;
    }
  }

  Future<void> getListData() async {
    try {
      ApiResponse rsp = await rm.RoleManager.instance.getRoleList(
        pageIndex: page,
        pageSize: pageSize,
        type: _mapToRoleManagerType(),
      );

      if (rsp.isSuccess) {
        List rawData = rsp.data[Security.security_param] ?? [];
        List<Map> data = rawData.cast<Map>();

        if (page == 0) {
          dataList.clear();
        }

        dataList.addAll(data);
        _hasMore = rsp.data[Security.security_hasMore] == true;
      }
    } catch (e) {
      // Error handled silently
    } finally {
      isLoading.value = false;
      isLoadingMore = false;
    }
  }
}
