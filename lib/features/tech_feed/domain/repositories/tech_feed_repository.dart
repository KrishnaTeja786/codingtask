import '../../../../core/errors/result.dart';
import '../entities/article_entity.dart';

class FeedSnapshot {
  const FeedSnapshot({
    required this.items,
    required this.fromCache,
    required this.fetchedAt,
  });
  final List<ArticleEntity> items;
  final bool fromCache;
  final DateTime fetchedAt;
}

abstract interface class TechFeedRepository {
  Future<Result<FeedSnapshot>> getTopStories({
    String? topicFilter,
    bool forceRefresh = false,
    int limit = 30,
  });

  Future<Result<ArticleEntity>> getArticle(int id);
}
