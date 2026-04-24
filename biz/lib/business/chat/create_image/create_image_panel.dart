import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/privacy/ai_consent_service.dart';
import 'package:biz/business/chat/chat_room/chat_room_view.dart';
import 'package:biz/business/chat/create_image/create_image_manager.dart';
import 'package:biz/shared/widget/balance_view.dart';
import 'package:biz/shared/widget/list_status_view.dart';

import '../../../base/assets/image_view.dart';
import '../../../base/router/router_names.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/toast/toast.dart';

class CreateImagePanel extends GetView<CreateImagePanelController> {
  CreateImagePanel({super.key});

  CreateImagePanelController get viewController => controller;

  Widget buildTabBar() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: viewController.config.value.prompts.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            if (viewController.selectedIndex.value != index) {
              viewController.selectedIndex.value = index;
              viewController.pageController.jumpToPage(index);
            }
          },
          child: Center(
            child: Obx(
              () => Container(
                decoration:
                    (index == viewController.selectedIndex.value)
                        ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        )
                        : null,
                padding:
                    (index == viewController.selectedIndex.value)
                        ? const EdgeInsets.symmetric(horizontal: 8)
                        : EdgeInsets.zero,
                alignment: Alignment.center,
                child: Text(
                  viewController.config.value.prompts[index].name,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        (index == viewController.selectedIndex.value)
                            ? const Color(0xFF07070A)
                            : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(width: 24);
      },
    );
  }

  Widget buildTabBarView() {
    return PageView.builder(
      controller: viewController.pageController,
      onPageChanged: (index) {
        viewController.selectedIndex.value = index;
      },
      itemBuilder: (context, index) {
        return Column(
          children: [
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF252329),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        viewController.config.value.prompts[index].tags
                            .map(
                              (e) => GestureDetector(
                                onTap: () {
                                  if (viewController
                                          .config
                                          .value
                                          .prompts[index]
                                          .selectedItem
                                          .value ==
                                      e) {
                                    viewController
                                        .config
                                        .value
                                        .prompts[index]
                                        .selectedItem
                                        .value = null;
                                    viewController.config.refresh();
                                  } else {
                                    viewController
                                        .config
                                        .value
                                        .prompts[index]
                                        .selectedItem
                                        .value = e;
                                    viewController.config.refresh();
                                  }
                                },
                                child: Obx(
                                  () => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration:
                                        (e ==
                                                viewController
                                                    .config
                                                    .value
                                                    .prompts[index]
                                                    .selectedItem
                                                    .value)
                                            ? BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            )
                                            : BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.white10,
                                            ),
                                    child: Text(
                                      e[Security.security_desc] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color:
                                            (e ==
                                                    viewController
                                                        .config
                                                        .value
                                                        .prompts[index]
                                                        .selectedItem
                                                        .value)
                                                ? Color(0xFF07070A)
                                                : const Color(0xFFA19C9A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      itemCount: viewController.config.value.prompts.length,
    );
  }

  Widget buildCreateImageButton() {
    return SafeArea(
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: () {
            viewController.createImage();
          },
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(0xFFFFF37C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Security.security_Create,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF07070A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ImageView(
                    viewController.currencyIcon,
                    width: 16,
                    height: 16,
                  ),
                ),
                Text(
                  viewController.price.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF07070A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 568,
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: BoxDecoration(
          color: Color(0xFF1A181E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Copywriting.security_images_you_like,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      BalanceView(
                        type: BalanceType.coin,
                        style: BalanceViewStyle(
                          color: AppColors.primary,
                          bgColor: Colors.white10,
                          borderRadius: 8,
                          height: 24,
                          padding: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.white10),
                SizedBox(
                  height: 44,
                  child: TabBar(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    labelPadding: EdgeInsets.only(right: 24),
                    controller: viewController.tabController,
                    onTap: (index) {
                      viewController.onTypeChanged(index);
                    },
                    dividerColor: Colors.transparent,
                    indicator: const BoxDecoration(),
                    indicatorPadding: EdgeInsets.zero,
                    indicatorWeight: 0,
                    tabs:
                        [
                          Security.security_select,
                          Security.security_enter,
                        ].map((e) {
                          final index = [
                            Security.security_select,
                            Security.security_enter,
                          ].indexOf(e);
                          return Tab(
                            child: Obx(() {
                              bool isSelected =
                                  viewController.typeIndex.value == index;
                              return Stack(
                                alignment: Alignment.bottomRight,
                                clipBehavior: Clip.none,
                                children: [
                                  Text(
                                    e,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Color(0xFFA19C9A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Positioned(
                                  //     bottom: -6,
                                  //     child: isSelected
                                  //         ? Image.asset(ImagePath.tab_selected, width: 40, height: 10)
                                  //         : SizedBox()
                                  // )
                                ],
                              );
                            }),
                          );
                        }).toList(),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () =>
                        viewController.typeIndex.value == 0
                            ? buildSelectView()
                            : buildEnterView(),
                  ),
                ),
                Obx(
                  () =>
                      viewController.listStatus.value == ListStatus.success
                          ? buildCreateImageButton()
                          : SizedBox.shrink(),
                ),
              ],
            ),
            Obx(() => ListStatusView(status: viewController.listStatus.value)),
          ],
        ),
      ),
    );
  }

  Widget buildEnterView() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: viewController.promptController,
        maxLines: 10,
        style: TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText:
              Copywriting
                  .security_enter_your_image_prompt__e_g__A_girl__sitting_on_a_bench___,
          hintStyle: TextStyle(color: Color(0xFF66676D), fontSize: 14),
          labelStyle: TextStyle(color: Colors.white, fontSize: 14),
          hintMaxLines: 3,
          filled: true,
          fillColor: Color(0xFF252329),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget buildSelectView() {
    return Column(
      children: [
        SizedBox(height: 8),
        SizedBox(height: 28, child: Obx(() => buildTabBar())),
        SizedBox(height: 12),
        Expanded(child: Obx(() => buildTabBarView())),
        SizedBox(height: 8),
        Container(
          height: 32,
          child: Obx(
            () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (ctx, index) {
                Map<String, dynamic> item =
                    viewController.selectedItems[index] ?? {};
                if (item.isEmpty) return SizedBox();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item[Security.security_desc] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF07070A),
                    ),
                  ),
                ).marginOnly(right: 8);
              },
              itemCount: viewController.selectedItems.length,
            ),
          ),
        ),
      ],
    );
  }
}

class CreateImagePanelController extends GetxController
    with GetTickerProviderStateMixin {
  var listStatus = ListStatus.idle.obs;
  var config = CreateImageConfig.none().obs;
  var selectedIndex = 0.obs;
  var pageController = PageController();
  late TabController tabController;
  RxInt typeIndex = 0.obs;
  TextEditingController promptController = TextEditingController();

  int get price {
    return config.value.price;
  }

  String get currencyIcon {
    if (config.value.type == 1) {
      return Images.security_gem_png;
    } else {
      return Images.security_coin_png;
    }
  }

  @override
  void onInit() {
    super.onInit();
    AIConsentService.promptForEntryIfNeeded(
      feature: AIConsentFeature.imageGeneration,
    );
    tabController = TabController(length: 2, vsync: this);
    getCreateImageConfigs();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void getCreateImageConfigs() async {
    if (config.value.prompts.isEmpty &&
        listStatus.value != ListStatus.loading) {
      listStatus.value = ListStatus.loading;
    }

    int userId = Get.find<ChatRoomViewController>().userId;

    CreateImageConfig result = await CreateImageManager.instance
        .getCreateImageConfigs(userId);

    if (result.success) {
      listStatus.value =
          result.prompts.isEmpty ? ListStatus.empty : ListStatus.success;
      if (result.prompts.isNotEmpty) {
        selectedIndex.value = 0;
      }
    } else {
      listStatus.value = ListStatus.error;
    }
    config.value = result;
  }

  void createImage() async {
    final agreed = await AIConsentService.ensureConsent(
      feature: AIConsentFeature.imageGeneration,
    );
    if (!agreed) {
      return;
    }

    List options = [];
    String imgPrompt = promptController.text;
    if (typeIndex.value == 0) {
      for (var element in config.value.prompts) {
        if (element.selectedItem.value != null) {
          options.add(element.selectedItem.value);
        }
      }
      if (options.isEmpty) {
        Toast.show(Copywriting.security_please_select_at_least_one_prompt);
        return;
      }
    } else {
      if (imgPrompt.isEmpty) {
        Toast.show(Copywriting.security_image_prompt_cannot_be_empty);
        return;
      }
    }

    Toast.loading(status: Copywriting.security_generating_in_progress);
    ApiResponse response = await CreateImageManager.instance.createImage(
      Get.find<ChatRoomViewController>().userId,
      options,
      imgPrompt,
    );
    if (response.isSuccess) {
      Toast.dismiss();
      //关闭弹窗
      // Get.back();
      Get.until((route) => route.settings.name == Routers.chat);
    } else {
      Toast.error(response.description);
    }
  }

  onTypeChanged(int index) {
    typeIndex.value = index;
  }

  List get selectedItems =>
      config.value.prompts.map((e) {
        return e.selectedItem.value;
      }).toList();
}
