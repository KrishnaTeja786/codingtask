import 'package:codingtask/core/database/app_database.dart';
import 'package:codingtask/core/database/daos/favorites_dao.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FavoritesDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = FavoritesDao(db);
  });

  tearDown(() => db.close());

  test('upsert + isFavorite + remove repo', () async {
    expect(await dao.isRepoFavorite(1), isFalse);
    await dao.upsertRepo(FavoriteReposCompanion.insert(
      id: const Value(1),
      name: 'flutter',
      fullName: 'flutter/flutter',
      ownerLogin: 'flutter',
      ownerAvatarUrl: 'https://x',
      htmlUrl: 'https://github.com/flutter/flutter',
      savedAt: DateTime.utc(2026),
    ));
    expect(await dao.isRepoFavorite(1), isTrue);
    await dao.removeRepo(1);
    expect(await dao.isRepoFavorite(1), isFalse);
  });

  test('articles upsert/remove', () async {
    await dao.upsertArticle(BookmarkedArticlesCompanion.insert(
      id: const Value(7),
      title: 't',
      createdAt: DateTime.utc(2026),
      savedAt: DateTime.utc(2026),
    ));
    expect(await dao.isArticleBookmarked(7), isTrue);
    await dao.removeArticle(7);
    expect(await dao.isArticleBookmarked(7), isFalse);
  });
}
