import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/background/background_sync_service.dart';
import '../../../../core/di/injector.dart';
import '../cubit/performance_metrics_cubit.dart';
import '../widgets/large_list_demo.dart';
import '../widgets/metrics_panel.dart';

class PerformanceLabPage extends StatelessWidget {
  const PerformanceLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PerformanceMetricsCubit>(),
      child: const _PerformanceLabView(),
    );
  }
}

class _PerformanceLabView extends StatelessWidget {
  const _PerformanceLabView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Lab'),
        actions: [
          IconButton(
            tooltip: 'Trigger background sync',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await sl<BackgroundSyncService>().runOnce();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Background sync triggered')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BlocBuilder<PerformanceMetricsCubit, PerformanceMetricsState>(
            builder: (context, state) => MetricsPanel(
              snapshot: state.snapshot,
              lastSync: state.lastSync,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Large list demo (1,000 items, recycled & image-cached)',
                  ),
                ),
                SizedBox(
                  height: 320,
                  // Bounded height so the outer ListView doesn't try to
                  // measure an infinite child — and the inner ListView
                  // gets its own viewport with proper recycling.
                  child: const LargeListDemo(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance techniques used',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• ListView.builder + cacheExtent for recycled rendering\n'
                    '• cached_network_image w/ memCache sizing\n'
                    '• compute() isolate for JSON parsing\n'
                    '• BlocSelector / buildWhen to reduce rebuilds\n'
                    '• const widget tree where possible\n'
                    '• Debounced search input\n'
                    '• Repository-level caching with TTL\n'
                    '• Stale-cache fallback when offline\n'
                    '• Stopwatch-instrumented DB reads\n'
                    '• Per-request HTTP timing via Dio interceptor',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
