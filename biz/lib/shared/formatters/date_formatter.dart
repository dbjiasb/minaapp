import 'package:intl/intl.dart';
class DateFormatter {
  static String format(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm'}) {
    return dateTime.toString();
  }

  static String getTodayStr() {
    return DateFormat("yyyy-MM-dd").format(DateTime.now());
  }

  static String diff(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays >= 1) {
      return "${time.month}/${time.day}";
    } else {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  static String formatSeconds(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = seconds ~/ 60;
    final secondsLeft = seconds % 60;

    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}";
    }
  }
}
