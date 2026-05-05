import '../../../github_trends/domain/entities/repo_entity.dart';
import '../repositories/favorites_repository.dart';

class ToggleFavoriteRepoUseCase {
  const ToggleFavoriteRepoUseCase(this._repo);
  final FavoritesRepository _repo;
  Future<void> call(RepoEntity repo) => _repo.toggleFavoriteRepo(repo);
}
