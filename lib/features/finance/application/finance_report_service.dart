import 'package:borj/core/money/money.dart';
import 'package:borj/features/finance/application/finance_summary.dart';
import 'package:borj/features/finance/domain/debt.dart';
import 'package:borj/features/finance/domain/finance_transaction.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:shamsi_date/shamsi_date.dart';

final class FinanceReportService {
  const FinanceReportService();

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

  FinanceSummary summary({
    required List<FinanceTransaction> transactions,
    required List<Debt> debts,
    required List<InstallmentPlan> installments,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toLocal();
    final currentMonthKey = jalaliMonthKey(reference);

    var allIncome = Money.zeroIRT;
    var allExpense = Money.zeroIRT;
    var monthIncome = Money.zeroIRT;
    var monthExpense = Money.zeroIRT;

    for (final transaction in transactions) {
      final occurredAt = transaction.occurredAtUtc.toLocal();
      final inCurrentMonth = jalaliMonthKey(occurredAt) == currentMonthKey;

      if (transaction.isIncome) {
        allIncome += transaction.amount;
        if (inCurrentMonth) {
          monthIncome += transaction.amount;
        }
      } else {
        allExpense += transaction.amount;
        if (inCurrentMonth) {
          monthExpense += transaction.amount;
        }
      }
    }

    var debtRemaining = Money.zeroIRT;
    for (final debt in debts) {
      debtRemaining += debt.remaining;
    }
    for (final installment in installments) {
      debtRemaining += installment.remaining;
    }

    return FinanceSummary(
      balance: allIncome - allExpense,
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      debtRemaining: debtRemaining,
    );
  }

  List<FinanceMonthPoint> trend({
    required List<FinanceTransaction> transactions,
    DateTime? now,
  }) {
    final reference = Jalali.fromDateTime((now ?? DateTime.now()).toLocal());
    final monthKeys = <(int year, int month)>[];

    var year = reference.year;
    var month = reference.month;

    for (var index = 0; index < 6; index++) {
      monthKeys.insert(0, (year, month));
      month -= 1;
      if (month == 0) {
        month = 12;
        year -= 1;
      }
    }

    return monthKeys
        .map((monthKey) {
          var income = Money.zeroIRT;
          var expense = Money.zeroIRT;

          for (final transaction in transactions) {
            final jalali = Jalali.fromDateTime(
              transaction.occurredAtUtc.toLocal(),
            );
            if (jalali.year != monthKey.$1 || jalali.month != monthKey.$2) {
              continue;
            }

            if (transaction.isIncome) {
              income += transaction.amount;
            } else {
              expense += transaction.amount;
            }
          }

          return FinanceMonthPoint(
            year: monthKey.$1,
            month: monthKey.$2,
            label: jalaliMonths[monthKey.$2 - 1],
            income: income,
            expense: expense,
          );
        })
        .toList(growable: false);
  }

  List<FinanceCategoryPoint> categories({
    required List<FinanceTransaction> transactions,
    required bool currentMonthOnly,
    DateTime? now,
  }) {
    final referenceMonthKey = jalaliMonthKey((now ?? DateTime.now()).toLocal());
    final totals = <String, Money>{};

    for (final transaction in transactions) {
      if (!transaction.isExpense) {
        continue;
      }

      if (currentMonthOnly &&
          jalaliMonthKey(transaction.occurredAtUtc.toLocal()) !=
              referenceMonthKey) {
        continue;
      }

      totals.update(
        transaction.category,
        (current) => current + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final result = totals.entries
        .map(
          (entry) => FinanceCategoryPoint(label: entry.key, value: entry.value),
        )
        .toList();

    result.sort((left, right) {
      final valueComparison = right.value.compareTo(left.value);
      if (valueComparison != 0) {
        return valueComparison;
      }
      return left.label.compareTo(right.label);
    });

    return result;
  }

  List<FinanceDayPoint> week({
    required List<FinanceTransaction> transactions,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toLocal();
    final today = DateTime(reference.year, reference.month, reference.day);

    return List<FinanceDayPoint>.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      var expense = Money.zeroIRT;

      for (final transaction in transactions) {
        if (!transaction.isExpense) {
          continue;
        }

        final occurredAt = transaction.occurredAtUtc.toLocal();
        if (_isSameLocalDate(occurredAt, date)) {
          expense += transaction.amount;
        }
      }

      return FinanceDayPoint(
        date: date,
        label: shortWeekdays[date.weekday - 1],
        value: expense,
        isToday: index == 6,
      );
    }, growable: false);
  }

  int jalaliMonthKey(DateTime date) {
    final jalali = Jalali.fromDateTime(date.toLocal());
    return jalali.year * 100 + jalali.month;
  }

  bool _isSameLocalDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
