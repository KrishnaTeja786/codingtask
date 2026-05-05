part of 'github_trends_bloc.dart';

enum TrendsStatus {
  idle,
  loading,
  refreshing,
  paginating,
  success,
  empty,
  failure,
}

class GithubTrendsState extends Equatable {
  const GithubTrendsState({
    this.status = TrendsStatus.idle,
    this.query = 'flutter language:dart',
    this.items = const [],
    this.favoriteIds = const {},
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.fetchedAt,
    this.failure,
  });

  final TrendsStatus status;
  final String query;
  final List<RepoEntity> items;
  final Set<int> favoriteIds;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final DateTime? fetchedAt;
  final Failure? failure;

  bool get isLoadingFirstPage =>
      status == TrendsStatus.loading && items.isEmpty;
  bool get hasError => failure != null;

  GithubTrendsState copyWith({
    TrendsStatus? status,
    String? query,
    List<RepoEntity>? items,
    Set<int>? favoriteIds,
    int? page,
    bool? hasMore,
    bool? fromCache,
    DateTime? fetchedAt,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return GithubTrendsState(
      status: status ?? this.status,
      query: query ?? this.query,
      items: items ?? this.items,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
        status,
        query,
        items,
        favoriteIds,
        page,
        hasMore,
        fromCache,
        fetchedAt,
        failure,
      ];
}
