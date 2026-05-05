import 'dart:convert';

import 'package:codingtask/core/database/app_database.dart';
import 'package:codingtask/core/database/daos/cache_dao.dart';
import 'package:codingtask/core/database/daos/favorites_dao.dart';
import 'package:codingtask/core/errors/failures.dart';
import 'package:codingtask/core/performance/performance_metrics.dart';
import 'package:codingtask/features/github_trends/data/datasources/github_remote_datasource.dart';
import 'package:codingtask/features/github_trends/data/models/repo_dto.dart';
import 'package:codingtask/features/github_trends/data/repositories/github_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_helpers/fakes.dart';

class _MockRemote extends Mock implements GithubRemoteDataSource {}

void main() {
  late AppDatabase db;
  late CacheDao cacheDao;
  late FavoritesDao favoritesDao;
  late MockNetworkInfo network;
  late _MockRemote remote;
  late PerformanceMetrics metrics;
  late GithubRepositoryImpl repo;

  setUpAll(registerFallbacks);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cacheDao = CacheDao(db);
    favoritesDao = FavoritesDao(db);
    network = MockNetworkInfo();
    remote = _MockRemote();
    metrics = PerformanceMetrics();
    repo = GithubRepositoryImpl(
      remote: remote,
      cache: cacheDao,
      favoritesDao: favoritesDao,
      networkInfo: network,
      metrics: metrics,
    );
  });

  tearDown(() async {
    await metrics.dispose();
    await db.close();
  });

  test('returns NetworkFailure when offline and no cache', () async {
    when(() => network.isOnline).thenAnswer((_) async => false);
    final res = await repo.searchRepositories(query: 'q', page: 1);
    expect(res.failureOrNull, isA<NetworkFailure>());
  });

  test('returns cache when fresh', () async {
    final dto = RepoSearchDto(
      totalCount: 1,
      items: [
        RepoDto(
          id: 1,
          name: 'flutter',
          fullName: 'flutter/flutter',
          description: 'd',
          ownerLogin: 'flutter',
          ownerAvatarUrl: 'https://x',
          htmlUrl: 'https://h',
          language: 'Dart',
          stars: 1,
          forks: 1,
          pushedAt: DateTime.utc(2026),
        ),
      ],
    );
    await cacheDao.put(
      key: 'gh_search:q:p1',
      payload: jsonEncode(dto.toJson()),
      ttl: const Duration(minutes: 30),
    );
    when(() => network.isOnline).thenAnswer((_) async => true);

    final res = await repo.searchRepositories(query: 'q', page: 1);
    expect(res.isOk, isTrue);
    expect(res.valueOrNull?.fromCache, isTrue);
    verifyNever(() => remote.searchRepositories(
          query: any(named: 'query'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ));
  });
}
