import 'package:flutter/foundation.dart';

/// Monotonic active story time. Loading, pauses and mandatory dialogue are excluded.
class AttemptClock {
  AttemptClock({int Function()? nowMicros}) {
    final watch = Stopwatch()..start();
    _now = nowMicros ?? () => watch.elapsedMicroseconds;
  }
  late final int Function() _now;
  int _stored = 0;
  int? _segment;
  bool hasStarted = false;
  bool get running => _segment != null;
  int get durationMs =>
      (_stored + (_segment == null ? 0 : _now() - _segment!)) ~/ 1000;
  void resume() {
    if (!running) {
      hasStarted = true;
      _segment = _now();
    }
  }

  void pause() {
    if (running) {
      _stored += _now() - _segment!;
      _segment = null;
    }
  }

  void reset() {
    _stored = 0;
    _segment = null;
    hasStarted = false;
  }
}

class RunRecord {
  RunRecord({
    required this.attemptId,
    required this.stageId,
    required this.stageVersion,
    required this.durationMs,
    required this.deaths,
    required Set<String> collectibles,
    required this.completed,
  }) : collectibles = Set.unmodifiable(collectibles);
  final int attemptId, stageVersion, durationMs, deaths;
  final String stageId;
  final Set<String> collectibles;
  final bool completed;
}

class PlaySession extends ChangeNotifier {
  final List<RunRecord> _results = [];
  final Set<String> viewedMemories = {};
  int _serial = 0;
  int allocateAttempt() => ++_serial;
  List<RunRecord> get results => List.unmodifiable(_results);
  void record(RunRecord result) {
    if (_results.any((r) => r.attemptId == result.attemptId)) return;
    _results.add(result);
    notifyListeners();
  }
}
