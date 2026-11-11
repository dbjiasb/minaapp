import 'dart:async';

import 'package:biz/business/discovery/video_match/match_scan/match_exit_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declining exit leaves the route and matching untouched', () async {
    var requests = 0;
    var pops = 0;
    final outcome = await MatchExitGuard().run(
      confirm: () async => false,
      cancel: () async {
        requests++;
        return true;
      },
      leave: () => pops++,
    );
    expect(outcome, MatchExitOutcome.cancelled);
    expect(requests, 0);
    expect(pops, 0);
  });

  test('failed cleanup keeps the route open', () async {
    var pops = 0;
    final outcome = await MatchExitGuard().run(
      confirm: () async => true,
      cancel: () async => false,
      leave: () => pops++,
    );
    expect(outcome, MatchExitOutcome.failed);
    expect(pops, 0);
  });

  test('exit waits for cleanup and ignores repeated back taps', () async {
    final guard = MatchExitGuard();
    final cleanup = Completer<bool>();
    var dialogs = 0;
    var requests = 0;
    var pops = 0;
    Future<MatchExitOutcome> back() => guard.run(
      confirm: () async {
        dialogs++;
        return true;
      },
      cancel: () {
        requests++;
        return cleanup.future;
      },
      leave: () => pops++,
    );
    final pending = back();
    await Future<void>.delayed(Duration.zero);
    expect(await back(), MatchExitOutcome.busy);
    expect(dialogs, 1);
    expect(requests, 1);
    expect(pops, 0);
    cleanup.complete(true);
    expect(await pending, MatchExitOutcome.exited);
    expect(pops, 1);
  });

  test('a cleanup exception permits retry and never pops', () async {
    final guard = MatchExitGuard();
    var pops = 0;
    await expectLater(
      guard.run(
        confirm: () async => true,
        cancel: () async => throw StateError('offline'),
        leave: () => pops++,
      ),
      throwsStateError,
    );
    expect(pops, 0);
    expect(
      await guard.run(
        confirm: () async => true,
        cancel: () async => true,
        leave: () => pops++,
      ),
      MatchExitOutcome.exited,
    );
    expect(pops, 1);
  });
}
