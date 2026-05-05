import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'favorites_dao.g.dart';

@DriftAccessor(tables: [FavoriteRepos, BookmarkedArticles])
class FavoritesDao extends DatabaseAccessor<AppDatabase>
    with _$FavoritesDaoMixin {
  FavoritesDao(super.db);

  // ----- Repos -----
  Stream<List<FavoriteRepo>> watchAllRepos() {
    return (select(favoriteRepos)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .watch();
  }

  Future<bool> isRepoFavorite(int id) async {
    final row = await (select(favoriteRepos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> upsertRepo(FavoriteReposCompanion entry) =>
      into(favoriteRepos).insertOnConflictUpdate(entry);

  Future<void> removeRepo(int id) =>
      (delete(favoriteRepos)..where((t) => t.id.equals(id))).go();

  // ----- Articles -----
  Stream<List<BookmarkedArticle>> watchAllArticles() {
    return (select(bookmarkedArticles)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .watch();
  }

  Future<bool> isArticleBookmarked(int id) async {
    final row =
        await (select(bookmarkedArticles)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> upsertArticle(BookmarkedArticlesCompanion entry) =>
      into(bookmarkedArticles).insertOnConflictUpdate(entry);

  Future<void> removeArticle(int id) =>
      (delete(bookmarkedArticles)..where((t) => t.id.equals(id))).go();
}
