import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:shamsi_date/shamsi_date.dart';

const List<String> _taskJalaliMonthNames = <String>[
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

String? taskStartLabel(TaskItem task) {
  final value = task.startAtUtc;
  if (value == null) return null;
  return 'شروع: ${_taskLocalDateTimeLabel(value)}';
}

String? taskDueLabel(TaskItem task) {
  final value = task.dueAtUtc;
  if (value == null) return null;
  return 'سررسید: ${_taskLocalDateTimeLabel(value)}';
}

String? taskEstimatedDurationLabel(TaskItem task) {
  final totalMinutes = task.estimatedDurationMinutes;
  if (totalMinutes == null) return null;

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) {
    return 'تخمین: ${taskPersianDigits(minutes)} دقیقه';
  }
  if (minutes == 0) {
    return 'تخمین: ${taskPersianDigits(hours)} ساعت';
  }
  return 'تخمین: ${taskPersianDigits(hours)} ساعت و '
      '${taskPersianDigits(minutes)} دقیقه';
}

String taskJalaliDateTimeLabel(DateTime valueLocal) {
  final local = valueLocal.isUtc ? valueLocal.toLocal() : valueLocal;
  final jalali = Jalali.fromDateTime(local);
  final month = _taskJalaliMonthNames[jalali.month - 1];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '${taskPersianDigits(jalali.day)} $month ${taskPersianDigits(jalali.year)}، '
      '${taskPersianDigits(hour)}:${taskPersianDigits(minute)}';
}

String taskPersianDigits(Object value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  return value.toString().split('').map((character) {
    final index = latin.indexOf(character);
    return index < 0 ? character : persian[index];
  }).join();
}

String _taskLocalDateTimeLabel(DateTime valueUtc) {
  return taskJalaliDateTimeLabel(valueUtc.toLocal());
}
