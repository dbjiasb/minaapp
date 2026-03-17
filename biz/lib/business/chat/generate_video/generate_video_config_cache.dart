import '../../../base/buffer_queue/buffer_queue.dart';

class GenerateVideoConfigCache {
  static final GenerateVideoConfigCache _instance = GenerateVideoConfigCache._internal();

  GenerateVideoConfigCache._internal();

  factory GenerateVideoConfigCache() => _instance;

  static GenerateVideoConfigCache get instance => _instance;

  BufferQueue cache = BufferQueue(10);

  save(int userId, Map map) {
    cache.setObject("GenerateVideoConfigCache$userId", map);
  }

  Map? get(int userId) {
    return cache.getObject("GenerateVideoConfigCache$userId");
  }
}
