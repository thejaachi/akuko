import 'package:akuko/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('foo@'), isNotNull);
      expect(Validators.email('foo@bar'), isNotNull);
    });

    test('accepts well-formed addresses', () {
      expect(Validators.email('reader@akuko.app'), isNull);
      expect(Validators.email('a.b+tag@example.co.uk'), isNull);
    });
  });

  group('Validators.password', () {
    test('requires at least 8 characters', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('must match the original', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
      expect(Validators.confirmPassword('abc12345', 'different'), isNotNull);
    });
  });

  group('Validators.fullName', () {
    test('rejects blank and too-short names', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('A'), isNotNull);
      expect(Validators.fullName('Ada'), isNull);
    });
  });
}
