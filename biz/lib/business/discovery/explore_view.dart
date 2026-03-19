import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/business/discovery/explore_item_view.dart';
import 'package:biz/business/discovery/swipe_explore_view.dart';
import '../../base/api_service/api_request.dart';
import '../../base/api_service/api_response.dart';
import '../../base/api_service/api_service.dart';
import '../../base/crypt/copywriting.dart';
import '../../core/util/cached_image.dart';
import '../../core/util/ui_util.dart';
import '../../core/util/collections_util.dart';
import 'discovery_view.dart';

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  int page = 0;

  RxList<dynamic> rxList = RxList();

  Widget _buildBody(List<dynamic> list) {
    return SwipeExploreView((context, onUrlChanged) {
      return PageView.builder(
        itemCount: list.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          return ExploreItemView(list.safeGet(index, {}));
        },
        onPageChanged: (index) {
          _preAllImage(index, list);
          loadMore(index);
        },
      );
    });
  }

  void _preAllImage(int currentIndex, List<dynamic> users) {
    int end = currentIndex + 3;
    if (end > users.length) {
      end = users.length;
    }
    for (var value in users.sublist(currentIndex, end)) {
      _preImage(value);
    }
  }

  void _preImage(Map<dynamic, dynamic> user) {
    if ((user[Security.security_hoverUrl] ?? "").isNotEmpty) {
      return;
    }
    String msBg = user[Security.security_recommendMission]?[Security.security_backgroundUrl] ?? "";
    String msPng = user[Security.security_recommendMission]?[Security.security_characterPngUrl] ?? "";
    String mc = (user[Security.security_photos] as List?).firstOrNull();

    if (msBg.isNotEmpty) {
      CachedImageProvider(msBg).resolve(ImageConfiguration.empty);
      CachedImageProvider(msPng).resolve(ImageConfiguration.empty);
    } else if (mc.isNotEmpty) {
      CachedImageProvider(mc).resolve(ImageConfiguration.empty);
    }
  }

  @override
  Widget build(BuildContext context) {

    Widget emptyView = GestureDetector(
      onTap: () {
        try {
          Get.find<DiscoveryController>().update();
        } catch (e) {
          print(e);
        }
      },
      child: UiUtils.buildCommonEmptyView(tips: Copywriting.security_no_datas__click_to_retry_),
    );

    return GetBuilder<DiscoveryController>(builder: (_) {
      return Container(
        alignment: Alignment.center,
        child: UiUtils.buildFutureView<List<dynamic>?>(getDataList(0), (
            data,
            context
            ) {
          if ((data ?? []).isEmpty) {
            return emptyView;
          } else {
            return Obx(() {
              _preAllImage(0, rxList);
              return _buildBody(data!);
            });
          }
        }, emptyView: emptyView),
      );
    });
  }

  Future<List<dynamic>?> getDataList(int pageNumber) async {
    page = pageNumber;
    ApiRequest request = ApiRequest(Apis.security_slidePendingList,
      params: {Security.security_limit: 30, Security.security_pageNumber: page},
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      page++;
      return response.data[Security.security_list];
    }

    return null;
  }

  bool isLoading = false;

  void loadMore(int index) async {
    if (!isLoading && (rxList.length - index < 8)) {
      isLoading = true;
      var data = await getDataList(page);
      isLoading = false;
      if ((data ?? []).isNotEmpty) {
        page++;
        rxList.addAll(data!);
      }
    }
  }
}
