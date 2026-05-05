import 'package:equatable/equatable.dart';

/// Domain entity. Pure Dart, no Flutter, no JSON. Presentation talks only
/// in these types — never DTOs.
class RepoEntity extends Equatable {
  const RepoEntity({
    required this.id,
    required this.name,
    required this.fullName,
    required this.description,
    required this.ownerLogin,
    required this.ownerAvatarUrl,
    required this.htmlUrl,
    required this.language,
    required this.stars,
    required this.forks,
    required this.pushedAt,
  });

  final int id;
  final String name;
  final String fullName;
  final String? description;
  final String ownerLogin;
  final String ownerAvatarUrl;
  final String htmlUrl;
  final String? language;
  final int stars;
  final int forks;
  final DateTime? pushedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        fullName,
        description,
        ownerLogin,
        ownerAvatarUrl,
        htmlUrl,
        language,
        stars,
        forks,
        pushedAt,
      ];
}
