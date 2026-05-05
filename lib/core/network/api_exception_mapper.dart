import 'dart:io';

import 'package:dio/dio.dart';

import '../errors/failures.dart';

/// Single place where infrastructure exceptions become typed [Failure]s.
/// Keeps the mapping consistent and unit-testable.
Failure mapDioError(Object error) {
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const TimeoutFailure(),
      DioExceptionType.badResponse => _fromStatus(error),
      DioExceptionType.cancel => const UnknownFailure('Request cancelled'),
      DioExceptionType.connectionError ||
      DioExceptionType.unknown =>
        error.error is SocketException
            ? const NetworkFailure()
            : UnknownFailure(error.message ?? 'Unknown network error'),
      DioExceptionType.badCertificate =>
        const ServerFailure('Bad certificate'),
    };
  }
  if (error is SocketException) return const NetworkFailure();
  if (error is FormatException) return const ParseFailure();
  return UnknownFailure(error.toString());
}

Failure _fromStatus(DioException error) {
  final status = error.response?.statusCode;
  if (status == 404) return const NotFoundFailure();
  if (status != null && status >= 500) {
    return ServerFailure('Server error ($status)', statusCode: status);
  }
  return ServerFailure(
    'Request failed${status != null ? ' ($status)' : ''}',
    statusCode: status,
  );
}
