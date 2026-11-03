import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/original_controls.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/features/tasks/presentation/task_details/task_planning_labels.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

const List<String> _jalaliMonths = <String>[
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

const List<String> _weekdays = <String>['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

final class TaskJalaliDateTimeField extends StatelessWidget {
  const TaskJalaliDateTimeField({
    required this.label,
    required this.valueLocal,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final String label;
  final DateTime? valueLocal;
  final ValueChanged<DateTime?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final value = valueLocal;
    final dateLabel = value == null ? 'تنظیم نشده' : _jalaliDateLabel(value);
    final timeLabel = value == null ? 'تنظیم نشده' : _localTimeLabel(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'زمان $label',
          style: TextStyle(
            color: palette.ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _DateTimePart(
              key: ValueKey<String>('task-$label-date'),
              semanticLabel: 'انتخاب تاریخ $label',
              icon: Icons.calendar_month_outlined,
              value: dateLabel,
              onPressed: () => _selectDate(context),
            ),
            _DateTimePart(
              key: ValueKey<String>('task-$label-time'),
              semanticLabel: 'انتخاب ساعت $label',
              icon: Icons.schedule_rounded,
              value: timeLabel,
              onPressed: () => _selectTime(context),
            ),
            if (value != null)
              OriginalPressable(
                semanticLabel: 'پاک کردن زمان $label',
                onPressed: () => onChanged(null),
                borderRadius: BorderRadius.circular(
                  OriginalDesignTokens.pillRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: palette.muted,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
        if (errorText case final error?) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            error,
            key: ValueKey<String>('task-$label-error'),
            style: TextStyle(
              color: palette.expense,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final base = valueLocal ?? DateTime.now();
    final selected = await _showTaskGlassPanel<Jalali>(
      context: context,
      barrierLabel: 'انتخاب تاریخ $label',
      child: _JalaliDatePickerPanel(
        title: 'انتخاب تاریخ $label',
        initial: Jalali.fromDateTime(base),
      ),
    );
    if (selected == null) return;

    final gregorian = selected.toDateTime();
    onChanged(
      DateTime(
        gregorian.year,
        gregorian.month,
        gregorian.day,
        base.hour,
        base.minute,
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final base = valueLocal ?? DateTime.now();
    final selected = await _showTaskGlassPanel<TimeOfDay>(
      context: context,
      barrierLabel: 'انتخاب ساعت $label',
      child: _TaskTimePickerPanel(
        title: 'انتخاب ساعت $label',
        initial: TimeOfDay.fromDateTime(base),
      ),
    );
    if (selected == null) return;

    onChanged(
      DateTime(base.year, base.month, base.day, selected.hour, selected.minute),
    );
  }
}

final class _DateTimePart extends StatelessWidget {
  const _DateTimePart({
    required this.semanticLabel,
    required this.icon,
    required this.value,
    required this.onPressed,
    super.key,
  });

  final String semanticLabel;
  final IconData icon;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);

    return SizedBox(
      width: 220,
      child: OriginalFieldSurface(
        radius: OriginalDesignTokens.fieldRadius,
        child: OriginalPressable(
          semanticLabel: semanticLabel,
          onPressed: onPressed,
          borderRadius: BorderRadius.circular(OriginalDesignTokens.fieldRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: <Widget>[
                Icon(icon, color: palette.accent, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value == 'تنظیم نشده'
                          ? palette.faint
                          : palette.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _JalaliDatePickerPanel extends StatefulWidget {
  const _JalaliDatePickerPanel({required this.title, required this.initial});

  final String title;
  final Jalali initial;

  @override
  State<_JalaliDatePickerPanel> createState() => _JalaliDatePickerPanelState();
}

final class _JalaliDatePickerPanelState extends State<_JalaliDatePickerPanel> {
  late Jalali _visibleMonth;
  late Jalali _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _visibleMonth = Jalali(widget.initial.year, widget.initial.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final firstGregorian = _visibleMonth.toDateTime();
    final dayOffset = (firstGregorian.weekday + 1) % 7;
    final days = _monthLength(_visibleMonth.year, _visibleMonth.month);

    return _PickerFrame(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              _PickerIconButton(
                semanticLabel: 'ماه قبل',
                icon: Icons.chevron_right_rounded,
                onPressed: () => setState(() {
                  _visibleMonth = _shiftMonth(_visibleMonth, -1);
                }),
              ),
              Expanded(
                child: Text(
                  '${_jalaliMonths[_visibleMonth.month - 1]} '
                  '${taskPersianDigits(_visibleMonth.year)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _PickerIconButton(
                semanticLabel: 'ماه بعد',
                icon: Icons.chevron_left_rounded,
                onPressed: () => setState(() {
                  _visibleMonth = _shiftMonth(_visibleMonth, 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: <Widget>[
              for (final weekday in _weekdays)
                Center(
                  child: Text(
                    weekday,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              for (var index = 0; index < dayOffset; index++)
                const SizedBox.shrink(),
              for (var day = 1; day <= days; day++)
                _DayButton(
                  day: day,
                  selected:
                      _selected.year == _visibleMonth.year &&
                      _selected.month == _visibleMonth.month &&
                      _selected.day == day,
                  today: _isToday(
                    Jalali(_visibleMonth.year, _visibleMonth.month, day),
                  ),
                  onPressed: () {
                    final value = Jalali(
                      _visibleMonth.year,
                      _visibleMonth.month,
                      day,
                    );
                    setState(() => _selected = value);
                    Navigator.of(context).pop(value);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.selected,
    required this.today,
    required this.onPressed,
  });

  final int day;
  final bool selected;
  final bool today;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final radius = BorderRadius.circular(12);

    return OriginalPressable(
      key: ValueKey<String>('task-jalali-day-$day'),
      semanticLabel: 'روز ${taskPersianDigits(day)}',
      onPressed: onPressed,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: selected
              ? palette.accent
              : today
              ? palette.accentSoft
              : Colors.transparent,
          border: today && !selected
              ? Border.all(color: palette.accent.withValues(alpha: .45))
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          taskPersianDigits(day),
          style: TextStyle(
            color: selected ? Colors.white : palette.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

final class _TaskTimePickerPanel extends StatefulWidget {
  const _TaskTimePickerPanel({required this.title, required this.initial});

  final String title;
  final TimeOfDay initial;

  @override
  State<_TaskTimePickerPanel> createState() => _TaskTimePickerPanelState();
}

final class _TaskTimePickerPanelState extends State<_TaskTimePickerPanel> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);

    return _PickerFrame(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _TimeUnit(
                  label: 'ساعت',
                  value: _hour,
                  increaseLabel: 'افزایش ساعت',
                  decreaseLabel: 'کاهش ساعت',
                  onIncrease: () => setState(() => _hour = (_hour + 1) % 24),
                  onDecrease: () => setState(() => _hour = (_hour + 23) % 24),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Text(
                    ':',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _TimeUnit(
                  label: 'دقیقه',
                  value: _minute,
                  increaseLabel: 'افزایش دقیقه',
                  decreaseLabel: 'کاهش دقیقه',
                  onIncrease: () =>
                      setState(() => _minute = (_minute + 1) % 60),
                  onDecrease: () =>
                      setState(() => _minute = (_minute + 59) % 60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OriginalPrimaryButton(
            label: 'تأیید ساعت',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pop(TimeOfDay(hour: _hour, minute: _minute)),
          ),
        ],
      ),
    );
  }
}

final class _TimeUnit extends StatelessWidget {
  const _TimeUnit({
    required this.label,
    required this.value,
    required this.increaseLabel,
    required this.decreaseLabel,
    required this.onIncrease,
    required this.onDecrease,
  });

  final String label;
  final int value;
  final String increaseLabel;
  final String decreaseLabel;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final valueText = value.toString().padLeft(2, '0');

    return Column(
      children: <Widget>[
        _PickerIconButton(
          semanticLabel: increaseLabel,
          icon: Icons.keyboard_arrow_up_rounded,
          onPressed: onIncrease,
        ),
        OriginalFieldSurface(
          radius: OriginalDesignTokens.fieldRadius,
          child: SizedBox(
            width: 72,
            height: 54,
            child: Center(
              child: Text(
                taskPersianDigits(valueText),
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        _PickerIconButton(
          semanticLabel: decreaseLabel,
          icon: Icons.keyboard_arrow_down_rounded,
          onPressed: onDecrease,
        ),
        Text(
          label,
          style: TextStyle(
            color: palette.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

final class _PickerFrame extends StatelessWidget {
  const _PickerFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);

    return AppleLiquidGlass(
      role: AppleGlassRole.largeSurface,
      shape: const AppleGlassShape.rounded(OriginalDesignTokens.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _PickerIconButton(
                  semanticLabel: 'بستن',
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }
}

final class _PickerIconButton extends StatelessWidget {
  const _PickerIconButton({
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OriginalPressable(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: OriginalPalette.of(context).muted, size: 21),
      ),
    );
  }
}

Future<T?> _showTaskGlassPanel<T>({
  required BuildContext context,
  required String barrierLabel,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: .32),
    transitionDuration: const Duration(milliseconds: 190),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

String _jalaliDateLabel(DateTime valueLocal) {
  final jalali = Jalali.fromDateTime(valueLocal);
  return '${taskPersianDigits(jalali.day)} '
      '${_jalaliMonths[jalali.month - 1]} '
      '${taskPersianDigits(jalali.year)}';
}

String _localTimeLabel(DateTime valueLocal) {
  final hour = valueLocal.hour.toString().padLeft(2, '0');
  final minute = valueLocal.minute.toString().padLeft(2, '0');
  return '${taskPersianDigits(hour)}:${taskPersianDigits(minute)}';
}

Jalali _shiftMonth(Jalali value, int delta) {
  final zeroBased = (value.year * 12) + (value.month - 1) + delta;
  final year = zeroBased ~/ 12;
  final month = (zeroBased % 12) + 1;
  return Jalali(year, month, 1);
}

int _monthLength(int year, int month) {
  final first = Jalali(year, month, 1).toDateTime();
  final next = _shiftMonth(Jalali(year, month, 1), 1).toDateTime();
  return next.difference(first).inDays;
}

bool _isToday(Jalali value) {
  final today = Jalali.fromDateTime(DateTime.now());
  return value.year == today.year &&
      value.month == today.month &&
      value.day == today.day;
}
