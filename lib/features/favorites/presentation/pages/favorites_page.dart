import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../github_trends/presentation/widgets/repo_card.dart';
import '../../../github_trends/presentation/widgets/state_widgets.dart';
import '../../../tech_feed/presentation/widgets/article_tile.dart';
import '../bloc/favorites_bloc.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.star), text: 'Repos'),
              Tab(icon: Icon(Icons.bookmark), text: 'Articles'),
            ],
          ),
          actions: [
            BlocBuilder<FavoritesBloc, FavoritesState>(
              buildWhen: (a, b) => a.sortBy != b.sortBy,
              builder: (context, state) {
                return PopupMenuButton<FavoritesSort>(
                  tooltip: 'Sort',
                  initialValue: state.sortBy,
                  onSelected: (v) => context
                      .read<FavoritesBloc>()
                      .add(FavoritesSortChanged(v)),
                  icon: const Icon(Icons.sort),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: FavoritesSort.dateSavedDesc,
                      child: Text('Date saved (newest)'),
                    ),
                    PopupMenuItem(
                      value: FavoritesSort.dateSavedAsc,
                      child: Text('Date saved (oldest)'),
                    ),
                    PopupMenuItem(
                      value: FavoritesSort.starsDesc,
                      child: Text('Stars / score (high)'),
                    ),
                    PopupMenuItem(
                      value: FavoritesSort.titleAsc,
                      child: Text('Title (A–Z)'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [_ReposTab(), _ArticlesTab()],
        ),
      ),
    );
  }
}

class _ReposTab extends StatelessWidget {
  const _ReposTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      buildWhen: (a, b) => a.repos != b.repos || a.sortBy != b.sortBy,
      builder: (context, state) {
        if (state.repos.isEmpty) {
          return const EmptyStateView(
            icon: Icons.star_outline,
            title: 'No favorite repos',
            subtitle: 'Tap the star on any repo to keep it here for offline.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) {
            final repo = state.sortedRepos[i];
            return RepoCard(
              key: ValueKey('fav_repo_${repo.id}'),
              repo: repo,
              isFavorite: true,
              onTap: () => context.push('/trends/${repo.id}', extra: repo),
              onToggleFavorite: () => context
                  .read<FavoritesBloc>()
                  .add(FavoritesRemoveRepo(repo.id)),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: state.sortedRepos.length,
        );
      },
    );
  }
}

class _ArticlesTab extends StatelessWidget {
  const _ArticlesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      buildWhen: (a, b) => a.articles != b.articles || a.sortBy != b.sortBy,
      builder: (context, state) {
        if (state.articles.isEmpty) {
          return const EmptyStateView(
            icon: Icons.bookmark_outline,
            title: 'No bookmarks yet',
            subtitle: 'Bookmark articles from the Tech Feed.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) {
            final a = state.sortedArticles[i];
            return ArticleTile(
              key: ValueKey('fav_article_${a.id}'),
              article: a,
              isBookmarked: true,
              onTap: () => context.push('/feed/${a.id}', extra: a),
              onToggleBookmark: () => context
                  .read<FavoritesBloc>()
                  .add(FavoritesRemoveArticle(a.id)),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: state.sortedArticles.length,
        );
      },
    );
  }
}
