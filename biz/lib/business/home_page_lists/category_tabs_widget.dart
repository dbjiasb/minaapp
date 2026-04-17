import 'package:biz/business/home_page_lists/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryTabsWidget extends StatelessWidget {
  final List<Category> categories;
  final int selectedIndex;
  final Function(int) onTap;

  const CategoryTabsWidget({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 8.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(categories.length, (index) {
            bool isSelected = index == selectedIndex;
            return GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(0xFFEDEFF3)
                      : Color(0xFF262B35),
                  borderRadius: BorderRadius.circular(28.r),
                ),
                child: Text(
                  categories[index].name,
                  style: TextStyle(
                    color: isSelected ? Color(0xFF07070a) : Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold ,
                    height: 1.5
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
