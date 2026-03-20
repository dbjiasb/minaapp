import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/business/moment/constant_state.dart';
import 'package:biz/business/moment/create_moment_view/post_as_page.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../base/assets/image_view.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../base/router/router_names.dart';
import '../../../core/util/cached_image.dart';
import '../../../shared/common_widget.dart';
import '../../../shared/sheet.dart';
import '../../chat/chat_record/chat_history_image_select_view.dart';
import 'create_moment_view_logic.dart';
import 'reorder_res_grid_view.dart';

class CreateMomentViewPage extends GetView<CreateMomentViewLogic> {
  const CreateMomentViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.focusNode.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Color(0xFF12151C),
        appBar: AppBarExt.darkAppBar(
          returnIconColor: Colors.white,
          backgroundColor: Color(0xFF12151C),
          title: '',
          actions: [
            Obx(
              () => GestureDetector(
                onTap: () {
                  controller.createMoment();
                },
                child: Text(
                  Security.security_post,
                  style: TextStyle(color: controller.canPost ? AppColors.primary : const Color(0x66FFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
                ).marginOnly(right: 16),
              ),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Copywriting.security_post_As, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          _buildSelectRole(),
          const SizedBox(height: 24),
          _buildInputView(),
          const SizedBox(height: 24),
          Obx(() {
            return controller.selectImage.isNotEmpty
                ? ReorderResGridView(controller.selectImage, onAddMoreTap: onAddPhoto)
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Copywriting.security_select_Image, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    _buildGeneratorImage(),
                    _buildHistoryAlbum(),
                  ],
                );
          }),
        ],
      ),
    );
  }

  void onAddPhoto() async {
    showAppBottomSheet([
      ListTile(
        title: Text(Copywriting.security_create_an_image_with_Generator),
        onTap: () async {
          Get.back();
          onTapGenerateImage();
        },
      ),
      ListTile(
        title: Text(Copywriting.security_select_From_Chat_History_Album),
        onTap: () async {
          Get.back();
          onTapHistoryAlbum();
        },
      ),
    ]);
  }

  Widget _buildInputView() {
    return Stack(
      children: [
        TextField(
          focusNode: controller.focusNode,
          controller: controller.textController,
          onChanged: (value) {
            controller.inputPostText.value = value;
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onSubmitted: (value) {},
          cursorColor: AppColors.primary,
          minLines: 5,
          maxLines: null,
          inputFormatters: controller.inputFormatters,
          decoration: InputDecoration(
            filled: true,
            counter: Obx(() {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${controller.inputPostText.value.characters.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(text: '/500', style: TextStyle(color: Color(0xFF494C53), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
            labelStyle: const TextStyle(color: Colors.white, fontSize: 14),
            hintText: Copywriting.security_enter_the_Description,
            fillColor: Colors.transparent,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 12, fontWeight: FontWeight.normal),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent, style: BorderStyle.none, width: 1)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent, width: 0)),
          ),
        ),
        Obx(() {
          return Positioned(
            top: 0,
            right: 0,
            child:
                controller.inputPostText.value.characters.isEmpty && controller.selectImage.isNotEmpty
                    ? GestureDetector(
                      onTap: () {
                        controller.generatePostContent();
                      },
                      child: Row(
                        children: [
                          CachedImage(imageUrl: '${MomentRes.base}iic_ai_replys.webp', width: 20, height: 20),
                          const SizedBox(width: 2),
                          Text(Copywriting.security_aI_Writer, style: TextStyle(color: Color(0xFFC1C2C7), fontSize: 14)),
                        ],
                      ),
                    )
                    : Container(),
          );
        }),
      ],
    );
  }

  Widget _buildSelectRole() {
    return GestureDetector(
      onTap: () {
        _showPostAsPanel();
      },
      child: Obx(() {
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Color(0xFF1B1E25), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              (controller.characterInfo?[Security.security_userBase]?[Security.security_avatarUrl] ?? "").isEmpty
                  ? Container(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(22)), width: 44, height: 44)
                  : CachedImage(
                    imageUrl: controller.characterInfo?[Security.security_userBase]?[Security.security_avatarUrl] ?? "",
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(22),
                    errorWidget: (context, url, error) {
                      return Container(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(22)), width: 44, height: 44);
                    },
                    placeholder: (context, url) {
                      return Container(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(22)), width: 44, height: 44);
                    },
                  ),
              const SizedBox(width: 8),
              Text(
                controller.characterUid != 0
                    ? controller.characterInfo?[Security.security_userBase]?[Security.security_nickName] ?? ''
                    : Copywriting.security_select_a_Character,
                style: TextStyle(color: controller.characterUid != 0 ? Colors.white : const Color(0xFFABABAD), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ImageView(Images.security_arrow_right_png, width: 16, height: 16, fit: BoxFit.cover),
            ],
          ),
        );
      }),
    );
  }

  void onTapGenerateImage() async {
    controller.focusNode.unfocus();
    if (controller.characterUid != 0) {
      dynamic res = await Get.toNamed(
        Routers.createPostImage,
        arguments: {
          Security.security_targetUid: controller.characterUid,
          Security.security_resInfoList: [...controller.selectImage],
        },
      );
      if (res is List<Map>) {
        List<Map> temp = [];
        for (var element in res) {
          int index = controller.selectImage.indexWhere((e) => e[Security.security_url] == element[Security.security_url]);
          if (index < 0) {
            temp.add(element);
          }
        }
        controller.selectImage.addAll(temp);
      }
    } else {
      EasyLoading.showToast(Copywriting.security_please_select_a_character_first);
    }
  }

  Widget _buildGeneratorImage() {
    return GestureDetector(
      onTap: onTapGenerateImage,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Color(0xFF1B1E25), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            CachedImage(imageUrl: MomentRes.base + Images.security_iic_create_from_gen_webp, width: 44, height: 44),
            const SizedBox(width: 10),
            Text(Copywriting.security_create_an_image_with_Generator, style: TextStyle(color: Color(0xFFABABAD), fontSize: 14)),
            const Spacer(),
            ImageView(Images.security_arrow_right_png, width: 16, height: 16, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }

  void onTapHistoryAlbum() async {
    controller.focusNode.unfocus();
    if (controller.characterUid != 0) {
      dynamic res = await ChatHistoryImageSelectView.toChatImgHistorySelect("${controller.characterUid}", [...controller.selectImage]);
      if (res is List<Map>) {
        List<Map> temp = [];
        for (var element in res) {
          int index = controller.selectImage.indexWhere((e) => e[Security.security_url] == element[Security.security_url]);
          if (index < 0) {
            temp.add(element);
          }
        }
        controller.selectImage.addAll(temp);
      }
    } else {
      EasyLoading.showToast(Copywriting.security_please_select_a_character_first);
    }
  }

  Widget _buildHistoryAlbum() {
    return GestureDetector(
      onTap: onTapHistoryAlbum,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Color(0xFF1B1E25), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            CachedImage(imageUrl: '${MomentRes.base}iic_album.webp', width: 44, height: 44),
            const SizedBox(width: 8),
            Text(Copywriting.security_select_From_Chat_History_Album, style: TextStyle(color: Color(0xFFABABAD), fontSize: 14)),
            const Spacer(),
            ImageView(Images.security_arrow_right_png, width: 16, height: 16, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }

  void _showPostAsPanel() {
    controller.focusNode.unfocus();
    Get.bottomSheet(PostAsPage());
  }
}
