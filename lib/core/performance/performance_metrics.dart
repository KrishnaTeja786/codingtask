import 'dart:async';
import 'dart:collection';

/// Centralized perf sink consumed by the Performance Lab tab.
///
/// Kept framework-agnostic (no Flutter import) so it stays usable in
/// background isolates and unit tests. All emissions are constant-time;
/// readers subscribe to a broadcast stream to avoid pulling lists per frame.
class PerformanceMetrics {
  PerformanceMetrics({int historyLimit = 50}) : _historyLimit = historyLimit;

  final int _historyLimit;
  final _controller = StreamController<PerfSnapshot>.broadcast();
  final Queue<ApiCallSample> _apiCalls = Queue();
  final Queue<DbReadSample> _dbReads = Queue();
  int _cacheHits = 0;
  int _cacheMisses = 0;
  String _backgroundStatus = 'idle';

  Stream<PerfSnapshot> get stream => _controller.stream;

  PerfSnapshot snapshot() => PerfSnapshot(
        apiCalls: List.unmodifiable(_apiCalls),
        dbReads: List.unmodifiable(_dbReads),
        cacheHits: _cacheHits,
        cacheMisses: _cacheMisses,
        backgroundStatus: _backgroundStatus,
      );

  void recordApiCall({
    required String url,
    required Duration duration,
    required bool ok,
    int? statusCode,
  }) {
    _apiCalls.addLast(
      ApiCallSample(
        url: url,
        duration: duration,
        ok: ok,
        statusCode: statusCode,
        at: DateTime.now(),
      ),
    );
    _trim(_apiCalls);
    _emit();
  }

  void recordDbRead({required String label, required Duration duration}) {
    _dbReads.addLast(
      DbReadSample(label: label, duration: duration, at: DateTime.now()),
    );
    _trim(_dbReads);
    _emit();
  }

  void recordCacheHit() {
    _cacheHits++;
    _emit();
  }

  void recordCacheMiss() {
    _cacheMisses++;
    _emit();
  }

  void recordBackgroundStatus(String status) {
    _backgroundStatus = status;
    _emit();
  }

  void _trim(Queue<Object?> q) {
    while (q.length > _historyLimit) {
      q.removeFirst();
    }
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(snapshot());
  }

  Future<void> dispose() => _controller.close();
}

/// Helper for scoped DB read timing. Use with `await metrics.timeDbRead(...)`.
extension DbReadTimer on PerformanceMetrics {
  Future<T> timeDbRead<T>(String label, Future<T> Function() body) async {
    final sw = Stopwatch()..start();
    try {
      return await body();
    } finally {
      sw.stop();
      recordDbRead(label: label, duration: sw.elapsed);
    }
  }
}

class PerfSnapshot {
  const PerfSnapshot({
    required this.apiCalls,
    required this.dbReads,
    required this.cacheHits,
    required this.cacheMisses,
    required this.backgroundStatus,
  });
  final List<ApiCallSample> apiCalls;
  final List<DbReadSample> dbReads;
  final int cacheHits;
  final int cacheMisses;
  final String backgroundStatus;

  Duration? get avgApi {
    if (apiCalls.isEmpty) return null;
    final us =
        apiCalls.fold<int>(0, (a, b) => a + b.duration.inMicroseconds) /
            apiCalls.length;
    return Duration(microseconds: us.round());
  }

  Duration? get avgDb {
    if (dbReads.isEmpty) return null;
    final us = dbReads.fold<int>(0, (a, b) => a + b.duration.inMicroseconds) /
        dbReads.length;
    return Duration(microseconds: us.round());
  }

  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    if (total == 0) return 0;
    return cacheHits / total;
  }
}

class ApiCallSample {
  const ApiCallSample({
    required this.url,
    required this.duration,
    required this.ok,
    required this.at,
    this.statusCode,
  });
  final String url;
  final Duration duration;
  final bool ok;
  final int? statusCode;
  final DateTime at;
}

class DbReadSample {
  const DbReadSample({
    required this.label,
    required this.duration,
    required this.at,
  });
  final String label;
  final Duration duration;
  final DateTime at;
}
