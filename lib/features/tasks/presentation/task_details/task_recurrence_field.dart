import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/presentation/task_details/task_jalali_date_time_field.dart';
import 'package:borj/features/tasks/presentation/task_details/task_recurrence_draft.dart';
import 'package:flutter/material.dart';

final class TaskRecurrenceField extends StatefulWidget {
  const TaskRecurrenceField({
    required this.value,
    required this.anchorLocal,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final TaskRecurrenceDraft value;
  final DateTime? anchorLocal;
  final ValueChanged<TaskRecurrenceDraft> onChanged;
  final String? errorText;

  @override
  State<TaskRecurrenceField> createState() => _TaskRecurrenceFieldState();
}

final class _TaskRecurrenceFieldState extends State<TaskRecurrenceField> {
  late final TextEditingController _intervalController;
  late final TextEditingController _timeZoneController;
  late final TextEditingController _monthlyController;
  late final TextEditingController _annualController;
  late final TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(
      text: widget.value.interval.toString(),
    );
    _timeZoneController = TextEditingController(
      text: widget.value.fixedTimeZoneId,
    );
    _monthlyController = TextEditingController(
      text: widget.value.monthlyDaysText,
    );
    _annualController = TextEditingController(
      text: widget.value.annualDatesText,
    );
    _countController = TextEditingController(
      text: widget.value.afterCount.toString(),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _timeZoneController.dispose();
    _monthlyController.dispose();
    _annualController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.value;
    final palette = OriginalPalette.of(context);

    return Semantics(
      container: true,
      label: 'تنظیم تکرار کار',
      child: OriginalFieldSurface(
        radius: OriginalDesignTokens.fieldRadius,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'تکرار',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: draft.enabled,
                    onChanged: (value) {
                      final next = draft.copy()..enabled = value;
                      _emit(next);
                    },
                  ),
                ],
              ),
              if (!draft.enabled)
                Text(
                  'این کار فقط یک‌بار در تقویم نمایش داده می‌شود.',
                  style: TextStyle(color: palette.muted, fontSize: 12.5),
                )
              else ...<Widget>[
                if (widget.anchorLocal == null)
                  _Hint(
                    text: 'برای تکرار، ابتدا زمان شروع یا سررسید را وارد کنید.',
                    error: true,
                  ),
                const SizedBox(height: 10),
                _Label(text: 'الگو'),
                const SizedBox(height: 6),
                OriginalPills(
                  items: const <String>['روزانه', 'هفتگی', 'ماهانه', 'سالانه'],
                  selected: draft.frequency.index,
                  compact: true,
                  onSelected: (index) {
                    final next = draft.copy()
                      ..frequency = RecurrenceFrequency.values[index];
                    if (next.frequency == RecurrenceFrequency.weekly &&
                        next.weeklyDays.isEmpty &&
                        widget.anchorLocal != null) {
                      next.weeklyDays.add(
                        RecurrenceWeekday.fromIsoNumber(
                          widget.anchorLocal!.weekday,
                        ),
                      );
                    }
                    _emit(next);
                  },
                ),
                const SizedBox(height: 12),
                _Label(text: 'هر چند دوره'),
                const SizedBox(height: 6),
                _NumberField(
                  controller: _intervalController,
                  semanticLabel: 'فاصله تکرار',
                  onChanged: (value) {
                    final next = draft.copy()
                      ..interval = int.tryParse(value) ?? 0;
                    _emit(next);
                  },
                ),
                const SizedBox(height: 12),
                _Label(text: 'تقویم'),
                const SizedBox(height: 6),
                OriginalPills(
                  items: const <String>['جلالی', 'میلادی'],
                  selected: draft.calendar == RecurrenceCalendar.jalali ? 0 : 1,
                  compact: true,
                  onSelected: (index) {
                    final next = draft.copy()
                      ..calendar = index == 0
                          ? RecurrenceCalendar.jalali
                          : RecurrenceCalendar.gregorian;
                    _emit(next);
                  },
                ),
                if (draft.frequency == RecurrenceFrequency.weekly) ...<Widget>[
                  const SizedBox(height: 12),
                  _Label(text: 'روزهای هفته'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: RecurrenceWeekday.values
                        .map((weekday) {
                          final selected = draft.weeklyDays.contains(weekday);
                          return FilterChip(
                            label: Text(_weekdayLabel(weekday)),
                            selected: selected,
                            onSelected: (value) {
                              final next = draft.copy();
                              if (value) {
                                next.weeklyDays.add(weekday);
                              } else {
                                next.weeklyDays.remove(weekday);
                              }
                              _emit(next);
                            },
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
                if (draft.frequency == RecurrenceFrequency.monthly) ...<Widget>[
                  const SizedBox(height: 12),
                  _Label(text: 'روزهای ماه'),
                  const SizedBox(height: 6),
                  _TextField(
                    controller: _monthlyController,
                    semanticLabel: 'روزهای ماه تکرار',
                    hintText: 'مثلاً ۵، ۲۰، ۳۱',
                    onChanged: (value) {
                      final next = draft.copy()..monthlyDaysText = value;
                      _emit(next);
                    },
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('آخرین روز ماه'),
                    value: draft.includeLastDay,
                    onChanged: (value) {
                      final next = draft.copy()
                        ..includeLastDay = value ?? false;
                      _emit(next);
                    },
                  ),
                ],
                if (draft.frequency == RecurrenceFrequency.yearly) ...<Widget>[
                  const SizedBox(height: 12),
                  _Label(text: 'تاریخ‌های سالانه'),
                  const SizedBox(height: 6),
                  _TextField(
                    controller: _annualController,
                    semanticLabel: 'تاریخ‌های سالانه تکرار',
                    hintText: 'مثلاً ۱/۱، ۷/۱۵',
                    onChanged: (value) {
                      final next = draft.copy()..annualDatesText = value;
                      _emit(next);
                    },
                  ),
                ],
                if (draft.frequency == RecurrenceFrequency.monthly ||
                    draft.frequency == RecurrenceFrequency.yearly) ...<Widget>[
                  const SizedBox(height: 12),
                  _Label(text: 'روز نامعتبر'),
                  const SizedBox(height: 6),
                  OriginalPills(
                    items: const <String>['ردکردن دوره', 'آخرین روز'],
                    selected:
                        draft.invalidDatePolicy ==
                            RecurrenceInvalidDatePolicy.skipPeriod
                        ? 0
                        : 1,
                    compact: true,
                    onSelected: (index) {
                      final next = draft.copy()
                        ..invalidDatePolicy = index == 0
                            ? RecurrenceInvalidDatePolicy.skipPeriod
                            : RecurrenceInvalidDatePolicy.clampToLastDay;
                      _emit(next);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                _Label(text: 'منطقه زمانی'),
                const SizedBox(height: 6),
                OriginalPills(
                  items: const <String>['شناور', 'ثابت'],
                  selected:
                      draft.timeZoneMode == RecurrenceTimeZoneMode.floating
                      ? 0
                      : 1,
                  compact: true,
                  onSelected: (index) {
                    final next = draft.copy()
                      ..timeZoneMode = index == 0
                          ? RecurrenceTimeZoneMode.floating
                          : RecurrenceTimeZoneMode.fixed;
                    _emit(next);
                  },
                ),
                if (draft.timeZoneMode ==
                    RecurrenceTimeZoneMode.fixed) ...<Widget>[
                  const SizedBox(height: 6),
                  _TextField(
                    controller: _timeZoneController,
                    semanticLabel: 'شناسه منطقه زمانی ثابت',
                    hintText: 'Asia/Tehran',
                    onChanged: (value) {
                      final next = draft.copy()..fixedTimeZoneId = value;
                      _emit(next);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                _Label(text: 'پایان'),
                const SizedBox(height: 6),
                OriginalPills(
                  items: const <String>[
                    'بدون پایان',
                    'تا تاریخ',
                    'پس از تعداد',
                  ],
                  selected: draft.endKind.index,
                  compact: true,
                  onSelected: (index) {
                    final next = draft.copy()
                      ..endKind = RecurrenceEndKind.values[index];
                    _emit(next);
                  },
                ),
                if (draft.endKind == RecurrenceEndKind.until) ...<Widget>[
                  const SizedBox(height: 8),
                  TaskJalaliDateTimeField(
                    label: 'پایان تکرار',
                    valueLocal: draft.untilLocal,
                    onChanged: (value) {
                      final next = draft.copy()..untilLocal = value;
                      _emit(next);
                    },
                  ),
                ],
                if (draft.endKind == RecurrenceEndKind.afterCount) ...<Widget>[
                  const SizedBox(height: 8),
                  _NumberField(
                    controller: _countController,
                    semanticLabel: 'تعداد رخدادهای تکرار',
                    onChanged: (value) {
                      final next = draft.copy()
                        ..afterCount = int.tryParse(value) ?? 0;
                      _emit(next);
                    },
                  ),
                ],
              ],
              if (widget.errorText case final error?) ...<Widget>[
                const SizedBox(height: 8),
                _Hint(text: error, error: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _emit(TaskRecurrenceDraft next) {
    widget.onChanged(next);
    setState(() {});
  }
}

final class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: OriginalPalette.of(context).ink,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

final class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Text(
      text,
      style: TextStyle(
        color: error ? palette.expense : palette.muted,
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

final class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.semanticLabel,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

final class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.semanticLabel,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

String _weekdayLabel(RecurrenceWeekday weekday) {
  return switch (weekday) {
    RecurrenceWeekday.monday => 'دوشنبه',
    RecurrenceWeekday.tuesday => 'سه‌شنبه',
    RecurrenceWeekday.wednesday => 'چهارشنبه',
    RecurrenceWeekday.thursday => 'پنجشنبه',
    RecurrenceWeekday.friday => 'جمعه',
    RecurrenceWeekday.saturday => 'شنبه',
    RecurrenceWeekday.sunday => 'یکشنبه',
  };
}
