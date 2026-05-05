import 'package:codingtask/core/errors/failures.dart';
import 'package:codingtask/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok carries value, fold takes onOk branch', () {
      const r = Result.ok(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.failureOrNull, isNull);
      expect(r.fold((v) => v + 1, (_) => -1), 43);
    });

    test('Err carries failure, fold takes onErr branch', () {
      const r = Result<int>.err(NetworkFailure('boom'));
      expect(r.isErr, isTrue);
      expect(r.failureOrNull, isA<NetworkFailure>());
      expect(r.fold((_) => 'ok', (f) => f.message), 'boom');
    });

    test('map transforms Ok and passes through Err', () {
      const okR = Result.ok(2);
      expect(okR.map((v) => v * 3).valueOrNull, 6);
      const errR = Result<int>.err(TimeoutFailure());
      expect(errR.map((v) => v * 3).failureOrNull, isA<TimeoutFailure>());
    });
  });
}
