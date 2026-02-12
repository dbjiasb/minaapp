import 'package:encrypt/encrypt.dart';

final _aesKey = Key.fromUtf8('CDhvMci5g7ExnCT885TqT7LT9S9I2A5l');
final _iv = IV.fromUtf8('xm7uIbAfnoq8TxCJ');

String decrypt(String encrypted) {
  final cipher = AES(_aesKey, mode: AESMode.cbc);
  final encrypter = Encrypter(cipher);
  return encrypter.decrypt64(encrypted, iv: _iv);
}
