import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/assets/image_path.dart';

class StyleTabBars extends StatelessWidget {
  final List<String> titles;
  Function(int)? onTabSelected;
  var selectedIndex = 0.obs;

  EdgeInsets? margin;

  TextStyle? get _defaultSelectedStyle => const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900);

  TextStyle? get _defaultUnselectedStyle => TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.bold);

  TextStyle? selectedStyle;
  TextStyle? unselectedStyle;

  StyleTabBars({required this.titles, this.onTabSelected, this.margin, this.selectedStyle, this.unselectedStyle});

  void switchToTab(int index) {
    if (index >= 0 && index < titles.length) {
      selectedIndex.value = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: margin,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: buildTabBarItem(index),
            onTap: () {
              onTabSelected?.call(index);
              selectedIndex.value = index;
            },
          );
        },
        separatorBuilder: (context, index) {
          return const SizedBox(width: 24);
        },
        itemCount: titles.length,
      ),
    );
  }

  Widget buildTabBarItem(int index) {
    return Center(
      child: Obx(
        () =>
            index == selectedIndex.value
                ? StyleTitleBar(title: titles[index])
                : Text(titles[index], style: unselectedStyle ?? _defaultUnselectedStyle, textScaler: TextScaler.noScaling),
      ),
    );
  }

  Widget StyleTitleBar({required String title}) {
    return IntrinsicWidth(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          Text(title, style: selectedStyle ?? _defaultSelectedStyle, textScaler: TextScaler.noScaling),
          // Positioned(bottom: -5, child: Image.asset(ImagePath.tab_selected, width: 40, height: 10)),
        ],
      ),
    );
  }
}
