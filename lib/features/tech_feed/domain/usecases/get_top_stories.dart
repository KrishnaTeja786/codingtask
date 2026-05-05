import '../../../../core/errors/result.dart';
import '../repositories/tech_feed_repository.dart';

class GetTopStoriesUseCase {
  const GetTopStoriesUseCase(this._repo);
  final TechFeedRepository _repo;

  Future<Result<FeedSnapshot>> call({
    String? topicFilter,
    bool forceRefresh = false,
  }) =>
      _repo.getTopStories(
        topicFilter: topicFilter,
        forceRefresh: forceRefresh,
      );
}
