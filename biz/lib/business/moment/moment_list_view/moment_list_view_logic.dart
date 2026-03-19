import 'package:biz/base/crypt/routes.dart';
import 'package:get/get.dart';

import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';

class MomentListViewLogic extends GetxController {
  final titleList = [Copywriting.security_for_You, Security.security_followed];

  RxInt currentIndex = 0.obs;

  String get currentTitle => titleList[currentIndex.value];

}
