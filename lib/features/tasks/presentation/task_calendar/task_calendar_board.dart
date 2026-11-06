import 'dart:async';

import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:borj/features/tasks/application/task_occurrence_projector.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:timezone/timezone.dart' as timezone;

typedef TaskOccurrenceAction =
    Future<void> Function(TaskCalendarOccurrence occurrence);
typedef TaskOccurrenceMoveAction =
    Future<void> Function(
      TaskCalendarOccurrence occurrence,
      DateTime movedGregorianLocal,
    );

final class TaskCalendarBoard extends StatefulWidget {
  const TaskCalendarBoard({
    required this.tasks,
    required this.rules,
    required this.exceptions,
    required this.completions,
    required this.floatingTimeZoneId,
    required this.onToggleCompleted,
    required this.onSkip,
    required this.onCancel,
    required this.onRestore,
    required this.onMove,
    this.projector = const TaskOccurrenceProjector(),
    this.now = DateTime.now,
    super.key,
  });

  final List<TaskItem> tasks;
  final List<TaskRecurrenceRule> rules;
  final List<TaskRecurrenceException> exceptions;
  final List<TaskOccurrenceCompletion> completions;
  final String floatingTimeZoneId;
  final TaskOccurrenceAction onToggleCompleted;
  final TaskOccurrenceAction onSkip;
  final TaskOccurrenceAction onCancel;
  final TaskOccurrenceAction onRestore;
  final TaskOccurrenceMoveAction onMove;
  final TaskOccurrenceProjector projector;
  final DateTime Function() now;

  @override
  State<TaskCalendarBoard> createState() => _TaskCalendarBoardState();
}

final class _TaskCalendarBoardState extends State<TaskCalendarBoard> {
  late DateTime _visibleAnchor;
  late DateTime _selectedDay;
  bool _jalali = true;
  final Set<String> _busy = <String>{};

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(widget.now());
    _visibleAnchor = today;
    _selectedDay = today;
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final window = _calendarWindow();
    final location = timezone.getLocation(widget.floatingTimeZoneId);
    final rangeStartUtc = timezone.TZDateTime(
      location,
      window.gridStart.year,
      window.gridStart.month,
      window.gridStart.day,
    ).toUtc();
    final dayAfterGrid = window.gridStart.add(
      Duration(days: window.days.length),
    );
    final rangeEndUtc = timezone.TZDateTime(
      location,
      dayAfterGrid.year,
      dayAfterGrid.month,
      dayAfterGrid.day,
    ).toUtc();

    final occurrences = widget.projector.project(
      tasks: widget.tasks,
      rules: widget.rules,
      exceptions: widget.exceptions,
      completions: widget.completions,
      rangeStartUtc: rangeStartUtc,
      rangeEndUtc: rangeEndUtc,
      floatingTimeZoneId: widget.floatingTimeZoneId,
    );
    final byDay = <String, List<TaskCalendarOccurrence>>{};
    for (final occurrence in occurrences) {
      final local = timezone.TZDateTime.from(occurrence.instantUtc, location);
      byDay
          .putIfAbsent(
            _dayKey(DateTime(local.year, local.month, local.day)),
            () => <TaskCalendarOccurrence>[],
          )
          .add(occurrence);
    }

    final selectedOccurrences =
        byDay[_dayKey(_selectedDay)] ?? const <TaskCalendarOccurrence>[];

