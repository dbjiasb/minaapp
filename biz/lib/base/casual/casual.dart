import 'package:biz/base/crypt/routes.dart';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../crypt/copywriting.dart';

class Casual {
  //给定一个字符串长度，随机生成一个字符串
  // static String randomString(int length) {}

  //给定一个范围，生成一个随机数字
  static int randomInRange(int min, int max) {
    if (min >= max) {
      String err = Copywriting.security_error__min_is_greater_than_or_equal_to_max;
      throw ArgumentError(err);
    }
    final random = Random.secure();
    return min + random.nextInt(max - min + 1);
  }

  //给定一个正数，生成0到该数减1范围内的随机数字
  static int randomWithin(int max) {
    if (max <= 0) {
      throw ArgumentError(Copywriting.security_error__max_should_not_be_a_negative_number_or_zero);
    }
    return randomInRange(0, max - 1);
  }

  //生成一个随机的UUID
  static String randomUUID() {
    return const Uuid().v4().replaceAll('-', '');
  }

  //随机生成一个ip
  static String randomIP() {
    return '${randomWithin(255)}.${randomWithin(255)}.${randomWithin(255)}.${randomWithin(255)}';
  }

  //随机生成一个时区
  static String randomTimeZone() {
    return 'UTC+${randomWithin(12)}';
  }
}
