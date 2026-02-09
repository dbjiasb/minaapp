extension ListEx<E> on List<E>? {

  List<E> safeSublist(int start, int end) {
    if (this == null) {
      return [];
    }
    if (0 <= start && start <= this!.length && end >= start) {
      if (end > this!.length) {
        end = this!.length;
      }
      return this!.sublist(start, end);
    }
    return [];
  }

  void safeInsert(int index, E value) {
    if (this == null) {
      return;
    }
    if (index >= 0 && index <= this!.length) {
      this!.insert(index, value);
    } else {
      this!.add(value);
    }
  }

  E? firstOrNull() {
    return isNullOrEmpty() ? null : this!.first;
  }

  bool isNullOrEmpty() {
    return this == null || this!.isEmpty;
  }

  E safeGet(int index, E defaultValue) {
    if (this == null) {
      return defaultValue;
    }
    if (index >= 0 && index < this!.length) {
      return this![index];
    } else {
      return defaultValue;
    }
  }

}
