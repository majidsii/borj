import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';

final class InstallmentPlan {
  InstallmentPlan({
    required this.id,
    required String title,
    required this.perInstallment,
    required this.installmentCount,
    required this.paidCount,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  }) : title = title.trim() {
    validateDomainId(id, entityName: 'برنامه اقساط');
    if (this.title.isEmpty) {
      throw const ValidationFailure('عنوان قسط نمی‌تواند خالی باشد.');
    }
    validateExactPositiveMoney(perInstallment);
    if (installmentCount < 1) {
      throw const ValidationFailure('تعداد اقساط باید حداقل یک باشد.');
    }
    try {
      perInstallment * installmentCount;
    } on MoneyOverflowFailure {
      throw const ValidationFailure('مجموع اقساط از حد مجاز بیشتر است.');
    }
    if (paidCount < 0 || paidCount > installmentCount) {
      throw const ValidationFailure('تعداد اقساط پرداخت‌شده نامعتبر است.');
    }
    validatePersistenceUtc(createdAtUtc);
    validatePersistenceUtc(updatedAtUtc);
  }

  final String id;
  final String title;
  final Money perInstallment;
  final int installmentCount;
  final int paidCount;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  int get remainingCount => installmentCount - paidCount;
  Money get total => perInstallment * installmentCount;
  Money get paid => perInstallment * paidCount;
  Money get remaining => perInstallment * remainingCount;
  bool get settled => remainingCount == 0;
  double get progressForChart => paidCount / installmentCount;

  InstallmentPlan copyWith({
    String? title,
    Money? perInstallment,
    int? installmentCount,
    int? paidCount,
    DateTime? updatedAtUtc,
  }) {
    return InstallmentPlan(
      id: id,
      title: title ?? this.title,
      perInstallment: perInstallment ?? this.perInstallment,
      installmentCount: installmentCount ?? this.installmentCount,
      paidCount: paidCount ?? this.paidCount,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InstallmentPlan &&
            other.id == id &&
            other.title == title &&
            other.perInstallment == perInstallment &&
            other.installmentCount == installmentCount &&
            other.paidCount == paidCount &&
            other.createdAtUtc == createdAtUtc &&
            other.updatedAtUtc == updatedAtUtc;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    perInstallment,
    installmentCount,
    paidCount,
    createdAtUtc,
    updatedAtUtc,
  );

  @override
  String toString() {
    return 'InstallmentPlan(id: $id, title: $title, '
        'perInstallment: $perInstallment, installmentCount: '
        '$installmentCount, paidCount: $paidCount)';
  }
}
