import 'dart:async';

import 'package:biz/base/assets/image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/business/moment/constant_state.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/util/collections_util.dart';
import 'package:biz/shared/app_theme.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/event_center/event_center.dart';
import '../../../base/report/report_manager.dart';
import '../../../base/router/route_helper.dart';
import '../../../base/router/router_names.dart';
import '../../../base/ui/overlay_popup.dart';
import '../../../base/ui/user_card_view.dart';
import '../../../core/util/cached_image.dart';
import '../../../shared/common_widget.dart';
import '../moment_service.dart';
import '../report/report_view.dart';

class MomentItemView extends StatefulWidget {
  final int listType;

  final int targetUid;

  final bool canRefresh;

  final Map? baseInfo;

  final GestureTapCallback? onCreateTap;

  const MomentItemView(this.listType, {
    this.targetUid = 0,
    this.canRefresh = true,
    this.onCreateTap,
    super.key,
    this.baseInfo
  });

  @override
  State<MomentItemView> createState() => _MomentItemViewState();
}

class _MomentItemViewState extends State<MomentItemView> {
  RxList momentInfoList = RxList();
  int fromId = 0;
  RxBool hasMore = true.obs;
  var isLoadingMore = false;

  dynamic event, deleteEvent, updateEvent;

  @override
  void initState() {
    super.initState();
    event = EventCenter.instance.addListener(kPostMomentSuccess, (object) {
      if (momentInfoList.isEmpty) {
        setState(() {});
      } else {
        momentInfoList.insert(0, object.data);
        momentInfoList.refresh();
      }
    });
    deleteEvent = EventCenter.instance.addListener(kDeleteMomentSuccess, (object) {
      momentInfoList.removeWhere((element) => element.id == object.data[Security.security_momentId]);
      momentInfoList.refresh();
    });
    updateEvent = EventCenter.instance.addListener(kUpdateMomentSuccess, (object) {
      Map data = object.data;
      int index = momentInfoList.indexWhere((element) => element[Security.security_id] == data[Security.security_id]);
      if (index != -1) {
        momentInfoList[index] = data;
        momentInfoList.refresh();
      }
    });
  }