    return Column(
      key: const ValueKey<String>('task-calendar-board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OriginalGlass(
          radius: OriginalDesignTokens.cardRadius,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'ماه قبل',
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Text(
                          window.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton(
                          onPressed: _goToday,
                          child: const Text('امروز'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'ماه بعد',
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              OriginalPills(
                items: const <String>['جلالی', 'میلادی'],
                selected: _jalali ? 0 : 1,
                compact: true,
                onSelected: (index) {
                  setState(() {
                    _jalali = index == 0;
                    _visibleAnchor = _selectedDay;
                  });
                },
              ),
              const SizedBox(height: 12),
              const Row(
                children: <Widget>[
                  _WeekdayLabel('ش'),
                  _WeekdayLabel('ی'),
                  _WeekdayLabel('د'),
                  _WeekdayLabel('س'),
                  _WeekdayLabel('چ'),
                  _WeekdayLabel('پ'),
                  _WeekdayLabel('ج'),
                ],
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: window.days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: .92,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemBuilder: (context, index) {
                  final day = window.days[index];
                  final key = _dayKey(day);
                  final items = byDay[key] ?? const <TaskCalendarOccurrence>[];
                  return _DayCell(
                    day: day,
                    jalali: _jalali,
                    inVisibleMonth: window.contains(day),
                    selected: _sameDay(day, _selectedDay),
                    occurrenceCount: items.length,
                    completedCount: items
                        .where((item) => item.isCompleted)
                        .length,
                    onTap: () => setState(() => _selectedDay = day),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _selectedTitle(),
          style: TextStyle(
            color: palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (selectedOccurrences.isEmpty)
          OriginalGlass(
            radius: OriginalDesignTokens.rowRadius,
            padding: const EdgeInsets.all(18),
            child: Text(
              'برای این روز کاری ثبت نشده است.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted),
            ),
          )
        else
          ...selectedOccurrences.map(
            (occurrence) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OccurrenceCard(
                occurrence: occurrence,
                busy: _busy.contains(occurrence.occurrenceKey),
                onToggleCompleted: occurrence.isActionable
                    ? () => _run(
                        occurrence,
                        () => widget.onToggleCompleted(occurrence),
                      )
                    : null,
                onSkip:
                    occurrence.recurring &&
                        occurrence.status ==
                            TaskCalendarOccurrenceStatus.scheduled
                    ? () => _run(occurrence, () => widget.onSkip(occurrence))
                    : null,
                onCancel:
                    occurrence.recurring &&
                        occurrence.status ==
                            TaskCalendarOccurrenceStatus.scheduled
                    ? () => _run(occurrence, () => widget.onCancel(occurrence))
                    : null,
                onRestore:
                    occurrence.recurring &&
                        (occurrence.status ==
                                TaskCalendarOccurrenceStatus.skipped ||
                            occurrence.status ==
                                TaskCalendarOccurrenceStatus.canceled ||
                            occurrence.status ==
                                TaskCalendarOccurrenceStatus.moved)
                    ? () => _run(occurrence, () => widget.onRestore(occurrence))
                    : null,
                onMove: occurrence.recurring && occurrence.isActionable
                    ? () => _pickMove(occurrence)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickMove(TaskCalendarOccurrence occurrence) async {
    final initial = occurrence.instantUtc.toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 5),
      lastDate: DateTime(initial.year + 20),
      helpText: 'انتقال رخداد',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'زمان جدید رخداد',
    );
    if (time == null || !mounted) return;
    final moved = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await _run(occurrence, () => widget.onMove(occurrence, moved));
  }

  Future<void> _run(
    TaskCalendarOccurrence occurrence,
    Future<void> Function() action,
  ) async {
    if (_busy.contains(occurrence.occurrenceKey)) return;
    setState(() => _busy.add(occurrence.occurrenceKey));
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy.remove(occurrence.occurrenceKey));
      }
    }
  }

  void _goToday() {
    final today = _dateOnly(widget.now());
    setState(() {
      _visibleAnchor = today;
      _selectedDay = today;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      if (_jalali) {
        final current = Jalali.fromDateTime(_visibleAnchor);
        final monthIndex = current.year * 12 + current.month - 1 + delta;
        final shiftedYear = monthIndex ~/ 12;
        final shiftedMonth = monthIndex % 12 + 1;
        final shifted = Jalali(shiftedYear, shiftedMonth, 1).toDateTime();
        _visibleAnchor = shifted;
        _selectedDay = shifted;
      } else {
        final shifted = DateTime(
          _visibleAnchor.year,
          _visibleAnchor.month + delta,
          1,
        );
        _visibleAnchor = shifted;
        _selectedDay = shifted;
      }
    });
  }

  _CalendarWindow _calendarWindow() {
    late final DateTime monthStart;
    late final DateTime monthEnd;
    late final String title;

    if (_jalali) {
      final jalali = Jalali.fromDateTime(_visibleAnchor);
      final first = Jalali(jalali.year, jalali.month, 1);
      final last = Jalali(jalali.year, jalali.month, first.monthLength);
      monthStart = _dateOnly(first.toDateTime());
      monthEnd = _dateOnly(last.toDateTime());
      title = '${_jalaliMonthName(jalali.month)} ${_fa(jalali.year)}';
    } else {
      monthStart = DateTime(_visibleAnchor.year, _visibleAnchor.month, 1);
      monthEnd = DateTime(_visibleAnchor.year, _visibleAnchor.month + 1, 0);
      title =
          '${_gregorianMonthName(_visibleAnchor.month)} '
          '${_fa(_visibleAnchor.year)}';
    }

    final offset = (monthStart.weekday - DateTime.saturday + 7) % 7;
    final gridStart = monthStart.subtract(Duration(days: offset));
    final days = List<DateTime>.generate(
      42,
      (index) => gridStart.add(Duration(days: index)),
      growable: false,
    );
    return _CalendarWindow(
      monthStart: monthStart,
      monthEnd: monthEnd,
      gridStart: gridStart,
      days: days,
      title: title,
    );
  }

  String _selectedTitle() {
    final jalali = Jalali.fromDateTime(_selectedDay);
    return '${_fa(jalali.day)} ${_jalaliMonthName(jalali.month)} '
        '${_fa(jalali.year)}';
  }
}

final class _CalendarWindow {
  const _CalendarWindow({
    required this.monthStart,
    required this.monthEnd,
    required this.gridStart,
    required this.days,
    required this.title,
  });

  final DateTime monthStart;
  final DateTime monthEnd;
  final DateTime gridStart;
  final List<DateTime> days;
  final String title;

  bool contains(DateTime day) {
    return !day.isBefore(monthStart) && !day.isAfter(monthEnd);
  }
}

final class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: OriginalPalette.of(context).muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.jalali,
    required this.inVisibleMonth,
    required this.selected,
    required this.occurrenceCount,
    required this.completedCount,
    required this.onTap,
  });

  final DateTime day;
  final bool jalali;
  final bool inVisibleMonth;
  final bool selected;
  final int occurrenceCount;
  final int completedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final number = jalali ? Jalali.fromDateTime(day).day : day.day;

    return Semantics(
      button: true,
      selected: selected,
      label: 'روز ${_fa(number)}، $occurrenceCount کار',
      child: Material(
        color: selected
            ? palette.accent.withValues(alpha: .16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? palette.accent : palette.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _fa(number),
                  style: TextStyle(
                    color: inVisibleMonth ? palette.ink : palette.faint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (occurrenceCount > 0)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      if (completedCount > 0) ...<Widget>[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 10,
                          color: palette.accent,
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _OccurrenceCard extends StatelessWidget {
  const _OccurrenceCard({
    required this.occurrence,
    required this.busy,
    required this.onToggleCompleted,
    required this.onSkip,
    required this.onCancel,
    required this.onRestore,
    required this.onMove,
  });

  final TaskCalendarOccurrence occurrence;
  final bool busy;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onSkip;
  final VoidCallback? onCancel;
  final VoidCallback? onRestore;
  final VoidCallback? onMove;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final location = timezone.getLocation(occurrence.timeZoneId);
    final local = timezone.TZDateTime.from(occurrence.instantUtc, location);
    final terminal =
        occurrence.status == TaskCalendarOccurrenceStatus.skipped ||
        occurrence.status == TaskCalendarOccurrenceStatus.canceled;

    return OriginalGlass(
      radius: OriginalDesignTokens.rowRadius,
      padding: const EdgeInsets.all(12),
      child: AbsorbPointer(
        absorbing: busy,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  _statusIcon(occurrence.status),
                  color: terminal ? palette.muted : palette.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    occurrence.task.title,
                    style: TextStyle(
                      color: terminal ? palette.muted : palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      decoration: terminal ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Text(
                  '${_fa(local.hour).padLeft(2, '۰')}:'
                  '${_fa(local.minute).padLeft(2, '۰')}',
                  style: TextStyle(
                    color: palette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _statusLabel(occurrence),
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: <Widget>[
                if (onToggleCompleted != null)
                  TextButton.icon(
                    onPressed: onToggleCompleted,
                    icon: Icon(
                      occurrence.isCompleted
                          ? Icons.undo_rounded
                          : Icons.check_rounded,
                    ),
                    label: Text(
                      occurrence.isCompleted ? 'بازکردن' : 'انجام شد',
                    ),
                  ),
                if (onMove != null)
                  TextButton.icon(
                    onPressed: onMove,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('انتقال'),
                  ),
                if (onSkip != null)
                  TextButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('ردکردن'),
                  ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('لغو'),
                  ),
                if (onRestore != null)
                  TextButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('بازگردانی'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _statusIcon(TaskCalendarOccurrenceStatus status) {
  return switch (status) {
    TaskCalendarOccurrenceStatus.scheduled => Icons.event_rounded,
    TaskCalendarOccurrenceStatus.moved => Icons.update_rounded,
    TaskCalendarOccurrenceStatus.completed => Icons.check_circle_rounded,
    TaskCalendarOccurrenceStatus.skipped => Icons.skip_next_rounded,
    TaskCalendarOccurrenceStatus.canceled => Icons.cancel_rounded,
  };
}

String _statusLabel(TaskCalendarOccurrence occurrence) {
  final type = occurrence.recurring ? 'تکرارشونده' : 'یک‌باره';
  final state = switch (occurrence.status) {
    TaskCalendarOccurrenceStatus.scheduled => 'برنامه‌ریزی‌شده',
    TaskCalendarOccurrenceStatus.moved => 'منتقل‌شده',
    TaskCalendarOccurrenceStatus.completed => 'انجام‌شده',
    TaskCalendarOccurrenceStatus.skipped => 'ردشده',
    TaskCalendarOccurrenceStatus.canceled => 'لغوشده',
  };
  return '$type · $state';
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _sameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _dayKey(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _fa(Object value) {
  const western = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return value.toString().split('').map((character) {
    final index = western.indexOf(character);
    return index < 0 ? character : persian[index];
  }).join();
}

String _jalaliMonthName(int month) {
  return const <String>[
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
  ][month - 1];
}

String _gregorianMonthName(int month) {
  return const <String>[
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
  ][month - 1];
}
