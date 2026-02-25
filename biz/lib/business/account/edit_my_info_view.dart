import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/sheet.dart';

import '../../core/account/account_service.dart';
import '../../core/util/cached_image.dart';
import '../../core/util/file_upload.dart';
import '../../shared/toast/toast.dart';
import '../../shared/widget/avatar_view.dart';

class EditMyInfoPage extends StatelessWidget {
  EditMyInfoPage({super.key});

  final EditMyInfoLogic controller = Get.put(EditMyInfoLogic());
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: AppBar(
        leading: InkWell(onTap: Get.back, child: Container(padding: EdgeInsets.all(16), child: CachedImage(imageUrl: ImagePath.ic_arrow_left_circle, width: 20, height: 20))),
        centerTitle: true,
        backgroundColor: AppColors.base_background,
        title: Text(Copywriting.security_edit_information, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          InkWell(
            onTap: controller.saveMyInfo,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(Security.security_Save, style: TextStyle(color: AppColors.ocMain, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            spacing: 8,
            children: [
              // 头像
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 88,
                    width: 88,
                    child: Stack(
                      children: [
                        Obx(
                          () =>
                              MyAccount.avatar.isEmpty
                                  ? Container(color: Colors.grey, height: 88, width: 88)
                                  : AvatarView(url: MyAccount.avatar, size: 88),
                        ),
                        Positioned(right: 2, bottom: 2, child: Icon(Icons.camera_alt, size: 24, color: Colors.white,)),
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [_buildNameItem(), _buildGenderItem(), _buildBirthdayItem()]),
              ),
              // Container(
              //   padding: EdgeInsets.all(12),
              //   decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Color(0xFF1E1A2E)),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(Security.security_Profile, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              //       Container(
              //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              //         height: 80,
              //         decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              //         child: TextField(
              //           controller: controller.profileController,
              //           style: TextStyle(color: Colors.white, fontSize: 11, height: 1.0),
              //           decoration: InputDecoration(
              //             border: InputBorder.none,
              //             isDense: true,
              //             hintText: 'Fill in your introduction...',
              //             hintStyle: TextStyle(color: Color(0xFF9EA1A8), fontSize: 11, fontWeight: AppFonts.medium),
              //           ),
              //           textAlignVertical: TextAlignVertical.center,
              //           textAlign: TextAlign.left,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameItem() {
    return Container(
      height: 40,
      padding: EdgeInsets.all(12),
      child: Row(
        spacing: 4,
        children: [
          Text(Security.security_Name, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: TextField(
              controller: controller.nameController,
              style: TextStyle(color: Colors.white, fontSize: 11, height: 1.0),
              decoration: InputDecoration(border: InputBorder.none, isDense: true),
              textAlignVertical: TextAlignVertical.center,
              textAlign: TextAlign.right,
            ),
          ),
          // Image.asset(ImagePath.right_arrow, height: 16, width: 16),
        ],
      ),
    );
  }

  Widget _buildGenderItem() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showGenderSelector,
      child: Container(
        height: 40,
        padding: EdgeInsets.all(12),
        child: Row(
          spacing: 4,
          children: [
            Text(Security.security_Gender, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            Expanded(
              child: Row(
                children: [
                  Spacer(),
                  Obx(() => Text(controller.genderText.value, style: TextStyle(color: Colors.white, fontSize: 11, height: 1.0))),
                  // Image.asset(ImagePath.right_arrow, height: 16, width: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayItem() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showDateSelector,
      child: Container(
        height: 40,
        padding: EdgeInsets.all(12),
        child: Row(
          spacing: 4,
          children: [
            Text(Security.security_Birthday, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            Expanded(
              child: Row(
                children: [
                  Spacer(),
                  Obx(
                    () => Text(
                      DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(controller.birthdayText.value)),
                      style: TextStyle(color: Colors.white, fontSize: 11, height: 1.0),
                    ),
                  ),
                  GestureDetector(onTap: () async {}, child: CachedImage(imageUrl: ImagePath.ic_arrow_right_circle, width: 20, height: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onAvatarTap() {
    showAppBottomSheet([
      ListTile(
        leading: Icon(Icons.photo_library),
        title: Text(Copywriting.security_select_from_the_album),
        onTap: () async {
          Get.back();
          onSelectAvatar(ImageSource.gallery);
        },
      ),
      ListTile(
        leading: Icon(Icons.photo_camera),
        title: Text(Copywriting.security_turn_on_the_camera),
        onTap: () async {
          Get.back();
          onSelectAvatar(ImageSource.camera);
        },
      ),
    ]);
  }

  _showDateSelector() async {
    final context = Get.context;
    if (context == null) {
      Toast.show(Copywriting.security_cannot_open_date_picker__please_retry_later);
      return;
    }
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime(2050));
    if (picked != null) {
      controller.handleBirthday(picked);
    }
  }

  _showGenderSelector() {
    showAppBottomSheet([
      ListTile(
        title: Text(Security.security_Male, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        onTap: () {
          Get.back();
          controller.setGender(Security.security_Male);
        },
      ),
      ListTile(
        title: Text(Security.security_Female, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        onTap: () {
          Get.back();
          controller.setGender(Security.security_Female);
        },
      ),
      ListTile(
        title: Text(Security.security_unknown, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        onTap: () {
          Get.back();
          controller.setGender(Security.security_unknown);
        },
      ),
    ]);
  }

  void onSelectAvatar(ImageSource source) async {
    // Get.back();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      controller.handleAvatar(pickedFile);
    }
  }
}

class EditMyInfoLogic extends GetxController {
  // ProfileManager get myInfo => ProfileManager.instance;
  final nameController = TextEditingController();
  final profileController = TextEditingController();
  final genderText = ''.obs;
  final birthdayText = 0.obs;

  @override
  void onInit() {
    super.onInit();
    nameController.text = MyAccount.name;
    profileController.text = MyAccount.bio;

    birthdayText.value = MyAccount.birthday;
    genderText.value = MyAccount.gender;
  }

  void handleAvatar(XFile pickedFile) async {
    Toast.loading(status: Copywriting.security_uploading_new_avatar___);
    final bytes = await pickedFile.readAsBytes();
    final imgUrl = await FilePushService.instance.upload(bytes, FileType.profile);

    if (imgUrl != null) {
      await AccountService.instance.updateMyAvatar(imgUrl);
    }
    Toast.show(Copywriting.security_avatar_uploaded);
  }

  void setGender(String gender) {
    genderText.value = gender;
  }

  void saveMyInfo() async {
    var gender = 0;
    if (genderText.value == Security.security_Male) {
      gender = 1;
    } else if (genderText.value == Security.security_Female) {
      gender = 2;
    } else {
      gender = 0;
    }
    Toast.loading(status: Copywriting.security_updating_information___);
    final rtn = await AccountService.instance.updateMyInfo(
      name: nameController.text,
      birthday: birthdayText.value.toString(),
      gender: gender,
      bio: profileController.text,
    );
    if (!rtn) {
      Toast.show(Copywriting.security_failed_to_update__please_retry_later);
      return;
    }
    Toast.show(Copywriting.security_information_updated_);
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  void handleBirthday(DateTime picked) {
    if (picked.isAfter(DateTime.now())) {
      Toast.show(Copywriting.security_selected_date_is_out_of_range_);
      return;
    }
    birthdayText.value = picked.millisecondsSinceEpoch;
  }
}
