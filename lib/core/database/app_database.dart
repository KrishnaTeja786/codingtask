import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Schema versioning is intentional: bumping [schemaVersion] + adding a
/// MigrationStrategy step is how we'd handle column additions in production.
@DriftDatabase(tables: [
  FavoriteRepos,
  BookmarkedArticles,
  HttpCacheEntries,
  SyncMetadata,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Production migration pattern. Example for v1 -> v2:
          // if (from < 2) {
          //   await m.addColumn(favoriteRepos, favoriteRepos.tagsCsv);
          // }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'smart_devhub.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
