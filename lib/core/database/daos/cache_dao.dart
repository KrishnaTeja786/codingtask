import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'cache_dao.g.dart';

class CacheRecord {
  const CacheRecord({
    required this.payload,
    required this.fetchedAt,
    required this.expiresAt,
  });
  final String payload;
  final DateTime fetchedAt;
  final DateTime expiresAt;

  bool get isFresh => DateTime.now().isBefore(expiresAt);
}

@DriftAccessor(tables: [HttpCacheEntries])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  CacheDao(super.db);

  Future<CacheRecord?> get(String key) async {
    final row = await (select(httpCacheEntries)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    return CacheRecord(
      payload: row.payload,
      fetchedAt: row.fetchedAt,
      expiresAt: row.expiresAt,
    );
  }

  Future<void> put({
    required String key,
    required String payload,
    required Duration ttl,
  }) {
    final now = DateTime.now();
    return into(httpCacheEntries).insertOnConflictUpdate(
      HttpCacheEntriesCompanion.insert(
        cacheKey: key,
        payload: payload,
        fetchedAt: now,
        expiresAt: now.add(ttl),
      ),
    );
  }

  Future<void> evict(String key) =>
      (delete(httpCacheEntries)..where((t) => t.cacheKey.equals(key))).go();
}
