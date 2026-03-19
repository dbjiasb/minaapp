import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/core/util/collections_util.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/security.dart';
import '../../core/util/ui_util.dart';
import '../../shared/app_theme.dart';
import '../home_page_lists/list_item.dart';
import 'logic.dart';

class SearchView extends GetView<SearchLogic> {
  final TextEditingController _searchEditController = TextEditingController();

  final List<TextInputFormatter> inputFormatters = [
    LengthLimitingTextInputFormatter(50), //
  ];
  final RxString _searchValue = "".obs;

  final List<String> _popSearchList = [
    Security.security_anime,
    Security.security_fantasy,
    Security.security_furry,
    Security.security_cute,
    Security.security_romance,
    Security.security_hero,
    Security.security_royalty,
  ];

  SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base_background,
      appBar: UiUtils.buildSAppBar(
        _buildSearchInput(),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            alignment: Alignment.center,
            child: InkWell(
              onTap: () {
                Get.back();
              },
              child: Text(
                Security.security_Cancel,
                style: const TextStyle(
                  color: Color(0x66FFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        leadingWidth: 0,
        titleSpacing: 5,
      ),
      body: Obx(() {
        return _buildSearch();
      }),
    );
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _searchEditController,
      onChanged: (value) {
        _searchValue.value = value;
        _searchValue.value == ""
            ? controller.searchStatus.value = '0'
            : null; //假设清空了就显示历史搜索那个界面了
      },
      onSubmitted: (value) {
        if (value == controller.searchText) {
          return;
        }
        if (value != "" && SearchLogic.recentSearch.contains(value)) {
          SearchLogic.recentSearch.remove(value);
          SearchLogic.recentSearch.insert(0, value);
        } else if (value != "") {
          SearchLogic.recentSearch.insert(0, value);
        }
        _searchValue.value = value;
        value != "" ? controller.search(value) : null;
        controller.rxSearchList.clear();
      },
      style: const TextStyle(color: Colors.white, fontSize: 12),
      cursorColor: Colors.white70,
      textInputAction: TextInputAction.search,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        filled: true,
        prefixIconConstraints: const BoxConstraints(
          maxWidth: 40,
          maxHeight: 24,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8),
          child: ImageView("small_search.webp", width: 24, height: 24),
        ),
        suffixIconConstraints: BoxConstraints(maxWidth: 40, maxHeight: 24),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 8.0), // 控制图标和输入框文字之间的距离
          child: InkWell(
            onTap: () {
              _searchValue.value = "";
              _searchEditController.clear();
              controller.searchStatus.value = '0';
            },
            child: const Icon(
              Icons.clear, // 可替换为其他图标
              color: Color(0xFF636268),
              size: 20,
            ),
          ),
        ),
        labelStyle: const TextStyle(color: Color(0xFF636268), fontSize: 13),
        hintText: Copywriting.security_search_Users_by_ID_or_Name,
        fillColor: const Color(0XFF1B1E25),
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        hintStyle: const TextStyle(color: Color(0xFF636268), fontSize: 13),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          borderSide: BorderSide(
            color: Colors.transparent,
            style: BorderStyle.none,
            width: 1,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent, width: 0),
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
    ).marginOnly(left: 8);
  }

  Widget _buildSearch() {
    switch (controller.searchStatus.value) {
      case "0":
        return Column(
          children: [
            Obx(
              () =>
                  SearchLogic.recentSearch.isNotEmpty
                      ? Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(
                          top: 16,
                          left: 16,
                          bottom: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  Copywriting.security_recent_Search,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: Copywriting.security_sF_Pro,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () => SearchLogic.recentSearch.clear(),
                                  child: ImageView(
                                    "ic_chat_msg_delete.png",
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 8,
                              runSpacing: 12,
                              children:
                                  SearchLogic.recentSearch
                                      .map(
                                        (tag) => Container(
                                          height: 24,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            color: Color(0x1AFFFFFF),
                                            border: Border.all(
                                              width: 1,
                                              color: Color(0x4dffffff),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(width: 10),
                                              InkWell(
                                                onTap: () {
                                                  SearchLogic.recentSearch
                                                      .remove(tag.toString());
                                                  SearchLogic.recentSearch
                                                      .insert(0, tag);
                                                  _searchEditController.text =
                                                      tag.toString();
                                                  controller.search(
                                                    tag.toString(),
                                                  );
                                                },
                                                child: Text(
                                                  tag.toString(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: Copywriting.security_sF_Pro,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap:
                                                    () => (SearchLogic
                                                        .recentSearch
                                                        .remove(tag)),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 7),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                      )
                      : Container(),
            ),
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 16, left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        Copywriting.security_popular_Search,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: Copywriting.security_sF_Pro,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                    ],
                  ),
                  SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children:
                        _popSearchList
                            .map(
                              (popularSearch) => Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Color(0x1AFFFFFF),
                                  border: Border.all(
                                    width: 1,
                                    color: Color(0x4dffffff),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 9),
                                    InkWell(
                                      onTap: () {
                                        SearchLogic.recentSearch.contains(
                                              popularSearch,
                                            )
                                            ? SearchLogic.recentSearch.remove(
                                              popularSearch,
                                            )
                                            : null;
                                        SearchLogic.recentSearch.insert(
                                          0,
                                          popularSearch,
                                        );
                                        _searchEditController.text =
                                            popularSearch;
                                        controller.search(popularSearch);
                                      },
                                      child: Text(
                                        popularSearch,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: Copywriting.security_sF_Pro,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ],
        );

      case "1":
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case "2":
        return _buildSearchContent();
      default:
        return UiUtils.buildCommonEmptyView();
    }
  }

  Widget _buildSearchContent() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: CustomScrollView(
        slivers: [
          SliverMasonryGrid(
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            delegate: SliverChildBuilderDelegate(
              childCount: controller.rxSearchList.length,
              (BuildContext context, int index) {
                RoleItem roleItem = RoleItem.fromMap(
                  controller.rxSearchList.safeGet(index, {}),
                );
                return roleItem.builder(context);
              },
            ),
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
          ),
        ],
      ),
    );
  }
}
