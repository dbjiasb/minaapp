import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class CalendarHelper {
  /// 将动态类型的时间戳或日期对象转换为指定格式的字符串
  /// 支持: DateTime、时间戳（秒或毫秒）、ISO 8601 字符串
  /// 默认格式: yy-MM-dd (如 "24-05-20")
  static String? formatDate({required dynamic date, String format = 'yyyy-MM-dd'}) {
    try {
      if (date == null) return null;

      DateTime parsedDate;
      if (date is DateTime) {
        parsedDate = date;
      } else if (date is int) {
        // 处理时间戳（可能是秒或毫秒）
        parsedDate = DateTime.fromMillisecondsSinceEpoch(date.toString().length <= 10 ? date * 1000 : date);
      } else if (date is String) {
        // 尝试解析字符串（可能是时间戳或 ISO 字符串）
        parsedDate = DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(int.tryParse(date) ?? 0);
      } else {
        throw ArgumentError('Unsupported date type: ${date.runtimeType}');
      }
 
      return DateFormat(format).format(parsedDate);
    } catch (e) {
      debugPrint('CalendarHelper.formatDate error: $e');
      return null;
    }
  }
}
