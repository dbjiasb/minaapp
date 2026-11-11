import 'dart:async';

import 'package:biz/base/api_service/api_request.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/home_page_lists/home_feed_logic.dart';
import 'package:flutter_test/flutter_test.dart';

ApiResponse page(List<Map> items) => ApiResponse(response: {})
  ..statusCode = 200
  ..data = {
    Constants.statusData: {Security.security_code: 0},
    Security.security_param: items,
    Security.security_hasMore: true,
  };

void main() {
  test(
    'requests only page zero and interleaves both sources with their types',
    () async {
      final requests = <ApiRequest>[];
      final roles = Completer<ApiResponse>();
      final stories = Completer<ApiResponse>();
      final logic = HomeFeedLogic(
        sendRequest: (request) {
          requests.add(request);
          return request.method == Apis.security_fetchUsers
              ? roles.future
              : stories.future;
        },
      );
      final loading = logic.refreshData();
      // Both requests start before either one completes; repeated refreshes coalesce.
      final repeated = logic.refreshData();
      expect(requests.length, 2);
      expect(requests[0].params[Security.security_index], 0);
      expect(requests[0].params[Security.security_length], 20);
      expect(requests[0].params[Security.security_type], 0);
      expect(requests[0].params[Security.security_filterCondition], isEmpty);
      expect(requests[1].method, Apis.security_getRecommendSceneList);
      expect(requests[1].params[Security.security_pageIndex], 0);
      expect(requests[1].params[Security.security_pageSize], 10);
      roles.complete(
        page([
          {'id': 'r1'},
          {'id': 'r2'},
          {'id': 'r3'},
        ]),
      );
      stories.complete(
        page([
          {'id': 's1'},
          {'id': 's2'},
        ]),
      );
      await Future.wait([loading, repeated]);
      expect(logic.items.map((item) => item.data['id']), [
        'r1',
        's1',
        'r2',
        's2',
        'r3',
      ]);
      expect(logic.items.map((item) => item.isStory), [
        false,
        true,
        false,
        true,
        false,
      ]);
      expect(logic.isLoading.value, isFalse);
      expect(logic.hasError.value, isFalse);
      // Even a hasMore response never triggers another request.
      await Future<void>.delayed(Duration.zero);
      expect(requests.length, 2);
    },
  );

  test(
    'refresh replaces the feed and requests both first pages again',
    () async {
      final requests = <ApiRequest>[];
      final logic = HomeFeedLogic(
        sendRequest: (request) async {
          requests.add(request);
          return page([
            {'id': requests.length},
          ]);
        },
      );
      await logic.refreshData();
      await logic.refreshData();
      expect(requests.length, 4);
      expect(logic.items.map((item) => item.data['id']), [3, 4]);
      for (final request in requests) {
        expect(
          request.params[request.method == Apis.security_fetchUsers
              ? Security.security_index
              : Security.security_pageIndex],
          0,
        );
      }
    },
  );

  for (final rolesFinishFirst in [true, false]) {
    test('refresh keeps the current feed until both sources finish '
        '(${rolesFinishFirst ? 'roles' : 'stories'} first)', () async {
      final roles = Completer<ApiResponse>();
      final stories = Completer<ApiResponse>();
      var requestCount = 0;
      final logic = HomeFeedLogic(
        sendRequest: (request) async {
          requestCount++;
          final isRole = request.method == Apis.security_fetchUsers;
          if (requestCount <= 2) {
            return page([
              {'id': isRole ? 'old-role' : 'old-story'},
            ]);
          }
          return isRole ? roles.future : stories.future;
        },
      );
      await logic.refreshData();
      final snapshots = <List<dynamic>>[];
      final subscription = logic.items.listen((items) {
        snapshots.add(items.map((item) => item.data['id']).toList());
      });
      addTearDown(subscription.cancel);
      var refreshCompleted = false;
      final refreshing = logic.refreshData().then((_) {
        refreshCompleted = true;
      });
      expect(requestCount, 4);

      final first = rolesFinishFirst ? roles : stories;
      final second = rolesFinishFirst ? stories : roles;
      first.complete(
        page([
          {'id': rolesFinishFirst ? 'new-role' : 'new-story'},
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(logic.items.map((item) => item.data['id']), [
        'old-role',
        'old-story',
      ]);
      expect(snapshots, isEmpty);
      expect(refreshCompleted, isFalse);

      second.complete(
        page([
          {'id': rolesFinishFirst ? 'new-story' : 'new-role'},
        ]),
      );
      await refreshing;
      await Future<void>.delayed(Duration.zero);

      expect(refreshCompleted, isTrue);
      expect(snapshots, [
        ['new-role', 'new-story'],
      ]);
    });
  }

  test(
    'a failed source still displays the other source and allows retry',
    () async {
      var fail = true;
      final logic = HomeFeedLogic(
        sendRequest: (request) async {
          if (fail && request.method == Apis.security_fetchUsers) {
            throw StateError('offline');
          }
          return page([
            {'id': request.method},
          ]);
        },
      );
      await logic.refreshData();
      expect(logic.items.single.isStory, isTrue);
      expect(logic.hasError.value, isTrue);
      expect(logic.isLoading.value, isFalse);
      fail = false;
      await logic.refreshData();
      expect(logic.items.length, 2);
      expect(logic.hasError.value, isFalse);
    },
  );
}
