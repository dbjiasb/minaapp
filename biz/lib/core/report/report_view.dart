import 'package:biz/base/crypt/copywriting.dart';
import 'package:flutter/material.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/core/report/report_manager.dart';

class ReportContentView extends StatefulWidget {
  final int reportedUserId;

  ReportContentView({super.key, required this.reportedUserId});

  ReportItem? selectedItem;
  String extra = '';

  @override
  State<ReportContentView> createState() => _ReportContentViewState();
}

class _ReportContentViewState extends State<ReportContentView> {
  List<ReportItem> items = ReportManager.instance.reportItems;
  int selectedIndex = 0;

  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.selectedItem = items.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          ReportItem item = items[index];
          return GestureDetector(
            onTap: () {
              widget.selectedItem = item;
              setState(() {
                selectedIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(selectedIndex == index ? ImagePath.selecet_1 : ImagePath.selecet_0, width: 16, height: 16),
                      SizedBox(width: 4),
                      Text(item.desc, style: TextStyle(color: Color(0xFF999999), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  if (index == items.length - 1)
                    Container(
                      margin: const EdgeInsets.only(top: 18),
                      decoration: BoxDecoration(color: Color(0xFFF1F0F4), borderRadius: BorderRadius.all(Radius.circular(8))),
                      child: TextField(
                        onChanged: (value) {
                          widget.extra = value;
                        },
                        controller: textEditingController,
                        decoration: InputDecoration(
                          hintText: Copywriting.security_describe_the_issue,
                          hintStyle: TextStyle(color: Color(0xFFAFAFAF), fontSize: 11, fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return Divider(height: 1, color: Color(0xFFF1F0F4));
        },
        itemCount: items.length,
      ),
    );
  }
}
