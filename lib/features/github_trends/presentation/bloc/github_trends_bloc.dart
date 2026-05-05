import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../favorites/domain/repositories/favorites_repository.dart';
import '../../domain/entities/repo_entity.dart';
import '../../domain/usecases/search_repositories.dart';

part 'github_trends_event.dart';
part 'github_trends_state.dart';

class GithubTrendsBloc extends Bloc<GithubTrendsEvent, GithubTrendsState> {
  GithubTrendsBloc({
    required SearchRepositoriesUseCase searchRepositories,
    required FavoritesRepository favoritesRepository,
  })  : _search = searchRepositories,
        _favorites = favoritesRepository,
        super(const GithubTrendsState()) {
    // restartable: cancels the in-flight search when the user types again.
    on<TrendsQueryChanged>(_onQueryChanged, transformer: restartable());
    on<TrendsRefreshed>(_onRefreshed, transformer: restartable());
    // droppable: extra "load more" taps while already paginating are ignored.
    on<TrendsLoadNextPage>(_onLoadNextPage, transformer: droppable());
    on<TrendsToggleFavorite>(_onToggleFavorite);
    on<_FavoritesUpdated>(
      (e, emit) => emit(state.copyWith(favoriteIds: e.ids)),
    );

    // Subscribe AFTER all on<X> handlers are registered so synchronous-leading
    // stream emissions can never race the handler registration.
    _favoriteIdsSub = _favorites.watchFavoriteRepoIds().listen((ids) {
      if (!isClosed) add(_FavoritesUpdated(ids));
    });
  }

  final SearchRepositoriesUseCase _search;
  final FavoritesRepository _favorites;
  late final StreamSubscription<Set<int>> _favoriteIdsSub;

  Future<void> _onQueryChanged(
    TrendsQueryChanged e,
    Emitter<GithubTrendsState> emit,
  ) async {
    if (e.query.trim().isEmpty) return;
    emit(state.copyWith(
      status: TrendsStatus.loading,
      query: e.query,
      items: const [],
      page: 1,
      hasMore: false,
      clearFailure: true,
    ));
    await _fetch(emit, page: 1, append: false, forceRefresh: false);
  }

  Future<void> _onRefreshed(
    TrendsRefreshed e,
    Emitter<GithubTrendsState> emit,
  ) async {
    emit(state.copyWith(status: TrendsStatus.refreshing, clearFailure: true));
    await _fetch(emit, page: 1, append: false, forceRefresh: true);
  }

  Future<void> _onLoadNextPage(
    TrendsLoadNextPage e,
    Emitter<GithubTrendsState> emit,
  ) async {
    if (!state.hasMore || state.status == TrendsStatus.paginating) return;
    emit(state.copyWith(status: TrendsStatus.paginating));
    await _fetch(emit, page: state.page + 1, append: true, forceRefresh: false);
  }

  Future<void> _onToggleFavorite(
    TrendsToggleFavorite e,
    Emitter<GithubTrendsState> emit,
  ) =>
      _favorites.toggleFavoriteRepo(e.repo);

  Future<void> _fetch(
    Emitter<GithubTrendsState> emit, {
    required int page,
    required bool append,
    required bool forceRefresh,
  }) async {
    final result = await _search(
      query: state.query,
      page: page,
      forceRefresh: forceRefresh,
    );
    result.fold(
      (pageData) {
        final merged =
            append ? [...state.items, ...pageData.items] : pageData.items;
        final status =
            merged.isEmpty ? TrendsStatus.empty : TrendsStatus.success;
        emit(state.copyWith(
          status: status,
          items: merged,
          page: pageData.page,
          hasMore: pageData.hasMore,
          fromCache: pageData.fromCache,
          fetchedAt: pageData.fetchedAt,
          clearFailure: true,
        ));
      },
      (failure) {
        emit(state.copyWith(
          status: TrendsStatus.failure,
          failure: failure,
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    await _favoriteIdsSub.cancel();
    return super.close();
  }
}

class _FavoritesUpdated extends GithubTrendsEvent {
  const _FavoritesUpdated(this.ids);
  final Set<int> ids;
  @override
  List<Object?> get props => [ids];
}
