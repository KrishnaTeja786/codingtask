import 'dart:io';

import 'package:codingtask/core/errors/failures.dart';
import 'package:codingtask/core/network/api_exception_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reqOpts = RequestOptions(path: '/x');

  group('mapDioError', () {
    test('connect timeout -> TimeoutFailure', () {
      final f = mapDioError(DioException(
        requestOptions: reqOpts,
        type: DioExceptionType.connectionTimeout,
      ));
      expect(f, isA<TimeoutFailure>());
    });

    test('socket exception -> NetworkFailure', () {
      final f = mapDioError(const SocketException('no net'));
      expect(f, isA<NetworkFailure>());
    });

    test('500 -> ServerFailure', () {
      final f = mapDioError(DioException(
        requestOptions: reqOpts,
        response: Response<dynamic>(
          requestOptions: reqOpts,
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      ));
      expect(f, isA<ServerFailure>());
      expect((f as ServerFailure).statusCode, 500);
    });

    test('404 -> NotFoundFailure', () {
      final f = mapDioError(DioException(
        requestOptions: reqOpts,
        response: Response<dynamic>(
          requestOptions: reqOpts,
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      ));
      expect(f, isA<NotFoundFailure>());
    });

    test('FormatException -> ParseFailure', () {
      final f = mapDioError(const FormatException('bad'));
      expect(f, isA<ParseFailure>());
    });
  });
}
