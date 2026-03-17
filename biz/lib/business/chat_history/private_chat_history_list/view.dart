import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/shared/app_theme.dart';
import 'logic.dart';
import 'private_chat_session_cell.dart';

class PrivateChatHistoryListView extends StatelessWidget {
  const PrivateChatHistoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(PrivateChatHistoryListLogic());

    return Obx(
      () => logic.isLoading.value
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SmartRefresher(
              controller: logic.refreshController,
              enablePullDown: true,
              enablePullUp: false,
              onRefresh: logic.onRefresh,
              child: logic.dataList.isEmpty
                  ? _emptyView(logic)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: logic.dataList.length,
                      itemBuilder: (context, index) {
                        final session = logic.dataList[index];
                        return Dismissible(
                          key: Key(session.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.w),
                            color: const Color(0xFFF0443E),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 24.w,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await logic.deleteSession(session);
                          },
                          child: PrivateChatSessionCell(
                            session: session,
                            onTap: () {
                              RouteHelper.toChat(
                                id: session.id,
                                name: session.name,
                                avatar: session.avatar,
                                coverUrl: session.backgroundUrl.value,
                                accountType: session.accountType,
                                type: 3, // 私聊
                                bio: session.bio,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _emptyView(PrivateChatHistoryListLogic logic) {
    return GestureDetector(
      onTap: () {
        logic.loadData();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 250.w),
          Center(
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.inbox_outlined,
                  size: 60.w,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
