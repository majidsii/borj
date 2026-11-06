import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Money toman(int minorUnits, {int scale = 0}) =>
      Money(minorUnits: minorUnits, currencyCode: 'IRT', scale: scale);

  final overflow = throwsA(isA<MoneyOverflowFailure>());

  group('checked arithmetic', () {
    test('addition throws at both int64 edges and allows exact edges', () {
      expect(() => toman(Money.maxInt64) + toman(1), overflow);
      expect(() => toman(Money.minInt64) + toman(-1), overflow);
      expect(toman(Money.maxInt64) + toman(0), toman(Money.maxInt64));
      expect(toman(Money.maxInt64) + toman(Money.minInt64), toman(-1));
    });

    test('subtraction throws at both int64 edges', () {
      expect(() => toman(Money.minInt64) - toman(1), overflow);
      expect(() => toman(Money.maxInt64) - toman(-1), overflow);
      expect(() => toman(0) - toman(Money.minInt64), overflow);
      expect(toman(5) - toman(7), toman(-2));
    });

    test('multiplication throws instead of wrapping', () {
      expect(() => toman(5000000000000000000) * 2, overflow);
      expect(() => toman(Money.minInt64) * -1, overflow);
      expect(() => toman(3037000500) * 3037000500, overflow);
      expect(toman(3037000499) * 3037000499, toman(9223372030926249001));
      expect(toman(Money.minInt64) * 1, toman(Money.minInt64));
    });

    test('negation and absolute value reject minInt64', () {
      expect(() => -toman(Money.minInt64), overflow);
      expect(() => toman(Money.minInt64).absolute, overflow);
      expect(-toman(5), toman(-5));
      expect(toman(-5).absolute, toman(5));
    });

    test('overflow is an AppFailure with a user message', () {
      try {
        toman(Money.maxInt64) + toman(1);
        fail('expected MoneyOverflowFailure');
      } on AppFailure catch (failure) {
        expect(failure, isA<MoneyOverflowFailure>());
        expect(failure.userMessage, isNotEmpty);
      }
    });

    test('static helpers expose the same checks', () {
      expect(() => Money.checkedAdd(Money.maxInt64, 1), overflow);
      expect(() => Money.checkedSubtract(Money.minInt64, 1), overflow);
      expect(() => Money.checkedMultiply(Money.maxInt64, 2), overflow);
      expect(() => Money.checkedNegate(Money.minInt64), overflow);
      expect(Money.checkedAdd(2, 3), 5);
    });
  });

  group('percentOf', () {
    test('rounds half up without overflowing value * 100', () {
      expect(toman(Money.maxInt64).percentOf(toman(Money.maxInt64)), 100);
      expect(toman(1).percentOf(toman(3)), 33);
      expect(toman(2).percentOf(toman(3)), 67);
      // 1e9 toman at the legacy scale 8 is 1e17 minor units; 1e17 * 100
      // overflows int64, which broke the donut legend.
      final half = toman(100000000000000000, scale: 8);
      final whole = toman(200000000000000000, scale: 8);
      expect(half.percentOf(whole), 50);
    });

    test('rejects an incompatible or non-positive total', () {
      expect(() => toman(1).percentOf(toman(0)), throwsArgumentError);
      expect(() => toman(1).percentOf(toman(5, scale: 2)), throwsArgumentError);
    });
  });
}
