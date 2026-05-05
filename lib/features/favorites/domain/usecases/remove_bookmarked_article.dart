import '../repositories/favorites_repository.dart';

class RemoveBookmarkedArticleUseCase {
  const RemoveBookmarkedArticleUseCase(this._repo);
  final FavoritesRepository _repo;
  Future<void> call(int id) => _repo.removeBookmarkedArticle(id);
}
