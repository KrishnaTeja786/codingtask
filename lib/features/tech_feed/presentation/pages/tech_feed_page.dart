import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../github_trends/presentation/widgets/state_widgets.dart';
import '../bloc/tech_feed_bloc.dart';
import '../widgets/article_tile.dart';

class TechFeedPage extends StatelessWidget {
  const TechFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TechFeedBloc>()..add(const FeedRequested()),
      child: const _TechFeedView(),
    );
  }
}

class _TechFeedView extends StatelessWidget {
  const _TechFeedView();

  static const _topics = <String?>[null, 'flutter', 'ai', 'rust', 'mobile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tech Feed')),
      body: Column(
        children: [
          BlocSelector<TechFeedBloc, TechFeedState, String?>(
            selector: (s) => s.topic,
            builder: (context, current) => SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final t = _topics[i];
                  final selected = t == current;
                  return FilterChip(
                    label: Text(t ?? 'All'),
                    selected: selected,
                    onSelected: (_) => context
                        .read<TechFeedBloc>()
                        .add(FeedTopicChanged(t)),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _topics.length,
              ),
            ),
          ),
          BlocSelector<TechFeedBloc, TechFeedState, (bool, DateTime?)>(
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
            child: BlocBuilder<TechFeedBloc, TechFeedState>(
              buildWhen: (a, b) =>
                  a.status != b.status ||
                  a.items != b.items ||
                  a.bookmarkedIds != b.bookmarkedIds ||
                  a.failure != b.failure,
              builder: (context, state) {
                final bloc = context.read<TechFeedBloc>();
                return switch (state.status) {
                  FeedStatus.loading when state.items.isEmpty =>
                    const LoadingListSkeleton(),
                  FeedStatus.failure when state.items.isEmpty =>
                    ErrorRetryView(
                      message: state.failure?.message ?? 'Unknown error',
                      onRetry: () =>
                          bloc.add(const FeedRefreshed()),
                    ),
                  FeedStatus.empty => const EmptyStateView(
                      title: 'No articles',
                      subtitle: 'Try a different topic.',
                    ),
                  _ => RefreshIndicator(
                      onRefresh: () async {
                        bloc.add(const FeedRefreshed());
                        await bloc.stream.firstWhere(
                          (s) => s.status != FeedStatus.refreshing,
                        );
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemBuilder: (context, i) {
                          final a = state.items[i];
                          return ArticleTile(
                            key: ValueKey('article_${a.id}'),
                            article: a,
                            isBookmarked: state.bookmarkedIds.contains(a.id),
                            onTap: () =>
                                context.push('/feed/${a.id}', extra: a),
                            onToggleBookmark: () =>
                                bloc.add(FeedToggleBookmark(a)),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemCount: state.items.length,
                      ),
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
