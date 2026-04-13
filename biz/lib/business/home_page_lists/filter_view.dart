import 'package:biz/business/home_page_lists/role_manager.dart';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/assets/image_path.dart';
import '../../base/crypt/security.dart';
import '../../shared/app_theme.dart';

class RoleFilterWidget extends StatelessWidget {
  RoleFilterWidget({this.tapId = 0, dynamic filterCondition, this.onApply}) {
    selectedGender.value = filterCondition?[Security.security_gender] ?? 0;
    filterCondition?[Security.security_tagIdList]?.forEach((element) {
      selectedTag[element] = {
        Security.security_id: element,
      };
    });
  }

  int tapId = 0;
  Function(int gender, List tagIds)? onApply;

  RxMap selectedTag = {}.obs;

  void selectTag(dynamic tag) {
    if (selectedTag[tag[Security.security_id]] != null) {
      selectedTag.remove(tag[Security.security_id]);
    } else {
      selectedTag[tag[Security.security_id]] = tag;
    }
    // update();
  }

  bool isTagSeled(int id) => selectedTag[id] != null ? true : false;
  RxInt selectedGender = 0.obs;

  static showFilter(int tapId,
      {dynamic filterCondition, Function(int gender, List tagIds)? onApply}) {
    Get.bottomSheet(
      RoleFilterWidget(
        tapId: tapId,
        filterCondition: filterCondition,
        onApply: onApply,
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1B1E25),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                Security.security_filters,
                style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(Icons.close, color: Color(0xFFABABAD), size: 24)//Image.asset(IMGP.chat_close, width: 24, height: 24),
              )
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            Security.security_gender,
            style: TextStyle(
                color: Color(0xFFABABAD),
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 12,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF12151C),
              borderRadius: BorderRadius.circular(22),
            ),
            height: 44,
            width: double.infinity,
            child: Obx(() {
              int sel = selectedGender.value;
              ButtonSegment<int> wc(t, v) => ButtonSegment(
                    label: Container(
                      // margin: const EdgeInsets.only(bottom: 4, top: 4),
                      decoration: BoxDecoration(
                        color: sel == v ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      height: 34,
                      alignment: Alignment.center,
                      child: Center(child: Text(
                        t,
                        style: TextStyle(
                          color: sel == v
                              ? const Color(0xFF110803)
                              : const Color(0xFF5C5E64),
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),),
                    ),
                    value: v,
                  );
              return SegmentedButton<int>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                  alignment: Alignment.center,
                  minimumSize:
                      WidgetStateProperty.all(const Size(double.infinity, 36)),
                  maximumSize:
                      WidgetStateProperty.all(const Size(double.infinity, 36)),
                  fixedSize:
                      WidgetStateProperty.all(const Size(double.infinity, 36)),
                  side: WidgetStateProperty.all(BorderSide.none),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22))),
                  elevation: WidgetStateProperty.all(0),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                ),
                showSelectedIcon: false,
                selected: {selectedGender.value},
                onSelectionChanged: (Set<int> newSelection) {
                  selectedGender.value = newSelection.first;
                },
                segments: <ButtonSegment<int>>[
                  wc(Security.security_all, 0),
                  wc(Security.security_female, 2),
                  wc(Security.security_male, 1),
                ],
              );
            }),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            Security.security_tags,
            style: TextStyle(
                color: Color(0xFFABABAD),
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 12,
          ),
          Expanded(
              child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
                child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RoleManager.instance.filterList
                  .map((e) => Obx(() => GestureDetector(
                        onTap: () {
                          selectTag(e);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isTagSeled(e[Security.security_id])
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Text(e[Security.security_name] ?? '',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isTagSeled(e[Security.security_id])
                                      ? Color(0xFF110803)
                                      : Color(0xFFABABAD))),
                        ),
                      )))
                  .toList(),
            ))
          ])),
          SizedBox(height: 12),
          SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      selectedGender.value = 0;
                      selectedTag.clear();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Color(0xFFABABAD),
                          size: 20,
                        ),
                        Text(
                          Security.security_reset.tr,
                          style: const TextStyle(
                              color: Color(0xFFABABAD),
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      List ids = selectedTag.keys.toList();
                      onApply?.call(selectedGender.value, ids);
                      Get.back();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Obx(() {
                        int count = selectedTag.entries.length;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(Security.security_done,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            if (count > 0) const SizedBox(width: 4),
                            if (count > 0)
                              Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                width: 16,
                                height: 16,
                                child: Text(count.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ),
                          ],
                        );
                      }),
                    ),
                  ))
                ],
              )),
          SizedBox(height: 16)
        ],
      ),
    );
  }
}
