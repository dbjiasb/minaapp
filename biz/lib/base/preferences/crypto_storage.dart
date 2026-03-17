import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:get_storage/get_storage.dart';

class CryptoStorage {
  static String md5For(String data) {
    final content = utf8.encode(data);
    final digest = md5.convert(content);
    return digest.toString();
  }

  static Future<void> write(String key, dynamic value) async {
    return GetStorage().write(md5For(key), value);
  }

  static T? read<T>(String key) {
    return GetStorage().read<T>(md5For(key));
  }

  static bool hasData(String key) {
    return GetStorage().hasData(md5For(key));
  }

  static Future<void> remove(String key) async {
    return GetStorage().remove(md5For(key));
  }

  static Future<void> erase() async {
    return GetStorage().erase();
  }

  static Future<void> clearStorageButKeep(List<String> keysToKeep) async {
    final Map<String, dynamic> preserved = {};
    for (final key in keysToKeep) {
      if (hasData(key)) {
        preserved[key] = await read(key);
      }
    }
    await erase();
    for (final entry in preserved.entries) {
      write(entry.key, entry.value);
    }
  }
}
