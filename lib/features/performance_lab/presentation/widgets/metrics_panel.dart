import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/performance/performance_metrics.dart';
import '../../../../core/utils/date_format.dart';

class MetricsPanel extends StatelessWidget {
  const MetricsPanel({
    required this.snapshot,
    required this.lastSync,
    super.key,
  });

  final PerfSnapshot snapshot;
  final SyncMetadataData? lastSync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Live Metrics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricBadge(
                  label: 'Avg API',
                  value: snapshot.avgApi != null
                      ? '${snapshot.avgApi!.inMilliseconds} ms'
                      : '—',
                ),
                _MetricBadge(
                  label: 'Avg DB read',
                  value: snapshot.avgDb != null
                      ? '${snapshot.avgDb!.inMicroseconds / 1000} ms'
                      : '—',
                ),
                _MetricBadge(
                  label: 'Cache hit rate',
                  value:
                      '${(snapshot.cacheHitRate * 100).toStringAsFixed(0)}%',
                  hint:
                      '${snapshot.cacheHits}/${snapshot.cacheHits + snapshot.cacheMisses}',
                ),
                _MetricBadge(
                  label: 'Background',
                  value: snapshot.backgroundStatus,
                ),
                if (lastSync?.lastSuccessAt != null)
                  _MetricBadge(
                    label: 'Last sync',
                    value: formatRelative(lastSync!.lastSuccessAt!),
                  ),
              ],
            ),
            if (snapshot.apiCalls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Recent API calls',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              ...snapshot.apiCalls.reversed.take(5).map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          c.ok ? Icons.check_circle : Icons.error,
                          size: 14,
                          color: c.ok
                              ? Colors.green.shade600
                              : scheme.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _shortenUrl(c.url),
                            style:
                                Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${c.duration.inMilliseconds} ms',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  String _shortenUrl(String full) {
    final uri = Uri.tryParse(full);
    if (uri == null) return full;
    return '${uri.host}${uri.path}';
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (hint != null)
            Text(
              hint!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }
}
