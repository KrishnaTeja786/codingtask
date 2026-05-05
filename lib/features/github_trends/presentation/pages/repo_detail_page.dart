import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/date_format.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../domain/entities/repo_entity.dart';
import '../bloc/github_trends_bloc.dart';

class RepoDetailPage extends StatelessWidget {
  const RepoDetailPage({required this.repo, super.key});
  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(repo.name),
        actions: [
          BlocSelector<FavoritesBloc, FavoritesState, bool>(
            selector: (s) => s.repos.any((e) => e.repo.id == repo.id),
            builder: (context, isFav) => IconButton(
              tooltip: isFav ? 'Remove favorite' : 'Add to favorites',
              icon: Icon(
                isFav ? Icons.star : Icons.star_outline,
                color: isFav ? Colors.amber.shade700 : null,
              ),
              onPressed: () => context
                  .read<GithubTrendsBloc>()
                  .add(TrendsToggleFavorite(repo)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: repo.ownerAvatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repo.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      repo.ownerLogin,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (repo.description != null) ...[
            Text(
              repo.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Stat(label: 'Stars', value: compactCount(repo.stars)),
              _Stat(label: 'Forks', value: compactCount(repo.forks)),
              if (repo.language != null)
                _Stat(label: 'Language', value: repo.language!),
              if (repo.pushedAt != null)
                _Stat(
                  label: 'Last push',
                  value: formatRelative(repo.pushedAt!),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(repo.htmlUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open on GitHub'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

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
        ],
      ),
    );
  }
}
