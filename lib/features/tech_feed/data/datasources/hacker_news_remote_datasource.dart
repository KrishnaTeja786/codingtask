import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/article_dto.dart';

abstract interface class HackerNewsRemoteDataSource {
  Future<List<int>> fetchTopStoryIds();
  Future<HnItemDto> fetchItem(int id);
  Future<List<HnItemDto>> fetchItemsBatch(List<int> ids);
  String encodeItems(List<HnItemDto> items);
  Future<List<HnItemDto>> decodeItems(String raw);
}

class HackerNewsRemoteDataSourceImpl implements HackerNewsRemoteDataSource {
  HackerNewsRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<List<int>> fetchTopStoryIds() async {
    final res = await _client.getJson<List<dynamic>>(
      '${AppConstants.hackerNewsBaseUrl}/topstories.json',
    );
    return (res.data ?? const [])
        .whereType<num>()
        .map((e) => e.toInt())
        .toList(growable: false);
  }

  @override
  Future<HnItemDto> fetchItem(int id) async {
    final res = await _client.getJson<Map<String, dynamic>>(
      '${AppConstants.hackerNewsBaseUrl}/item/$id.json',
    );
    return HnItemDto.fromJson(res.data ?? const {});
  }

  /// HN API has no batch endpoint; issue parallel requests with a concurrency
  /// cap to avoid socket exhaustion on poor networks.
  @override
  Future<List<HnItemDto>> fetchItemsBatch(List<int> ids) async {
    const concurrency = 8;
    final results = <HnItemDto>[];
    for (var start = 0; start < ids.length; start += concurrency) {
      final end = (start + concurrency).clamp(0, ids.length);
      final slice = ids.sublist(start, end);
      final batch = await Future.wait(slice.map(fetchItem));
      results.addAll(batch);
    }
    return results;
  }

  @override
  String encodeItems(List<HnItemDto> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  /// Decode happens on a worker isolate so a 30-item cache restore never
  /// blocks the UI when scrolling lists are flinging.
  @override
  Future<List<HnItemDto>> decodeItems(String raw) => compute(_decodeItems, raw);
}

List<HnItemDto> _decodeItems(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .whereType<Map<String, dynamic>>()
      .map(HnItemDto.fromJson)
      .toList(growable: false);
}
