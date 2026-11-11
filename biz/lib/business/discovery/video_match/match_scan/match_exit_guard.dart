enum MatchExitOutcome { cancelled, failed, exited, busy }

/// Keeps the route open until confirmation and server cleanup both succeed.
class MatchExitGuard {
  bool _pending = false;

  Future<MatchExitOutcome> run({
    required Future<bool> Function() confirm,
    required Future<bool> Function() cancel,
    required void Function() leave,
  }) async {
    if (_pending) return MatchExitOutcome.busy;
    _pending = true;
    try {
      if (!await confirm()) return MatchExitOutcome.cancelled;
      if (!await cancel()) return MatchExitOutcome.failed;
      leave();
      return MatchExitOutcome.exited;
    } finally {
      _pending = false;
    }
  }
}
