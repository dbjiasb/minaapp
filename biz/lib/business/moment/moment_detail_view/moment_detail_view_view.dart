import 'dart:io';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:biz/base/ui/overlay_popup.dart';
import 'package:biz/core/util/collections_util.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/router/router_names.dart';
import '../../../base/ui/user_card_view.dart';
import '../../../core/account/account_service.dart';
import '../../../core/util/cached_image.dart';
import '../../../shared/common_widget.dart';
import '../constant_state.dart';
import '../report/report_view.dart';
import 'comment_list_view.dart';
import 'moment_detail_view_logic.dart';

class MomentDetailViewPage extends GetView<MomentDetailViewLogic> {
  const MomentDetailViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final OverlayPopupController menuController = OverlayPopupController();
    return Scaffold(
      backgroundColor: Color(0xFF12151C),
      appBar: AppBarExt.buildCustomAppBar(
        _buildBarView(),
        actions: [
          _buildCollectView(),
          OverlayPopup(
            menuBuilder: () {
              return Container(
                width: 72,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: IntrinsicWidth(
                  child: Column(
                    children: [
                      (MyAccount.userId == controller.rxMomentInfo.value[Security.security_posterUid] || MyAccount.userId == controller.rxMomentInfo.value[Security.security_authorUid])
                          ? InkWell(
                            onTap: () {
                              menuController.hideMenu();
                              controller.deleteMoment(controller.rxMomentInfo.value[Security.security_id]);
                            },
                            child: Text(
                              Security.security_delete,
                              style: TextStyle(color: Color(0xFF080E1B), fontWeight: FontWeight.bold, fontSize: 12),
                            ).marginSymmetric(vertical: 8),
                          )
                          : InkWell(
                            onTap: () {
                              menuController.hideMenu();
                              Get.dialog(ReportView(controller.rxMomentInfo.value[Security.security_id], 1), useSafeArea: false);
                            },
                            child: Text(
                              Security.security_report,
                              style: TextStyle(color: Color(0xFF080E1B), fontWeight: FontWeight.bold, fontSize: 12),
                            ).marginSymmetric(vertical: 8),
                          ),
                    ],
                  ),
                ),
              );
            },
            pressType: PressType.singleClick,
            showArrow: false,
            child: CachedImage(imageUrl: '${MomentRes.base}iic_chat_more.webp', width: 24, height: 24).marginOnly(right: 16),
          ),
        ],
      ),
      body: SafeArea(bottom: false, top: true, child: _buildBody(context)),
    );
  }

  Widget _buildBarView() {
    return Obx(() {
      return Row(
        children: [
          CachedImage(imageUrl: controller.rxMomentInfo.value[Security.security_avatarUrl] ?? '', width: 36, height: 36, borderRadius: BorderRadius.circular(18)),
          const SizedBox(width: 8),
          Text(controller.rxMomentInfo.value[Security.security_nickname] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );
    });
  }

  Widget _buildCollectView() {
    return GestureDetector(
      onTap: () {
        controller.collectAction();
      },
      child: Obx(() {
        return CachedImage(imageUrl:
          MomentRes.base + (controller.rxCollectStatus.value ? 'iic_collect.webp' : 'iic_uncollect.webp'),
          width: 24,
          height: 24,
          fit: BoxFit.cover,
        ).marginOnly(right: 16);
      }),
    );
  }

  Widget _buildFollowView() {
    return Obx(() {
      return Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(right: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: controller.isFollowed.value ? Colors.white.withOpacity(0.5) : Colors.transparent, width: 1),
          color: controller.isFollowed.value ? Colors.transparent : Colors.white,
        ),
        child: Text(
          controller.isFollowed.value ? Security.security_followed : Security.security_follow,
          style: TextStyle(color: controller.isFollowed.value ? Colors.white.withOpacity(0.5) : Color(0xFF12151C), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    });
  }

  Widget _buildTextContentView() {
    return Obx(() {
      return (controller.rxMomentInfo.value[Security.security_content] ?? '').isNotEmpty
          ? Container(
            margin: const EdgeInsets.only(top: 16),
            width: double.infinity,
            child: Text(controller.rxMomentInfo.value[Security.security_content] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
          )
          : Container();
    });
  }

  // 展示图片或者视频
  Widget _buildResContentView() {
    return Obx(() {
      List resInfos = controller.rxMomentInfo.value[Security.security_resInfos]??[];
      if (resInfos.isEmpty) {
        return Container();
      } else {
        int length = resInfos.length;
        if (length == 1) {
          return AspectRatio(aspectRatio: 343 / 410, child: _buildResView(resInfos.first));
        } else {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: length > 2 ? 3 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: length,
            itemBuilder: (context, index) {
              return _buildResView(resInfos.safeGet(index, {}));
            },
          );
          // return OptionGridView(
          //   itemCount: length,
          //   rowCount: length > 2 ? 3 : 2,
          //   crossAxisSpacing: 8,
          //   mainAxisSpacing: 8,
          //   itemBuilder: (context, index) {
          //     return AspectRatio(
          //       aspectRatio: 1 / 1,
          //       child: _buildResView(controller.rxMomentInfo.value.resInfos
          //           .safeGet(index, {})),
          //     );
          //   },
          // );
        }
      }
    }).marginOnly(top: 12);
  }

  Widget _buildLikeBnt() {
    return GestureDetector(
      onTap: () {
        controller.likeMomentAction(controller.rxMomentInfo.value);
      },
      child: Obx(() {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CachedImage(imageUrl:
            controller.rxMomentInfo.value[Security.security_isLike] == 1
                  ? '${MomentRes.base}iic_like.webp'
                  : '${MomentRes.base}iic_unlike.webp',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 4),
            Text(
              '${controller.rxMomentInfo.value[Security.security_likeCount]}',
              style: TextStyle(
                color: controller.rxMomentInfo.value[Security.security_isLike] == 1 ? Color(0xFFFF56BB) : const Color(0xFF5C5E64),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCommentView() {
    return GestureDetector(
      onTap: () {
        controller.replyComment({});
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CachedImage(imageUrl: '${MomentRes.base}iic_comment.webp', width: 24, height: 24, fit: BoxFit.cover),
          const SizedBox(width: 4),
          Obx(() {
            return Text(
              '${controller.rxMomentInfo.value[Security.security_commentCount]}',
              style: const TextStyle(color: Color(0xFF5C5E64), fontSize: 12, fontWeight: FontWeight.w600),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionView() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          // Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     Image.asset(
          //       'assets/images/ic_send_doll.webp',
          //       package: Security.security_app_common,
          //       width: 24,
          //       height: 24,
          //     ),
          //     const SizedBox(
          //       width: 4,
          //     ),
          //     const Text(
          //       'SEND TIP',
          //       style: TextStyle(color: Color(0xFF5C5E64), fontSize: 12),
          //     )
          //   ],
          // ),
          const Spacer(),
          _buildLikeBnt(),
          const SizedBox(width: 16),
          _buildCommentView(),
        ],
      ),
    );
  }

  Widget _buildResView(Map resInfo) {
    return InkWell(
      onTap: () {
        if (resInfo[Security.security_type] == 2) {
          Get.toNamed(Routers.videoPlayer, arguments: {Security.security_videoUrl: resInfo[Security.security_url] ?? ''});
          // ViewerRoute.toVideoView(resInfo.url ?? '');
        } else {
          controller.viewImages(resInfo);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            resInfo[Security.security_type] == EMomentResType.VIDEO
                ? VideoView(videoUrl: resInfo[Security.security_url] ?? '')
                : CachedImage(
                  imageUrl: resInfo[Security.security_url] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  errorWidget: (context, url, error) {
                    return Container(
                      color: Colors.grey,
                      width: double.infinity,
                    );
                  },
                  placeholder: (context, url) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(color: Color(0xFF2F3137), borderRadius: BorderRadius.circular(16)),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildLineView() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0x00FFFFFF), Color(0x1AFFFFFF), Color(0x00FFFFFF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
      ),
      height: 1,
      width: double.infinity,
    );
  }

  Widget _buildBody(BuildContext context) {
    return ExtendedNestedScrollView(
      onlyOneScrollInBody: true,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverList(delegate: SliverChildListDelegate([_buildTextContentView(), _buildResContentView(), _buildOptionView(), _buildLineView()])),
          SliverPersistentHeader(
            delegate: StickyHeaderDelegate(
              child: Container(
                color: Color(0xFF12151C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(Security.security_comments, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            pinned: true,
            floating: true,
          ),
        ];
      },
      body: Column(children: [
        const Expanded(child: CommentListView()),
        _buildTextField(),
        SafeArea(child: SizedBox(height: Platform.isAndroid ? 10 : 0,))
      ]),
    ).marginSymmetric(horizontal: 16);
  }

  Widget _buildTextField() {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFB9B9B9).withOpacity(0.3), borderRadius: BorderRadius.circular(100)),
        child: TextField(
          focusNode: controller.focusNode,
          onChanged: (value) {
            controller.inputText.value = value;
          },
          onSubmitted: (value) {
            if (value.isEmpty) return;
            controller.commentMoment(controller.rxMomentInfo.value[Security.security_id], value);
          },
          inputFormatters: [LengthLimitingTextInputFormatter(250)],
          controller: controller.textController,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
          decoration: InputDecoration(
            hintText:
                (controller.rxReplyCommentInfo.value[Security.security_nickname] ?? "").isEmpty
                    ? Copywriting.security_post_your_reply
                    : "reply to @${controller.rxReplyCommentInfo.value[Security.security_nickname]}",
            hintStyle: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
            filled: true,
            isCollapsed: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
          ),
          cursorColor: Colors.white,
          textInputAction: TextInputAction.send,
          maxLines: 1,
          // 固定最大行数
          minLines: 1,
          // 固定最小行数
          expands: false,
          keyboardType: TextInputType.text,
        ),
      );
    }).marginSymmetric(vertical: 8);
  }
}

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  late final Widget child;

  double barHeight = 50;

  StickyHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => barHeight;

  @override
  double get minExtent => barHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
