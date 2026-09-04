import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'dart:collection';
import 'package:intl/intl.dart';

const kOnlineCheckInterval = 3 * 60; // 3 minutes online check

extension DateTimeExt on DateTime {
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;

  /// util of online
  String onlineDescription() {
    int timestamp = DateTime.now().secondsSinceEpoch;
    if (timestamp - secondsSinceEpoch < kOnlineCheckInterval) {
      return Security.security_online;
    } else if (timestamp - secondsSinceEpoch < 10 * 60) {
      return "last seen just now";
    } else if (timestamp - secondsSinceEpoch < 60 * 60) {
      return 'last seen $minute minutes ago';
    } else if (timestamp - secondsSinceEpoch < 24 * 60 * 60) {
      return 'last seen $hour hours ago';
    } else {
      return DateFormat(
        "yyyy/MM/dd",
      ).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
    }
  }

  bool get isOnline =>
      DateTime.now().secondsSinceEpoch - secondsSinceEpoch <
      kOnlineCheckInterval;
  DateTime newestOfflineTime() {
    return DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().microsecondsSinceEpoch - kOnlineCheckInterval * 1000,
    );
  }
}

/// 一些常用格式参照。可以自定义格式，例如：'yyyy/MM/dd HH:mm:ss'，'yyyy/M/d HH:mm:ss'。
/// 格式要求
/// year -> yyyy/yy   month -> MM/M    day -> dd/d
/// hour -> HH/H      minute -> mm/m   second -> ss/s
class DateFormats {
  static String full = 'yyyy-MM-dd HH:mm:ss';
  static String y_mo_d_h_m = 'yyyy-MM-dd HH:mm';
  static String y_mo_d = 'yyyy-MM-dd';
  static String y_mo = 'yyyy-MM';
  static String mo_d = 'MM-dd';
  static String mo_d_h_m = Copywriting.security_mM_dd_HH_mm;
  static String h_m_s = 'HH:mm:ss';
  static String h_m = 'HH:mm';
  static String zh_full = 'yyyy年MM月dd日 HH时mm分ss秒';
  static String zh_y_mo_d_h_m = 'yyyy年MM月dd日 HH时mm分';
  static String zh_y_mo_d = 'yyyy年MM月dd日';
  static String zh_y_mo = 'yyyy年MM月';
  static String zh_mo_d = 'MM月dd日';
  static String zh_mo_d_h_m = Copywriting.security_mM_dd__HH_mm_;
  static String zh_h_m_s = 'HH时mm分ss秒';
  static String zh_h_m = 'HH时mm分';
}

/// month->days.
Map<int, int> MONTH_DAY = {
  1: 31,
  2: 28,
  3: 31,
  4: 30,
  5: 31,
  6: 30,
  7: 31,
  8: 31,
  9: 30,
  10: 31,
  11: 30,
  12: 31,
};

/// Date Util.
class DateUtil {
  static int oneDayTs = 24 * 60 * 60;

  /// get DateTime By DateStr.
  static DateTime? getDateTime(String dateStr, {bool? isUtc}) {
    DateTime? dateTime = DateTime.tryParse(dateStr);
    if (isUtc != null) {
      if (isUtc) {
        dateTime = dateTime?.toUtc();
      } else {
        dateTime = dateTime?.toLocal();
      }
    }
    return dateTime;
  }

