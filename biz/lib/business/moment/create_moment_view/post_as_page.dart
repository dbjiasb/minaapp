import 'package:biz/business/create_center/create_oc_dialog.dart';
import 'package:biz/business/moment/constant_state.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/core/util/collections_util.dart';
import 'package:biz/shared/widget/avatar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../base/assets/image_view.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/common_widget.dart';
import '../moment_service.dart';
import 'create_moment_view_logic.dart';

class PostAsPage extends StatelessWidget {
  PostAsPage({super.key});

  final CreateMomentViewLogic createController = Get.find<CreateMomentViewLogic>();
  final PostAsPageController postAsPageController = Get.put(PostAsPageController());

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF12151C), borderRadius: BorderRadius.only(topRight: Radius.circular(24), topLeft: Radius.circular(24))),
      child: Column(
        children: [
          _buildTitleView(),
          const SizedBox(height: 12),
          // _buildSearchView(),
          // const SizedBox(
          //   height: 12,
          // ),
          _buildView(),
        ],
      ),
    );
  }

  Widget _buildTitleView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox.shrink(), // 占位，保持结构
        Text(Copywriting.security_post_As, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        GestureDetector(
          onTap: () {
            Get.back();
          },
          child: CachedImage(imageUrl: '${MomentRes.base}/iic_close.webp', width: 24, height: 24),
        ),
      ],
    );
  }

  Widget _buildSearchView() {
    return GestureDetector(
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFFFFFFFF).withOpacity(0.05), borderRadius: const BorderRadius.all(Radius.circular(8))),
        child: Row(
          children: [
            Image.asset('packages/modules/assets/moment/ic_group_search.webp', width: 16, height: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Center(
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: Security.security_name,
                    isCollapsed: true,
                    hintStyle: TextStyle(color: Color(0xFF494C53), fontSize: 12),
                  ),
                  textInputAction: TextInputAction.search,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  minLines: 1,
                  expands: false,
                  onChanged: (value) {
                    postAsPageController.keyword.value = value;
                  },
                  onSubmitted: (value) {
                    postAsPageController.onSearch();
                    searchFocusNode.requestFocus();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () {},
    );
  }

  Widget _buildView() {
    return Flexible(
      child: AppBarExt.mainBody(postAsPageController.getListData(0), (data, context) {
        var param = data[Security.security_param];
        List<Map> list = param == null ? [] : (param as List).cast<Map<String, dynamic>>();

        if (list.isEmpty == true) {
          return _buildEmptyView();
        } else {
          postAsPageController.refreshData(list);
          postAsPageController.hasMore.value = data[Security.security_hasMore] == 1;
          return _buildRoleList();
        }
      }),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ImageView("empty_list.png", width: 172, height: 146),
          const SizedBox(height: 16),
          Text(
            textAlign: TextAlign.center,
            Copywriting.security_you_need_to_have_your_own_role_to_post___nGo_create_a_character,
            // style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal),
            style: TextStyle(color: Color(0xFFABABAD), fontSize: 14, fontWeight: FontWeight.normal),
          ),
          GestureDetector(
            onTap: () {
              Get.back();
              CreateOcDialog.show();
            },
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedImage(imageUrl: '${MomentRes.base}iic_add.webp', width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(Copywriting.security_create_Character, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleList() {
    return Obx(() {
      return RefreshIndicator(
        onRefresh: postAsPageController.onRefresh,
        child: ListView.separated(
          controller: postAsPageController.scrollController,
          itemCount: postAsPageController.characterSelectInfo.length,
          padding: const EdgeInsets.only(top: 12, bottom: 80),
          separatorBuilder: (context, index) {
            return const SizedBox(height: 4);
          },
          itemBuilder: (context, index) {
            return _buildItemView(postAsPageController.characterSelectInfo.safeGet(index, {}));
          },
        ),
      );
    });
  }

  Widget _buildItemView(Map characterSelectInfo) {
    return InkWell(
      onTap: () {
        if (characterSelectInfo[Security.security_dailyPostCount] >= characterSelectInfo[Security.security_dailyMaxPostCount]) {
          EasyLoading.showToast(Copywriting.security_daily_post_limit_exceeded);
        } else {
          createController.updateCharacterInfo(characterSelectInfo);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            AvatarView(url: characterSelectInfo[Security.security_userBase]?[Security.security_avatarUrl] ?? '', size: 44),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  characterSelectInfo[Security.security_userBase][Security.security_nickName] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                _buildCharacterFlag(characterSelectInfo),
              ],
            ),
            const Spacer(),
            Obx(() {
              return ImageView(
                createController.characterInfo?[Security.security_userBase]?[Security.security_uid] ==
                        characterSelectInfo[Security.security_userBase][Security.security_uid]
                    ? "ic_check.png"
                    : "ic_uncheck.png",
                height: 24,
                width: 24,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterFlag(Map characterSelectInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            characterSelectInfo[Security.security_dailyPostCount] >= characterSelectInfo[Security.security_dailyMaxPostCount]
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFFF1E6B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Today remaining(${characterSelectInfo[Security.security_dailyMaxPostCount] - characterSelectInfo[Security.security_dailyPostCount]}/${characterSelectInfo[Security.security_dailyMaxPostCount]})',
        style: TextStyle(
          fontSize: 10,
          color:
              characterSelectInfo[Security.security_dailyPostCount] >= characterSelectInfo[Security.security_dailyMaxPostCount]
                  ? const Color(0xFFFF1E6B)
                  : const Color(0xFFABABAD),
        ),
      ),
    );
  }
}

class PostAsPageController extends GetxController {
  final ScrollController scrollController = ScrollController();
  RxBool hasMore = true.obs;
  RxList<Map> characterSelectInfo = RxList();
  RxString keyword = "".obs;
  int pageIndex = 0;

  @override
  void onInit() {
    scrollController.addListener(() {
      if ((scrollController.position.pixels >= scrollController.position.maxScrollExtent - 64) && hasMore.value) {
        onLoading();
      }
    });
    super.onInit();
  }

  void onSearch() {
    pageIndex = 0;
    onRefresh();
  }

  Future<Map> getListData(int index) async {
    pageIndex = index;
    return await MomentService.getSelectCharacterList(pageIndex: pageIndex, keyword: keyword.value);
  }

  void refreshData(List<Map> characterSelectInfoList) {
    characterSelectInfo.clear();
    characterSelectInfo.addAll(characterSelectInfoList);
  }

  Future<void> onRefresh() async {
    Map? getCharacterSelectListRsp = await getListData(0);
    refreshData(getCharacterSelectListRsp[Security.security_param] ?? []);
    hasMore.value = getCharacterSelectListRsp[Security.security_hasMore] == 1;
    pageIndex++;
  }

  void onLoading() async {
    if (!hasMore.value) return;
    Map getCharacterSelectListRsp = await getListData(pageIndex);
    characterSelectInfo.addAll(getCharacterSelectListRsp[Security.security_param] ?? []);
    hasMore.value = getCharacterSelectListRsp[Security.security_hasMore] == 1;
    pageIndex++;
  }
}
