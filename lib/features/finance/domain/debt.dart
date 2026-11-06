import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/finance/domain/finance_transaction.dart';

final class Debt {
  Debt({
    required this.id,
    required String title,
    required this.total,
    required this.paid,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  }) : title = title.trim() {
    validateDomainId(id, entityName: 'بدهی');
    if (this.title.isEmpty) {
      throw const ValidationFailure('عنوان بدهی نمی‌تواند خالی باشد.');
    }
    validateExactPositiveMoney(total);
    validateExactNonNegativeMoney(paid);
    if (paid > total) {
      throw const ValidationFailure(
        'مبلغ پرداخت‌شده نمی‌تواند بیشتر از کل بدهی باشد.',
      );
    }
    validatePersistenceUtc(createdAtUtc);
    validatePersistenceUtc(updatedAtUtc);
  }

  final String id;
  final String title;
  final Money total;
  final Money paid;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  Money get remaining => total - paid;
  bool get settled => remaining.isZero;
  double get progressForChart => paid.minorUnits / total.minorUnits;

  Debt copyWith({
    String? title,
    Money? total,
    Money? paid,
    DateTime? updatedAtUtc,
  }) {
    return Debt(
      id: id,
      title: title ?? this.title,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Debt &&
            other.id == id &&
            other.title == title &&
            other.total == total &&
            other.paid == paid &&
            other.createdAtUtc == createdAtUtc &&
            other.updatedAtUtc == updatedAtUtc;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, total, paid, createdAtUtc, updatedAtUtc);

  @override
  String toString() {
    return 'Debt(id: $id, title: $title, total: $total, paid: $paid)';
  }
}
