import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../favorites/domain/repositories/favorites_repository.dart';
import '../../domain/entities/article_entity.dart';
import '../../domain/usecases/get_top_stories.dart';

part 'tech_feed_event.dart';
part 'tech_feed_state.dart';

class TechFeedBloc extends Bloc<TechFeedEvent, TechFeedState> {
  TechFeedBloc({
    required GetTopStoriesUseCase getTopStories,
    required FavoritesRepository favoritesRepository,
  })  : _get = getTopStories,
        _favorites = favoritesRepository,
        super(const TechFeedState()) {
    on<FeedRequested>(_onRequested, transformer: restartable());
    on<FeedRefreshed>(_onRefreshed, transformer: restartable());
    on<FeedTopicChanged>(_onTopicChanged, transformer: restartable());
    on<FeedToggleBookmark>(_onToggleBookmark);
    on<_BookmarksUpdated>((e, emit) =>
        emit(state.copyWith(bookmarkedIds: e.ids)));

    _bookmarkSub = _favorites.watchBookmarkedArticleIds().listen(
          (ids) {
            if (!isClosed) add(_BookmarksUpdated(ids));
          },
        );
  }

  final GetTopStoriesUseCase _get;
  final FavoritesRepository _favorites;
  late final StreamSubscription<Set<int>> _bookmarkSub;

  Future<void> _onRequested(
    FeedRequested e,
    Emitter<TechFeedState> emit,
  ) async {
    emit(state.copyWith(status: FeedStatus.loading, clearFailure: true));
    await _load(emit, forceRefresh: false);
  }

  Future<void> _onRefreshed(
    FeedRefreshed e,
    Emitter<TechFeedState> emit,
  ) async {
    emit(state.copyWith(status: FeedStatus.refreshing, clearFailure: true));
    await _load(emit, forceRefresh: true);
  }

  Future<void> _onTopicChanged(
    FeedTopicChanged e,
    Emitter<TechFeedState> emit,
  ) async {
    emit(state.copyWith(
      topic: e.topic,
      status: FeedStatus.loading,
      clearFailure: true,
    ));
    await _load(emit, forceRefresh: false);
  }

  Future<void> _onToggleBookmark(
    FeedToggleBookmark e,
    Emitter<TechFeedState> emit,
  ) =>
      _favorites.toggleBookmarkArticle(e.article);

  Future<void> _load(
    Emitter<TechFeedState> emit, {
    required bool forceRefresh,
  }) async {
    final res = await _get(
      topicFilter: state.topic,
      forceRefresh: forceRefresh,
    );
    res.fold(
      (snap) => emit(state.copyWith(
        status:
            snap.items.isEmpty ? FeedStatus.empty : FeedStatus.success,
        items: snap.items,
        fromCache: snap.fromCache,
        fetchedAt: snap.fetchedAt,
        clearFailure: true,
      )),
      (failure) => emit(state.copyWith(
        status: FeedStatus.failure,
        failure: failure,
      )),
    );
  }

  @override
  Future<void> close() async {
    await _bookmarkSub.cancel();
    return super.close();
  }
}

class _BookmarksUpdated extends TechFeedEvent {
  const _BookmarksUpdated(this.ids);
  final Set<int> ids;
  @override
  List<Object?> get props => [ids];
}
