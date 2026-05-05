import '../../../../core/errors/result.dart';
import '../repositories/github_repository.dart';

/// Single-purpose use case. Keeping the call signature explicit makes blocs
/// easier to test (mock one method, not a whole repo).
class SearchRepositoriesUseCase {
  const SearchRepositoriesUseCase(this._repo);
  final GithubRepository _repo;

  Future<Result<RepoSearchPage>> call({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) {
    return _repo.searchRepositories(
      query: query,
      page: page,
      forceRefresh: forceRefresh,
    );
  }
}
