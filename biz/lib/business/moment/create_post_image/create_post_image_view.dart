import 'package:biz/base/assets/image_view.dart';
import 'package:biz/core/util/collections_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/report/report_manager.dart';
import '../../../core/util/cached_image.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/common_widget.dart';
import '../constant_state.dart';
import 'create_post_image_logic.dart';

class CreatePostImagePage extends GetView<CreatePostImageLogic> {
  const CreatePostImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    controller.initArguments();
    ReportManager.sendEvent(Security.security_pv_generate_image, {});
    return Scaffold(
      backgroundColor: Color(0xFF12151C),
      appBar: AppBarExt.darkAppBar(
        returnIconColor: Colors.white,
        backgroundColor: Color(0xFF12151C),
        title: Copywriting.security_generate_for_Moment,
        actions: [
          Obx(() {
            return GestureDetector(
              onTap: () {
                if (controller.rxResInfoList.isNotEmpty) {
                  Get.back(result: controller.rxResInfoList);
                }
              },
              child: Text(
                Security.security_select,
                style: TextStyle(color: controller.rxResInfoList.isNotEmpty ? AppColors.primary : Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ).marginOnly(right: 16),
            );
          }),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Obx(() {
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  controller.loadOldMessage();
                },
                child: ListView.separated(
                  reverse: true,
                  itemCount: controller.createRecordList.length,
                  controller: controller.scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 24);
                  },
                  itemBuilder: (context, index) {
                    return _buildItemView(controller.createRecordList.safeGet(index, {}));
                  },
                ),
              ),
            ),
            _buildInputView(),
          ],
        );
      }).marginSymmetric(horizontal: 16),
    );
  }

  Widget _buildItemView(Map userCreationRecord) {
    List<Map> res = (userCreationRecord[Security.security_res] ?? []).cast<Map>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildItemDesc(userCreationRecord[Security.security_prompt] ?? ""),
        Text(Security.security_image, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)).marginOnly(top: 16, bottom: 8),
        if (res.isNotEmpty) _buildItemImage(res),
        if (userCreationRecord[Security.security_reloadInfo]?[Security.security_reload] == 1)
          _buildItemRefreshView(userCreationRecord[Security.security_reloadInfo] ?? {}, userCreationRecord[Security.security_id]),
        _buildItemLineView(),
      ],
    );
  }

  Widget _imageLoadingView() {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(image: CachedImageProvider('${MomentRes.base}iic_loading_img.png'), fit: BoxFit.cover),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const CircularProgressIndicator(color: Color(0xFFFF56BB)),
    );
  }

  Widget _buildItemDesc(String desc) {
    return Container(
      margin: const EdgeInsets.only(right: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF2D3442).withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
      child: SelectableText(desc, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  Widget _buildItemImage(List<Map> createResList) {
    return GridView.builder(
      shrinkWrap: true,
      // 关键：自适应高度
      physics: const NeverScrollableScrollPhysics(),
      // 禁止滚动
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 保持2列
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 168.0 / 256.0, // 保持原比例
      ),
      itemCount: createResList.length,
      itemBuilder: (context, index) {
        Map res = createResList.safeGet(index, {});
        return Stack(
          children: [
            AspectRatio(
              aspectRatio: 168.0 / 256.0,
              child:
                  res[Security.security_prepared] == 1
                      ? GestureDetector(
                        onTap: () {
                          controller.addOrRemove(res[Security.security_url]!);
                        },
                        child: CachedImage(
                          imageUrl: res[Security.security_url] ?? "",
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(16),
                          errorWidget: (context, url, error) {
                            return Container(color: Colors.grey, width: double.infinity);
                          },
                          placeholder: (context, url) {
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(color: Color(0xFF2F3137), borderRadius: BorderRadius.circular(16)),
                            );
                          },
                        ),
                      )
                      : _imageLoadingView(),
            ),
            if ((res[Security.security_url] ?? "").isNotEmpty && res[Security.security_prepared] == 1)
              Positioned(
                top: 8,
                right: 8,
                child: Obx(() {
                  return GestureDetector(
                    onTap: () {
                      controller.addOrRemove(res[Security.security_url]!);
                    },
                    child: ImageView(
                      controller.rxResInfoList.indexWhere((element) => element[Security.security_url] == res[Security.security_url]) >= 0
                          ? "ic_check.png"
                          : "ic_uncheck.png",
                      height: 24,
                      width: 24,
                    ),
                  );
                }),
              ),
          ],
        );
      },
    );
  }

  Widget _buildItemRefreshView(Map reloadInfo, int createId) {
    return GestureDetector(
      onTap: () {
        controller.reloadCreationResource(createId, reloadInfo[Security.security_costType], reloadInfo[Security.security_cost]);
      },
      child: Row(
        children: [
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
            child: Row(
              children: [
                Icon(Icons.refresh, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  reloadInfo[Security.security_cost] == 0
                      ? Security.security_free
                      : "${reloadInfo[Security.security_cost]} ${reloadInfo[Security.security_costType] == ECurrencyType.COINS ? "Coins" : "Gems"}",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemLineView() {
    return Container(margin: const EdgeInsets.only(top: 24), color: const Color(0xFF403F45), width: double.infinity, height: 1);
  }

  Widget _buildInputView() {
    return Row(children: [Expanded(child: _buildTextField()), const SizedBox(width: 8), _buildSendBnt()]);
  }

  Widget _buildTextField() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        InkWell(
          onTap: () {},
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 12, right: 36, top: 12, bottom: 12),
            decoration: BoxDecoration(color: const Color(0xFFB9B9B9).withOpacity(0.6), borderRadius: BorderRadius.circular(100)),
            child: TextField(
              focusNode: controller.focusNode,
              onChanged: (value) {
                controller.inputText.value = value;
              },
              onSubmitted: (value) {
                if (value.isEmpty) return;
                controller.createResource(controller.costInfo.value[Security.security_costType], controller.costInfo.value[Security.security_costValue]);
              },
              inputFormatters: [LengthLimitingTextInputFormatter(250)],
              controller: controller.controller,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
              decoration: InputDecoration(
                // contentPadding: const EdgeInsets.only(left: 15, right: 45, top: 12, bottom: 12),
                hintText: Copywriting.security_image_details__facial_features__clothing,
                hintStyle: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
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
          ),
        ),
        // Positioned(
        //   right: 12,
        //   child: GestureDetector(
        //     onTap: () {},
        //     child: Image.asset(
        //       'assets/images/message/ic_chat_replylist.webp',
        //       package: Security.security_app_common,
        //       width: 20,
        //       height: 20,
        //     ),
        //   ),
        // )
      ],
    ).marginSymmetric(vertical: 12);
  }

  Widget _buildSendBnt() {
    return Obx(() {
      return GestureDetector(
        onTap: () {
          controller.createResource(controller.costInfo.value[Security.security_costType], controller.costInfo.value[Security.security_costValue]);
        },
        child: Stack(
          children: [
            CachedImage(imageUrl: '${MomentRes.base}iic_moment_send.webp', width: 36, height: 36, fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,

              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.48), borderRadius: BorderRadius.circular(100)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ImageView(
                      controller.costInfo.value[Security.security_costType] == ECurrencyType.GEMS ? "gem.png" : 'coin.png',
                      width: 12,
                      height: 12,
                      // color: Colors.red,
                    ),
                    Text(
                      '${controller.costInfo.value[Security.security_costValue] ?? 15}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
