part of 'favorites_bloc.dart';

enum FavoritesStatus { loading, success }

/// Sort modes available across both lists.
enum FavoritesSort {
  dateSavedDesc,
  dateSavedAsc,
  starsDesc,
  titleAsc,
}

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.loading,
    this.repos = const [],
    this.articles = const [],
    this.sortBy = FavoritesSort.dateSavedDesc,
  });

  final FavoritesStatus status;
  final List<FavoriteRepoEntry> repos;
  final List<BookmarkedArticleEntry> articles;
  final FavoritesSort sortBy;

  /// Memoized sorted view. Sorting on every build would dominate frame time
  /// on large favorite sets; we sort once per state.
  late final List<RepoEntity> sortedRepos = _sortRepos();
  late final List<ArticleEntity> sortedArticles = _sortArticles();

  List<RepoEntity> _sortRepos() {
    final out = repos.toList();
    switch (sortBy) {
      case FavoritesSort.dateSavedDesc:
        out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      case FavoritesSort.dateSavedAsc:
        out.sort((a, b) => a.savedAt.compareTo(b.savedAt));
      case FavoritesSort.starsDesc:
        out.sort((a, b) => b.repo.stars.compareTo(a.repo.stars));
      case FavoritesSort.titleAsc:
        out.sort(
          (a, b) =>
              a.repo.name.toLowerCase().compareTo(b.repo.name.toLowerCase()),
        );
    }
    return out.map((e) => e.repo).toList(growable: false);
  }

  List<ArticleEntity> _sortArticles() {
    final out = articles.toList();
    switch (sortBy) {
      case FavoritesSort.dateSavedDesc:
        out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      case FavoritesSort.dateSavedAsc:
        out.sort((a, b) => a.savedAt.compareTo(b.savedAt));
      case FavoritesSort.starsDesc:
        out.sort((a, b) => b.article.score.compareTo(a.article.score));
      case FavoritesSort.titleAsc:
        out.sort(
          (a, b) => a.article.title
              .toLowerCase()
              .compareTo(b.article.title.toLowerCase()),
        );
    }
    return out.map((e) => e.article).toList(growable: false);
  }

  bool get isEmpty => repos.isEmpty && articles.isEmpty;

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<FavoriteRepoEntry>? repos,
    List<BookmarkedArticleEntry>? articles,
    FavoritesSort? sortBy,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      repos: repos ?? this.repos,
      articles: articles ?? this.articles,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [status, repos, articles, sortBy];
}
