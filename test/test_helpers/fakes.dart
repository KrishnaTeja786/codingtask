import 'package:codingtask/core/errors/failures.dart';
import 'package:codingtask/core/network/network_info.dart';
import 'package:codingtask/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:codingtask/features/github_trends/domain/entities/repo_entity.dart';
import 'package:codingtask/features/github_trends/domain/repositories/github_repository.dart';
import 'package:codingtask/features/tech_feed/domain/entities/article_entity.dart';
import 'package:codingtask/features/tech_feed/domain/repositories/tech_feed_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockGithubRepository extends Mock implements GithubRepository {}

class MockTechFeedRepository extends Mock implements TechFeedRepository {}

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

RepoEntity buildRepo({int id = 1, String name = 'flutter'}) => RepoEntity(
      id: id,
      name: name,
      fullName: 'flutter/$name',
      description: 'desc',
      ownerLogin: 'flutter',
      ownerAvatarUrl: 'https://example.com/a.png',
      htmlUrl: 'https://github.com/flutter/$name',
      language: 'Dart',
      stars: 1000,
      forks: 100,
      pushedAt: DateTime.utc(2026),
    );

ArticleEntity buildArticle({int id = 1, String title = 'A title'}) =>
    ArticleEntity(
      id: id,
      title: title,
      url: 'https://example.com/$id',
      author: 'alice',
      score: 42,
      commentCount: 7,
      createdAt: DateTime.utc(2026),
    );

RepoSearchPage buildPage({
  List<RepoEntity>? items,
  int page = 1,
  bool hasMore = false,
  bool fromCache = false,
}) =>
    RepoSearchPage(
      items: items ?? [buildRepo()],
      totalCount: items?.length ?? 1,
      page: page,
      hasMore: hasMore,
      fromCache: fromCache,
      fetchedAt: DateTime.utc(2026),
    );

FeedSnapshot buildSnap({List<ArticleEntity>? items, bool fromCache = false}) =>
    FeedSnapshot(
      items: items ?? [buildArticle()],
      fromCache: fromCache,
      fetchedAt: DateTime.utc(2026),
    );

void registerFallbacks() {
  registerFallbackValue(buildRepo());
  registerFallbackValue(buildArticle());
  registerFallbackValue(const NetworkFailure());
}
