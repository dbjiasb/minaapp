import 'package:biz/base/environment/environment.dart';

abstract final class ApiConfig {
  static String get baseUrl => Environment.instance.isDev ? 'https://test-api.miratales.online' : 'https://open.miratales.online';
  static const String path = '/mina';
  static String get wsUrl => Environment.instance.isDev ? 'ws://test-ws.miratales.online' : 'ws://ws.miratales.online';
  static const String cdn = 'https://cdn.miratales.online';
}
