import 'dart:async';

import '../repositories/favorites_repository.dart';

class FavoritesSnapshot {
  const FavoritesSnapshot({required this.repos, required this.articles});
  final List<FavoriteRepoEntry> repos;
  final List<BookmarkedArticleEntry> articles;
}

class WatchFavoritesUseCase {
  const WatchFavoritesUseCase(this._repo);
  final FavoritesRepository _repo;

  Stream<FavoritesSnapshot> call() {
    final repos = _repo.watchFavoriteRepos();
    final articles = _repo.watchBookmarkedArticles();
    return Stream<FavoritesSnapshot>.multi((controller) {
      List<FavoriteRepoEntry> latestRepos = const [];
      List<BookmarkedArticleEntry> latestArticles = const [];
      var hasRepos = false;
      var hasArticles = false;

      void emit() {
        if (!hasRepos || !hasArticles) return;
        controller.add(FavoritesSnapshot(
          repos: latestRepos,
          articles: latestArticles,
        ));
      }

      final s1 = repos.listen(
        (r) {
          latestRepos = r;
          hasRepos = true;
          emit();
        },
        onError: controller.addError,
      );
      final s2 = articles.listen(
        (a) {
          latestArticles = a;
          hasArticles = true;
          emit();
        },
        onError: controller.addError,
      );
      controller.onCancel = () async {
        await s1.cancel();
        await s2.cancel();
      };
    });
  }
}