  @override
  void dispose() {
    if (event != null) {
      EventCenter.instance.removeListener(kPostMomentSuccess, event!);
    }
    if (deleteEvent != null) {
      EventCenter.instance.removeListener(kDeleteMomentSuccess, deleteEvent!);
    }
    if (updateEvent != null) {
      EventCenter.instance.removeListener(kUpdateMomentSuccess, updateEvent!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ReportManager.sendEvent(Security.security_pv_user_moment_list, {Security.security_listType: widget.listType.toString()});
    return AppBarExt.mainBody<Map?>(getListData(0), loadColor: Colors.white, (data, context) {
      var rawData = data?[Security.security_param] ?? [];
      List<Map> listData = (rawData as List).cast<Map>();
      if (listData.isEmpty) {
        return InkWell(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          onTap: () {
            setState(() {});
          },
          child: _buildEmptyView(),
        );
      } else {
        refreshData(listData);
        fromId = data?[Security.security_nextId];
        hasMore.value = data?[Security.security_hasMore] == 1;
        return _buildView();
      }
    });
  }

  Widget _buildEmptyView() {
    return Container(
      alignment: Alignment.center,
      color: widget.listType == 2 ? AppColors.base_background : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ImageView("empty_list.png", width: 172, height: 146),
          const SizedBox(height: 16),
          if (widget.listType == 2 && (widget.baseInfo != null || widget.targetUid == 0))
          GestureDetector(
            onTap: () {
              if (widget.onCreateTap != null) {
                widget.onCreateTap?.call();
              } else {
                ReportManager.sendEvent(Security.security_click_post_bnt, {Security.security_type: "3"});
                Get.toNamed(Routers.createMoment, arguments: widget.baseInfo);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedImage(imageUrl: '${MomentRes.base}iic_add.webp', width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(Copywriting.security_create_Moment, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return NotificationListener(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          final reachBottom = metrics.pixels >= metrics.maxScrollExtent - 64;
          if (reachBottom && hasMore.value && !isLoadingMore) {
            isLoadingMore = true;//防抖处理
            onLoading();
          }
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverList.separated(
              itemCount: momentInfoList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildItemView(momentInfoList.safeGet(index, {}));
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildView() {
    return Obx(() {
      return widget.canRefresh ? RefreshIndicator(onRefresh: () async => onRefresh(), child: _buildListView()) : _buildListView();
    });
  }

  Widget _buildItemView(Map momentInfo) {
    OverlayPopupController controller = OverlayPopupController();
    return InkWell(
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onTap: () {
        Get.toNamed(Routers.detailMoment, arguments: momentInfo);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                onTap: () {
                  if (((momentInfo[Security.security_robotInfo]?[Security.security_masterInfo]?[Security.security_uid] ?? 0) != 0) &&
                      (momentInfo[Security.security_robotInfo]?[Security.security_masterInfo]?[Security.security_uid] ?? 0) != MyAccount.userId &&
                      (momentInfo[Security.security_robotInfo]?[Security.security_shared] == EShareState.PRIVATE ||
                          momentInfo[Security.security_robotInfo]?[Security.security_audit] != EAiAuditStatus.PASS)) {
                    EasyLoading.showToast(Copywriting.security_character_is_private);
                  } else {
                    RouteHelper.toPage(
                      Routers.person,
                      args: {
                        Security.security_personInfo: {
                          Security.security_userInfo: {
                            Security.security_baseInfo: {
                              Security.security_uid: momentInfo[Security.security_posterUid],
                              Security.security_nickName: momentInfo[Security.security_nickname],
                              Security.security_avatarUrl: momentInfo[Security.security_avatarUrl],
                            },
                          },
                        },
                      },
                    );
                  }
                },
                child: CachedImage(imageUrl: momentInfo[Security.security_avatarUrl] ?? '', width: 44, height: 44, borderRadius: BorderRadius.circular(22)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    momentInfo[Security.security_nickname] ?? '',
                    style: const TextStyle(color: Color(0xFFABABAD), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat(Copywriting.security_mM_dd_HH_mm).format(DateTime.fromMillisecondsSinceEpoch(momentInfo[Security.security_createTime])),
                    style: const TextStyle(color: Color(0xFF494C53), fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              OverlayPopup(
                controller: controller,
                menuBuilder: () {
                  return Container(
                    width: 72,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: IntrinsicWidth(
                      child: Column(
                        children: [
                          (MyAccount.userId == momentInfo[Security.security_posterUid] || MyAccount.userId == momentInfo[Security.security_authorUid])
                              ? InkWell(
                                overlayColor: WidgetStateProperty.all(Colors.transparent),
                                onTap: () {
                                  controller.hideMenu();
                                  deleteMoment(momentInfo[Security.security_id]);
                                },
                                child: Text(
                                  Security.security_delete,
                                  style: TextStyle(color: Color(0xFF080E1B), fontWeight: FontWeight.bold, fontSize: 12),
                                ).marginSymmetric(vertical: 8),
                              )
                              : InkWell(
                                overlayColor: WidgetStateProperty.all(Colors.transparent),
                                onTap: () {
                                  controller.hideMenu();
                                  Get.dialog(ReportView(momentInfo[Security.security_id], 1), useSafeArea: false);
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
                child: CachedImage(imageUrl: MomentRes.base + 'iic__share.webp', width: 20, height: 20),
              ),
            ],
          ),
          if ((momentInfo[Security.security_content] ?? '').isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 52, top: 12),
              width: double.infinity,
              child: Text(momentInfo[Security.security_content] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          if ((momentInfo[Security.security_resInfos] ?? []).isNotEmpty)
            _buildItemRes((momentInfo[Security.security_resInfos] as List).cast<Map>()).marginOnly(left: 52, top: 8),
          _buildOptionView(momentInfo),
          if (momentInfo[Security.security_auditStatus] == EAiAuditStatus.NOT_PASS &&
              widget.listType == EMomentListType.MOMENT_LIST_USER &&
              widget.targetUid == 0)
            _buildWarnView(),
          _buildLineView(),
        ],
      ),
    );
  }

  Widget _buildWarnView() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFFF1E6B).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CachedImage(imageUrl: '${MomentRes.base}iic_warning.webp', width: 16, height: 16),
          const SizedBox(width: 4),
          Text(Copywriting.security_this_moment_does_not_meet_community_requirements__please_edit, style: TextStyle(color: Color(0xFFFF1E6B), fontSize: 9)),
        ],
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

  Widget _buildResView(Map resInfo) {
    return InkWell(
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onTap: () {
        if (resInfo[Security.security_type] == 2) {
          Get.toNamed(Routers.videoPlayer, arguments: {Security.security_videoUrl: resInfo[Security.security_url] ?? ''});
          // ViewerRoute.toVideoView(resInfo.url ?? '');
        } else {
          viewImages(resInfo);
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
                  errorWidget: (context, url, error) {
                    return Container(color: Colors.grey, width: double.infinity);
                  },
                  borderRadius: BorderRadius.all(Radius.circular(12)),
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

  Widget _buildItemRes(List<Map> resInfoList) {
    int length = resInfoList.length;
    if (length == 0) {
      return Container();
    } else if (length == 1) {
      return SizedBox(width: 188.0, height: 280.0, child: _buildResView(resInfoList.first));
    } else {
      return Row(
        children: [
          Expanded(child: AspectRatio(aspectRatio: 1 / 1, child: _buildResView(resInfoList.first))),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                AspectRatio(aspectRatio: 1 / 1, child: _buildResView(resInfoList[1])),
                if (length > 2)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          CachedImage(imageUrl: '${MomentRes.base}iic_multi.webp', width: 12, height: 12),
                          const SizedBox(width: 4),
                          Text('+$length', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLikeBnt(Map momentInfo) {
    return GestureDetector(
      onTap: () {
        likeMomentAction(momentInfo);
      },
      child: Row(
        children: [
          CachedImage(
            imageUrl: momentInfo[Security.security_isLike] == 1 ? MomentRes.base + 'iic_like.webp' : MomentRes.base + 'iic_unlike.webp',
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 4),
          Text(
            '${momentInfo[Security.security_likeCount]}',
            style: TextStyle(
              color: momentInfo[Security.security_isLike] == 1 ? AppColors.primary : const Color(0xFF5C5E64),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentView(int commentCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CachedImage(imageUrl: '${MomentRes.base}iic_comment.webp', width: 24, height: 24, fit: BoxFit.cover),
        const SizedBox(width: 4),
        Text('$commentCount', style: const TextStyle(color: Color(0xFF5C5E64), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildOptionView(Map momentInfo) {
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 52),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
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
          _buildLikeBnt(momentInfo),
          const SizedBox(width: 16),
          _buildCommentView(momentInfo[Security.security_commentCount] ?? 0),
        ],
      ),
    );
  }

  void onRefresh() async {
    Map? rsp = await getListData(0);
    var rawData = rsp?[Security.security_param] ?? [];
    List<Map> listData = (rawData as List).cast<Map>();
    refreshData(listData);
    hasMore.value = rsp?[Security.security_hasMore] == 1;
    fromId = rsp?[Security.security_nextId] ?? 0;
  }

  void onLoading() async {
    if (!hasMore.value) return;
    Map? rsp = await getListData(fromId);
    var rawData = rsp?[Security.security_param] ?? [];
    List<Map> listData = (rawData as List).cast<Map>();
    momentInfoList.addAll(listData);
    hasMore.value = rsp?[Security.security_hasMore] == 1;
    fromId = rsp?[Security.security_nextId] ?? 0;
    isLoadingMore = false;
  }

  void refreshData(List<Map> momentList) {
    momentInfoList.clear();
    momentInfoList.addAll(momentList);
  }

  Future<Map?> getListData(int wFromId) async {
    fromId = wFromId;
    return MomentService.getMomentInfoList(listType: widget.listType, fromId: wFromId, targetUid: widget.targetUid);
  }

  void likeMomentAction(Map momentInfo) async {
    bool wantLikeAction = momentInfo[Security.security_isLike] != 1;
    if (wantLikeAction) {
      momentInfo[Security.security_isLike] = 1;
      momentInfo[Security.security_likeCount] = momentInfo[Security.security_likeCount] + 1;
    } else {
      momentInfo[Security.security_isLike] = 0;
      momentInfo[Security.security_likeCount] = momentInfo[Security.security_likeCount] - 1;
    }
    momentInfo[Security.security_likeCount] = momentInfo[Security.security_likeCount] < 0 ? 0 : momentInfo[Security.security_likeCount];
    momentInfoList.refresh();
    await MomentService.likeMomentAction(
      wantLikeAction,
      momentInfo[Security.security_id],
      posterUid: momentInfo[Security.security_posterUid],
      authorUid: momentInfo[Security.security_authorUid],
    );
  }

  void deleteMoment(int momentId) {
    EasyLoading.show();
    MomentService.deleteMoment(momentId)
        .then((value) {
          EasyLoading.dismiss();
          if (value[Security.security_tCommonRsp]?[Security.security_code] == 0) {
            momentInfoList.removeWhere((element) => element.id == momentId);
            momentInfoList.refresh();
          } else {
            EasyLoading.showToast(value[Security.security_tCommonRsp]?[Security.security_msg] ?? Copywriting.security_operation_failed);
          }
        })
        .catchError((e) {
          // if (e is WupException) {
          EasyLoading.showToast(e.message);
          EasyLoading.dismiss();
          // } else {
          //   EasyLoading.showToast(Copywriting.security_operation_failed);
          //   EasyLoading.dismiss();
          // }
        });
  }

  void viewImages(Map res) {
    // List<String> imageUrls = momentInfoList
    //     .expand<Map>((m) => (m[Security.security_resInfos] ?? []).take(2))
    //     .where((e) => (e[Security.security_type] == 0 || e[Security.security_type] == 1) && (e[Security.security_url] ?? "").isNotEmpty)
    //     .map((e) => (e[Security.security_url] ?? "") as String)
    //     .toList();
    // int index = imageUrls.indexWhere((entry) => entry == res[Security.security_url]);
    // if (index == -1) {
    //   index = 0;
    // }

    Get.toNamed(Routers.imageBrowser, arguments: {Security.security_imageUrl: res[Security.security_url]});
  }
}
