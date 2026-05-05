part of 'tech_feed_bloc.dart';

sealed class TechFeedEvent extends Equatable {
  const TechFeedEvent();
  @override
  List<Object?> get props => const [];
}

class FeedRequested extends TechFeedEvent {
  const FeedRequested();
}

class FeedRefreshed extends TechFeedEvent {
  const FeedRefreshed();
}

class FeedTopicChanged extends TechFeedEvent {
  const FeedTopicChanged(this.topic);
  final String? topic;
  @override
  List<Object?> get props => [topic];
}

class FeedToggleBookmark extends TechFeedEvent {
  const FeedToggleBookmark(this.article);
  final ArticleEntity article;
  @override
  List<Object?> get props => [article.id];
}
