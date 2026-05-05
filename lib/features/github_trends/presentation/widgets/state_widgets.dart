import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingListSkeleton extends StatelessWidget {
  const LoadingListSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: scheme.surfaceContainerHighest,
        highlightColor: scheme.surfaceContainerHigh,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: itemCount,
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    required this.message,
    required this.onRetry,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineCacheBanner extends StatelessWidget {
  const OfflineCacheBanner({required this.fetchedAt, super.key});
  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 16,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Showing cached data',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
              ),
            ),
            Text(
              _ago(fetchedAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
