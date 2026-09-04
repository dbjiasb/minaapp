import 'dart:ui';

import 'package:biz/core/util/date_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  final now = DateTime(2026, 9, 4, 12);

  String format(Duration age) {
    return DateUtilsExt.formatMomentTime(
      now.subtract(age).millisecondsSinceEpoch,
      now: now,
    );
  }

  setUp(() {
    Get.locale = const Locale('en', 'US');
  });

  tearDown(() {
    Get.locale = null;
  });

  test('formats recent moment times into relative buckets', () {
    expect(format(const Duration(seconds: 59)), 'Just now');
    expect(format(const Duration(minutes: 1)), '1 minute ago');
    expect(format(const Duration(minutes: 59)), '59 minutes ago');
    expect(format(const Duration(hours: 1)  ), '1 hour ago');
    expect(format(const Duration(hours: 23)), '23 hours ago');
    expect(format(const Duration(days: 1)), '1 day ago');
    expect(format(const Duration(days: 6)), '6 days ago');
    expect(format(const Duration(days: 7)), '1 week ago');
    expect(format(const Duration(days: 29)), '4 weeks ago');
  });

  test('uses absolute dates for moments that are at least 30 days old', () {
    expect(format(const Duration(days: 30)), '08-05 12:00');
    expect(
      DateUtilsExt.formatMomentTime(
        DateTime(2025, 8, 5, 12).millisecondsSinceEpoch,
        now: now,
      ),
      '2025-08-05',
    );
  });

  test('handles invalid and future timestamps', () {
    expect(DateUtilsExt.formatMomentTime(0, now: now), isEmpty);
    expect(
      DateUtilsExt.formatMomentTime(
        now.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        now: now,
      ),
      'Just now',
    );
  });

  test('uses the active locale for relative time', () {
    Get.locale = const Locale('de', 'DE');
    expect(format(const Duration(minutes: 2)), 'Vor 2 Minuten');

    Get.locale = const Locale('ar', 'AE');
    expect(format(const Duration(days: 2)), 'منذ 2 يوم');
  });
}
