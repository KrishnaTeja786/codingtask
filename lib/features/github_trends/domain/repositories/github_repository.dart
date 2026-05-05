import '../../../../core/errors/result.dart';
import '../entities/repo_entity.dart';

class RepoSearchPage {
  const RepoSearchPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.hasMore,
    required this.fromCache,
    required this.fetchedAt,
  });

  final List<RepoEntity> items;
  final int totalCount;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final DateTime fetchedAt;
}

abstract interface class GithubRepository {
  Future<Result<RepoSearchPage>> searchRepositories({
    required String query,
    required int page,
    bool forceRefresh = false,
  });
}
