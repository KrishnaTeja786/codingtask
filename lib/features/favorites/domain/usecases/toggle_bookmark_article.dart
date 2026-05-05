import '../../../tech_feed/domain/entities/article_entity.dart';
import '../repositories/favorites_repository.dart';

class ToggleBookmarkArticleUseCase {
  const ToggleBookmarkArticleUseCase(this._repo);
  final FavoritesRepository _repo;
  Future<void> call(ArticleEntity a) => _repo.toggleBookmarkArticle(a);
}
