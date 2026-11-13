import 'package:shamsi_date/shamsi_date.dart';

/// Persian date labels. Every input is a naive wall-clock value in the task
/// calendar zone (never UTC-flagged); the label reads its fields as they are
/// and applies no zone conversion.
abstract final class PersianDateLabel {
  static const List<String> _weekdays = <String>[
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنج‌شنبه',
    'جمعه',
    'شنبه',
    'یک‌شنبه',
  ];

  static const List<String> _months = <String>[
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

  static const List<String> _gregorianMonths = <String>[
    'ژانویه',
    'فوریه',
    'مارس',
    'آوریل',
    'مه',
    'ژوئن',
    'ژوئیه',
    'اوت',
    'سپتامبر',
    'اکتبر',
    'نوامبر',
    'دسامبر',
  ];

  /// «چهارشنبه ۱۳ آبان» (phone Today subtitle).
  static String short(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    final weekday = _weekdays[dateTime.weekday - 1];
    return '$weekday ${_fa(jalali.day)} ${_months[jalali.month - 1]}';
  }

  /// «۱۴ آبان» (task row date).
  static String dayMonth(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${_fa(jalali.day)} ${_months[jalali.month - 1]}';
  }

  /// «چهارشنبه، ۴ نوامبر» (desktop date chip subtitle).
  static String gregorianShort(DateTime dateTime) {
    final weekday = _weekdays[dateTime.weekday - 1];
    return '$weekday، ${_fa(dateTime.day)} '
        '${_gregorianMonths[dateTime.month - 1]}';
  }

  /// «۱۳ آبان ۱۴۰۵» (desktop date chip title).
  static String jalaliLong(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${_fa(jalali.day)} ${_months[jalali.month - 1]} '
        '${_fa(jalali.year)}';
  }

  static String full(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    final weekday = _weekdays[dateTime.weekday - 1];
    return '$weekday، ${_fa(jalali.day)} ${_months[jalali.month - 1]} ${_fa(jalali.year)}';
  }

  static String _fa(Object value) {
    const latin = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return value.toString().split('').map((character) {
      final index = latin.indexOf(character);
      return index < 0 ? character : persian[index];
    }).join();
  }
}