  /// get DateTime By Milliseconds.
  static DateTime? getDateTimeByMs(int ms, {bool isUtc = false}) {
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: isUtc);
  }

  /// get DateMilliseconds By DateStr.
  static int? getDateMsByTimeStr(String dateStr) {
    DateTime? dateTime = DateTime.tryParse(dateStr);
    return dateTime?.millisecondsSinceEpoch;
  }

  /// get Now Date Milliseconds.
  static int getNowDateMs() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// get Now Date Str.(yyyy-MM-dd HH:mm:ss)
  static String getNowDateStr() {
    return formatDate(DateTime.now());
  }

  /// format date by milliseconds.
  /// milliseconds 日期毫秒
  static String formatDateMs(int ms, {bool isUtc = false, String? format}) {
    return formatDate(getDateTimeByMs(ms, isUtc: isUtc), format: format);
  }

  /// format date by date str.
  /// dateStr 日期字符串
  static String formatDateStr(
    String dateStr, {
    bool isUtc = false,
    String? format,
  }) {
    return formatDate(getDateTime(dateStr, isUtc: isUtc), format: format);
  }

  /// format date by DateTime.
  /// format 转换格式(已提供常用格式 DateFormats，可以自定义格式：'yyyy/MM/dd HH:mm:ss')
  /// 格式要求
  /// year -> yyyy/yy   month -> MM/M    day -> dd/d
  /// hour -> HH/H      minute -> mm/m   second -> ss/s
  static String formatDate(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';
    format = format ?? DateFormats.full;
    if (format.contains(Security.security_yy)) {
      String year = dateTime.year.toString();
      if (format.contains(Security.security_yyyy)) {
        format = format.replaceAll(Security.security_yyyy, year);
      } else {
        format = format.replaceAll(
          Security.security_yy,
          year.substring(year.length - 2, year.length),
        );
      }
    }

    format = _comFormat(dateTime.month, format, 'M', Security.security_mM);
    format = _comFormat(dateTime.day, format, 'd', Security.security_dd);
    format = _comFormat(dateTime.hour, format, 'H', Security.security_hH);
    format = _comFormat(dateTime.minute, format, 'm', Security.security_mM);
    format = _comFormat(dateTime.second, format, 's', Security.security_sSS);
    format = _comFormat(
      dateTime.millisecond,
      format,
      'S',
      Security.security_sSS,
    );

    return format;
  }

  /// com format.
  static String _comFormat(
    int value,
    String format,
    String single,
    String full,
  ) {
    if (format.contains(single)) {
      if (format.contains(full)) {
        format = format.replaceAll(
          full,
          value < 10 ? '0$value' : value.toString(),
        );
      } else {
        format = format.replaceAll(single, value.toString());
      }
    }
    return format;
  }

  /// get day of year.
  /// 在今年的第几天.
  static int getDayOfYear(DateTime dateTime) {
    int year = dateTime.year;
    int month = dateTime.month;
    int days = dateTime.day;
    for (int i = 1; i < month; i++) {
      days = days + MONTH_DAY[i]!;
    }
    if (isLeapYearByYear(year) && month > 2) {
      days = days + 1;
    }
    return days;
  }

  /// get day of year.
  /// 在今年的第几天.
  static int getDayOfYearByMs(int ms, {bool isUtc = false}) {
    return getDayOfYear(DateTime.fromMillisecondsSinceEpoch(ms, isUtc: isUtc));
  }

  /// is today.
  /// 是否是当天.
  static bool isToday(int milliseconds, {bool isUtc = false, int locMs = 0}) {
    if (milliseconds == 0) return false;
    DateTime old = DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: isUtc,
    );
    DateTime? now;
    if (locMs != 0) {
      now = DateUtil.getDateTimeByMs(locMs);
    } else {
      now = isUtc ? DateTime.now().toUtc() : DateTime.now().toLocal();
    }
    return old.year == now?.year &&
        old.month == now?.month &&
        old.day == now?.day;
  }

  /// is yesterday by dateTime.
  /// 是否是昨天.
  static bool isYesterday(DateTime dateTime, DateTime locDateTime) {
    if (yearIsEqual(dateTime, locDateTime)) {
      int spDay = getDayOfYear(locDateTime) - getDayOfYear(dateTime);
      return spDay == 1;
    } else {
      return ((locDateTime.year - dateTime.year == 1) &&
          dateTime.month == 12 &&
          locDateTime.month == 1 &&
          dateTime.day == 31 &&
          locDateTime.day == 1);
    }
  }

  /// is yesterday by millis.
  /// 是否是昨天.
  static bool isYesterdayByMs(int ms, int locMs) {
    return isYesterday(
      DateTime.fromMillisecondsSinceEpoch(ms),
      DateTime.fromMillisecondsSinceEpoch(locMs),
    );
  }

  /// is Week.
  /// 是否是本周.
  static bool isWeek(int ms, {bool isUtc = false, int locMs = 0}) {
    if (ms <= 0) {
      return false;
    }
    DateTime old = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: isUtc);
    DateTime? now;
    if (locMs != 0) {
      now = DateUtil.getDateTimeByMs(locMs, isUtc: isUtc);
    } else {
      now = isUtc ? DateTime.now().toUtc() : DateTime.now().toLocal();
    }

    if (now == null) {
      return false;
    }

    DateTime? tmpOld = now.millisecondsSinceEpoch > old.millisecondsSinceEpoch
        ? old
        : now;
    DateTime tmpNow = now.millisecondsSinceEpoch > old.millisecondsSinceEpoch
        ? now
        : old;
    return (tmpNow.weekday >= tmpOld.weekday) &&
        (tmpNow.millisecondsSinceEpoch - tmpOld.millisecondsSinceEpoch <=
            7 * 24 * 60 * 60 * 1000);
  }

  /// year is equal.
  /// 是否同年.
  static bool yearIsEqual(DateTime dateTime, DateTime locDateTime) {
    return dateTime.year == locDateTime.year;
  }

  /// year is equal.
  /// 是否同年.
  static bool yearIsEqualByMs(int ms, int locMs) {
    return yearIsEqual(
      DateTime.fromMillisecondsSinceEpoch(ms),
      DateTime.fromMillisecondsSinceEpoch(locMs),
    );
  }

  /// Return whether it is leap year.
  /// 是否是闰年
  static bool isLeapYear(DateTime dateTime) {
    return isLeapYearByYear(dateTime.year);
  }

  /// Return whether it is leap year.
  /// 是否是闰年
  static bool isLeapYearByYear(int year) {
    return year % 4 == 0 && year % 100 != 0 || year % 400 == 0;
  }
}

