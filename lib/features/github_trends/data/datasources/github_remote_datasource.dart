import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/repo_dto.dart';

abstract interface class GithubRemoteDataSource {
  Future<({RepoSearchDto data, String rawJson})> searchRepositories({
    required String query,
    required int page,
    required int perPage,
  });
}

class GithubRemoteDataSourceImpl implements GithubRemoteDataSource {
  GithubRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<({RepoSearchDto data, String rawJson})> searchRepositories({
    required String query,
    required int page,
    required int perPage,
  }) async {
    final response = await _client.getJson<Map<String, dynamic>>(
      '${AppConstants.githubBaseUrl}/search/repositories',
      query: {
        'q': query,
        'sort': 'stars',
        'order': 'desc',
        'page': page,
        'per_page': perPage,
      },
    );
    final body = response.data ?? const <String, dynamic>{};
    // Heavy JSON dispatched to a worker isolate. The GitHub search payload
    // for 30 repos is ~80 KB; doing it on the UI isolate would skip frames
    // on lower-end devices.
    final dto = await compute(_parseSearch, body);
    return (data: dto, rawJson: jsonEncode(body));
  }
}

RepoSearchDto _parseSearch(Map<String, dynamic> body) =>
    RepoSearchDto.fromJson(body);
