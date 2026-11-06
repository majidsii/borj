import 'package:borj/core/money/money.dart';
import 'package:borj/features/finance/application/finance_summary.dart';
import 'package:shamsi_date/shamsi_date.dart';

export 'package:borj/features/finance/application/finance_summary.dart';

enum FinanceEntryType { expense, income, debt, installment }

final class FinancePreviewTransaction {
  FinancePreviewTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.createdAt,
  });

  final int id;
  final FinanceEntryType type;
  final String title;
  final String category;
  final Money amount;
  final DateTime createdAt;

  bool get isIncome => type == FinanceEntryType.income;
}

final class FinancePreviewDebt {
  FinancePreviewDebt({
    required this.id,
    required this.title,
    required this.total,
    required this.paid,
  });

  final int id;
  final String title;
  final Money total;
  Money paid;

  Money get remaining {
    final value = total - paid;
    return value.isNegative ? total.copyWith(minorUnits: 0) : value;
  }

  double get progress => total.isZero
      ? 0
      : (paid.minorUnits / total.minorUnits).clamp(0, 1).toDouble();
  bool get settled => remaining.isZero;
}

final class FinancePreviewInstallment {
  FinancePreviewInstallment({
    required this.id,
    required this.title,
    required this.perInstallment,
    required this.count,
    required this.paidCount,
  });

  final int id;
  final String title;
  final Money perInstallment;
  final int count;
  int paidCount;

  int get remainingCount => (count - paidCount).clamp(0, count).toInt();
  Money get remaining => perInstallment * remainingCount;
  double get progress =>
      count <= 0 ? 0 : (paidCount / count).clamp(0, 1).toDouble();
  bool get settled => remainingCount == 0;
}

final class FinancePreviewTotals extends FinanceSummary {
  const FinancePreviewTotals({
    required super.balance,
    required super.monthIncome,
    required super.monthExpense,
    required super.debtRemaining,
  });
}

abstract final class FinancePreviewMath {
  static const List<String> jalaliMonths = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<String> shortWeekdays = <String>[
    'د',
    'س',
    'چ',
    'پ',
    'ج',
    'ش',
    'ی',
  ];

  static FinancePreviewTotals totals({
    required List<FinancePreviewTransaction> transactions,
    required List<FinancePreviewDebt> debts,
    required List<FinancePreviewInstallment> installments,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final monthKey = jalaliMonthKey(reference);
    var income = Money.zeroIRT;
    var expense = Money.zeroIRT;
    var monthIncome = Money.zeroIRT;
    var monthExpense = Money.zeroIRT;

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
        if (jalaliMonthKey(transaction.createdAt) == monthKey) {
          monthIncome += transaction.amount;
        }
      } else {
        expense += transaction.amount;
        if (jalaliMonthKey(transaction.createdAt) == monthKey) {
          monthExpense += transaction.amount;
        }
      }
    }

    final debtRemaining =
        debts.fold<Money>(Money.zeroIRT, (sum, debt) => sum + debt.remaining) +
        installments.fold<Money>(
          Money.zeroIRT,
          (sum, installment) => sum + installment.remaining,
        );

