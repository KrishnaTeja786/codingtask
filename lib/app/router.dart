import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';
import '../features/github_trends/domain/entities/repo_entity.dart';
import '../features/github_trends/presentation/bloc/github_trends_bloc.dart';
import '../features/github_trends/presentation/pages/repo_detail_page.dart';
import '../features/tech_feed/domain/entities/article_entity.dart';
import '../features/tech_feed/presentation/bloc/tech_feed_bloc.dart';
import '../features/tech_feed/presentation/pages/article_detail_page.dart';
import 'bottom_nav.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const AppShell(),
      ),
      GoRoute(
        path: '/trends/:id',
        builder: (context, state) {
          final repo = state.extra as RepoEntity?;
          if (repo == null) {
            return const _MissingExtraScaffold(label: 'repository');
          }
          // Detail page needs its own GithubTrendsBloc only for the toggle
          // event; FavoritesBloc is app-scoped (provided by SmartDevHubApp).
          return BlocProvider<GithubTrendsBloc>(
            create: (_) => sl<GithubTrendsBloc>(),
            child: RepoDetailPage(repo: repo),
          );
        },
      ),
      GoRoute(
        path: '/feed/:id',
        builder: (context, state) {
          final article = state.extra as ArticleEntity?;
          if (article == null) {
            return const _MissingExtraScaffold(label: 'article');
          }
          return BlocProvider<TechFeedBloc>(
            create: (_) => sl<TechFeedBloc>(),
            child: ArticleDetailPage(article: article),
          );
        },
      ),
    ],
  );
}

class _MissingExtraScaffold extends StatelessWidget {
  const _MissingExtraScaffold({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('No $label provided.')),
    );
  }
}
