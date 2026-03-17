import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/business/crowd/crowd_manager.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/core/util/ui_util.dart';
import '../../base/api_service/api_request.dart';
import '../../base/api_service/api_response.dart';
import '../../base/api_service/api_service.dart';
import '../../base/assets/image_path.dart';
import '../../base/assets/image_view.dart';
import '../../base/crypt/apis.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/security.dart';
import '../../shared/app_theme.dart';
import '../../shared/widget/keep_alive_wrapper.dart';
import '../../shared/widget/title_bar.dart';
import 'create_crowed_logic.dart';
import 'package:collection/collection.dart';
import 'package:biz/core/util/collections_util.dart';

class CreateCrowedPage extends GetView<CreateCrowedLogic> {
  const CreateCrowedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          onPressed: RouteHelper.back,
          icon: ImageView("back.png", height: 24, width: 24),
        ),
        backgroundColor: Colors.transparent,
        title: Text(Copywriting.security_create_Group, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Copywriting.security_sF_Pro_bold, fontWeight: FontWeight.bold),
      ),
      ),
      body: _buildBodyView(context),
    );
  }

  Widget _buildBodyView(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildNameView(),
          SizedBox(height: 24),
          ..._buildMemberView(),
          SizedBox(height: 24),
          ..._buildScenarioView(),
          Spacer(),
          _buildCreateView(),
        ],
      ).marginSymmetric(horizontal: 16),
    );
  }

  List<Widget> _buildNameView() {
    return [
      Text(
        Copywriting.security_group_Name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      Container(
        height: 44,
        margin: EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF272533),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Center(
          child: TextField(
            focusNode: controller.nameFocusNode,
            controller: controller.nameTextController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: Copywriting.security_enter_the_group_name,
              isCollapsed: true,
              hintStyle: TextStyle(color: Color(0xFF636268), fontSize: 13),
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
            style: const TextStyle(color: Colors.white, fontSize: 12),
            onChanged: (value) {
              controller.rxNameText.value = value;
            },
          ),
        ),
      ),
    ];
  }

  Widget _buildOwnerView() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: CachedImage.clipImage(
                imageUrl: MyAccount.avatar,
                width: 52,
                height: 52,
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  Security.security_owner,
                  style: TextStyle(
                    color: Color(0xFF727272),
                    fontSize: 9,
                    height: 16 / 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Image.asset('assets/images/message/group/ic_group_owner.webp', width: 24, height: 24, package: Security.security_app_common)
          ],
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          constraints: BoxConstraints(maxWidth: 56),
          child: Text(
            MyAccount.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 16 / 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreView() {
    return GestureDetector(
      onTap: () async {
        Get.bottomSheet(
          RolePanelView(
            controller.rxSelectRoleList,
            controller.addOrRemoveRoleItem,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF1B1E25),
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            alignment: Alignment.center,
            child: ImageView("chat_add.png", width: 24, height: 24),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMemberView() {
    return [
      Text(
        Copywriting.security_group_Member,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 10),
      Obx(() {
        return GridView.count(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          childAspectRatio: 60 / 80,
          shrinkWrap: true,
          children: [
            _buildOwnerView(),
            ...(controller.rxSelectRoleList
                .map((element) => _buildSelectRole(element))
                .toList()),
            _buildAddMoreView(),
          ],
        );
      }),
    ];
  }

  Widget _buildSelectRole(Map<dynamic, dynamic> roleItem) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: CachedImage.clipImage(
                imageUrl:
                    roleItem[Security.security_userBase]?[Security.security_avatarUrl] ?? '',
                width: 52,
                height: 52,
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  controller.addOrRemoveRoleItem(roleItem);
                },
                child: ImageView(
                  "ic_chat_msg_delete.png",
                  width: 16,
                  height: 16,
                ),
              ),
            ),
            // Image.asset('assets/images/message/group/ic_group_owner.webp', width: 24, height: 24, package: Security.security_app_common)
          ],
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          constraints: BoxConstraints(maxWidth: 56),
          child: Text(
            roleItem[Security.security_userBase]?[Security.security_nickName] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 16 / 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildScenarioView() {
    return [
      Text(
        Copywriting.security_group_Scenario,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      Container(
        height: 132,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF272533),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: TextField(
          controller: controller.scenarioTextController,
          focusNode: controller.scenarioFocusNode,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: Copywriting.security_enter_the_Group_Scenario,
            isCollapsed: true,
            hintStyle: const TextStyle(color: Color(0xFF636268), fontSize: 12),
          ),
          maxLines: null,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          onChanged: (value) {
            controller.rxScenarioText.value = value;
          },
          onSubmitted: (value){
            controller.scenarioFocusNode.unfocus();
          },
        ),
      ),
    ];
  }

  Widget _buildCreateView() {
    return Obx(() {
      return GestureDetector(
        onTap: () {
          controller.createGroup();
        },
        child: SafeArea(
          bottom: true,
          child: Opacity(
            opacity: controller.canCreate ? 1 : 0.4,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16, top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    Copywriting.security_create_Group,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 4),
                  CrowedManager.instance.createCostValue == 0
                      ? (MyAccount.isSubscribed
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ImageView(
                                "premium.png",
                                width: 16,
                                height: 16,
                              ),
                              Text(
                                '${MyAccount.freeCrowedLeftTimes == -1 ? "∞" : "(${MyAccount.freeCrowedUsedTimes}/${(MyAccount.freeCrowedLeftTimes + MyAccount.freeCrowedUsedTimes)})"} free',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            ' Free',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ))
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ImageView(
                            CrowedManager.instance.createCostType == 0
                                ? "coin.png"
                                : "gem.png",
                            width: 16,
                            height: 16,
                          ),
                          Text(
                            ' ${CrowedManager.instance.createCostValue}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class RolePanelView extends StatefulWidget {
  final RxSet<dynamic> rxSelectRoleList;

  final ValueChanged<Map<dynamic, dynamic>> addOrRemoveCallBack;

  const RolePanelView(
    this.rxSelectRoleList,
    this.addOrRemoveCallBack, {
    super.key,
  });

  @override
  State<RolePanelView> createState() => _RolePanelViewState();
}

class _RolePanelViewState extends State<RolePanelView>
    with SingleTickerProviderStateMixin {
  final List<String> tabNames = [Copywriting.security_contact_List, Copywriting.security_my_OCs];

  late TabController tabController;

  RxInt currentIndex = 0.obs;

  @override
  void initState() {
    tabController = TabController(vsync: this, length: tabNames.length);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF202028),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.all(16),
        height: 682,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  Copywriting.security_add_Group_Member,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsets.symmetric(vertical: 6),
                  width: double.infinity,
                  child: TabBar(
                    tabs: tabNames.mapIndexed(_buildTab).toList(),
                    controller: tabController,
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    onTap: (index) {
                      currentIndex.value = index;
                    },
                    labelPadding: const EdgeInsets.only(right: 8),
                    indicatorColor: Colors.transparent,
                    indicator: const BoxDecoration(),
                    indicatorPadding: EdgeInsets.zero,
                    indicatorWeight: 0,
                    dividerHeight: 0,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: tabNames.mapIndexed(_buildItemView).toList(),
                  ),
                ),
              ],
            ),
            Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: RouteHelper.back,
                  child: ImageView("ic_close.png", width: 24, height: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String name) {
    return Obx(() {
      bool isSelected = currentIndex.value == index;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Color(0xFF272533),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Color(0xFFABABAD),
          ),
        ),
      );
    });
  }

  Widget _buildItemView(int index, String name) {
    return KeepAliveWrapper(child: _buildRoleList(index + 1));
  }

  Future<List<dynamic>> getRoleListByType(int type) async {
    ApiRequest request = ApiRequest(Apis.security_getCharacterSelectList,
      params: {Security.security_pageSize: 50, Security.security_listType: type},
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      return response.data[Security.security_param] ?? [];
    }
    return [];
  }

  Widget _buildRoleList(int type) {
    return UiUtils.buildFutureView<List<dynamic>?>(getRoleListByType(type), (
      data,
      context,
    ) {
      if (data == null || data.isNullOrEmpty()) {
        return UiUtils.buildCommonEmptyView();
      } else {
        return ListView.builder(
          itemBuilder: (context, index) {
            return _buildItem(data.safeGet(index, {}));
          },
          itemCount: data.length,
        );
      }
    });
  }

  Widget _buildItem(Map<dynamic, dynamic> roleItem) {
    return InkWell(
      onTap: () {
        widget.addOrRemoveCallBack.call(roleItem);
      },
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.ocBox,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CachedImage.clipImage(
              imageUrl:
                  roleItem[Security.security_userBase]?[Security.security_avatarUrl] ?? '',
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
            ),
            SizedBox(width: 10),
            Text(
              roleItem[Security.security_userBase]?[Security.security_nickName] ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            Obx(() {
              bool isSelect = widget.rxSelectRoleList.any(
                (element) =>
                    (element[Security.security_userBase]?[Security.security_uid] ?? 0) ==
                    (roleItem[Security.security_userBase]?[Security.security_uid] ?? 0),
              );
              return ImageView(
                isSelect ? "ic_check.png" : "ic_uncheck.png",
                height: 24,
                width: 24,
              );
            }),
          ],
        ),
      ),
    );
  }
}
