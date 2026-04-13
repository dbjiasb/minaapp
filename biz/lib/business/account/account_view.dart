import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/user_manager/user_manager.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/avatar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../base/api_service/api_response.dart';
import '../../base/app_info/app_manager.dart';
import '../../base/event_center/event_center.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/cached_image.dart';
import '../../core/util/calendar_helper.dart';
import '../../core/util/log_util.dart';
import '../../shared/alert.dart';
import '../../shared/interactions.dart';
import '../../shared/toast/toast.dart';
import '../../shared/widget/keep_alive_wrapper.dart';
import '../../shared/widget/title_bar.dart';
import '../chat/setting/message_setting.dart';
import '../create_center/create_oc_dialog.dart';
import '../create_center/create_oc_rv_dialog.dart';
import '../moment/constant_state.dart';
import '../moment/moment_list_view/moment_item_view.dart';
import 'about_view.dart';
import 'companion_view.dart';
import 'my_group.dart';

class AccountView extends StatelessWidget {
  AccountView({super.key});

  final AccountViewController controller = Get.put(AccountViewController());

  String get avatarUrl => MyAccount.avatar;

  String get nickname => MyAccount.name;

  String get ID => MyAccount.id;

  @override
  Widget build(BuildContext context) {
    StyleTabBars tabBar = StyleTabBars(
      selectedStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      unselectedStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.bold),
      titles: controller.tabNames,
      onTabSelected: (index) {
        controller.pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.linearToEaseOut);
      },
    );
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(systemOverlayStyle: SystemUiOverlayStyle.light, backgroundColor: AppColors.base_background, elevation: 0, toolbarHeight: 0),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(bottom: 0, height: 400, left: 0, right: 0, child: Container(color: AppColors.base_background)),
          Positioned(
            left: 0,
            right: 0,
            top: 32,
            bottom: 0,
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.refreshData();
                },
                child: NestedScrollView(
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Container(
                          padding: EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 8),
                          child: Column(
                            // spacing: 16,
                            children: [
                              InfoArea(),
                              SizedBox(height: 24),
                              premiumArea(),
                              buildCurrencyRow(),
                              SizedBox(height: 12),
                              menuArea(),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(pinned: true, floating: true, delegate: _TabBarDelegate(tabBar)),
                    ];
                  },
                  body: _buildFeatureView(tabBar),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: GestureDetector(
                      onTap: toSetting,
                      child: Icon(
                        Icons.settings, size: 28, color: Colors.white
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutView() {
    return GestureDetector(
      onTap: () {
        logout();
      },
      child: Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Color(0xFF261F1F)),
        child: Text(Copywriting.security_log_out, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF8397D))),
      ),
    );
  }

  void checkTermsOfService() {
    Get.toNamed(
      Routers.webView,
      arguments: {Security.security_title: Copywriting.security_terms_of_service, Security.security_url: AppManager.instance.termsHtml},
    );
  }

  void checkPrivacyPolicy() {
    Get.toNamed(
      Routers.webView,
      arguments: {Security.security_title: Copywriting.security_privacy_policy, Security.security_url: AppManager.instance.privacyHtml},
    );
  }

  void logout() {
    showConfirmAlert(
      Copywriting.security_log_out,
      Copywriting.security_are_you_sure_you_want_to_log_out_,
      onConfirm: () {
        AccountService.instance.logout();
        // Get.offAllNamed(Routers.login);
      },
      onCancel: () {},
    );
  }

  void deleteAccount() async {
    showConfirmAlert(
      Copywriting.security_delete_account_,
      Copywriting.security_are_you_sure_you_want_to_delete_your_account_,
      onConfirm: () async {
        Toast.loading(status: Copywriting.security_deleting___);
        ApiResponse response = await AccountService.instance.deleteAccount();
        Toast.dismiss();
        if (response.isSuccess) {
          RouteHelper.popAllAndToPage(Routers.loginChannel);
        } else {
          Toast.error(response.description);
        }
      },
    );
  }

  void toSetting() {
    Get.toNamed(Routers.setting);
  }

  void messageSettings() {
    RH.toView(MessageSettingView());
  }

  void toAbout() {
    RH.toView(AboutView());
  }

  void feedbackLog() async {
    Toast.loading();
    await L.upload();
    Toast.show(Copywriting.security_upload_Log_success);
  }

  Widget InfoArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarView(url: avatarUrl, size: 72),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Text(
                nickname.isNotEmpty ? nickname : Security.security_user,
                style: TextStyle(color: Color(0xFFFFE407), fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                Interactions.copyToClipboard(ID.toString());
              },
              child: Row(
                spacing: 2,
                children: [
                  Text('ID:$ID', style: TextStyle(color: Color(0xFF7F848F), fontSize: 10, fontWeight: FontWeight.w500)),
                  CachedImage(imageUrl: ImagePath.ic_copy, height: 14, width: 14),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: 16,),
        GestureDetector(
          onTap: () {
            Get.toNamed(Routers.editMe);
          },
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Color(0xFF272533)),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Center(
              child: Row(
                children: [
                  CachedImage(imageUrl: ImagePath.ic_edit, width: 16, height: 16, color: Colors.white),
                  SizedBox(width: 2),
                  Text(Copywriting.security_edit, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  // Widget _buildCurrencyItem(BalanceType type) {
  //   return GestureDetector(
  //     onTap: () {
  //       RH.toRecharge(type.index);
  //     },
  //     child: BalanceView(
  //       type: type == BalanceType.coin ? BalanceType.coin : BalanceType.gem,
  //       style: BalanceViewStyle(color: Colors.white, bgColor: Color(0xff1E1C2A).withValues(alpha: 0.5), height: 30, borderRadius: 12, padding: 8),
  //     ),
  //   );
  // }

  buildCurrencyRow() => Row(
    children: [
      Expanded(
        flex: 1,
        child: GestureDetector(
          onTap: () async {
            await RH.toGems();
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(color: Color(0xFF202026), borderRadius: BorderRadius.all(Radius.circular(12))),
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Copywriting.security_my_Gems, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ImageView(Images.security_gem_png, width: 24, height: 24),
                        SizedBox(width: 4),
                        Obx(() => Text(MyAccount.gems.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60,)
                // CachedImage(imageUrl: ImagePath.ic_arrow_right_circle, width: 20, height: 20),
              ],
            ),
          ),
        ),
      ),
      SizedBox(width: 4),
      Expanded(
        flex: 1,
        child: GestureDetector(
          onTap: () async {
            await RH.toCoins();
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(color: Color(0xFF202026), borderRadius: BorderRadius.all(Radius.circular(12))),
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Copywriting.security_my_Coins, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    // Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     Text(Copywriting.security_my_Coins, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    //     // const Spacer(),
                    //     // CachedImage(imageUrl: ImagePath.ic_arrow_right_circle, width: 20, height: 20),
                    //   ],
                    // ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ImageView(Images.security_coin_png, width: 24, height: 24),
                        SizedBox(width: 4),
                        Obx(() => Text(MyAccount.coins.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60,)
                // CachedImage(imageUrl: ImagePath.ic_arrow_right_circle, width: 20, height: 20),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  // Widget connectionArea() {
  //   return Row(
  //     children: [
  //       InkWell(
  //         onTap: () {
  //           RH.toPage(Routers.relationList, params: {Security.security_type: '0'});
  //         },
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Obx(() => Text(MyAccount.followingNum.value.toString(), style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
  //             SizedBox(height: 4),
  //             Text(Security.security_following, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
  //           ],
  //         ),
  //       ),
  //       SizedBox(width: 32),
  //       InkWell(
  //         onTap: () {
  //           RH.toPage(Routers.relationList, params: {Security.security_type: '1'});
  //         },
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Obx(() => Text(MyAccount.followerNum.value.toString(), style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
  //             SizedBox(height: 4),
  //             Text(Security.security_followed, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
  //           ],
  //         ),
  //       ),
  //       // SizedBox(width: 16,),
  //       // Column(
  //       //   crossAxisAlignment: CrossAxisAlignment.start,
  //       //   children: [
  //       //     Text(
  //       //       MyAccount.followingNum.toString(),
  //       //       style: TextStyle(
  //       //         color: Colors.white,
  //       //         fontSize: 13,
  //       //         fontWeight: FontWeight.bold,
  //       //       ),
  //       //     ),
  //       //     SizedBox(height: 4),
  //       //     Text(
  //       //       'Collections',
  //       //       style: TextStyle(
  //       //         color: Colors.white.withValues(alpha: 0.7),
  //       //         fontSize: 9,
  //       //       ),
  //       //     ),
  //       //   ],
  //       // ),
  //     ],
  //   );
  // }

  Widget premiumArea() {
    return GestureDetector(
      onTap: () {
        RH.toPremium();
      },
      child: Container(
        height: 48,
        padding: EdgeInsets.only(left: 16, right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          image: DecorationImage(image: ImageView.getImageProvider(Images.security_premium_bg_png), fit: BoxFit.cover),
        ),
        child: Row(
          children: [
            ImageView(Images.security_premium_png, height: 24, width: 24).marginOnly(right: 8),
            Text(
              Security.security_vIP,
              style: TextStyle(color: Color(0xFF07070A), fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Spacer(),
            Obx(
              () => MyAccount.isSubscribed
                  ? Row(
                      children: [
                        Text(
                          '${Copywriting.security_expires_on} ${CalendarHelper.formatDate(date: MyAccount.premEdTm) ?? ''}',
                          style: const TextStyle(color: Color(0xFF07070A), fontSize: 14, fontWeight: FontWeight.w600),
                        ).marginOnly(right: 8),
                        ImageView(Images.security_arrow_right_png, height: 16, width: 16, color: Colors.black.withValues(alpha: 0.5)),
                      ],
                    )
                  : Container(
                      height: 24,
                      width: 84,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF171411), Color(0xFF84786C), Color(0xFF07070A)],
                          stops: [0.049, 0.361, 0.879],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(Security.security_Subscribe, style: TextStyle(color: Color(0xFFFFEFDA), fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
            ),
          ],
        ),
      ).marginOnly(bottom: 12),
    );
  }

  // Widget _buildTitleView() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: StyleTabBars(
  //           titles: controller.tabNames,
  //           onTabSelected: (index) {
  //             controller.tabController.index = index;
  //           },
  //         ),
  //       ),
  //       // GestureDetector(
  //       //   onTap: () {
  //       //     CreateOcDialog.show();
  //       //   },
  //       //   child: CachedImage(imageUrl: ImagePath.ic_mine_create, height: 24, width: 24),
  //       // ),
  //     ],
  //   );
  // }

  Widget _buildFeatureView(StyleTabBars tabBar) {
    return Container(
      padding: EdgeInsets.only(top: 4),
      color: AppColors.base_background,
      child: PageView(
        controller: controller.pageController,
        onPageChanged: (index) {
          tabBar.switchToTab(index);
        },
        children: controller.tabPage,
      ),
    );
  }

  Widget menuArea() {
    return Container(
      decoration: BoxDecoration(color: Color(0xFF202026), borderRadius: BorderRadius.all(Radius.circular(12))),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //
              InkWell(
                onTap: () async {
                  await RH.toTask();
                  UserManager.instance.queryUserReminders();
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        ImageView(Images.mina_task, width: 28, height: 28),
                        SizedBox(height: 4),
                        Text(Copywriting.security_daily_Task, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Positioned(
                      right: 5,
                      top: 3,
                      child: Obx(() {
                        return UserManager.instance.taskReminder.value
                            ? Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                            : Container();
                      }),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  RH.toPage(
                    Routers.webView,
                    args: {Security.security_title: '', Security.security_url: AppManager.instance.notificationUrl, Security.security_hideHeader: 1},
                  );
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Icon(Icons.notifications, color: Colors.white),
                        ImageView(Images.mina_notification, width: 28, height: 28),
                        SizedBox(height: 4),
                        Text(Security.security_notifications, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Positioned(
                      right: 5,
                      top: 3,
                      child: Obx(() {
                        return UserManager.instance.notificationReminder.value
                            ? Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                            : Container();
                      }),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Get.toNamed(Routers.collections, arguments: {});
                },
                child: Column(
                  children: [
                    ImageView(Images.mina_collection, width: 28, height: 28),
                    SizedBox(height: 4),
                    Text(Security.security_collections, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  L.uploadIfNeed();
                  Get.toNamed(Routers.webView, arguments: {Security.security_title: '', Security.security_url: Preferences.instance.dcLink});
                },
                child: Column(
                  children: [
                    // Icon(Icons.feedback, color: Colors.white),
                    ImageView(Images.mina_feedback, width: 28, height: 28),
                    SizedBox(height: 4),
                    Text(Security.security_feedback, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          // Row(
          //   children: [
          //
          //   ],
          // )
        ],
      ),
    );
  }

  // Widget _buildCompanionItem(dynamic companion) {
  //   String uidStr = (companion[Security.security_uid] ?? 0).toString();
  //   String bio = (companion[Security.security_bio] ?? 0).toString();
  //   return GestureDetector(
  //     behavior: HitTestBehavior.opaque,
  //     onTap: () {
  //       RH.toChat(
  //         id: uidStr,
  //         name: companion[Security.security_nickname],
  //         avatar: companion[Security.security_avatarUrl],
  //         coverUrl: companion[Security.security_coverUrl],
  //         accountType: companion[Security.security_accountType],
  //       );
  //     },
  //     child: Stack(
  //       children: [
  //         Container(
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(8),
  //             image: DecorationImage(image: CachedImageProvider(companion[Security.security_coverUrl]), fit: BoxFit.cover),
  //           ),
  //           child: Column(
  //             children: [
  //               Spacer(),
  //               Container(
  //                 width: double.infinity,
  //                 padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
  //                 decoration: BoxDecoration(color: AppColors.base_background.withValues(alpha: 0.6)),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       companion[Security.security_nickname],
  //                       maxLines: 1,
  //                       style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //
  //                     if (bio.isNotEmpty) SizedBox(height: 6),
  //                     if (bio.isNotEmpty) Text(bio, style: TextStyle(color: Color(0xFF999999), fontSize: 10, fontWeight: FontWeight.w500), maxLines: 3),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

// Tab栏的委托类
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final StyleTabBars tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.base_background,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: tabBar),
          GestureDetector(
            onTap: () {
              if (Preferences.instance.isRv) {
                CreateOcRvDialog.show();
              } else {
                CreateOcDialog.show();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(colors: [Color(0xFFffee6b), Color(0xFFfff8bf)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ImageView(Images.security_ic_add_create_png, width: 20, height: 20),
                  SizedBox(width: 2),
                  Text(Security.security_create, style: TextStyle(color: Color(0xFF07070a), fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

class AccountViewController extends GetxController with GetTickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  late TabController tabController;
  PageController pageController = PageController();

  List<String> tabNames = ['Companions'].obs;
  RxList<Widget> tabPage = [KeepAliveWrapper(child: MyCompanionView(viewAll: 0))].obs;

  @override
  void onInit() {
    super.onInit();
    if (!Preferences.instance.isRv) {
      tabNames.add(Copywriting.security_group_Chat);
      tabNames.add(Security.security_moment);
      tabPage.add(KeepAliveWrapper(child: MyGroupView()));
      tabPage.add(KeepAliveWrapper(child: MomentItemView(EMomentListType.MOMENT_LIST_USER, targetUid: 0, canRefresh: false)));
    }
    tabController = TabController(vsync: this, length: tabNames.length);

    EventCenter.instance.addListener(kEventCenterUserDidLogin, (_) {
      refreshData();
    });

    refreshData();
  }

  Future refreshData() async {
    await refreshMyInfo();
  }

  Future refreshMyInfo() async {
    AccountService.instance.getPremInfo();
    AccountService.instance.refreshBalance();
    AccountService.instance.queryMyInfo();

    await Future.delayed(Duration(milliseconds: 1000), () {
      UserManager.instance.queryUserReminders();
    });
  }

  Future refreshDataIfNeed() async {
    int lastRefreshTime = Preferences.instance.getInt(Security.security_kPrefLastRefreshTime);
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - lastRefreshTime < 30 * 1000) {
      return;
    }
    refreshData();
    Preferences.instance.setInt(Security.security_kPrefLastRefreshTime, currentTime);
  }
}
