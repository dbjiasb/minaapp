import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/keep_alive_wrapper.dart';
import '../../base/crypt/images.dart';
import '../../base/preferences/preferences.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/cached_image.dart';
import '../../shared/widget/app_widgets.dart';
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
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        backgroundColor: AppColors.base_background,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 40.w,
              padding: EdgeInsets.only(left: 16.w, right: 16.w),
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
            SizedBox(height: 4.w,),
            _buildRecommendView(),
            SizedBox(height: 4.w,),
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 12.w),
              child: TabBar(
                tabs: logic.tabs.map((e) => Obx(() {
                  int index = logic.tabs.indexOf(e);
                  bool isSelected = logic.currentTabIndex.value == index;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFFEDEFF3)
                          : Color(0xFF262B35),
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    child: Text(
                      e.name,
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Color(0xFF07070A)
                              : Colors.white,
                          height: 1.5
                      ),
                    ),
                  );
                })).toList(),
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
              ),
            ),

            SizedBox(height: 8.w),

            // Tab 内容
            Expanded(
              child: TabBarView(
                controller: logic.tabController,
                children: logic.tabs.map((e) {
                  if (e.type == SessionListType.theater) {
                    return KeepAliveWrapper(child: TheaterHistoryListView());
                  } else {
                    return KeepAliveWrapper(child: PrivateChatHistoryListView(type: e.type));
                  }
                }).toList(),

                // [
                //   KeepAliveWrapper(child: PrivateChatHistoryListView()),
                //   KeepAliveWrapper(child: TheaterHistoryListView()),
                // ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendView() {
    return Obx(
          () => !Preferences.instance.isRv && logic.showRecommend.value && logic.recommendList.isNotEmpty
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Trending',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 6.w),
              // refreshingRecommend
              Obx(
                    () => logic.refreshingRecommend.value
                    ? Container(
                  margin: const EdgeInsets.only(left: 2),
                  width: 11.w,
                  height: 11.w,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    backgroundColor: Colors.transparent,
                    strokeWidth: 2,
                  ),
                )
                    : GestureDetector(
                  onTap: () {
                    logic.queryRecommendList(true);
                  },
                  child: ImageView(Images.mina_refresh_trend, width: 11.w, height: 11.w)
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
              children: logic.recommendList.map((e) {
                return GestureDetector(
                  onTap: () {
                    RouteHelper.toChat(id: e[Security.security_uid].toString(), name: e[Security.security_nickname], avatar: e[Security.security_avatar], accountType: e[Security.security_accountType], type: 0);
                  },
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Container(width: 70, height: 54),
                          ClipRRect(borderRadius: BorderRadius.circular(24), child: CachedImage(imageUrl: e[Security.security_avatar] ?? '', width: 48, height: 48, fit: BoxFit.cover, borderRadius: BorderRadius.circular(24))),
                          Positioned(right: 0, bottom: -4, left: 0, child: AppWidgets.userTag(e[Security.security_accountType], id: e[Security.security_uid].toString())),
                        ],
                      ),
                      SizedBox(height: 4.w),
                      Container(
                        alignment: Alignment.center,
                        width: 66,
                        child: Text(
                          e[Security.security_nickname] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
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
}
