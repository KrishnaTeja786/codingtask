import 'package:codingtask/core/errors/failures.dart';
import 'package:codingtask/core/errors/result.dart';
import 'package:codingtask/features/github_trends/domain/usecases/search_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_helpers/fakes.dart';

void main() {
  late MockGithubRepository repo;
  late SearchRepositoriesUseCase usecase;

  setUpAll(registerFallbacks);

  setUp(() {
    repo = MockGithubRepository();
    usecase = SearchRepositoriesUseCase(repo);
  });

  test('forwards args and returns Ok page', () async {
    when(() => repo.searchRepositories(
          query: any(named: 'query'),
          page: any(named: 'page'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => Result.ok(buildPage()));

    final res = await usecase(query: 'flutter', page: 1);

    expect(res.isOk, isTrue);
    expect(res.valueOrNull?.items, isNotEmpty);
    verify(() => repo.searchRepositories(
          query: 'flutter',
          page: 1,
          forceRefresh: false,
        )).called(1);
  });

  test('propagates failure', () async {
    when(() => repo.searchRepositories(
          query: any(named: 'query'),
          page: any(named: 'page'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => const Result.err(NetworkFailure()));

    final res = await usecase(query: 'q', page: 1);
    expect(res.failureOrNull, isA<NetworkFailure>());
  });
}
