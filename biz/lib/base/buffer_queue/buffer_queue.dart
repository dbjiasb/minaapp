import 'dart:collection';

class BufferQueue {
  final int size;
  BufferQueue(this.size);

  // 使用LinkedHashMap实现LRU缓存
  final LinkedHashMap<Object, dynamic> _cache = LinkedHashMap();

  // 获取缓存（会更新访问顺序）
  dynamic getObject(Object key) {
    final value = _cache.remove(key); // 先移除旧位置
    if (value != null) {
      _cache[key] = value; // 重新插入到末尾（最近使用）
    }
    return value;
  }

  // 设置缓存（自动执行淘汰策略）
  void setObject(Object key, dynamic value) {
    // 先更新访问顺序
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }

    _cache[key] = value;

    // 执行淘汰策略
    while (_cache.length > size) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
  }

  // 删除指定缓存
  void removeObject(Object key) {
    _cache.remove(key);
  }

  // 清空所有缓存
  void removeAllObjects() {
    _cache.clear();
  }
}
