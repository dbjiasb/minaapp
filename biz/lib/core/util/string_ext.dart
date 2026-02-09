
extension StringExt on String? {
  int safeParse({int defaultValue = 0}) {
    if (this == null) {
      return defaultValue;
    }
    try {
      return int.parse(this!);
    } catch (e) {
      return defaultValue;
    }
  }
}
