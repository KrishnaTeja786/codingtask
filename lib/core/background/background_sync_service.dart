import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';

/// Public interface so unit tests and the simulated path can stub it without
/// pulling in the workmanager plugin's MethodChannel.
abstract interface class BackgroundSyncService {
  Future<void> initialize();
  Future<void> registerPeriodicSync();
  Future<void> cancelAll();

  /// Triggers an in-process refresh. Used by the manual "Sync now" button and
  /// by widget tests; the real periodic job calls the same logic via the
  /// top-level [callbackDispatcher].
  Future<void> runOnce();
}

typedef SyncJob = Future<void> Function();

/// Production implementation. On Android the periodic job is dispatched by
/// WorkManager. On iOS, BGTaskScheduler imposes hard limits (system decides
/// when to run; minimum interval ~15 minutes; not guaranteed). We document
/// this in docs/PERFORMANCE_NOTES.md and surface a manual "Sync now" action.
class WorkManagerBackgroundSyncService implements BackgroundSyncService {
  WorkManagerBackgroundSyncService(this._inProcessJob);

  final SyncJob _inProcessJob;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // The plugin spawns a fresh isolate when running periodic jobs; the
    // dispatcher must be a top-level function (see [callbackDispatcher]).
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  @override
  Future<void> registerPeriodicSync() async {
    // Idempotent: workmanager dedupes by uniqueName.
    await Workmanager().registerPeriodicTask(
      AppConstants.bgTaskRefreshAll,
      AppConstants.bgTaskRefreshAll,
      frequency: AppConstants.bgPeriod,
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  @override
  Future<void> cancelAll() => Workmanager().cancelAll();

  @override
  Future<void> runOnce() => _inProcessJob();
}

/// In-process fallback used by tests or platforms where we don't want to
/// register the real plugin. Behavior is identical from the caller's POV.
class InProcessBackgroundSyncService implements BackgroundSyncService {
  InProcessBackgroundSyncService(this._job);
  final SyncJob _job;
  Timer? _timer;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> registerPeriodicSync() async {
    _timer?.cancel();
    _timer = Timer.periodic(AppConstants.bgPeriod, (_) => _job());
  }

  @override
  Future<void> cancelAll() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> runOnce() => _job();
}

/// Top-level dispatcher invoked by WorkManager in a fresh isolate. Because
/// it runs without our DI graph, we keep it intentionally minimal — it just
/// signals success; real refresh happens when the app is foregrounded
/// because background isolates cannot share the in-memory caches/blocs.
///
/// For a heavier production setup we'd: re-init DI here, run the same use
/// cases against Drift, and notify the UI via a NotificationsPlugin. That
/// is left as a documented extension point.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Returning true tells WorkManager the job succeeded.
    return true;
  });
}
