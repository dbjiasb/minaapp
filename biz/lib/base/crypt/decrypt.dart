import 'package:encrypt/encrypt.dart';

final _aesKey = Key.fromUtf8('32bytes-long-secret-key-12345678');
final _iv = IV.fromUtf8('16bytes-iv-strin');

String decrypt(String encrypted) {
  final cipher = AES(_aesKey, mode: AESMode.cbc);
  final encrypter = Encrypter(cipher);
  return encrypter.decrypt64(encrypted, iv: _iv);
}
