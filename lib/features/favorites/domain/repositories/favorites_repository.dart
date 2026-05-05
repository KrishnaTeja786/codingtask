import '../../../github_trends/domain/entities/repo_entity.dart';
import '../../../tech_feed/domain/entities/article_entity.dart';

/// Snapshot wrapper so the repo never leaks Drift types.
class FavoriteRepoEntry {
  const FavoriteRepoEntry({required this.repo, required this.savedAt});
  final RepoEntity repo;
  final DateTime savedAt;
}

class BookmarkedArticleEntry {
  const BookmarkedArticleEntry({
    required this.article,
    required this.savedAt,
  });
  final ArticleEntity article;
  final DateTime savedAt;
}

abstract interface class FavoritesRepository {
  Stream<List<FavoriteRepoEntry>> watchFavoriteRepos();
  Stream<Set<int>> watchFavoriteRepoIds();
  Future<void> toggleFavoriteRepo(RepoEntity repo);
  Future<void> removeFavoriteRepo(int id);

  Stream<List<BookmarkedArticleEntry>> watchBookmarkedArticles();
  Stream<Set<int>> watchBookmarkedArticleIds();
  Future<void> toggleBookmarkArticle(ArticleEntity article);
  Future<void> removeBookmarkedArticle(int id);
}
