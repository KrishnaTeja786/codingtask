import '../repositories/favorites_repository.dart';

class RemoveFavoriteRepoUseCase {
  const RemoveFavoriteRepoUseCase(this._repo);
  final FavoritesRepository _repo;
  Future<void> call(int id) => _repo.removeFavoriteRepo(id);
}
