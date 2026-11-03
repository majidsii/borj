import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';

String legacyDigits(int value) => Money.toPersianDigits('$value');

String legacyEntityLabel(LegacyEntityType type) => switch (type) {
  LegacyEntityType.task => 'کار',
  LegacyEntityType.transaction => 'تراکنش',
  LegacyEntityType.debt => 'بدهی',
  LegacyEntityType.installment => 'قسط',
};

String legacySkipReasonLabel(LegacySkipReason reason) => switch (reason) {
  LegacySkipReason.notAnObject => 'ساختار رکورد نامعتبر',
  LegacySkipReason.emptyTitle => 'عنوان خالی',
  LegacySkipReason.duplicateId => 'شناسه تکراری',
  LegacySkipReason.invalidAmount => 'مبلغ نامعتبر',
  LegacySkipReason.invalidCount => 'تعداد نامعتبر',
  LegacySkipReason.totalOverflow => 'مجموع اقساط بیش از حد مجاز',
  LegacySkipReason.failedValidation => 'رد شده در اعتبارسنجی',
};

String legacyWarningLabel(LegacyWarningCode code) => switch (code) {
  LegacyWarningCode.tasksUnreadable => 'فهرست کارها خوانده نشد',
  LegacyWarningCode.financeUnreadable => 'داده‌های مالی خوانده نشد',
  LegacyWarningCode.unknownTransactionType =>
    'نوع تراکنش ناشناخته بود و به‌عنوان هزینه وارد شد',
  LegacyWarningCode.paidClamped => 'مبلغ پرداخت‌شده به کل بدهی محدود شد',
  LegacyWarningCode.paidCountClamped => 'تعداد اقساط پرداخت‌شده محدود شد',
};
