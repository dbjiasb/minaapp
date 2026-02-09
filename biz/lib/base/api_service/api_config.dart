import 'package:biz/base/environment/environment.dart';

abstract final class ApiConfig {
  static String get baseUrl => Environment.instance.isDev ? 'https://test-api.heartink.online' : 'https://api.heartink.online';
  static const String path = '/mina';
  static String get wsUrl => Environment.instance.isDev ? 'ws://test-ws.heartink.online' : 'ws://ws.heartink.online';
  static const String cdn = 'https://cdn.heartink.online';
}
