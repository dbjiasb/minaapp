import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_request.dart';
import 'package:biz/base/api_service/api_response.dart';

import '../../../base/api_service/api_service.dart';
import '../../../base/crypt/security.dart';

class TheaterHistoryListViewLogic extends GetxController {
  final scrollController = ScrollController();
  final RxBool isLoading = true.obs;
  final RxList dataList = RxList<Map>();
  bool isLoadingMore = false;
  bool _hasMore = true;
  int page = 0;
  int pageSize = 20;

  @override
  void onInit() {
    scrollController.addListener(() {
      if ((scrollController.position.pixels >= scrollController.position.maxScrollExtent)) {
        loadMoreData();
      }
    });
    super.onInit();

    initData();
  }

  void initData() {
    isLoading.value = true;
    refreshData();
  }

  void refreshData() {
    page = 0;
    getListData();
  }

  void getListData() async {
    Map<String, dynamic> args = {};
    args["pageIndex"] = page;
    args["pageSize"] = pageSize;
    try {
      ApiResponse rsp = await ApiService.instance.sendRequest(ApiRequest("getSceneSessionList", params: args));
      List rawData = rsp.data[Security.security_param] ?? [];
      List<Map> data = rawData.cast<Map>();
      if (page == 0) {
        dataList.clear();
      }
      dataList.addAll(data);

      _hasMore = rsp.data[Security.security_hasMore] == 1;
    } finally {
      isLoading.value = false;
      isLoadingMore = false;
    }
  }

  void loadMoreData() {
    if (!_hasMore) return;
    if (isLoadingMore) return;
    page++;
    isLoadingMore = true;
    getListData();
  }
}
