part of 'tech_feed_bloc.dart';

enum FeedStatus { idle, loading, refreshing, success, empty, failure }

class TechFeedState extends Equatable {
  const TechFeedState({
    this.status = FeedStatus.idle,
    this.items = const [],
    this.bookmarkedIds = const {},
    this.topic,
    this.fromCache = false,
    this.fetchedAt,
    this.failure,
  });

  final FeedStatus status;
  final List<ArticleEntity> items;
  final Set<int> bookmarkedIds;
  final String? topic;
  final bool fromCache;
  final DateTime? fetchedAt;
  final Failure? failure;

  TechFeedState copyWith({
    FeedStatus? status,
    List<ArticleEntity>? items,
    Set<int>? bookmarkedIds,
    String? topic,
    bool? fromCache,
    DateTime? fetchedAt,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return TechFeedState(
      status: status ?? this.status,
      items: items ?? this.items,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      topic: topic ?? this.topic,
      fromCache: fromCache ?? this.fromCache,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        bookmarkedIds,
        topic,
        fromCache,
        fetchedAt,
        failure,
      ];
}
