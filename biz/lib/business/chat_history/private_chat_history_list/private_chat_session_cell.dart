import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/shared/formatters/date_formatter.dart';

class PrivateChatSessionCell extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;

  const PrivateChatSessionCell({
    super.key,
    required this.session,
    required this.onTap,
  });

  Widget _buildAccountTypeBadge() {
    if (session.accountType == 1 || session.accountType == 3 || session.accountType == 4) {
      // AI badge
      return Container(
        margin: EdgeInsets.only(left: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF556AEB), Color(0xFFB635F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFAFB2FF).withOpacity(0.6), width: 1),
          borderRadius: BorderRadius.circular(8.w),
        ),
        child: Text(
          'AI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (session.accountType == 0) {
      // Real badge
      return Container(
        margin: EdgeInsets.only(left: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEB55DD), Color(0xFFF38D45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFFDBAA2).withOpacity(0.6), width: 1),
          borderRadius: BorderRadius.circular(8.w),
        ),
        child: Text(
          'Real',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
        color: Colors.transparent,
        child: Row(
          children: [
            // 头像
            ClipRRect(
              borderRadius: BorderRadius.circular(22.w),
              child: CachedImage(
                imageUrl: session.avatar,
                width: 44.w,
                height: 44.w,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.w),
            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 名称
                      Text(
                        session.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 账号类型徽章
                      _buildAccountTypeBadge(),
                      const Spacer(),
                      // 时间
                      Text(
                        DateFormatter.diff(session.lastMessageTime),
                        style: TextStyle(
                          color: const Color(0xFFA19C9A),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.w),
                  Row(
                    children: [
                      // 最后一条消息
                      Expanded(
                        child: Text(
                          session.showExtMessage,
                          style: TextStyle(
                            color: const Color(0xFFA19C9A),
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 未读徽章
                      if (session.unreadNumber.value > 0)
                        Container(
                          margin: EdgeInsets.only(left: 8.w),
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0443E),
                            borderRadius: BorderRadius.circular(7.w),
                          ),
                          constraints: BoxConstraints(minWidth: 14.w, minHeight: 14.w),
                          child: Text(
                            session.unreadNumber.value > 99 ? '99+' : '${session.unreadNumber.value}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
