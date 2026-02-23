import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/environment/environment.dart';
import 'package:biz/base/preferences/preferences.dart';

class ReportItem {
  final Map data;
  bool isLast = false;

  ReportItem(this.data);

  int get id => data[Security.security_id] ?? 0;

  String get desc => data[Security.security_desc] ?? '';
}

class ReportManager {
  //生成单利
  static final ReportManager _instance = ReportManager._internal();

  factory ReportManager() {
    return _instance;
  }

  ReportManager._internal();

  static ReportManager get instance => _instance;

  List<ReportItem> reportItems = [];

  //查询举报选项
  Future<List<ReportItem>> getReportOptions() async {
    if (reportItems.isNotEmpty) {
      return reportItems;
    }
    ApiRequest request = ApiRequest(Apis.security_fetchTipOffOptions);
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      List data = response.data[Security.security_reasons];
      List items = data.map((e) => ReportItem(e)).toList();
      ReportItem last = items.last;
      if (Preferences.instance.isRv) {
        items.removeLast();
        items.shuffle();
      }
      reportItems = [...items, last];
      return reportItems;
    } else {
      return [];
    }
  }

  //提交举报
  Future<ApiResponse> submitReport(int userId, int reasonId, {String extra = ''}) async {
    ApiRequest request = ApiRequest(
      Apis.security_tipOffUser,
      params: {Security.security_userId: userId, Security.security_optionId: reasonId, Security.security_additional: extra},
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    return response;
  }
}
