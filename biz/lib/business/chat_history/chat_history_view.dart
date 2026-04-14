import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/keep_alive_wrapper.dart';
import '../../base/app_info/app_manager.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/images.dart';
import '../../base/preferences/preferences.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/cached_image.dart';
import '../../shared/widget/app_widgets.dart';
import '../chat/chat_manager.dart';
import '../chat/setting/message_setting.dart';
import 'chat_history_logic.dart';
import 'theater_history_list/view.dart';
import 'private_chat_history_list/view.dart';

class ChatHistoryView extends StatefulWidget {
  const ChatHistoryView({super.key});

  @override
  State<ChatHistoryView> createState() => _ChatHistoryViewState();
}

class _ChatHistoryViewState extends State<ChatHistoryView> {
  final logic = Get.put(ChatHistoryViewController());

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = _buildTabBar();
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        backgroundColor: AppColors.base_background,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        toolbarHeight: 40,
        leadingWidth: 200,
        leading: Container(
          padding: EdgeInsets.only(left: 16.w),
          alignment: Alignment.centerLeft,
          child: Text(
            Security.security_history,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: Security.security_hYPangDunDun,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _showSessionSetting,
            child: Icon(Icons.more_horiz, size: 24, color: Colors.white),
          ).marginOnly(right: 16)
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildRecommendView().marginSymmetric(vertical: 4.w),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ChatHistoryTabBarDelegate(
                  tabBar: tabBar,
                  leftPadding: 12.w,
                  bottomSpacing: 8.w,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: logic.tabController,
            children:
                logic.tabs.map((e) {
                  if (e.type == SessionListType.theater) {
                    return KeepAliveWrapper(child: TheaterHistoryListView());
                  } else {
                    return KeepAliveWrapper(
                      child: PrivateChatHistoryListView(type: e.type),
                    );
                  }
                }).toList(),
          ),
        ),
      ),
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      tabs:
          logic.tabs
              .map(
                (e) => Obx(() {
                  int index = logic.tabs.indexOf(e);
                  bool isSelected = logic.currentTabIndex.value == index;
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.w,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFEDEFF3) : Color(0xFF262B35),
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    child: Text(
                      e.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Color(0xFF07070A) : Colors.white,
                        height: 1.5,
                      ),
                    ),
                  );
                }),
              )
              .toList(),
      controller: logic.tabController,
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      onTap: (index) {
        logic.currentTabIndex.value = index;
      },
      labelPadding: const EdgeInsets.only(right: 12),
      indicatorColor: Colors.transparent,
      indicator: const BoxDecoration(),
      dividerHeight: 0,
    );
  }

  Widget _buildRecommendView() {
    return Obx(
      () =>
          !Preferences.instance.isRv &&
                  logic.showRecommend.value &&
                  logic.recommendList.isNotEmpty
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        Security.security_Trending,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      // refreshingRecommend
                      Obx(
                        () =>
                            logic.refreshingRecommend.value
                                ? Container(
                                  margin: const EdgeInsets.only(left: 2),
                                  width: 11.w,
                                  height: 11.w,
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    strokeWidth: 2,
                                  ),
                                )
                                : GestureDetector(
                                  onTap: () {
                                    logic.queryRecommendList(true);
                                  },
                                  child: ImageView(
                                    Images.mina_refresh_trend,
                                    width: 11.w,
                                    height: 11.w,
                                  ),
                                ),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          logic.showRecommend.value = false;
                        },
                        child: Icon(Icons.close, size: 22, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children:
                          logic.recommendList.map((e) {
                            return GestureDetector(
                              onTap: () {
                                RouteHelper.toChat(
                                  id: e[Security.security_uid].toString(),
                                  name: e[Security.security_nickname],
                                  avatar: e[Security.security_avatar],
                                  accountType: e[Security.security_accountType],
                                  type: 0,
                                );
                              },
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.topCenter,
                                    clipBehavior: Clip.none,
                                    children: [
                                      const SizedBox(width: 70, height: 54),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: CachedImage(
                                          imageUrl:
                                              e[Security.security_avatar] ?? '',
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: -4,
                                        left: 0,
                                        child: AppWidgets.userTag(
                                          e[Security.security_accountType],
                                          id:
                                              e[Security.security_uid]
                                                  .toString(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.w),
                                  Container(
                                    alignment: Alignment.center,
                                    width: 66,
                                    child: Text(
                                      e[Security.security_nickname] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).marginOnly(bottom: 8);
                          }).toList(),
                    ),
                  ),
                ],
              ).marginOnly(left: 16.w, right: 16.w)
              : Container(),
    );
  }

  void _showSessionSetting() {
    List<String> titles = Preferences.instance.isRv
        ? [Copywriting.security_mark_all_as_read, Security.security_notification]
        : [Copywriting.security_mark_all_as_read, Security.security_notification, Copywriting.security_message_setting];
    Get.dialog(
      InkWell(
        onTap: Get.back,
        child: Container(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
            margin: const EdgeInsets.only(top: 48, right: 16),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: titles.map((e) {
                  int index = titles.indexOf(e);
                  return InkWell(
                    onTap: () {
                      Get.back();
                      if (index == 0) {
                        maskAllRead();
                      } else if (index == 1) {
                        RouteHelper.handleRoute(AppManager.instance.notificationUrl,);
                      } else if (index == 2) {
                        Get.to(MessageSettingView());
                      }
                    },
                    child: Container(
                      width: 132,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Text(
                        e,
                        style: const TextStyle(color: AppColors.base_background, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void maskAllRead() async {
    await ChatManager.instance.sessionHandler.clearUnreadCount();
  }
}

class _ChatHistoryTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final double leftPadding;
  final double bottomSpacing;

  _ChatHistoryTabBarDelegate({
    required this.tabBar,
    required this.leftPadding,
    required this.bottomSpacing,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      color: AppColors.base_background,
      padding: EdgeInsets.only(left: leftPadding, bottom: bottomSpacing),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + bottomSpacing;

  @override
  double get minExtent => tabBar.preferredSize.height + bottomSpacing;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
