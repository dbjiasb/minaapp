import 'package:get/get.dart';

import '../../base/api_service/api_request.dart';
import '../../base/api_service/api_response.dart';
import '../../base/api_service/api_service.dart';
import '../../base/crypt/apis.dart';
import '../../base/crypt/security.dart';
import 'role_manager.dart';

typedef HomeFeedRequest = Future<ApiResponse> Function(ApiRequest request);

class HomeFeedItem {
  const HomeFeedItem(this.data, {required this.isStory});

  final Map data;
  final bool isStory;
}

/// A single feed of the first Recommend and Story pages, without pagination.
class HomeFeedLogic extends GetxController {
  HomeFeedLogic({HomeFeedRequest? sendRequest})
    : _sendRequest = sendRequest ?? _sendDefaultRequest;

  static Future<ApiResponse> _sendDefaultRequest(ApiRequest request) =>
      ApiService.instance.sendRequest(request);

  final HomeFeedRequest _sendRequest;
  final items = <HomeFeedItem>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  Future<void>? _refresh;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() =>
      _refresh ??= _loadFirstPages().whenComplete(() => _refresh = null);

  Future<void> _loadFirstPages() async {
    final pages = await Future.wait([
      _loadPage(
        ApiRequest(
          Apis.security_fetchUsers,
          params: {
            Security.security_version: 0,
            Security.security_index: 0,
            Security.security_length: 20,
            Security.security_type: RoleListType.ai_and_script.value,
            Security.security_userId: 0,
            Security.security_filterCondition: <String, dynamic>{},
          },
        ),
      ),
      _loadPage(
        ApiRequest(
          Apis.security_getRecommendSceneList,
          params: {
            Security.security_pageIndex: 0,
            Security.security_pageReal: 1,
            Security.security_normal: 100,
            Security.security_pageSize: 10,
          },
        ),
      ),
    ]);
    if (isClosed) return;

    final roles = pages[0] ?? <Map>[];
    final stories = pages[1] ?? <Map>[];
    final mixed = <HomeFeedItem>[];
    // Interleave so both content types appear from the start of the feed.
    for (var i = 0; i < roles.length || i < stories.length; i++) {
      if (i < roles.length) {
        mixed.add(HomeFeedItem(roles[i], isStory: false));
      }
      if (i < stories.length) {
        mixed.add(HomeFeedItem(stories[i], isStory: true));
      }
    }
    hasError.value = pages.any((page) => page == null);
    // Publish one snapshot only after both requests finish, keeping the current
    // feed visible throughout a pull-to-refresh.
    items.value = mixed;
    isLoading.value = false;
  }

  Future<List<Map>?> _loadPage(ApiRequest request) async {
    try {
      final response = await _sendRequest(request);
      if (!response.isSuccess) return null;
      return ((response.data[Security.security_param] ?? []) as List)
          .cast<Map>();
    } catch (_) {
      return null;
    }
  }
}
