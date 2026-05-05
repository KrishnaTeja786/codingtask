import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'sync_metadata_dao.g.dart';

@DriftAccessor(tables: [SyncMetadata])
class SyncMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.db);

  Future<SyncMetadataData?> get(String jobId) {
    return (select(syncMetadata)..where((t) => t.jobId.equals(jobId)))
        .getSingleOrNull();
  }

  Stream<SyncMetadataData?> watch(String jobId) {
    return (select(syncMetadata)..where((t) => t.jobId.equals(jobId)))
        .watchSingleOrNull();
  }

  Future<void> markStarted(String jobId) async {
    final existing = await get(jobId);
    await into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion.insert(
        jobId: jobId,
        lastAttemptAt: Value(DateTime.now()),
        lastStatus: const Value('running'),
        runCount: Value((existing?.runCount ?? 0) + 1),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markSuccess(String jobId) async {
    final now = DateTime.now();
    await into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion.insert(
        jobId: jobId,
        lastSuccessAt: Value(now),
        lastAttemptAt: Value(now),
        lastStatus: const Value('success'),
      ),
    );
  }

  Future<void> markFailure(String jobId, String error) {
    return into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion.insert(
        jobId: jobId,
        lastAttemptAt: Value(DateTime.now()),
        lastStatus: const Value('error'),
        lastError: Value(error),
      ),
    );
  }
}
