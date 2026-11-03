import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('arithmetic requires the same currency and scale', () {
      const income = Money(
        minorUnits: 50_000_000,
        currencyCode: 'IRT',
        scale: 0,
      );
      const expense = Money(
        minorUnits: 12_500_000,
        currencyCode: 'IRT',
        scale: 0,
      );

      expect(
        income - expense,
        const Money(minorUnits: 37_500_000, currencyCode: 'IRT', scale: 0),
      );
      expect(
        () =>
            income + const Money(minorUnits: 1, currencyCode: 'USD', scale: 2),
        throwsArgumentError,
      );
    });

    test('comparison rejects incompatible money definitions', () {
      const toman = Money(minorUnits: 100, currencyCode: 'IRT', scale: 0);
      const rial = Money(minorUnits: 100, currencyCode: 'IRR', scale: 0);

      expect(() => toman.compareTo(rial), throwsArgumentError);
    });

    test(
      'parses Persian Arabic and Latin digits with eight-decimal precision',
      () {
        final value = Money.parseMajorUnits(
          '۱۲۳٬۴۵۶٫۷۸۹۰۱۲۳۴',
          currencyCode: 'IRT',
          scale: 8,
        );

        expect(value.minorUnits, 12_345_678_901_234);
        expect(value.formatMajorUnits(), '۱۲۳٬۴۵۶٫۷۸۹۰۱۲۳۴');
        expect(
          Money.parseMajorUnits(
            '١٢٣,٤٥٦.٧٨٩٠١٢٣٤',
            currencyCode: 'IRT',
            scale: 8,
          ),
          value,
        );
      },
    );

    test('trims only unnecessary output zeros without rounding', () {
      final value = Money.parseMajorUnits(
        '12000.50000000',
        currencyCode: 'IRT',
        scale: 8,
      );

      expect(value.formatMajorUnits(), '۱۲٬۰۰۰٫۵');
      expect(
        value.formatMajorUnits(trimFractionZeros: false),
        '۱۲٬۰۰۰٫۵۰۰۰۰۰۰۰',
      );
    });

    test(
      'rejects values with more fractional digits than the configured scale',
      () {
        expect(
          () => Money.parseMajorUnits(
            '1.123456789',
            currencyCode: 'IRT',
            scale: 8,
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'multiplies and clamps exact values without floating-point arithmetic',
      () {
        final installment = Money.parseMajorUnits(
          '1000.125',
          currencyCode: 'IRT',
          scale: 8,
        );
        final total = installment * 3;
        final payment = Money.parseMajorUnits(
          '5000.75',
          currencyCode: 'IRT',
          scale: 8,
        );

        expect(total.formatMajorUnits(), '۳٬۰۰۰٫۳۷۵');
        const zero = Money(minorUnits: 0, currencyCode: 'IRT', scale: 8);
        expect(payment.clamp(zero, total), total);
        expect((-installment).absolute, installment);
      },
    );
  });
}
