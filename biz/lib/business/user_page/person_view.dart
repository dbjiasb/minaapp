import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/router/router_names.dart';
// import 'package:biz/business/account/collections_view.dart';
import 'package:biz/business/chat/chat_room/chat_room_view.dart';
import 'package:biz/business/chat/person_manager.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/util/es_helper.dart';
import 'package:biz/core/util/ui_util.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/title_bar.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/user_manager/user_manager.dart';
import '../../base/api_service/api_response.dart';
import '../../base/assets/image_view.dart';
import '../../base/preferences/preferences.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/cached_image.dart';
import '../../shared/toast/toast.dart';
import '../../shared/widget/app_widgets.dart';
import '../create_center/character_service.dart';
import '../home_page_lists/list_item.dart';
import '../home_page_lists/role_manager.dart';
import '../moment/constant_state.dart';
import '../moment/moment_list_view/moment_item_view.dart';

class PersonViewPage extends StatelessWidget {
  PersonViewPage({Key? key}) : super(key: key);

  late PersonViewController controller;
  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    controller = PersonViewController(Get.arguments[Security.security_personInfo] ?? {});
    RxInt tabSelectIndex = RxInt(0);
    Obx obxTabBars = Obx(
      () => StyleTabBars(
        titles: controller.tabsTitle.value,
        onTabSelected: (index) {
          pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.linearToEaseOut);
        },
      )..selectedIndex = tabSelectIndex,
    );
    Get.put(controller, tag: 'person_view_${controller.uid}');
    return Scaffold(
      key: Key('person_view_${controller.uid}'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Container(width: double.infinity, height: double.infinity, color: Colors.black),
                Obx(() {
                  return ColorFiltered(
                    colorFilter: ColorFilter.mode(Color(0xFF000000).withValues(alpha: 0.1), BlendMode.srcOver),
                    child: CachedImage(
                      imageUrl: controller.background,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: (context, url, error) => Container(width: double.infinity, height: double.infinity, color: AppColors.main),
                    ),
                  );
                }),
              ],
            ),
          ),

          // 内容
          Positioned.fill(
            child: ExtendedNestedScrollView(
              onlyOneScrollInBody: true,
              headerSliverBuilder: (c, i) {
                return [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.only(left: 22, right: 22),
                      margin: EdgeInsets.only(top: 350),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0), Colors.black, Colors.black],
                        ),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [_buildHeaderSection(), _buildProfileSection()]),
                    ),
                  ),
                  SliverPersistentHeader(pinned: true, floating: true, delegate: _TabBarDelegate(obxTabBars)),
                ];
              },
              pinnedHeaderSliverHeightBuilder: () {
                return MediaQuery.of(context).padding.top + kToolbarHeight + 48;
              },
              body: Container(
                color: AppColors.base_background,
                child: PageView(
                  controller: pageController,
                  onPageChanged: (i) {
                    tabSelectIndex.value = i;
                  },
                  children: [_buildGallerySection(), if (controller.isReal) _buildOcSection(), _buildMomentListSection()],
                ),
              ),
            ),
          ),

          // 返回按钮
          Positioned(
            left: 16,
            right: 16,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(width: 32, height: 44, alignment: Alignment.center, child: ImageView(Images.security_back_png, width: 24, height: 24)),
                  ),
                  Obx(
                    () =>
                        controller.loading.value
                            ? Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                            : Container(),
                  ),
                  Obx(
                    () => GestureDetector(
                      onTap: () {
                        if (controller.isStarred) {
                          controller.unCollectUser();
                        } else {
                          controller.collectUser();
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 44,
                        alignment: Alignment.center,
                        child: ImageView(controller.isStarred ? Images.security_user_collected_png : Images.security_user_collect_png, width: 24, height: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 聊天按钮
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: GestureDetector(
              onTap: onToChatTap,
              child: SafeArea(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
                  height: 52,
                  child: Text(Security.security_Chat, style: TextStyle(color: Color(0xFF07070A), fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcSection() {
    return Obx(
      () =>
          controller.myCompanions.isNotEmpty
              ? GridView.count(
                padding: EdgeInsets.only(top: 16, left: 16, right: 16),
                physics: const NeverScrollableScrollPhysics(),
                // 1. 禁用GridView自身滚动
                shrinkWrap: true,
                // 2. 适应内容高度
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 168 / 256,
                children:
                    controller.myCompanions.map((companion) {
                      String linkNum = RoleItem.shortStringForCount(companion[Security.security_heatInfo]?[Security.security_connectors] ?? 0);
                      String heatNum = RoleItem.shortStringForCount(companion[Security.security_heatInfo]?[Security.security_heatValue] ?? 0);
                      String coverUrl = companion[Security.security_coverUrl];
                      String nickname = companion[Security.security_nickname];
                      int uid = companion[Security.security_uid];
                      int accountType = companion[Security.security_accountType];
                      String avatar = companion[Security.security_avatarUrl];

                      return GestureDetector(
                        onTap: () {
                          RH.toChat(id: "$uid", name: nickname, avatar: avatar, coverUrl: coverUrl, accountType: accountType);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CachedImage(
                                  imageUrl: coverUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(color: AppColors.ocMain),
                                ),
                              ),
                              Column(
                                children: [
                                  Spacer(),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.01),
                                          Colors.black.withValues(alpha: 0.6),
                                          Colors.black.withValues(alpha: 0.9),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
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
                                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // AppWidgets.userTag(companion[Security.security_accountType]),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                ImageView(Images.security_linknum_webp, width: 12, height: 12).marginOnly(right: 2),
                                                Text(linkNum, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                                                SizedBox(width: 4),
                                                Image.asset(Images.security_heart_count_webp, width: 12, height: 12).marginOnly(right: 2),
                                                Text(heatNum, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              )
              : Container(height: Get.height * 0.5, child: UiUtils.buildCommonEmptyView()),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.only(top: 44),
      alignment: Alignment.bottomLeft,
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            // Row(
            //   children: [
            //     CircleAvatar(
            //       radius: 36,
            //       backgroundColor: Colors.transparent,
            //       child: Container(
            //         decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(width: 1, color: Colors.white.withValues(alpha: 0.8))),
            //         child: ClipOval(
            //           child: CachedImage(
            //             imageUrl: controller.avatarUrl,
            //             fit: BoxFit.cover,
            //             errorWidget: (context, url, error) => Container(color: Colors.grey, height: 72, width: 72),
            //             width: 72,
            //             height: 72,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            // SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              controller.name,
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppWidgets.userTag(controller.accountType, id: controller.uid.toString()),
                          if (controller.isMyOc) CharacterService.auditTextWidget(controller.myOcShared, controller.myOcAudit, isUserPage: true),
                        ],
                      ),
                    ),
                    // Spacer(),
                    Obx(() {
                      return controller.isMyOc ? _buildEditOCButton() : _buildFollowButton();
                    }),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: controller.uid.toString()));
                        Toast.show(Copywriting.security_copied_ID_to_clipboard);
                      },
                      child: Text('ID: ${controller.uid}', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    if (!controller.isReal)
                      GestureDetector(
                        onTap: () {
                          if (controller.masterUid == 0) return;
                          RH.toPersonalView(uid: controller.masterUid, name: controller.masterName, avatar: controller.masterAvatar, accountType: 0);
                        },
                        child: Row(
                          children: [
                            SizedBox(width: 12),
                            Text('Creator:', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                            SizedBox(width: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedImage(
                                imageUrl: controller.masterAvatar,
                                fit: BoxFit.cover,
                                width: 16,
                                height: 16,
                                errorWidget: (context, url, error) => Container(color: Colors.grey, height: 16, width: 16),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(controller.masterName, style: TextStyle(color: Color(0xFFFFEF3B), fontSize: 10, fontWeight: FontWeight.w500)),
                            Icon(Icons.arrow_forward_ios, color: Color(0xFFFFEF3B), size: 10),
                          ],
                        ),
                      ),
                  ],
                ),
                // SizedBox(height: 12),
                // Row(
                //   children: [
                //     Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(controller.linkNum, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                //         Text(
                //           Security.security_connectors,
                //           style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w500),
                //         ),
                //       ],
                //     ),
                //     SizedBox(width: 12),
                //     Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(controller.followersNum, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                //         Text(
                //           Security.security_followers,
                //           style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w500),
                //         ),
                //       ],
                //     ),
                //     SizedBox(width: 12),
                //     Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(controller.heatNum, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                //         Text(Security.security_heat, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w500)),
                //       ],
                //     ),
                //   ],
                // ),
                if (controller.characters.isNotEmpty) SizedBox(height: 12),
                if (controller.characters.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        controller.characters
                            .map(
                              (char) => Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withValues(alpha: 0.1),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Text(char, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                              ),
                            )
                            .toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentListSection() =>
      MomentItemView(EMomentListType.MOMENT_LIST_USER, targetUid: controller.uid, canRefresh: false, baseInfo: controller.isMyOc ? controller.baseInfo : null);

  Widget _buildGallerySection() {
    return Obx(
      () =>
          controller.gallery.isNotEmpty
              ? GridView.count(
                padding: EdgeInsets.only(top: 16, left: 16, right: 16),
                physics: const NeverScrollableScrollPhysics(),
                // 1. 禁用GridView自身滚动
                shrinkWrap: true,
                // 2. 适应内容高度
                crossAxisCount: 2,
                mainAxisSpacing: 7,
                crossAxisSpacing: 8,
                childAspectRatio: 168 / 256,
                children:
                    controller.gallery
                        .map(
                          (url) => GestureDetector(
                            onTap: () {
                              Get.toNamed(
                                Routers.imageBrowser,
                                arguments: {Security.security_imageUrl: url, Security.security_canDownload: controller.isReal ? 0 : 1},
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (context, url, error) => Container(color: AppColors.ocMain)),
                            ),
                          ),
                        )
                        .toList(),
              )
              : Container(height: Get.height * 0.5, child: UiUtils.buildCommonEmptyView()),
    );
  }

  Widget _buildFollowButton() {
    return Obx(
      () => GestureDetector(
        onTap: () {
          controller.followAction();
        },
        child: !controller.isFollowed ? _buildButtonContent(false) : _buildButtonContent(true),
      ),
    );
  }

  Widget _buildEditOCButton() {
    return GestureDetector(
      onTap: () {
        RH.toPage(Routers.editOC, args: {Security.security_targetUid: controller.uid});
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Center(
          child: Row(
            spacing: 4,
            children: [
              Icon(Icons.edit, color: Colors.black, size: 14),
              Text(Copywriting.security_edit, style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(bool followed) {
    final color = followed ? Colors.white.withValues(alpha: 0.1) : Color(0xFFFFF37C);
    final textColor = followed ? Colors.white : Color(0xFF07070A);
    final text = followed ? Security.security_followed : Security.security_follow;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color),
      child: Row(
        spacing: 4,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(text, style: TextStyle(color: textColor, fontSize: 14, fontWeight: AppFonts.medium))],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Obx(
            () => Text(controller.bio.isEmpty ? '......' : controller.bio, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void onToChatTap() {
    if (Get.isRegistered<ChatRoomViewController>()) {
      Get.back();
      return;
    }
    RH.toChat(
      id: controller.uid.toString(),
      name: controller.name,
      avatar: controller.avatarUrl,
      coverUrl: controller.background,
      accountType: controller.accountType,
    );
  }
}

// Tab栏的委托类
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Obx tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Column(children: [Container(color: Colors.black, padding: EdgeInsets.only(left: 16, right: 16, bottom: 4), child: tabBar)]);
  }

  @override
  double get maxExtent => 40;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class PersonViewController extends GetxController {
  PersonViewController(Map<String, dynamic> personInfo) {
    personalInfo.value = personInfo;
  }

  final personalInfo = <String, dynamic>{}.obs;

  UserManager get userManager => UserManager.instance;

  List get gallery => personalInfo[Security.security_gallery] ?? [];

  Map get userInfo => personalInfo[Security.security_userInfo] ?? {};

  Map get baseInfo => userInfo[Security.security_baseInfo] ?? {};

  String get avatarUrl => baseInfo[Security.security_avatarUrl] ?? '';

  String get background => personalInfo[Security.security_chatBackground] ?? '';

  String get name => baseInfo[Security.security_nickName] ?? '';

  int get uid => baseInfo[Security.security_uid] ?? 0;

  int get followers => personalInfo[Security.security_fansCount] ?? 0;

  int get followings => personalInfo[EncHelper.ps_foloc] ?? 0;

  int get gender => baseInfo[EncHelper.ps_gdr] ?? 0;

  int get birthday => userInfo[EncHelper.ps_bfda] ?? 0;

  int get age => userInfo[EncHelper.ps_ag] ?? 0;

  String get constellation => userInfo[EncHelper.ps_cstat] ?? '';

  String get location => userInfo[EncHelper.ps_lct] ?? '';

  List get education => personalInfo[EncHelper.ps_educat] ?? [];

  String get bio => userInfo[Security.security_bio] ?? '';

  int get star => personalInfo[Security.security_star] ?? 0;
  RxInt rxStar = 0.obs;

  bool get isStarred => rxStar.value == 1 || star == 1;

  set isStarred(bool value) {
    rxStar.value = value ? 1 : 0;
    personalInfo[Security.security_star] = value ? 1 : 0;
  }

  bool get isFollowed => relation & 4 == 4;

  int get relation => personalInfo[Security.security_relation] ?? 0;

  set relation(int value) {
    personalInfo[Security.security_relation] = value;
    personalInfo.refresh();
  }

  bool get isMyOc => masterUid == MyAccount.userId;

  int get masterUid => personalInfo[Security.security_robotInfo]?[Security.security_masterInfo]?[Security.security_uid] ?? 0;

  int get myOcShared => personalInfo[Security.security_robotInfo]?[Security.security_shared] ?? 0;

  int get myOcAudit => personalInfo[Security.security_audit] ?? 0;

  int get accountType => baseInfo[Security.security_accountType] ?? 0;

  bool get isReal => accountType == 0;

  String get masterName => personalInfo[Security.security_robotInfo]?[Security.security_masterInfo]?[Security.security_nickName] ?? '';

  String get masterAvatar => personalInfo[Security.security_robotInfo]?[Security.security_masterInfo]?[Security.security_avatarUrl] ?? '';

  String get linkNum => RoleItem.shortStringForCount(personalInfo[Security.security_heatInfo]?[Security.security_connectors] ?? 0);

  String get heatNum => RoleItem.shortStringForCount(personalInfo[Security.security_heatInfo]?[Security.security_heatValue] ?? 0);

  String get followersNum => RoleItem.shortStringForCount(followers);

  RxList<String> tabsTitle = [Security.security_Gallery].obs;
  RxList<Map> myCompanions = RxList<Map>();

  List get characters {
    List c = personalInfo[Security.security_characters] ?? [];
    return c;
  }

  // String get type {
  //   if (isReal) return ImagePath.real_tag;
  //   if (baseInfo[EncHelper.ps_act] == 1 || baseInfo[EncHelper.ps_act] == 3 || baseInfo[EncHelper.ps_act] == 4) {
  //     return ImagePath.ai_tag;
  //   }
  //   return '';
  // }

  RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (uid == 0) {
      Toast.show(Copywriting.security_no_user_information__getting_back___);
      Get.back();
    }
    getPersonInfo(uid);
    fetchMyCompanions();
  }

  void getPersonInfo(int uid) async {
    loading.value = true;
    ApiResponse response = await UserManager.instance.queryUserInfo(uid);
    if (!response.isSuccess) {
      if (background.isEmpty) Toast.show(response.description);
      return;
    }
    personalInfo.value = UserProfileInfo(response.data[Security.security_param]).data;
    personalInfo.refresh();
    loading.value = false;

    tabsTitle.value =
        isReal
            ? [Security.security_Gallery, Security.security_character, if (!Preferences.instance.isRv) Security.security_moment]
            : [Security.security_Gallery, if (!Preferences.instance.isRv) Security.security_moment];
  }

  Future fetchMyCompanions() async {
    final rsp = await RoleManager.instance.getRoleList(targetUid: uid, pageIndex: 0, pageSize: 200, version: 0, type: RoleListType.custom_ai);
    if (rsp.isSuccess) {
      List rawData = rsp.data[Security.security_param] ?? [];
      myCompanions.value = rawData.cast<Map>();
    }
  }

  Future<void> collectUser() async {
    Toast.loading(status: Copywriting.security_loading___);
    final rtn = await PersonManager.instance.collectUser(uid, 1);
    if (rtn == false) {
      Toast.error(Copywriting.security_fail_to_collect);
      return;
    }
    // getPersonInfo(uid);
    isStarred = true;
    Toast.success(Security.security_collected);
  }

  Future<void> unCollectUser() async {
    Toast.loading(status: Copywriting.security_loading___);
    final rtn = await PersonManager.instance.collectUser(uid, 0);
    if (rtn == false) {
      Toast.error(Copywriting.security_failed_to_unfollow);
      return;
    }
    isStarred = false;
    Toast.success(Security.security_Unfollowed);
  }

  @override
  void onClose() {
    // EventCenter.instance.sendEvent(kRefreshMyCollections, {});
    super.onClose();
  }

  Future<void> followAction() async {
    bool wantedFollow = !isFollowed;
    if (wantedFollow) {
      relation |= 4;
    } else {
      relation &= ~4;
    }
    ApiResponse response = await UserManager.instance.followAction(targetUid: uid, opt: wantedFollow ? 1 : 0);
    if (!response.isSuccess) {
      Toast.show(response.description);
    }
  }
}
