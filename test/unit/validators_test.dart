import 'package:flutter_test/flutter_test.dart';
import 'package:robux_box/core/error/failure.dart';
import 'package:robux_box/core/error/result.dart';
import 'package:robux_box/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('password requires length + letters + digits', () {
      expect(Validators.password('abc12345'), isNull);
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('allletters'), isNotNull);
    });

    test('confirmPassword matches', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
      expect(Validators.confirmPassword('x', 'y'), isNotNull);
    });

    test('phone', () {
      expect(Validators.phone('+15551234567'), isNull);
      expect(Validators.phone('123'), isNotNull);
    });

    test('otp requires 6 digits', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('12a456'), isNotNull);
      expect(Validators.otp('123'), isNotNull);
    });

    test('robloxUsername', () {
      expect(Validators.robloxUsername('Player_123'), isNull);
      expect(Validators.robloxUsername('ab'), isNotNull);
      expect(Validators.robloxUsername('has space'), isNotNull);
    });
  });

  group('Result', () {
    test('success carries value and folds', () {
      const Result<int> r = Result.success(42);
      expect(r.isSuccess, isTrue);
      expect(r.valueOrNull, 42);
      expect(r.when(success: (v) => v * 2, failure: (_) => -1), 84);
    });

    test('failure carries failure and folds', () {
      const Result<int> r = Result.failure(NetworkFailure());
      expect(r.isFailure, isTrue);
      expect(r.failureOrNull, isA<NetworkFailure>());
      expect(r.when(success: (_) => 'ok', failure: (f) => f.code),
          'network/unavailable');
    });

    test('map transforms success only', () {
      const Result<int> ok = Result.success(2);
      expect(ok.map((v) => v + 1).valueOrNull, 3);
      const Result<int> err = Result.failure(UnknownFailure());
      expect(err.map((v) => v + 1).isFailure, isTrue);
    });
  });
}
