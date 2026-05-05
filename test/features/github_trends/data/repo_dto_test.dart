import 'package:codingtask/features/github_trends/data/models/repo_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepoDto.fromJson', () {
    test('parses a typical item', () {
      final dto = RepoDto.fromJson({
        'id': 1,
        'name': 'flutter',
        'full_name': 'flutter/flutter',
        'description': 'A framework',
        'owner': {
          'login': 'flutter',
          'avatar_url': 'https://x/y.png',
        },
        'html_url': 'https://github.com/flutter/flutter',
        'language': 'Dart',
        'stargazers_count': 1000,
        'forks_count': 200,
        'pushed_at': '2026-01-01T00:00:00Z',
      });
      expect(dto.id, 1);
      expect(dto.ownerLogin, 'flutter');
      expect(dto.stars, 1000);
      expect(dto.pushedAt!.year, 2026);
    });

    test('falls back gracefully for missing fields', () {
      final dto = RepoDto.fromJson({'id': 9});
      expect(dto.name, '');
      expect(dto.ownerLogin, '');
      expect(dto.stars, 0);
      expect(dto.pushedAt, isNull);
    });
  });

  group('RepoSearchDto.fromJson', () {
    test('decodes items list and total', () {
      final dto = RepoSearchDto.fromJson({
        'total_count': 2,
        'items': [
          {'id': 1, 'owner': <String, dynamic>{}},
          {'id': 2, 'owner': <String, dynamic>{}},
        ],
      });
      expect(dto.totalCount, 2);
      expect(dto.items, hasLength(2));
    });
  });
}
