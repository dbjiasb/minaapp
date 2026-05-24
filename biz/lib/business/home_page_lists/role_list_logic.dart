import 'package:biz/business/home_page_lists/role_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:biz/base/api_service/api_response.dart';
import '../../base/crypt/security.dart';


class RoleListLogic extends GetxController {
  final RoleListType type;
  final ScrollController? externalScrollController;

  RoleListLogic({required this.type, this.externalScrollController});

  late final ScrollController scrollController;
  final RefreshController refreshController = RefreshController(initialRefresh: false);
  final RxBool isLoading = true.obs;
  final RxList dataList = RxList<Map>();
  final RxList banners = [].obs;
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

    if (type == RoleListType.ai_and_script) {
      RoleManager.instance.onFilterChange = () {
        refreshController.requestRefresh();
      };
    }
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

  Set<int> listedIds = {};

  Future<void> getListData() async {
    try {
      ApiResponse rsp = await RoleManager.instance.getRoleList(
        pageIndex: page,
        pageSize: pageSize,
        type: type,
      );

      if (rsp.isSuccess) {
        List rawData = rsp.data[Security.security_param] ?? [];
        List<Map> data = rawData.cast<Map>();
        List banner = rsp.data[Security.security_banners] ?? [];

        if (page == 0) {
          dataList.clear();
          listedIds.clear();
          banners.value = banner;
        }

        for (int i = 0; i < data.length; i++) {
          Map info = data[i];
          int uid = info[Security.security_uid] ?? 0;
          if (listedIds.contains(uid)) continue;
          listedIds.add(uid);
          dataList.add(info);
        }

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
