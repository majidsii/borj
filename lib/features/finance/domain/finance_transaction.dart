import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';

enum FinanceTransactionType { income, expense }

final class FinanceTransaction {
  FinanceTransaction.create({
    required this.id,
    required this.type,
    required String title,
    required String category,
    required this.amount,
    required this.occurredAtUtc,
    required this.createdAtUtc,
    DateTime? updatedAtUtc,
  }) : title = title.trim(),
       category = category.trim(),
       updatedAtUtc = updatedAtUtc ?? createdAtUtc {
    validateDomainId(id, entityName: 'تراکنش');
    validateExactPositiveMoney(amount);
    if (this.title.isEmpty) {
      throw const ValidationFailure('عنوان تراکنش نمی‌تواند خالی باشد.');
    }
    if (this.category.isEmpty) {
      throw const ValidationFailure('دسته تراکنش نمی‌تواند خالی باشد.');
    }
    validatePersistenceUtc(occurredAtUtc);
    validatePersistenceUtc(createdAtUtc);
    validatePersistenceUtc(this.updatedAtUtc);
  }

  final String id;
  final FinanceTransactionType type;
  final String title;
  final String category;
  final Money amount;
  final DateTime occurredAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  bool get isIncome => type == FinanceTransactionType.income;
  bool get isExpense => type == FinanceTransactionType.expense;

  FinanceTransaction copyWith({
    FinanceTransactionType? type,
    String? title,
    String? category,
    Money? amount,
    DateTime? occurredAtUtc,
    DateTime? updatedAtUtc,
  }) {
    return FinanceTransaction.create(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FinanceTransaction &&
            other.id == id &&
            other.type == type &&
            other.title == title &&
            other.category == category &&
            other.amount == amount &&
            other.occurredAtUtc == occurredAtUtc &&
            other.createdAtUtc == createdAtUtc &&
            other.updatedAtUtc == updatedAtUtc;
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    category,
    amount,
    occurredAtUtc,
    createdAtUtc,
    updatedAtUtc,
  );

  @override
  String toString() {
    return 'FinanceTransaction(id: $id, type: $type, title: $title, '
        'category: $category, amount: $amount)';
  }
}

void validateDomainId(String value, {required String entityName}) {
  if (value.trim().isEmpty) {
    throw ValidationFailure('شناسه $entityName نمی‌تواند خالی باشد.');
  }
}

void validatePersistenceUtc(DateTime value) {
  if (!value.isUtc) {
    throw const ValidationFailure(
      'زمان اطلاعات مالی باید به‌صورت UTC ذخیره شود.',
    );
  }
}

void validateExactMoneyDefinition(Money value) {
  if (value.currencyCode != Money.tomanCurrencyCode ||
      value.scale != Money.financeScale) {
    throw const ValidationFailure(
      'مبلغ باید با واحد تومان و به‌صورت عدد صحیح ثبت شود.',
    );
  }
}

void validateExactPositiveMoney(Money value) {
  validateExactMoneyDefinition(value);
  if (!value.isPositive) {
    throw const ValidationFailure(
      'مبلغ باید بیشتر از صفر و با واحد تومان ثبت شود.',
    );
  }
}

void validateExactNonNegativeMoney(Money value) {
  validateExactMoneyDefinition(value);
  if (value.isNegative) {
    throw const ValidationFailure('مبلغ نمی‌تواند منفی باشد.');
  }
}
