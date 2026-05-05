part of 'favorites_bloc.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => const [];
}

class FavoritesSortChanged extends FavoritesEvent {
  const FavoritesSortChanged(this.sortBy);
  final FavoritesSort sortBy;
  @override
  List<Object?> get props => [sortBy];
}

class FavoritesRemoveRepo extends FavoritesEvent {
  const FavoritesRemoveRepo(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

class FavoritesRemoveArticle extends FavoritesEvent {
  const FavoritesRemoveArticle(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

class _FavoritesUpdated extends FavoritesEvent {
  const _FavoritesUpdated(this.repos, this.articles);
  final List<FavoriteRepoEntry> repos;
  final List<BookmarkedArticleEntry> articles;
  @override
  List<Object?> get props => [repos, articles];
}
