import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/user_manager/user_manager.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/avatar_view.dart';

import '../../base/api_service/api_response.dart';
import '../../base/app_info/app_manager.dart';
import '../../base/event_center/event_center.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/log_util.dart';
import '../../shared/alert.dart';
import '../../shared/interactions.dart';
import '../../shared/toast/toast.dart';
import '../chat/setting/message_setting.dart';
import 'about_view.dart';

class AccountView extends StatelessWidget {
  AccountView({super.key});

  final AccountViewController controller = Get.put(AccountViewController());

  String get avatarUrl => MyAccount.avatar;

  String get nickname => MyAccount.name;

  String get ID => MyAccount.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
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
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 32),
                        child: Column(
                          // spacing: 16,
                          children: [
                            InfoArea(),
                            SizedBox(height: 32),
                            Container(
                              decoration: BoxDecoration(color: Color(0xFF202026), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  _settingItem("About", ImagePath.set_about, toAbout),
                                  _settingItem("Terms of service", ImagePath.set_tos, checkTermsOfService),
                                  _settingItem("Privacy policy", ImagePath.set_privacy, checkPrivacyPolicy),
                                  // _settingItem("Feedback log", ImagePath.ic_feedback_log, feedbackLog),
                                  _settingItem("Account Deletion", ImagePath.set_delete, deleteAccount),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            _logoutView(),
                          ],
                        ),
                      ),
                    ),
                    // _buildFeatureView(),
                  ],
                ),
              ),
            ),
          ),
          // Positioned(
          //   top: 0,
          //   right: 0,
          //   left: 0,
          //   child: SafeArea(
          //     bottom: false,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.end,
          //       children: [
          //         Padding(
          //           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          //           child: GestureDetector(
          //             onTap: () {
          //               Get.toNamed(Routers.editMe);
          //             },
          //             child: Container(
          //               decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Color(0xFF272533)),
          //               padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          //               child: Center(
          //                 child: Row(
          //                   children: [
          //                     Image.asset(ImagePath.ic_edit, width: 16, height: 16),
          //                     Text(Copywriting.security_edit, style: TextStyle(color: Color(0xFFC1C5CD), fontSize: 12, fontWeight: FontWeight.w500)),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _settingItem(String name, String icon, Function() click) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: click,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(width: 12),

            Image.asset(icon, width: 20, height: 20),
            SizedBox(width: 8),

            Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Spacer(),
            Image.asset(ImagePath.ic_arrow_right_circle, width: 20, height: 20),

            SizedBox(width: 12),
          ],
        ),
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
        child: Text("Log out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF8397D))),
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
                  Image.asset(ImagePath.ic_copy, height: 14, width: 14),
                ],
              ),
            ),
          ],
        ),
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

  // buildCurrencyRow() => Row(
  //   children: [
  //     Expanded(
  //       child: GestureDetector(
  //         onTap: () async {
  //           await RH.toGems();
  //         },
  //         child: Container(
  //           height: 48,
  //           decoration: BoxDecoration(color: Color(0xFF1F222E), borderRadius: BorderRadius.all(Radius.circular(12))),
  //           child: Row(
  //             children: [
  //               SizedBox(width: 12),
  //               Image.asset(ImagePath.ic_diamond, width: 24, height: 24),
  //               SizedBox(width: 4),
  //               Obx(() => Text(MyAccount.gems.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
  //               Spacer(),
  //               Image.asset(ImagePath.ic_arrow_right_circle, width: 16, height: 16),
  //               SizedBox(width: 12),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //     SizedBox(width: 11),
  //     Expanded(
  //       child: GestureDetector(
  //         onTap: () async {
  //           await RH.toCoins();
  //         },
  //         child: Container(
  //           height: 48,
  //           decoration: BoxDecoration(color: Color(0xFF1F222E), borderRadius: BorderRadius.all(Radius.circular(12))),
  //           child: Row(
  //             children: [
  //               SizedBox(width: 12),
  //               Image.asset(ImagePath.ic_coin, width: 24, height: 24),
  //               SizedBox(width: 4),
  //               Obx(() => Text(MyAccount.coins.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
  //               Spacer(),
  //               Image.asset(ImagePath.ic_arrow_right_circle, width: 16, height: 16),
  //               SizedBox(width: 12),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   ],
  // );

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

  // Widget premiumArea() {
  //   return GestureDetector(
  //     onTap: () {
  //       Get.toNamed(Routers.rechargePremium);
  //     },
  //     child: Container(
  //       padding: EdgeInsets.all(1),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.all(Radius.circular(12)),
  //         gradient: LinearGradient(
  //           colors: [
  //             Colors.white.withValues(alpha: 0),
  //             Colors.white.withValues(alpha: 0),
  //             Colors.white.withValues(alpha: 0.6),
  //             Colors.white.withValues(alpha: 0),
  //             Colors.white.withValues(alpha: 0),
  //           ],
  //         ),
  //       ),
  //       child: Container(
  //         height: 54,
  //         padding: EdgeInsets.symmetric(horizontal: 12),
  //         decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF8E588), Color(0xffF66CAB)]), borderRadius: BorderRadius.circular(12)),
  //         child: Row(
  //           spacing: 8,
  //           children: [
  //             Image.asset(ImagePath.ic_freelie_pro, height: 24, width: 24),
  //             Expanded(
  //               child: Text(
  //                 !MyAccount.isSubscribed ? "Feelie Pro" : MyAccount.premName,
  //                 style: TextStyle(color: Color(0xFFE83887), fontSize: 14, fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //             Obx(
  //                   () =>
  //               MyAccount.isSubscribed
  //                   ? Row(
  //                 spacing: 4,
  //                 children: [
  //                   Text(Copywriting.security_expires_on, style: TextStyle(color: AppColors.mainLightColor, fontSize: 14, fontWeight: FontWeight.bold)),
  //                   Text(
  //                     CalendarHelper.formatDate(date: MyAccount.premEdTm) ?? EncHelper.rcg_err,
  //                     style: const TextStyle(color: AppColors.mainLightColor, fontSize: 14, fontWeight: FontWeight.bold),
  //                   ),
  //                   SizedBox(width: 4),
  //                   Image.asset(ImagePath.ic_arrow_right_circle, height: 16, width: 16),
  //                 ],
  //               )
  //                   : Container(
  //                 height: 32,
  //                 padding: EdgeInsets.symmetric(horizontal: 12),
  //                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
  //                 alignment: Alignment.center,
  //                 child: Text(Security.security_Subscribe, style: TextStyle(color: Color(0xFFE83887), fontSize: 14, fontWeight: FontWeight.bold)),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
  //       //   child: Image.asset(ImagePath.ic_mine_create, height: 24, width: 24),
  //       // ),
  //     ],
  //   );
  // }

  // _buildFeatureView() {
  //   return Obx(
  //         () =>
  //     controller.myCompanionViewController.myCompanions.isEmpty
  //         ? SliverToBoxAdapter(
  //       child: Column(
  //         children: [
  //           Image.asset(ImagePath.img_empty, height: 180, width: 180),
  //           GestureDetector(
  //             onTap: () {
  //               CreateOcDialog.show();
  //             },
  //             child: Container(
  //               alignment: Alignment.center,
  //               height: 42,
  //               width: 134,
  //               decoration: BoxDecoration(color: Color(0xFFFFE407), borderRadius: BorderRadius.all(Radius.circular(12))),
  //               child: Text("Go Create", style: TextStyle(color: Color(0xFF0F0F0F), fontSize: 16, fontWeight: FontWeight.bold)),
  //             ),
  //           ),
  //         ],
  //       ),
  //     )
  //         : SliverPadding(
  //       padding: EdgeInsets.only(bottom: 16, right: 16, left: 16, top: 8),
  //       sliver: SliverGrid.count(
  //         crossAxisCount: 3,
  //         crossAxisSpacing: 8,
  //         mainAxisSpacing: 8,
  //         childAspectRatio: 112 / 180,
  //         children: controller.myCompanionViewController.myCompanions.map((item) => _buildCompanionItem(item)).toList(),
  //       ),
  //     ),
  //   );
  // }

  // Widget menuArea() {
  //   return Container(
  //     decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: [
  //             //
  //             InkWell(
  //               onTap: () async {
  //                 await RH.toTask();
  //                 UserManager.instance.queryUserReminders();
  //               },
  //               child: Stack(
  //                 children: [
  //                   Column(
  //                     children: [
  //                       Image.asset(ImagePath.ic_mine_task, width: 28, height: 28),
  //                       // Icon(Icons.task, color: Colors.white),
  //                       SizedBox(height: 4),
  //                       Text(Copywriting.security_daily_Task, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
  //                     ],
  //                   ),
  //                   Positioned(
  //                     right: 5,
  //                     top: 3,
  //                     child: Obx(() {
  //                       return UserManager.instance.taskReminder.value
  //                           ? Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle))
  //                           : Container();
  //                     }),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             InkWell(
  //               onTap: () {
  //                 RH.toPage(
  //                   Routers.webView,
  //                   args: {Security.security_title: '', Security.security_url: AppManager.instance.notificationUrl, Security.security_hideHeader: 1},
  //                 );
  //               },
  //               child: Stack(
  //                 children: [
  //                   Column(
  //                     children: [
  //                       Image.asset(ImagePath.ic_mine_notification, width: 28, height: 28),
  //                       SizedBox(height: 4),
  //                       Text(Security.security_notifications, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
  //                     ],
  //                   ),
  //                   Positioned(
  //                     right: 5,
  //                     top: 3,
  //                     child: Obx(() {
  //                       return UserManager.instance.notificationReminder.value
  //                           ? Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle))
  //                           : Container();
  //                     }),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             InkWell(
  //               onTap: () {
  //                 Get.toNamed(Routers.collections, arguments: {});
  //               },
  //               child: Column(
  //                 children: [
  //                   Image.asset(ImagePath.ic_mine_collection, width: 28, height: 28),
  //                   SizedBox(height: 4),
  //                   Text(Security.security_collections, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
  //                 ],
  //               ),
  //             ),
  //             InkWell(
  //               onTap: () {
  //                 L.uploadIfNeed();
  //                 Get.toNamed(Routers.webView, arguments: {Security.security_title: '', Security.security_url: Preferences.instance.dcLink});
  //               },
  //               child: Column(
  //                 children: [
  //                   // Icon(Icons.feedback, color: Colors.white),
  //                   Image.asset(ImagePath.ic_mine_feedback, width: 28, height: 28),
  //                   SizedBox(height: 4),
  //                   Text(Security.security_feedback, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         // Row(
  //         //   children: [
  //         //
  //         //   ],
  //         // )
  //       ],
  //     ),
  //   );
  // }

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

class AccountViewController extends GetxController with GetTickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  late TabController tabController;

  var tabNames = [
    // Copywriting.security_my_Companion,
    // , Copywriting.security_group_Chat
  ];

  @override
  void onInit() {
    super.onInit();
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
