import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/keep_alive_wrapper.dart';
import 'chat_history_logic.dart';
import 'theater_history_list/view.dart';
import 'private_chat_history_list/view.dart';

class ChatHistoryView extends StatefulWidget {
  const ChatHistoryView({super.key});

  @override
  State<ChatHistoryView> createState() => _ChatHistoryViewState();
}

class _ChatHistoryViewState extends State<ChatHistoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final logic = Get.put(ChatHistoryViewController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        logic.onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      body: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Top bar - History 标题
            Container(
              height: 44.w,
              padding: EdgeInsets.only(left: 16.w, right: 16.w),
              alignment: Alignment.centerLeft,
              child: Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'HYPangDunDun',
                ),
              ),
            ),

            // TabBar 样式
            Container(
              height: 40.w,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 16.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => GestureDetector(
                    onTap: () {
                      _tabController.animateTo(0);
                      logic.onTabChanged(0);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                      decoration: BoxDecoration(
                        color: logic.currentTabIndex.value == 0
                            ? Color(0xFFEEEEEE)
                            : Color(0xFFEEEEEE).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        'Story',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: logic.currentTabIndex.value == 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: logic.currentTabIndex.value == 0
                              ? Color(0xFF07070A)
                              : Colors.white,
                        ),
                      ),
                    ),
                  )),
                  SizedBox(width: 8.w),
                  Obx(() => GestureDetector(
                    onTap: () {
                      _tabController.animateTo(1);
                      logic.onTabChanged(1);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                      decoration: BoxDecoration(
                        color: logic.currentTabIndex.value == 1
                            ? Color(0xFFEEEEEE)
                            : Color(0xFFEEEEEE).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: logic.currentTabIndex.value == 1
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: logic.currentTabIndex.value == 1
                              ? Color(0xFF07070A)
                              : Colors.white,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),

            SizedBox(height: 8.w),

            // Tab 内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  KeepAliveWrapper(child: TheaterHistoryListView()),
                  KeepAliveWrapper(child: PrivateChatHistoryListView()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
