import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Large list rendering demo. Shows ListView.builder w/ recycling and
/// CachedNetworkImage for stable image identity across rebuilds.
class LargeListDemo extends StatelessWidget {
  const LargeListDemo({super.key, this.itemCount = 1000});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: itemCount,
      // The cacheExtent gives the engine room to pre-render items just
      // outside the viewport, smoothing fast flings.
      cacheExtent: 600,
      itemBuilder: (context, i) => _LargeListItem(
        index: i,
        scheme: scheme,
      ),
    );
  }
}

class _LargeListItem extends StatelessWidget {
  const _LargeListItem({required this.index, required this.scheme});
  final int index;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final url = 'https://picsum.photos/seed/$index/120/120';
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          memCacheWidth: 96,
          memCacheHeight: 96,
          placeholder: (_, __) => Container(
            width: 48,
            height: 48,
            color: scheme.surfaceContainerHighest,
          ),
        ),
      ),
      title: Text('Item #$index'),
      subtitle: Text('Cached image • recycled tile'),
    );
  }
}
