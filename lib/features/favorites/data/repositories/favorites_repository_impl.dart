import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/favorites_dao.dart';
import '../../../../core/performance/performance_metrics.dart';
import '../../../github_trends/domain/entities/repo_entity.dart';
import '../../../tech_feed/domain/entities/article_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import 'package:drift/drift.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl({
    required FavoritesDao dao,
    required PerformanceMetrics metrics,
  })  : _dao = dao,
        _metrics = metrics;

  final FavoritesDao _dao;
  final PerformanceMetrics _metrics;

  // ----- Repos -----
  @override
  Stream<List<FavoriteRepoEntry>> watchFavoriteRepos() {
    return _dao.watchAllRepos().map(
          (rows) => rows.map(_toRepoEntry).toList(growable: false),
        );
  }

  @override
  Stream<Set<int>> watchFavoriteRepoIds() {
    return _dao.watchAllRepos().map((rows) => rows.map((r) => r.id).toSet());
  }

  @override
  Future<void> toggleFavoriteRepo(RepoEntity repo) async {
    final exists = await _metrics.timeDbRead(
      'favorites.isRepoFavorite(${repo.id})',
      () => _dao.isRepoFavorite(repo.id),
    );
    if (exists) {
      await _dao.removeRepo(repo.id);
    } else {
      await _dao.upsertRepo(_toRepoCompanion(repo));
    }
  }

  @override
  Future<void> removeFavoriteRepo(int id) => _dao.removeRepo(id);

  FavoriteRepoEntry _toRepoEntry(FavoriteRepo row) => FavoriteRepoEntry(
        repo: RepoEntity(
          id: row.id,
          name: row.name,
          fullName: row.fullName,
          description: row.description,
          ownerLogin: row.ownerLogin,
          ownerAvatarUrl: row.ownerAvatarUrl,
          htmlUrl: row.htmlUrl,
          language: row.language,
          stars: row.stars,
          forks: row.forks,
          pushedAt: row.pushedAt,
        ),
        savedAt: row.savedAt,
      );

  FavoriteReposCompanion _toRepoCompanion(RepoEntity r) =>
      FavoriteReposCompanion.insert(
        id: Value(r.id),
        name: r.name,
        fullName: r.fullName,
        description: Value(r.description),
        ownerLogin: r.ownerLogin,
        ownerAvatarUrl: r.ownerAvatarUrl,
        htmlUrl: r.htmlUrl,
        language: Value(r.language),
        stars: Value(r.stars),
        forks: Value(r.forks),
        pushedAt: Value(r.pushedAt),
        savedAt: DateTime.now(),
      );

  // ----- Articles -----
  @override
  Stream<List<BookmarkedArticleEntry>> watchBookmarkedArticles() {
    return _dao.watchAllArticles().map(
          (rows) => rows.map(_toArticleEntry).toList(growable: false),
        );
  }

  @override
  Stream<Set<int>> watchBookmarkedArticleIds() {
    return _dao.watchAllArticles().map((r) => r.map((a) => a.id).toSet());
  }

  @override
  Future<void> toggleBookmarkArticle(ArticleEntity article) async {
    final exists = await _metrics.timeDbRead(
      'favorites.isArticleBookmarked(${article.id})',
      () => _dao.isArticleBookmarked(article.id),
    );
    if (exists) {
      await _dao.removeArticle(article.id);
    } else {
      await _dao.upsertArticle(_toArticleCompanion(article));
    }
  }

  @override
  Future<void> removeBookmarkedArticle(int id) => _dao.removeArticle(id);

  BookmarkedArticleEntry _toArticleEntry(BookmarkedArticle row) =>
      BookmarkedArticleEntry(
        article: ArticleEntity(
          id: row.id,
          title: row.title,
          url: row.url,
          author: row.author,
          score: row.score,
          commentCount: row.commentCount,
          createdAt: row.createdAt,
          topic: row.topic,
        ),
        savedAt: row.savedAt,
      );

  BookmarkedArticlesCompanion _toArticleCompanion(ArticleEntity a) =>
      BookmarkedArticlesCompanion.insert(
        id: Value(a.id),
        title: a.title,
        url: Value(a.url),
        author: Value(a.author),
        score: Value(a.score),
        commentCount: Value(a.commentCount),
        topic: Value(a.topic),
        createdAt: a.createdAt,
        savedAt: DateTime.now(),
      );
}
