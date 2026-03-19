import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:biz/core/util/collections_util.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../core/util/cached_image.dart';
import 'moment_detail_view_logic.dart';

class CommentListView extends GetView<MomentDetailViewLogic> {
  const CommentListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      int length = controller.translateMap.length;
      return controller.groupCommentList.isEmpty
          ? _buildEmptyView()
          : ListView.separated(
            itemBuilder: (context, index) {
              return _buildCommentItem(controller.groupCommentList[index].key, controller.groupCommentList[index].value);
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 26);
            },
            itemCount: controller.groupCommentList.length,
          );
    });
  }

  Widget _buildEmptyView() {
    // return Center(
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.center,
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       Image.asset(
    //         'assets/images/ic_page_empty.webp',
    //         width: 172,
    //         height: 146,
    //         package: Security.security_app_common,
    //       ),
    //     ],
    //   ),
    // );
    return Container();
  }

  Widget _buildCommentItem(Map commentInfo, List<Map> replyCommentInfo) {
    String? content = controller.translateMap[commentInfo[Security.security_id]];
    bool hasTran = controller.translateMap.containsKey(commentInfo[Security.security_id]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedImage(imageUrl: commentInfo[Security.security_avatarUrl] ?? '', width: 36, height: 36, borderRadius: BorderRadius.circular(18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(commentInfo[Security.security_nickname] ?? "", style: const TextStyle(color: Color(0xFFABABAD), fontSize: 12)),
              const SizedBox(height: 4),
              Text(content ?? commentInfo[Security.security_content] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat(Copywriting.security_mM_dd_HH_mm).format(DateTime.fromMillisecondsSinceEpoch(commentInfo[Security.security_createTime])),
                    style: const TextStyle(color: Color(0xFF494C53), fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      controller.replyComment(commentInfo);
                    },
                    child: Text(Security.security_reply, style: TextStyle(color: Color(0xFFABABAD), fontSize: 12)),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      controller.translateComment(commentInfo);
                    },
                    child: Text(
                      hasTran ? Security.security_recovery : Security.security_translate,
                      style: const TextStyle(
                        color: Color(0xFF85C0FF),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF85C0FF),
                        // 下划线颜色（可选）
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ),
                  ),
                ],
              ),
              if (replyCommentInfo.isNotEmpty)
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return _buildChildCommentView(replyCommentInfo.safeGet(index, {}));
                  },
                  padding: const EdgeInsets.only(top: 12),
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 16);
                  },
                  itemCount: replyCommentInfo.length,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildCommentView(Map commentInfo) {
    String? content = controller.translateMap[commentInfo[Security.security_id]];
    bool hasTran = controller.translateMap.containsKey(commentInfo[Security.security_id]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedImage(imageUrl: commentInfo[Security.security_avatarUrl] ?? '', width: 24, height: 24, borderRadius: BorderRadius.circular(12)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(commentInfo[Security.security_nickname] ?? "", style: const TextStyle(color: Color(0xFFABABAD), fontSize: 12)),
              const SizedBox(height: 4),
              Text(content ?? commentInfo[Security.security_content] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat(Copywriting.security_mM_dd_HH_mm).format(DateTime.fromMillisecondsSinceEpoch(commentInfo[Security.security_createTime])),
                    style: const TextStyle(color: Color(0xFF494C53), fontSize: 12),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      controller.translateComment(commentInfo);
                    },
                    child: Text(
                      hasTran ? Security.security_recovery : Security.security_translate,
                      style: const TextStyle(
                        color: Color(0xFF85C0FF),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF85C0FF),
                        // 下划线颜色（可选）
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