    return FinancePreviewTotals(
      balance: income - expense,
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      debtRemaining: debtRemaining,
    );
  }

  static List<FinanceMonthPoint> trend({
    required List<FinancePreviewTransaction> transactions,
    DateTime? now,
  }) {
    final reference = Jalali.fromDateTime(now ?? DateTime.now());
    final months = <(int year, int month)>[];
    var year = reference.year;
    var month = reference.month;

    for (var index = 0; index < 6; index++) {
      months.insert(0, (year, month));
      month -= 1;
      if (month == 0) {
        month = 12;
        year -= 1;
      }
    }

    return months
        .map((value) {
          var income = Money.zeroIRT;
          var expense = Money.zeroIRT;
          for (final transaction in transactions) {
            final jalali = Jalali.fromDateTime(transaction.createdAt);
            if (jalali.year != value.$1 || jalali.month != value.$2) {
              continue;
            }
            if (transaction.isIncome) {
              income += transaction.amount;
            } else {
              expense += transaction.amount;
            }
          }
          return FinanceMonthPoint(
            year: value.$1,
            month: value.$2,
            label: jalaliMonths[value.$2 - 1],
            income: income,
            expense: expense,
          );
        })
        .toList(growable: false);
  }

  static List<FinanceCategoryPoint> categories({
    required List<FinancePreviewTransaction> transactions,
    required bool currentMonthOnly,
    DateTime? now,
  }) {
    final referenceKey = jalaliMonthKey(now ?? DateTime.now());
    final values = <String, Money>{};
    for (final transaction in transactions) {
      if (transaction.isIncome) continue;
      if (currentMonthOnly &&
          jalaliMonthKey(transaction.createdAt) != referenceKey) {
        continue;
      }
      values.update(
        transaction.category,
        (current) => current + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final result = values.entries
        .map(
          (entry) => FinanceCategoryPoint(label: entry.key, value: entry.value),
        )
        .toList();
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  static List<FinanceDayPoint> week({
    required List<FinancePreviewTransaction> transactions,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    return List<FinanceDayPoint>.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      var value = Money.zeroIRT;
      for (final transaction in transactions) {
        if (transaction.isIncome) continue;
        final created = transaction.createdAt;
        if (created.year == date.year &&
            created.month == date.month &&
            created.day == date.day) {
          value += transaction.amount;
        }
      }
      return FinanceDayPoint(
        date: date,
        label: shortWeekdays[date.weekday - 1],
        value: value,
        isToday: index == 6,
      );
    }, growable: false);
  }

  static int jalaliMonthKey(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return jalali.year * 100 + jalali.month;
  }

  static Money parseAmount(String raw) {
    return Money.tryParseMajorUnits(
          raw,
          currencyCode: Money.tomanCurrencyCode,
          scale: Money.financeScale,
        ) ??
        Money.zeroIRT;
  }

  static int parseCount(String raw) {
    var normalized = Money.normalizeDigits(raw.trim());
    normalized = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(normalized) ?? 0;
  }

  static String money(Money amount) => amount.formatMajorUnits();

  static String compact(Money amount) {
    final absoluteMinor = amount.minorUnits.abs();
    final scaleFactor = _powerOfTen(amount.scale);
    if (absoluteMinor >= 1000000000 * scaleFactor) {
      return '${fa(_roundedSingleDecimal(amount.minorUnits, 1000000000 * scaleFactor))} میلیارد';
    }
    if (absoluteMinor >= 1000000 * scaleFactor) {
      return '${fa(_roundedSingleDecimal(amount.minorUnits, 1000000 * scaleFactor))} میلیون';
    }
    if (absoluteMinor >= 1000 * scaleFactor) {
      return '${fa(_roundedSingleDecimal(amount.minorUnits, 1000 * scaleFactor))} هزار';
    }
    return money(amount);
  }

  static String jalaliShort(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${fa(jalali.day.toString())} '
        '${jalaliMonths[jalali.month - 1]}';
  }

  static String fa(Object value) => Money.toPersianDigits(value.toString());

  static int _powerOfTen(int exponent) {
    var value = 1;
    for (var index = 0; index < exponent; index++) {
      value *= 10;
    }
    return value;
  }

  static String _roundedSingleDecimal(int numerator, int denominator) {
    final negative = numerator < 0;
    final absolute = numerator.abs();
    var whole = absolute ~/ denominator;
    var tenth =
        ((absolute % denominator) * 10 + denominator ~/ 2) ~/ denominator;
    if (tenth == 10) {
      whole += 1;
      tenth = 0;
    }
    final sign = negative ? '−' : '';
    return tenth == 0 ? '$sign$whole' : '$sign$whole.$tenth';
  }
}
