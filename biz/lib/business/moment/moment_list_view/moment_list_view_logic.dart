import 'package:get/get.dart';

import '../../../localize/tab_labels.dart';

class MomentListViewLogic extends GetxController {
  List<String> get titleList => [TabLabels.forYou, TabLabels.followed];

  RxInt currentIndex = 0.obs;

  String get currentTitle => titleList[currentIndex.value];

}
