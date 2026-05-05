import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/daos/cache_dao.dart';
import '../../../../core/database/daos/favorites_dao.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_exception_mapper.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/performance/performance_metrics.dart';
import '../../domain/entities/article_entity.dart';
import '../../domain/repositories/tech_feed_repository.dart';
import '../datasources/hacker_news_remote_datasource.dart';
import '../models/article_dto.dart';

class TechFeedRepositoryImpl implements TechFeedRepository {
  TechFeedRepositoryImpl({
    required HackerNewsRemoteDataSource remote,
    required CacheDao cache,
    required FavoritesDao favoritesDao,
    required NetworkInfo networkInfo,
    required PerformanceMetrics metrics,
  })  : _remote = remote,
        _cache = cache,
        _favoritesDao = favoritesDao,
        _networkInfo = networkInfo,
        _metrics = metrics;

  final HackerNewsRemoteDataSource _remote;
  final CacheDao _cache;
  // ignore: unused_field — reserved for `isBookmarked` join in v2.
  final FavoritesDao _favoritesDao;
  final NetworkInfo _networkInfo;
  final PerformanceMetrics _metrics;

  @override
  Future<Result<FeedSnapshot>> getTopStories({
    String? topicFilter,
    bool forceRefresh = false,
    int limit = 30,
  }) async {
    final cached = await _metrics.timeDbRead(
      'cache.get(${CacheKeys.hackerNewsTop})',
      () => _cache.get(CacheKeys.hackerNewsTop),
    );

    if (!forceRefresh && cached != null && cached.isFresh) {
      _metrics.recordCacheHit();
      final items = await _remote.decodeItems(cached.payload);
      return Result.ok(_buildSnapshot(items, topicFilter,
          fromCache: true, fetchedAt: cached.fetchedAt));
    }

    final online = await _networkInfo.isOnline;
    if (!online) {
      if (cached != null) {
        _metrics.recordCacheHit();
        final items = await _remote.decodeItems(cached.payload);
        return Result.ok(_buildSnapshot(items, topicFilter,
            fromCache: true, fetchedAt: cached.fetchedAt));
      }
      _metrics.recordCacheMiss();
      return const Result.err(NetworkFailure());
    }

    try {
      _metrics.recordCacheMiss();
      final ids = (await _remote.fetchTopStoryIds()).take(limit).toList();
      final items = await _remote.fetchItemsBatch(ids);
      await _cache.put(
        key: CacheKeys.hackerNewsTop,
        payload: _remote.encodeItems(items),
        ttl: AppConstants.feedCacheTtl,
      );
      return Result.ok(_buildSnapshot(items, topicFilter,
          fromCache: false, fetchedAt: DateTime.now()));
    } on Object catch (e) {
      if (cached != null) {
        final items = await _remote.decodeItems(cached.payload);
        return Result.ok(_buildSnapshot(items, topicFilter,
            fromCache: true, fetchedAt: cached.fetchedAt));
      }
      return Result.err(mapDioError(e));
    }
  }

  FeedSnapshot _buildSnapshot(
    List<HnItemDto> items,
    String? topicFilter, {
    required bool fromCache,
    required DateTime fetchedAt,
  }) {
    final entities = items.map((d) => d.toEntity()).toList(growable: false);
    final filtered = (topicFilter == null || topicFilter.isEmpty)
        ? entities
        : entities
            .where((a) =>
                a.title.toLowerCase().contains(topicFilter.toLowerCase()))
            .toList(growable: false);
    return FeedSnapshot(
      items: filtered,
      fromCache: fromCache,
      fetchedAt: fetchedAt,
    );
  }

  @override
  Future<Result<ArticleEntity>> getArticle(int id) async {
    final key = CacheKeys.hackerNewsItem(id);
    final cached = await _cache.get(key);
    if (cached != null && cached.isFresh) {
      _metrics.recordCacheHit();
      final list = await _remote.decodeItems('[${cached.payload}]');
      return Result.ok(list.first.toEntity());
    }
    try {
      _metrics.recordCacheMiss();
      final item = await _remote.fetchItem(id);
      // Wrap a single item in a JSON array so encode/decode share one path.
      final encoded = _remote.encodeItems([item]);
      await _cache.put(
        key: key,
        payload: encoded.substring(1, encoded.length - 1),
        ttl: AppConstants.feedCacheTtl,
      );
      return Result.ok(item.toEntity());
    } on Object catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
