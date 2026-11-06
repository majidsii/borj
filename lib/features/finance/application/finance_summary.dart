import 'package:borj/core/money/money.dart';

class FinanceSummary {
  const FinanceSummary({
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
    required this.debtRemaining,
  });

  final Money balance;
  final Money monthIncome;
  final Money monthExpense;
  final Money debtRemaining;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FinanceSummary &&
            other.balance == balance &&
            other.monthIncome == monthIncome &&
            other.monthExpense == monthExpense &&
            other.debtRemaining == debtRemaining;
  }

  @override
  int get hashCode =>
      Object.hash(balance, monthIncome, monthExpense, debtRemaining);
}

final class FinanceMonthPoint {
  const FinanceMonthPoint({
    required this.year,
    required this.month,
    required this.label,
    required this.income,
    required this.expense,
  });

  final int year;
  final int month;
  final String label;
  final Money income;
  final Money expense;
}

final class FinanceCategoryPoint {
  const FinanceCategoryPoint({required this.label, required this.value});

  final String label;
  final Money value;
}

final class FinanceDayPoint {
  const FinanceDayPoint({
    required this.date,
    required this.label,
    required this.value,
    required this.isToday,
  });

  final DateTime date;
  final String label;
  final Money value;
  final bool isToday;
}
