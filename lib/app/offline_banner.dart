import 'package:flutter/material.dart';

import '../core/di/injector.dart';
import '../core/network/network_info.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final info = sl<NetworkInfo>();
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<bool>(
      stream: info.onStatusChange,
      builder: (context, snap) {
        final online = snap.data ?? true;
        if (online) return const SizedBox.shrink();
        return Material(
          color: scheme.errorContainer,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: scheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You are offline — showing cached data',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
