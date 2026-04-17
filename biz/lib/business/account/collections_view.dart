import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/core/user_manager/user_manager.dart';
import 'package:biz/base/crypt/routes.dart';

import '../../base/api_service/api_response.dart';
import '../../base/assets/image_path.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../base/assets/image_view.dart';
import '../../base/crypt/constants.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/images.dart';
import '../../base/crypt/security.dart';
import '../../base/router/router_names.dart';
import '../../core/util/cached_image.dart';
import '../../shared/app_theme.dart';
import '../../shared/widget/app_widgets.dart';
import '../../shared/widget/list_status_view.dart';
import '../../shared/widget/title_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../home_page_lists/list_item.dart';

import '../home_page_lists/role_manager.dart';

var kRefreshMyCollections = Security.security_kRefreshMyCollections;

class CollectionsView extends StatelessWidget {
  CollectionsViewController viewController = Get.put(CollectionsViewController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        leading: InkWell(overlayColor: WidgetStateProperty.all(Colors.transparent), onTap: Get.back, child: Container(alignment: Alignment.center, padding: EdgeInsets.only(left: 16), child: ImageView(Images.security_back_png, fit: BoxFit.cover, height: 24, width: 24))),
        centerTitle: true,
        backgroundColor: AppColors.base_background,
        title: Text(
          Security.security_collection,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewController.onRefresh,
                child: Obx(
                  () =>
                      viewController.status.value == ListStatus.success
                          ? MasonryGridView.count(
                            controller: viewController.scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            itemBuilder: (context, index) {
                              return viewController.items[index].builder(context);
                            },
                            itemCount: viewController.items.length,
                          )
                          : ListStatusView(status: viewController.status.value, emptyDesc: Copywriting.security_no_favorites_yet__go_and_follow_some_people_),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionsViewController extends GetxController {
  var status = ListStatus.idle.obs;
  var items = [].obs;
  late ScrollController scrollController;

  CollectionsViewController() {
    scrollController = ScrollController();
    EventCenter.instance.addListener(kRefreshMyCollections, (_) {
      onRefresh();
    });
  }

  bool _hasMore = true;
  int _pageIndex = 0;
  int pageSize = 20;

  bool loadingMore = false;

  @override
  void onInit() {
    super.onInit();
    getStarsList();
    addObservers();
  }

  addObservers() {
    scrollController.addListener(() {
      if ((scrollController.position.pixels >= scrollController.position.maxScrollExtent - 64) && _hasMore && loadingMore == false) {
        loadMoreData();
      }
    });
  }

  loadMoreData() async {
    if (loadingMore) return;
    loadingMore = true;
    _pageIndex++;
    await getStarsList(pageIndex: _pageIndex);
    loadingMore = false;
  }

  Future<void> onRefresh() async {
    _pageIndex = 0;
    _hasMore = true;
    await getStarsList();
  }

  getStarsList({int pageIndex = 0, int targetUid = 0}) async {
    if (items.isEmpty && status.value == ListStatus.idle) {
      status.value = ListStatus.loading;
    }

    ApiResponse response = await RoleManager.instance.getMyStars(pageIndex: _pageIndex, pageSize: pageSize);
    if (response.statusCode == 200) {
      List infos = response.data[Security.security_list] ?? [];
      List newItems = infos.map((e) => CollectionsCard(e)).toList();

      if (pageIndex == 0) {
        items.clear();
      }
      items.addAll(newItems);
      status.value = items.isEmpty ? ListStatus.empty : ListStatus.success;
      _hasMore = response.data[Security.security_hasMore] ?? true;
    } else {
      if (items.isEmpty) {
        status.value = ListStatus.error;
      }
    }
  }
}

class CollectionsCard extends RoleItem {
  CollectionsCard(super.info);

  Future<String> getCoverUrl() async {
    var url = info[Security.security_coverUrl];
    if (url != null) return url;

    final UserProfileInfo? queryInfo = await UserManager.instance.getUserInfo(info[Security.security_uid]);
    return queryInfo?.coverImageUrl ?? '';
  }

  String get nickname => info[Security.security_nickname] ?? '';

  String get bio => info[Security.security_bio] ?? '';

  int get accountType => info[Constants.acType] ?? 0;

  void _onItemClicked({bool call = false}) {
    Map<String, dynamic> params = {
      Security.security_id: info[Security.security_uid].toString(),
      Security.security_name: info[Security.security_nickname] ?? '',
      Security.security_avatar: info[Security.security_avatarUrl] ?? '',
      Security.security_backgroundUrl: info[Security.security_coverUrl] ?? '',
      Security.security_accountType: info[Security.security_accountType] ?? 0,
    };

    Get.toNamed(Routers.chat, arguments: {Security.security_session: jsonEncode(params), Security.security_call: call});
  }

  @override
  Widget builder(BuildContext context) {
    return GestureDetector(
      onTap: _onItemClicked,
      child: AspectRatio(
        aspectRatio: 168 / 260,
        child: FutureBuilder<String>(
          future: getCoverUrl(),
          builder: (context, snapshot) {
            final coverUrl = snapshot.data ?? '';
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: isLoading ? null : DecorationImage(image: CachedImageProvider(coverUrl), fit: BoxFit.cover),
              ),
              child: Stack(
                children: [
                  if (isLoading) const Center(child: CircularProgressIndicator(color: Colors.white)),

                  Column(
                    children: [
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          // image: DecorationImage(image: CachedNetworkImageProvider(ImagePath.person_img_mask), fit: BoxFit.cover),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    nickname,
                                    maxLines: 1,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // AppWidgets.userTag(accountType),
                              ],
                            ),
                            Text(bio, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
