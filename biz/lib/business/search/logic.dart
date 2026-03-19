import 'package:biz/base/crypt/routes.dart';
import 'package:get/get.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../base/api_service/api_request.dart';
import '../../base/api_service/api_response.dart';
import '../../base/api_service/api_service.dart';
import '../../base/crypt/apis.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/security.dart';

class SearchLogic extends GetxController {
  //0 未搜索，1 loading 2 success,3.other error
  RxString searchStatus = "0".obs;

  RxInt curIndex = 0.obs;

  RxList<dynamic> rxSearchList = RxList(); //搜索到的结果都在这里面了，要放在瀑布流中展示的数据

  static RxList recentSearch = [].obs; //可以直接弄成static，那么就说明大家用的永远是这一份，
  //不加static则每次调用都需要传一次全局的变量

  String convertNum(int num) {
    if (num > 1000) {
      return '${(num / 1000).toStringAsFixed(1)}k';
    }
    return num.toString();
  }

  String searchText = "";

  void search(String value) {
    searchStatus.value = "1";
    searchText = value;
    _searchUser(value);
  }

  void _searchUser(String searchValue) async {
    ApiRequest request = ApiRequest(Apis.security_searchUser,
      params: {Security.security_keyword: searchValue},
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      List<dynamic> data = response.data[Security.security_result] ?? [];
      if (searchText == searchValue && data.isNotEmpty) {
        rxSearchList.value = data;
        searchStatus.value = "2";
      } else {
        searchStatus.value = Security.security_nothingHere;
        rxSearchList.clear();
      }
    } else {
      if (searchText == searchValue) {
        searchStatus.value = Copywriting.security_search_Failed;
        rxSearchList.clear();
      }
      Toast.show(response.description);
    }
  }
}
