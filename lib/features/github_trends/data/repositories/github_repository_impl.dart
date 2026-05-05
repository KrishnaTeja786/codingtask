import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/daos/cache_dao.dart';
import '../../../../core/database/daos/favorites_dao.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_exception_mapper.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/performance/performance_metrics.dart';
import '../../domain/repositories/github_repository.dart';
import '../datasources/github_remote_datasource.dart';
import '../models/repo_dto.dart';

class GithubRepositoryImpl implements GithubRepository {
  GithubRepositoryImpl({
    required GithubRemoteDataSource remote,
    required CacheDao cache,
    required FavoritesDao favoritesDao,
    required NetworkInfo networkInfo,
    required PerformanceMetrics metrics,
  })  : _remote = remote,
        _cache = cache,
        _favoritesDao = favoritesDao,
        _networkInfo = networkInfo,
        _metrics = metrics;

  final GithubRemoteDataSource _remote;
  final CacheDao _cache;
  // ignore: unused_field — reserved for "isFavorite" enrichment in v2.
  final FavoritesDao _favoritesDao;
  final NetworkInfo _networkInfo;
  final PerformanceMetrics _metrics;

  String _key(String query, int page) => 'gh_search:$query:p$page';

  @override
  Future<Result<RepoSearchPage>> searchRepositories({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async {
    final key = _key(query, page);

    // 1) Try cache for fast first paint, unless caller forces refresh.
    final cached = await _metrics.timeDbRead(
      'cache.get($key)',
      () => _cache.get(key),
    );

    if (!forceRefresh && cached != null && cached.isFresh) {
      _metrics.recordCacheHit();
      return Result.ok(_pageFromCache(cached, page, fromCache: true));
    }

    // 2) Network — fall back to stale cache when offline / failed.
    final online = await _networkInfo.isOnline;
    if (!online) {
      if (cached != null) {
        _metrics.recordCacheHit();
        return Result.ok(_pageFromCache(cached, page, fromCache: true));
      }
      _metrics.recordCacheMiss();
      return const Result.err(NetworkFailure());
    }

    try {
      _metrics.recordCacheMiss();
      final res = await _remote.searchRepositories(
        query: query,
        page: page,
        perPage: AppConstants.defaultPageSize,
      );
      await _cache.put(
        key: key,
        payload: res.rawJson,
        ttl: AppConstants.trendsCacheTtl,
      );
      return Result.ok(
        _pageFromDto(res.data, page, fromCache: false),
      );
    } on Object catch (e) {
      // Last-ditch fallback to stale cache to keep the UI alive.
      if (cached != null) {
        return Result.ok(_pageFromCache(cached, page, fromCache: true));
      }
      return Result.err(mapDioError(e));
    }
  }

  RepoSearchPage _pageFromDto(
    RepoSearchDto dto,
    int page, {
    required bool fromCache,
  }) {
    final fetchedAt = DateTime.now();
    return RepoSearchPage(
      items: dto.items.map((e) => e.toEntity()).toList(growable: false),
      totalCount: dto.totalCount,
      page: page,
      hasMore: page * AppConstants.defaultPageSize < dto.totalCount &&
          dto.items.isNotEmpty,
      fromCache: fromCache,
      fetchedAt: fetchedAt,
    );
  }

  RepoSearchPage _pageFromCache(
    CacheRecord rec,
    int page, {
    required bool fromCache,
  }) {
    final dto = RepoSearchDto.fromJson(
      jsonDecode(rec.payload) as Map<String, dynamic>,
    );
    return RepoSearchPage(
      items: dto.items.map((e) => e.toEntity()).toList(growable: false),
      totalCount: dto.totalCount,
      page: page,
      hasMore: page * AppConstants.defaultPageSize < dto.totalCount &&
          dto.items.isNotEmpty,
      fromCache: fromCache,
      fetchedAt: rec.fetchedAt,
    );
  }
}
