import 'package:drift/drift.dart';

/// Drift table for favorite GitHub repos. We persist a denormalized snapshot
/// so the Favorites tab works fully offline without re-fetching.
class FavoriteRepos extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get fullName => text()();
  TextColumn get description => text().nullable()();
  TextColumn get ownerLogin => text()();
  TextColumn get ownerAvatarUrl => text()();
  TextColumn get htmlUrl => text()();
  TextColumn get language => text().nullable()();
  IntColumn get stars => integer().withDefault(const Constant(0))();
  IntColumn get forks => integer().withDefault(const Constant(0))();
  DateTimeColumn get pushedAt => dateTime().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Bookmarked Hacker News stories. Same denormalization rationale.
class BookmarkedArticles extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get url => text().nullable()();
  TextColumn get author => text().nullable()();
  IntColumn get score => integer().withDefault(const Constant(0))();
  IntColumn get commentCount => integer().withDefault(const Constant(0))();
  TextColumn get topic => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Generic key/value cache for raw API responses. TTL is enforced at read
/// time; entries past expiry are kept until the next write so they can still
/// serve as offline fallback.
class HttpCacheEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

/// Tracks last sync time / status per logical job. Used by the Performance
/// Lab metrics panel and to dedupe background jobs.
class SyncMetadata extends Table {
  TextColumn get jobId => text()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastStatus => text().withDefault(const Constant('idle'))();
  TextColumn get lastError => text().nullable()();
  IntColumn get runCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {jobId};
}
