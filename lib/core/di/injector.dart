import 'package:get_it/get_it.dart';

import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/remove_favorite_repo.dart';
import '../../features/favorites/domain/usecases/remove_bookmarked_article.dart';
import '../../features/favorites/domain/usecases/toggle_favorite_repo.dart';
import '../../features/favorites/domain/usecases/toggle_bookmark_article.dart';
import '../../features/favorites/domain/usecases/watch_favorites.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/github_trends/data/datasources/github_remote_datasource.dart';
import '../../features/github_trends/data/repositories/github_repository_impl.dart';
import '../../features/github_trends/domain/repositories/github_repository.dart';
import '../../features/github_trends/domain/usecases/search_repositories.dart';
import '../../features/github_trends/presentation/bloc/github_trends_bloc.dart';
import '../../features/performance_lab/presentation/cubit/performance_metrics_cubit.dart';
import '../../features/tech_feed/data/datasources/hacker_news_remote_datasource.dart';
import '../../features/tech_feed/data/repositories/tech_feed_repository_impl.dart';
import '../../features/tech_feed/domain/repositories/tech_feed_repository.dart';
import '../../features/tech_feed/domain/usecases/get_top_stories.dart';
import '../../features/tech_feed/presentation/bloc/tech_feed_bloc.dart';
import '../background/background_sync_service.dart';
import '../database/app_database.dart';
import '../database/daos/cache_dao.dart';
import '../database/daos/favorites_dao.dart';
import '../database/daos/sync_metadata_dao.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../performance/performance_metrics.dart';

/// Single composition root. Manual get_it registrations are deliberately
/// chosen over `injectable`'s codegen — explicit ordering reads better in
/// reviews and keeps cold-start cost low.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies({AppDatabase? overrideDb}) async {
  // ---------- core singletons ----------
  sl
    ..registerSingleton<PerformanceMetrics>(PerformanceMetrics())
    ..registerSingleton<NetworkInfo>(ConnectivityNetworkInfo())
    ..registerSingleton<DioClient>(DioClient(metrics: sl()))
    ..registerSingleton<AppDatabase>(overrideDb ?? AppDatabase())
    ..registerLazySingleton<FavoritesDao>(() => FavoritesDao(sl()))
    ..registerLazySingleton<CacheDao>(() => CacheDao(sl()))
    ..registerLazySingleton<SyncMetadataDao>(() => SyncMetadataDao(sl()));

  // ---------- github_trends ----------
  sl
    ..registerLazySingleton<GithubRemoteDataSource>(
      () => GithubRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<GithubRepository>(
      () => GithubRepositoryImpl(
        remote: sl(),
        cache: sl(),
        favoritesDao: sl(),
        networkInfo: sl(),
        metrics: sl(),
      ),
    )
    ..registerLazySingleton<SearchRepositoriesUseCase>(
      () => SearchRepositoriesUseCase(sl()),
    )
    ..registerFactory<GithubTrendsBloc>(
      () => GithubTrendsBloc(
        searchRepositories: sl(),
        favoritesRepository: sl(),
      ),
    );

  // ---------- tech_feed ----------
  sl
    ..registerLazySingleton<HackerNewsRemoteDataSource>(
      () => HackerNewsRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<TechFeedRepository>(
      () => TechFeedRepositoryImpl(
        remote: sl(),
        cache: sl(),
        favoritesDao: sl(),
        networkInfo: sl(),
        metrics: sl(),
      ),
    )
    ..registerLazySingleton<GetTopStoriesUseCase>(
      () => GetTopStoriesUseCase(sl()),
    )
    ..registerFactory<TechFeedBloc>(
      () => TechFeedBloc(
        getTopStories: sl(),
        favoritesRepository: sl(),
      ),
    );

  // ---------- favorites ----------
  sl
    ..registerLazySingleton<FavoritesRepository>(
      () => FavoritesRepositoryImpl(dao: sl(), metrics: sl()),
    )
    ..registerLazySingleton<WatchFavoritesUseCase>(
      () => WatchFavoritesUseCase(sl()),
    )
    ..registerLazySingleton<ToggleFavoriteRepoUseCase>(
      () => ToggleFavoriteRepoUseCase(sl()),
    )
    ..registerLazySingleton<ToggleBookmarkArticleUseCase>(
      () => ToggleBookmarkArticleUseCase(sl()),
    )
    ..registerLazySingleton<RemoveFavoriteRepoUseCase>(
      () => RemoveFavoriteRepoUseCase(sl()),
    )
    ..registerLazySingleton<RemoveBookmarkedArticleUseCase>(
      () => RemoveBookmarkedArticleUseCase(sl()),
    )
    // FavoritesBloc is app-scoped: it keeps a DB stream open and is read by
    // both list pages AND the detail screens. Singleton avoids resubscribing.
    ..registerLazySingleton<FavoritesBloc>(
      () => FavoritesBloc(
        watchFavorites: sl(),
        removeRepo: sl(),
        removeArticle: sl(),
      ),
    );

  // ---------- performance lab ----------
  sl.registerFactory<PerformanceMetricsCubit>(
    () => PerformanceMetricsCubit(sl(), syncMetadataDao: sl()),
  );

  // ---------- background ----------
  sl.registerSingleton<BackgroundSyncService>(
    WorkManagerBackgroundSyncService(() async {
      // In-process refresh: refresh trends and feed via repos. Errors are
      // swallowed because background work must never crash the host app.
      final github = sl<GithubRepository>();
      final feed = sl<TechFeedRepository>();
      final syncDao = sl<SyncMetadataDao>();
      final metrics = sl<PerformanceMetrics>();
      metrics.recordBackgroundStatus('running');
      await syncDao.markStarted('refresh_all');
      try {
        await github.searchRepositories(
          query: 'flutter language:dart',
          page: 1,
          forceRefresh: true,
        );
        await feed.getTopStories(forceRefresh: true);
        await syncDao.markSuccess('refresh_all');
        metrics.recordBackgroundStatus('success');
      } on Object catch (e) {
        await syncDao.markFailure('refresh_all', e.toString());
        metrics.recordBackgroundStatus('error');
      }
    }),
  );
}

Future<void> resetDependencies() => sl.reset();
