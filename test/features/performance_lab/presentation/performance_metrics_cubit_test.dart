import 'package:codingtask/core/database/app_database.dart';
import 'package:codingtask/core/database/daos/sync_metadata_dao.dart';
import 'package:codingtask/core/performance/performance_metrics.dart';
import 'package:codingtask/features/performance_lab/presentation/cubit/performance_metrics_cubit.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncMetadataDao dao;
  late PerformanceMetrics metrics;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SyncMetadataDao(db);
    metrics = PerformanceMetrics();
  });

  tearDown(() async {
    await metrics.dispose();
    await db.close();
  });

  test('emits new state when metrics record an api call', () async {
    final cubit = PerformanceMetricsCubit(metrics, syncMetadataDao: dao);
    final emitted = <int>[];
    final sub = cubit.stream.listen((s) => emitted.add(s.snapshot.apiCalls.length));

    metrics.recordApiCall(
      url: 'x',
      duration: const Duration(milliseconds: 12),
      ok: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(emitted, contains(1));
    await sub.cancel();
    await cubit.close();
  });

  test('reflects sync metadata changes', () async {
    final cubit = PerformanceMetricsCubit(metrics, syncMetadataDao: dao);
    await dao.markSuccess('refresh_all');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.lastSync?.lastStatus, 'success');
    await cubit.close();
  });
}
