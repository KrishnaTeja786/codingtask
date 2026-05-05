import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../performance/performance_metrics.dart';

/// Wraps Dio so the rest of the app does not depend on a concrete HTTP lib.
/// Handles timeouts, retries on safe GETs only, and emits per-request timing
/// to the [PerformanceMetrics] sink.
class DioClient {
  DioClient({
    required this.metrics,
    Dio? dio,
  }) : _dio = dio ?? _buildDio() {
    _dio.interceptors.add(_TimingInterceptor(metrics));
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: AppConstants.maxRetries,
        retryDelays: const [
          Duration(milliseconds: 200),
          Duration(milliseconds: 600),
        ],
        // Retry only safe, idempotent GETs on transient failures.
        retryEvaluator: (DioException error, int attempt) async {
          if (error.requestOptions.method.toUpperCase() != 'GET') return false;
          final code = error.response?.statusCode;
          const transient = {408, 429, 500, 502, 503, 504};
          if (code != null && transient.contains(code)) return true;
          return error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.connectionError;
        },
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          error: true,
        ),
      );
    }
  }

  final PerformanceMetrics metrics;
  final Dio _dio;

  static Dio _buildDio() => Dio(
        BaseOptions(
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          sendTimeout: AppConstants.connectTimeout,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'SmartDevHub/1.0 (Flutter)',
          },
          responseType: ResponseType.json,
        ),
      );

  Future<Response<T>> getJson<T>(
    String url, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(url, queryParameters: query, cancelToken: cancelToken);
  }
}

class _TimingInterceptor extends Interceptor {
  _TimingInterceptor(this._metrics);
  final PerformanceMetrics _metrics;
  static const _key = '__started_at__';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra[_key] = DateTime.now().microsecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _record(response.requestOptions, ok: true, status: response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(
      err.requestOptions,
      ok: false,
      status: err.response?.statusCode,
    );
    handler.next(err);
  }

  void _record(RequestOptions opts, {required bool ok, int? status}) {
    final start = opts.extra[_key] as int?;
    if (start == null) return;
    final elapsed = Duration(
      microseconds: DateTime.now().microsecondsSinceEpoch - start,
    );
    _metrics.recordApiCall(
      url: '${opts.baseUrl}${opts.path}',
      duration: elapsed,
      ok: ok,
      statusCode: status,
    );
  }
}
