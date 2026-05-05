import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../github_trends/domain/entities/repo_entity.dart';
import '../../../tech_feed/domain/entities/article_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/usecases/remove_bookmarked_article.dart';
import '../../domain/usecases/remove_favorite_repo.dart';
import '../../domain/usecases/watch_favorites.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({
    required WatchFavoritesUseCase watchFavorites,
    required RemoveFavoriteRepoUseCase removeRepo,
    required RemoveBookmarkedArticleUseCase removeArticle,
  })  : _watch = watchFavorites,
        _removeRepo = removeRepo,
        _removeArticle = removeArticle,
        super(const FavoritesState()) {
    on<_FavoritesUpdated>((e, emit) => emit(state.copyWith(
          status: FavoritesStatus.success,
          repos: e.repos,
          articles: e.articles,
        )));
    on<FavoritesSortChanged>(
      (e, emit) => emit(state.copyWith(sortBy: e.sortBy)),
    );
    on<FavoritesRemoveRepo>((e, emit) => _removeRepo(e.id));
    on<FavoritesRemoveArticle>((e, emit) => _removeArticle(e.id));

    _sub = _watch().listen((snap) {
      if (!isClosed) add(_FavoritesUpdated(snap.repos, snap.articles));
    });
  }

  final WatchFavoritesUseCase _watch;
  final RemoveFavoriteRepoUseCase _removeRepo;
  final RemoveBookmarkedArticleUseCase _removeArticle;
  late final StreamSubscription<FavoritesSnapshot> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
