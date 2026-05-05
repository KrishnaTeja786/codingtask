import 'package:flutter/material.dart';

import '../../../../core/utils/date_format.dart';
import '../../domain/entities/article_entity.dart';

class ArticleTile extends StatelessWidget {
  const ArticleTile({
    required this.article,
    required this.isBookmarked,
    required this.onTap,
    required this.onToggleBookmark,
    super.key,
  });

  final ArticleEntity article;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${article.score}',
                  style: text.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (article.author != null) article.author!,
                        '${article.commentCount} comments',
                        formatRelative(article.createdAt),
                      ].join(' • '),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('bm_${article.id}'),
                onPressed: onToggleBookmark,
                tooltip:
                    isBookmarked ? 'Remove bookmark' : 'Bookmark article',
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                  color: isBookmarked ? scheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
