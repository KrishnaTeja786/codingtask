import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/date_format.dart';
import '../../domain/entities/repo_entity.dart';

/// Const-friendly card widget. The favorite button uses an explicit Key tied
/// to the repo id so swaps in the same slot don't lose animation identity.
class RepoCard extends StatelessWidget {
  const RepoCard({
    required this.repo,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
  });

  final RepoEntity repo;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: repo.ownerAvatarUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: scheme.surfaceContainerHighest,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person_outline,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo.name,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          repo.ownerLogin,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey('fav_${repo.id}'),
                    onPressed: onToggleFavorite,
                    tooltip:
                        isFavorite ? 'Remove favorite' : 'Add to favorites',
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_outline,
                      color: isFavorite ? Colors.amber.shade700 : null,
                    ),
                  ),
                ],
              ),
              if (repo.description != null && repo.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  repo.description!,
                  style: text.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _Chip(
                    icon: Icons.star_outline,
                    label: compactCount(repo.stars),
                  ),
                  _Chip(
                    icon: Icons.call_split,
                    label: compactCount(repo.forks),
                  ),
                  if (repo.language != null)
                    _Chip(icon: Icons.code, label: repo.language!),
                  if (repo.pushedAt != null)
                    _Chip(
                      icon: Icons.update,
                      label: formatRelative(repo.pushedAt!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
