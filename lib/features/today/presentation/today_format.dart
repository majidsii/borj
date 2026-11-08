import 'package:borj/core/money/money.dart';

/// «۱۴:۳۰», «۹:۰۵»: hours without a leading zero, minutes two digits,
/// Persian digits. [t] is a zone wall-clock time.
String formatClock(DateTime t) =>
    Money.toPersianDigits('${t.hour}:${t.minute.toString().padLeft(2, '0')}');
