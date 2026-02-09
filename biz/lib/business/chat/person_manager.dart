import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';

import 'package:biz/base/api_service/api_request.dart';
import 'package:biz/base/api_service/api_service.dart';

import '../../core/user_manager/user_manager.dart';

class PersonManager {
  //生成单利
  static final PersonManager _instance = PersonManager._internal();

  PersonManager._internal();

  factory PersonManager() => _instance;

  static PersonManager get instance => _instance;

  Future<bool> collectUser(int userId, int todo) async {
    final req = ApiRequest(Apis.security_star, params: {Security.security_otherUid: userId, Security.security_action: todo});
    final rsp = await ApiService.instance.sendRequest(req);
    if (rsp.isSuccess) {
      return true;
    }
    return false;
  }
}
