import 'package:bloc_test/bloc_test.dart';
import 'package:codingtask/core/errors/failures.dart';
import 'package:codingtask/core/errors/result.dart';
import 'package:codingtask/features/tech_feed/domain/usecases/get_top_stories.dart';
import 'package:codingtask/features/tech_feed/presentation/bloc/tech_feed_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_helpers/fakes.dart';

class _UseCase extends GetTopStoriesUseCase {
  _UseCase(super.repo);
}

void main() {
  late MockTechFeedRepository repo;
  late GetTopStoriesUseCase usecase;
  late MockFavoritesRepository favorites;

  setUpAll(registerFallbacks);

  setUp(() {
    repo = MockTechFeedRepository();
    usecase = _UseCase(repo);
    favorites = MockFavoritesRepository();
    when(() => favorites.watchBookmarkedArticleIds())
        .thenAnswer((_) => const Stream.empty());
  });

  blocTest<TechFeedBloc, TechFeedState>(
    'success path',
    setUp: () {
      when(() => repo.getTopStories(
            topicFilter: any(named: 'topicFilter'),
            forceRefresh: any(named: 'forceRefresh'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Result.ok(buildSnap()));
    },
    build: () => TechFeedBloc(
      getTopStories: usecase,
      favoritesRepository: favorites,
    ),
    act: (b) => b.add(const FeedRequested()),
    expect: () => [
      isA<TechFeedState>().having((s) => s.status, 'status', FeedStatus.loading),
      isA<TechFeedState>().having((s) => s.status, 'status', FeedStatus.success),
    ],
  );

  blocTest<TechFeedBloc, TechFeedState>(
    'serves stale cache after failure',
    setUp: () {
      when(() => repo.getTopStories(
            topicFilter: any(named: 'topicFilter'),
            forceRefresh: any(named: 'forceRefresh'),
            limit: any(named: 'limit'),
          )).thenAnswer(
        (_) async => Result.ok(buildSnap(fromCache: true)),
      );
    },
    build: () => TechFeedBloc(
      getTopStories: usecase,
      favoritesRepository: favorites,
    ),
    act: (b) => b.add(const FeedRequested()),
    verify: (b) => expect(b.state.fromCache, isTrue),
  );

  blocTest<TechFeedBloc, TechFeedState>(
    'failure when no cache',
    setUp: () {
      when(() => repo.getTopStories(
            topicFilter: any(named: 'topicFilter'),
            forceRefresh: any(named: 'forceRefresh'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const Result.err(NetworkFailure()));
    },
    build: () => TechFeedBloc(
      getTopStories: usecase,
      favoritesRepository: favorites,
    ),
    act: (b) => b.add(const FeedRequested()),
    expect: () => [
      isA<TechFeedState>().having((s) => s.status, 'status', FeedStatus.loading),
      isA<TechFeedState>()
          .having((s) => s.status, 'status', FeedStatus.failure)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );
}
