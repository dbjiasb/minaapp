import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/crowd/info/controller.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/shared/app_theme.dart';

import '../../../base/assets/image_path.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/router/route_helper.dart';
import '../../../base/router/router_names.dart';
import '../../../shared/widget/title_bar.dart';
import '../create_crowed_page.dart';

class CrowedInfoView extends GetView<CrowedInfoController> {
  const CrowedInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: ImageView("back.png", height: 24, width: 24),
        ),
        backgroundColor: Colors.transparent,
        title: StyleTabBars(
          titles: [Copywriting.security_group_Info],
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        ),
        actions: [_buildEditAction()],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildEditAction() {
    return Obx(() {
      return InkWell(
        onTap: () {
          if (controller.editing.value) {
            controller.updateCrowInfo();
          } else {
            controller.editing.value = true;
          }
        },
        child:
            controller.editing.value
                ? Text(
                  Security.security_save,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ).marginOnly(right: 16)
                : Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF272533),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.white),
                      Text(
                        Copywriting.security_edit,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
      );
    });
  }

  Widget _buildCrowInfo() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0x0DFFFFFF),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedImage.clipImage(
                  imageUrl: controller.rxCrowInfo.value.avatar,
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(22),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Obx(() {
                    return Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            controller.editing.value
                                ? Color(0xFF272533)
                                : Colors.transparent,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: controller.nameController,
                        enabled: controller.editing.value,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: Copywriting.security_edit_Group_Name,
                          isCollapsed: true,
                          hintStyle: TextStyle(
                            color: Color(0xFFABABAD),
                            fontSize: 12,
                          ),
                        ),
                        inputFormatters: [LengthLimitingTextInputFormatter(40)],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        onChanged: (value) {
                          controller.rxNameText.value = value;
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
            SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color:
                    controller.editing.value
                        ? Color(0xFF272533)
                        : Colors.transparent,
                borderRadius: BorderRadius.all(Radius.circular(13)),
              ),
              constraints: const BoxConstraints(minHeight: 50),
              child: TextField(
                controller: controller.scenarioController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: Copywriting.security_edit_Group_Scenario,
                  isCollapsed: true,
                  hintStyle: TextStyle(color: Color(0xFFABABAD), fontSize: 12),
                  enabled: controller.editing.value,
                ),
                maxLines: 6,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                style: const TextStyle(color: Color(0xFFABABAD), fontSize: 11),
                onChanged: (value) {
                  controller.rxScenarioText.value = value;
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMemberView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(() {
        bool edit = controller.editing.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  Copywriting.security_group_Member,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${controller.rxCrowInfo.value.members.length}',
                  style: TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  dynamic member = controller.rxCrowInfo.value.members[index];
                  bool isOwner = member[Security.security_role] == 1;
                  bool isPremiumOnly = member[Security.security_premiumOnly] == 1;
                  bool isActiveVip = MyAccount.isSubscribed;
                  bool isDeactivated = member[Security.security_state] == 3;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          RouteHelper.toPage(
                            Routers.person,
                            args: {
                              Security.security_personInfo: {
                                Security.security_userInfo: {
                                  Security.security_baseInfo: {
                                    Security.security_uid:
                                        member[Security.security_userbase][Security
                                            .security_uid],
                                    Security.security_nickName:
                                        member[Security.security_userbase][Security
                                            .security_nickName],
                                    Security.security_avatarUrl:
                                        member[Security.security_userbase][Security
                                            .security_avatarUrl],
                                    Security.security_accountType:
                                        member[Security.security_userbase][Security
                                            .security_accountType],
                                  },
                                },
                              },
                            },
                          );
                        },
                        child: CachedImage.clipImage(
                          imageUrl:
                              member[Security.security_userbase]?[Security
                                  .security_avatarUrl] ??
                              "",
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${member[Security.security_userbase]?[Security.security_nickName] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 20 / 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x0DFFFFFF),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            Copywriting.security_group_Owner,
                            style: TextStyle(
                              color: Color(0xFFFFEF3B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).marginOnly(left: 4),
                      if (isPremiumOnly)
                        ImageView(
                          "premium.png",
                          width: 16,
                          height: 16,
                        ).marginOnly(left: 4),
                      if (isPremiumOnly && !isActiveVip) //会员可聊过期
                        GestureDetector(
                          onTap: () {
                            RH.toPremium();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x0DF8F8F8),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              Security.security_expired,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ).marginOnly(left: 4),
                        ),
                      if (isDeactivated) //UGC私有
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x0DF8F8F8),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            Security.security_deactivated,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).marginOnly(left: 4),
                      const Spacer(),
                      if (!isOwner && edit)
                        InkWell(
                          onTap: () async {
                            controller.tryRemoveMember(member);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 6,
                            ),
                            child: ImageView(
                              "ic_chat_msg_delete.png",
                              color: Color(0xFFF84652),
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 20);
                },
                itemCount: controller.rxCrowInfo.value.members.length,
              ),
            ),
            if(controller.editing.value)
            _buildAddMemberView(),
          ],
        );
      }),
    );
  }

  Widget _buildAddMemberView() {
    return GestureDetector(
      onTap: () {
        Get.bottomSheet(
          RolePanelView(
            controller.rxSelectRoleList,
            controller.addOrRemoveRoleItem,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1B1E25),
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: Center(
              child: ImageView("chat_add.png", width: 24, height: 24),
            ),
          ).marginOnly(right: 8),
          Text(
            Copywriting.security_add_New_Group_Member,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisbandButton() {
    return GestureDetector(
      onTap: () async {
        controller.tryDisband();
      },
      child: SafeArea(
        bottom: true,
        child: Container(
          margin: EdgeInsets.only(top: 30),
          padding: const EdgeInsets.symmetric(vertical: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFF272533),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          child: Center(
            child: Text(
              Copywriting.security_disband_Group,
              style: TextStyle(
                color: Color(0xFFF84652),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildCrowInfo(),
        SizedBox(height: 12),
        Expanded(child: _buildMemberView()),
        _buildDisbandButton(),
      ],
    ).marginSymmetric(horizontal: 16, vertical: 12);
  }
}
