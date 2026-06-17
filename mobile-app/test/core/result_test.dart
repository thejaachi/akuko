import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok exposes value and folds to success branch', () {
      const Result<int> r = Ok(42);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull, 42);
      expect(r.fold((_) => 'err', (v) => 'ok:$v'), 'ok:42');
    });

    test('Err exposes failure and folds to failure branch', () {
      const failure = NotFoundFailure('missing');
      const Result<int> r = Err(failure);
      expect(r.isErr, isTrue);
      expect(r.failureOrNull, failure);
      expect(r.fold((f) => f.message, (_) => 'ok'), 'missing');
    });

    test('map transforms Ok and preserves Err', () {
      const Result<int> ok = Ok(2);
      expect(ok.map((v) => v * 10).valueOrNull, 20);

      const Result<int> err = Err(ServerFailure());
      expect(err.map((v) => v * 10).isErr, isTrue);
    });

    test('getOrThrow throws the failure for Err', () {
      const Result<int> err = Err(NetworkFailure());
      expect(() => err.getOrThrow(), throwsA(isA<NetworkFailure>()));
    });

    test('guardAsync captures thrown errors as Err', () async {
      final result = await guardAsync<int>(
        () async => throw StateError('boom'),
        onError: (_, __) => const ServerFailure('failed'),
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });
}
