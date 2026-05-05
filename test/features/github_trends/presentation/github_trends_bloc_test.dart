import 'package:bloc_test/bloc_test.dart';
import 'package:codingtask/core/errors/failures.dart';
import 'package:codingtask/core/errors/result.dart';
import 'package:codingtask/features/github_trends/domain/usecases/search_repositories.dart';
import 'package:codingtask/features/github_trends/presentation/bloc/github_trends_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_helpers/fakes.dart';

class _UseCase extends SearchRepositoriesUseCase {
  _UseCase(super.repo);
}

void main() {
  late MockGithubRepository repo;
  late SearchRepositoriesUseCase usecase;
  late MockFavoritesRepository favorites;

  setUpAll(registerFallbacks);

  setUp(() {
    repo = MockGithubRepository();
    usecase = _UseCase(repo);
    favorites = MockFavoritesRepository();
    when(() => favorites.watchFavoriteRepoIds())
        .thenAnswer((_) => const Stream.empty());
  });

  blocTest<GithubTrendsBloc, GithubTrendsState>(
    'emits loading -> success when query succeeds',
    setUp: () {
      when(() => repo.searchRepositories(
            query: any(named: 'query'),
            page: any(named: 'page'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => Result.ok(buildPage(hasMore: true)));
    },
    build: () => GithubTrendsBloc(
      searchRepositories: usecase,
      favoritesRepository: favorites,
    ),
    act: (b) => b.add(const TrendsQueryChanged('flutter')),
    skip: 0,
    expect: () => [
      isA<GithubTrendsState>().having((s) => s.status, 'status',
          TrendsStatus.loading),
      isA<GithubTrendsState>().having((s) => s.status, 'status',
          TrendsStatus.success),
    ],
  );

  blocTest<GithubTrendsBloc, GithubTrendsState>(
    'emits loading -> failure on network error',
    setUp: () {
      when(() => repo.searchRepositories(
            query: any(named: 'query'),
            page: any(named: 'page'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => const Result.err(NetworkFailure()));
    },
    build: () => GithubTrendsBloc(
      searchRepositories: usecase,
      favoritesRepository: favorites,
    ),
    act: (b) => b.add(const TrendsQueryChanged('flutter')),
    expect: () => [
      isA<GithubTrendsState>().having((s) => s.status, 'status',
          TrendsStatus.loading),
      isA<GithubTrendsState>()
          .having((s) => s.status, 'status', TrendsStatus.failure)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<GithubTrendsBloc, GithubTrendsState>(
    'pagination appends items',
    setUp: () {
      var call = 0;
      when(() => repo.searchRepositories(
            query: any(named: 'query'),
            page: any(named: 'page'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((inv) async {
        call++;
        return Result.ok(buildPage(
          items: [buildRepo(id: call)],
          page: call,
          hasMore: call == 1,
        ));
      });
    },
    build: () => GithubTrendsBloc(
      searchRepositories: usecase,
      favoritesRepository: favorites,
    ),
    act: (b) async {
      b.add(const TrendsQueryChanged('flutter'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(const TrendsLoadNextPage());
    },
    skip: 1,
    verify: (b) {
      expect(b.state.items, hasLength(2));
      expect(b.state.page, 2);
    },
  );

  blocTest<GithubTrendsBloc, GithubTrendsState>(
    'emits empty when result is empty',
    setUp: () {
      when(() => repo.searchRepositories(
            query: any(named: 'query'),
            page: any(named: 'page'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => Result.ok(buildPage(items: const [])));
    },
    build: () => GithubTrendsBloc(
      searchRepositories: usecase,
      favoritesRepository: favorites,
    ),
    act: (b) => b.add(const TrendsQueryChanged('zzzzz')),
    expect: () => [
      isA<GithubTrendsState>()
          .having((s) => s.status, 'status', TrendsStatus.loading),
      isA<GithubTrendsState>()
          .having((s) => s.status, 'status', TrendsStatus.empty),
    ],
  );
}
