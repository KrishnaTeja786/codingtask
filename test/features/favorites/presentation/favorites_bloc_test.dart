import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:codingtask/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:codingtask/features/favorites/domain/usecases/remove_bookmarked_article.dart';
import 'package:codingtask/features/favorites/domain/usecases/remove_favorite_repo.dart';
import 'package:codingtask/features/favorites/domain/usecases/watch_favorites.dart';
import 'package:codingtask/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_helpers/fakes.dart';

class _StubWatch extends WatchFavoritesUseCase {
  _StubWatch(this._stream) : super(MockFavoritesRepository());
  final Stream<FavoritesSnapshot> _stream;
  @override
  Stream<FavoritesSnapshot> call() => _stream;
}

void main() {
  setUpAll(registerFallbacks);

  late MockFavoritesRepository repo;

  setUp(() {
    repo = MockFavoritesRepository();
  });

  blocTest<FavoritesBloc, FavoritesState>(
    'updates state when watcher emits',
    build: () {
      final ctrl = StreamController<FavoritesSnapshot>();
      Future<void>.microtask(() {
        ctrl.add(FavoritesSnapshot(
          repos: [
            FavoriteRepoEntry(repo: buildRepo(), savedAt: DateTime.utc(2026)),
          ],
          articles: const [],
        ));
      });
      return FavoritesBloc(
        watchFavorites: _StubWatch(ctrl.stream),
        removeRepo: RemoveFavoriteRepoUseCase(repo),
        removeArticle: RemoveBookmarkedArticleUseCase(repo),
      );
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.repos, hasLength(1));
      expect(b.state.sortedRepos.first.id, 1);
    },
  );

  blocTest<FavoritesBloc, FavoritesState>(
    'sort change re-orders repos',
    build: () {
      final snap = FavoritesSnapshot(
        repos: [
          FavoriteRepoEntry(
            repo: buildRepo(id: 1, name: 'beta'),
            savedAt: DateTime.utc(2026, 1, 1),
          ),
          FavoriteRepoEntry(
            repo: buildRepo(id: 2, name: 'alpha'),
            savedAt: DateTime.utc(2026, 6, 1),
          ),
        ],
        articles: const [],
      );
      return FavoritesBloc(
        watchFavorites: _StubWatch(Stream.value(snap)),
        removeRepo: RemoveFavoriteRepoUseCase(repo),
        removeArticle: RemoveBookmarkedArticleUseCase(repo),
      );
    },
    wait: const Duration(milliseconds: 10),
    act: (b) => b.add(const FavoritesSortChanged(FavoritesSort.titleAsc)),
    verify: (b) => expect(b.state.sortedRepos.first.name, 'alpha'),
  );

  blocTest<FavoritesBloc, FavoritesState>(
    'remove repo invokes use case',
    build: () {
      when(() => repo.removeFavoriteRepo(any())).thenAnswer((_) async {});
      return FavoritesBloc(
        watchFavorites: _StubWatch(const Stream<FavoritesSnapshot>.empty()),
        removeRepo: RemoveFavoriteRepoUseCase(repo),
        removeArticle: RemoveBookmarkedArticleUseCase(repo),
      );
    },
    act: (b) => b.add(const FavoritesRemoveRepo(42)),
    verify: (_) => verify(() => repo.removeFavoriteRepo(42)).called(1),
  );
}
