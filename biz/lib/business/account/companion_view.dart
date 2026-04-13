import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/assets/image_view.dart';
import 'package:biz/business/create_center/character_service.dart';
import 'package:bubble_pop_up/bubble_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../base/crypt/copywriting.dart';
import '../../base/crypt/security.dart';
import '../../base/event_center/event_center.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/cached_image.dart';
import '../../shared/app_theme.dart';
import '../../shared/widget/list_status_view.dart';
import '../home_page_lists/list_item.dart';
import '../home_page_lists/role_manager.dart';

const int kCharactersShowInMine = 8;
const int kCrossAxisCount = 3;

class MyCompanionView extends GetView<MyCompanionViewController> {
  MyCompanionView({super.key, int? viewAll}) {
    String vaStr = viewAll?.toString() ?? Get.parameters[Security.security_viewAll] ?? '0';
    controller = Get.put(MyCompanionViewController(viewAll: vaStr == '1'), tag: vaStr);
  }

  @override
  late MyCompanionViewController controller;

  Widget _buildCompanionGridItem(dynamic companion) {
    String uidStr = (companion[Security.security_uid] ?? 0).toString();
    String linkNum = RoleItem.shortStringForCount(companion[Security.security_heatInfo]?[Security.security_connectors] ?? 0);
    String heatNum = RoleItem.shortStringForCount(companion[Security.security_heatInfo]?[Security.security_heatValue] ?? 0);

    int shared = companion[Security.security_robotInfo]?[Security.security_shared] ?? 0;
    int audit = companion[Security.security_audit] ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        RH.toChat(
          id: uidStr,
          name: companion[Security.security_nickname],
          avatar: companion[Security.security_avatarUrl],
          coverUrl: companion[Security.security_coverUrl],
          accountType: companion[Security.security_accountType],
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: CachedImageProvider(companion[Security.security_coverUrl]), fit: BoxFit.cover),
            ),
            child: Column(
              children: [
                Spacer(),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // image: DecorationImage(image: AssetImage(ImagePath.person_img_mask), fit: BoxFit.cover),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              companion[Security.security_nickname],
                              maxLines: 1,
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // AppWidgets.userTag(companion[Security.security_accountType]),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.start,
                      //   children: [
                      //     Row(
                      //       children: [
                      //         Image.asset(IMGP.link_num, width: 12, height: 12).marginOnly(right: 2),
                      //         Text(linkNum, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                      //         SizedBox(width: 4),
                      //         Image.asset(IMGP.heart_count, width: 12, height: 12).marginOnly(right: 2),
                      //         Text(heatNum, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                      //       ],
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(left: 8, top: 8, child: CharacterService.auditTextWidget(shared, audit)),
          Positioned(
            right: 8,
            top: 8,
            child: BubblePopUp(
              key: Key(uidStr),
              config: BubblePopUpConfig(
                baseAnchor: Alignment.bottomCenter, // Position of the arrow's POC on the base widget
                popUpAnchor: Alignment.topCenter, // Position of the arrow on the pop-up widget
                arrowDirection: ArrowDirection.up,
              ),
              popUpColor: Colors.black,
              popUp: Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        ApiResponse ret = await CharacterService.instance.deleteOC(uidStr);
                        if (ret.isSuccess) {
                          controller.myCompanions.remove(companion);
                        }
                      },
                      child: Text(Security.security_delete, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                child: Icon(Icons.more_vert, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionListItem(dynamic companion) {
    String uidStr = (companion[Security.security_uid] ?? 0).toString();
    String linkNum = RoleItem.shortStringForCount(companion[Security.security_heatInfo]?[Security.security_connectors] ?? 0);
    String heatNum = RoleItem.shortStringForCount(companion[Security.security_heatInfo]?[Security.security_heatValue] ?? 0);

    int shared = companion[Security.security_robotInfo]?[Security.security_shared] ?? 0;
    int audit = companion[Security.security_audit] ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        RH.toChat(
          id: uidStr,
          name: companion[Security.security_nickname],
          avatar: companion[Security.security_avatarUrl],
          coverUrl: companion[Security.security_coverUrl],
          accountType: companion[Security.security_accountType],
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Color(0xFF1A181E)),
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetImage(
                    imageUrl: companion[Security.security_coverUrl],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(companion[Security.security_nickname], style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          ImageView(shared == 1 ? "oc_public.png" : "oc_private.png", height: 20, width: 20),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        companion[Security.security_bio],
                        style: TextStyle(color: Color(0xFFB8B7B4), fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).marginSymmetric(horizontal: 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar:
          controller.viewAll
              ? AppBar(
                systemOverlayStyle: SystemUiOverlayStyle.light,
                title: Text('My Companions', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.base_background,
                leading: IconButton(onPressed: Get.back, icon: ImageView(Images.security_back_png, height: 24, width: 24)),
              )
              : null,
      body: Obx(() {
        int showCount = controller.myCompanions.length;

        bool showRequesting = controller.requestingOwnerRole.value == true && showCount == 0;

        if (!showRequesting && showCount == 0) {
          return Container(
            color: AppColors.base_background,
            child: ListStatusView(status: ListStatus.empty, emptyDesc: 'No companions yet, go create one!'),
          );
        }

        return showRequesting
            ? Container(color: AppColors.base_background, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            : ListView.separated(
              itemBuilder: (context, index) {
                return _buildCompanionListItem(controller.myCompanions[index]);
              },
              separatorBuilder: (context, index) => SizedBox(height: 4),
              itemCount: controller.myCompanions.length,
            );
      }),
    );
  }
}

class MyCompanionViewController extends GetxController {
  MyCompanionViewController({this.viewAll = false});

  bool viewAll = false;
  final myCompanions = [].obs;
  RxBool requestingOwnerRole = false.obs;

  Future fetchMyCompanions() async {
    requestingOwnerRole.value = true;
    final rsp = await RoleManager.instance.getRoleList(pageIndex: 0, pageSize: viewAll ? 200 : 50, version: 0, type: RoleListType.custom_ai);
    requestingOwnerRole.value = false;
    if (rsp.isSuccess) {
      myCompanions.value = rsp.data[Security.security_param] ?? [];
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchMyCompanions();
    EventCenter.instance.addListener(Security.security_kDidCreateRole, onEvent);
  }

  @override
  void onClose() {
    super.onClose();
    EventCenter.instance.removeListener(Security.security_kDidCreateRole, onEvent);
  }

  void onEvent(Event e) {
    fetchMyCompanions();
  }
}
