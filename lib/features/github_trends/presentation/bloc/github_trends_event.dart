part of 'github_trends_bloc.dart';

sealed class GithubTrendsEvent extends Equatable {
  const GithubTrendsEvent();
  @override
  List<Object?> get props => const [];
}

class TrendsQueryChanged extends GithubTrendsEvent {
  const TrendsQueryChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class TrendsRefreshed extends GithubTrendsEvent {
  const TrendsRefreshed();
}

class TrendsLoadNextPage extends GithubTrendsEvent {
  const TrendsLoadNextPage();
}

class TrendsToggleFavorite extends GithubTrendsEvent {
  const TrendsToggleFavorite(this.repo);
  final RepoEntity repo;
  @override
  List<Object?> get props => [repo.id];
}