extension DateUtilsExt on DateUtil {
  static DateFormat _df1 = DateFormat(Copywriting.security_mM_dd_HH_mm);
  static DateFormat _df2 = DateFormat("HH:mm");

  static String commonCovertTime(int time, {String newPattern = "yyyy-MM-dd"}) {
    return DateFormat(
      newPattern,
    ).format(DateTime.fromMillisecondsSinceEpoch(time));
  }

  /// Formats a moment timestamp as relative time while it is recent, then
  /// falls back to an absolute date so old content remains unambiguous.
  static String formatMomentTime(int milliseconds, {DateTime? now}) {
    if (milliseconds <= 0) {
      return '';
    }

    final currentTime = now ?? DateTime.now();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final difference = currentTime.difference(createdAt);

    if (difference.isNegative || difference.inMinutes < 1) {
      return Copywriting.security_just_now;
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1
          ? Copywriting.security_one_minute_ago
          : _withCount(Copywriting.security_minutes_ago, minutes);
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1
          ? Copywriting.security_one_hour_ago
          : _withCount(Copywriting.security_hours_ago, hours);
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1
          ? Copywriting.security_one_day_ago
          : _withCount(Copywriting.security_days_ago, days);
    }
    if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return weeks == 1
          ? Copywriting.security_one_week_ago
          : _withCount(Copywriting.security_weeks_ago, weeks);
    }

    final pattern = createdAt.year == currentTime.year
        ? Copywriting.security_mM_dd_HH_mm
        : DateFormats.y_mo_d;
    return DateFormat(pattern).format(createdAt);
  }

  static String _withCount(String template, int count) {
    return template.replaceAll('{count}', count.toString());
  }

  ///封号的时间格式化
  static String fhTime(int time) {
    return DateFormat(
      "yyyy.MM.dd HH:mm",
    ).format(DateTime.fromMillisecondsSinceEpoch(time));
  }

  ///广场的时间格式化
  static String convertTime(int time) {
    if (time == 0) {
      return '';
    }
    var now = DateTime.now();
    var dataTime = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    if (DateTime(now.year, now.month, now.day).millisecondsSinceEpoch >
        time * 1000) {
      ///昨天之前
      return _df1.format(dataTime);
    } else {
      return _df2.format(dataTime);
    }
  }

  ///倒计时 13位时间戳
  static String downTime(int seconds) {
    if (seconds >= 0) {
      int minu = seconds ~/ 60;
      int second = seconds % 60;
      String time = minu >= 10 ? '$minu:' : '0$minu:';
      time = second >= 10 ? (time + '$second') : (time + '0$second');
      return time;
    }
    return '';
  }

  ///倒计时 13位时间戳
  static String downTimeDay(int seconds) {
    if (seconds >= 0) {
      int hour = seconds ~/ (60 * 60);
      int minu = (seconds - hour * 60 * 60) ~/ 60;
      int second = seconds % 60;

      String time = hour >= 10 ? '$hour : ' : '0$hour : ';

      time = minu >= 10 ? (time + '$minu : ') : (time + '0$minu : ');

      time = second >= 10 ? (time + '$second') : (time + '0$second');
      return time;
    }
    return '';
  }

  ///倒计时 13位时间戳
  static String downTimeWithHH_MMOr_MM_SS(int seconds) {
    int hourSecs = 60 * 60;
    int hour = seconds ~/ hourSecs;
    int minu = (seconds - hour * hourSecs) ~/ 60;
    int second = seconds % 60;

    if (hour > 0) {
      String time = hour >= 10 ? '$hour:' : '0$hour:';
      return minu >= 10 ? ('$time$minu') : ('${time}0$minu');
    } else {
      return minu >= 10 ? '$minu:$second' : '0$minu:$second';
    }
  }
}
