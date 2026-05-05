import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../bloc/github_trends_bloc.dart';
import '../widgets/repo_card.dart';
import '../widgets/state_widgets.dart';
import '../widgets/trends_search_bar.dart';

class GithubTrendsPage extends StatelessWidget {
  const GithubTrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<GithubTrendsBloc>()..add(const TrendsQueryChanged('flutter language:dart')),
      child: const _GithubTrendsView(),
    );
  }
}

class _GithubTrendsView extends StatefulWidget {
  const _GithubTrendsView();

  @override
  State<_GithubTrendsView> createState() => _GithubTrendsViewState();
}

class _GithubTrendsViewState extends State<_GithubTrendsView> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      context.read<GithubTrendsBloc>().add(const TrendsLoadNextPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub Trends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: BlocSelector<GithubTrendsBloc, GithubTrendsState, String>(
              selector: (s) => s.query,
              builder: (context, query) => TrendsSearchBar(
                initial: query,
                onChanged: (v) => context
                    .read<GithubTrendsBloc>()
                    .add(TrendsQueryChanged(v)),
              ),
            ),
          ),
          TopicChips(
            onPick: (q) => context
                .read<GithubTrendsBloc>()
                .add(TrendsQueryChanged(q)),
          ),
          BlocSelector<GithubTrendsBloc, GithubTrendsState,
              (bool, DateTime?)>(
            selector: (s) => (s.fromCache, s.fetchedAt),
            builder: (_, t) {
              final (fromCache, fetchedAt) = t;
              if (!fromCache || fetchedAt == null) {
                return const SizedBox.shrink();
              }
              return OfflineCacheBanner(fetchedAt: fetchedAt);
            },
          ),
          Expanded(
            child: BlocBuilder<GithubTrendsBloc, GithubTrendsState>(
              buildWhen: (a, b) =>
                  a.status != b.status ||
                  a.items != b.items ||
                  a.favoriteIds != b.favoriteIds ||
                  a.failure != b.failure,
              builder: (context, state) => _Body(state: state, scrollCtrl: _scrollCtrl),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.scrollCtrl});
  final GithubTrendsState state;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GithubTrendsBloc>();
    return switch (state.status) {
      TrendsStatus.loading when state.items.isEmpty => const LoadingListSkeleton(),
      TrendsStatus.failure when state.items.isEmpty => ErrorRetryView(
          message: state.failure?.message ?? 'Unknown error',
          onRetry: () => bloc.add(const TrendsRefreshed()),
        ),
      TrendsStatus.empty => const EmptyStateView(
          title: 'No repositories',
          subtitle: 'Try a different search term.',
        ),
      _ => RefreshIndicator(
          onRefresh: () async {
            bloc.add(const TrendsRefreshed());
            await bloc.stream.firstWhere(
              (s) => s.status != TrendsStatus.refreshing,
            );
          },
          child: ListView.separated(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemBuilder: (context, i) {
              if (i == state.items.length) {
                return state.hasMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              }
              final repo = state.items[i];
              return RepoCard(
                key: ValueKey('repo_${repo.id}'),
                repo: repo,
                isFavorite: state.favoriteIds.contains(repo.id),
                onTap: () =>
                    context.push('/trends/${repo.id}', extra: repo),
                onToggleFavorite: () =>
                    bloc.add(TrendsToggleFavorite(repo)),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: state.items.length + 1,
          ),
        ),
    };
  }
}
