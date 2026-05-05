import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/date_format.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../domain/entities/article_entity.dart';
import '../bloc/tech_feed_bloc.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({required this.article, super.key});
  final ArticleEntity article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          BlocSelector<FavoritesBloc, FavoritesState, bool>(
            selector: (s) => s.articles.any((e) => e.article.id == article.id),
            builder: (context, isBookmarked) => IconButton(
              tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              ),
              onPressed: () => context
                  .read<TechFeedBloc>()
                  .add(FeedToggleBookmark(article)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (article.author != null) 'by ${article.author}',
              '${article.score} points',
              '${article.commentCount} comments',
              formatRelative(article.createdAt),
            ].join(' • '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          if (article.url != null)
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(article.url!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open article'),
            ),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://news.ycombinator.com/item?id=${article.id}'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Open HN discussion'),
          ),
        ],
      ),
    );
  }
}
