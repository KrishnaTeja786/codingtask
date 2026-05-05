import '../../domain/entities/repo_entity.dart';

/// Hand-written DTO. Avoids json_serializable codegen for this simple case
/// while still keeping JSON parsing isolated to the data layer.
class RepoDto {
  const RepoDto({
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

  factory RepoDto.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    return RepoDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      description: json['description'] as String?,
      ownerLogin: owner['login'] as String? ?? '',
      ownerAvatarUrl: owner['avatar_url'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      language: json['language'] as String?,
      stars: (json['stargazers_count'] as num?)?.toInt() ?? 0,
      forks: (json['forks_count'] as num?)?.toInt() ?? 0,
      pushedAt: _parseDate(json['pushed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'full_name': fullName,
        'description': description,
        'owner': {'login': ownerLogin, 'avatar_url': ownerAvatarUrl},
        'html_url': htmlUrl,
        'language': language,
        'stargazers_count': stars,
        'forks_count': forks,
        'pushed_at': pushedAt?.toUtc().toIso8601String(),
      };

  RepoEntity toEntity() => RepoEntity(
        id: id,
        name: name,
        fullName: fullName,
        description: description,
        ownerLogin: ownerLogin,
        ownerAvatarUrl: ownerAvatarUrl,
        htmlUrl: htmlUrl,
        language: language,
        stars: stars,
        forks: forks,
        pushedAt: pushedAt,
      );
}

DateTime? _parseDate(Object? raw) {
  if (raw is! String) return null;
  return DateTime.tryParse(raw);
}

class RepoSearchDto {
  const RepoSearchDto({required this.totalCount, required this.items});
  final int totalCount;
  final List<RepoDto> items;

  factory RepoSearchDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return RepoSearchDto(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(RepoDto.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_count': totalCount,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
