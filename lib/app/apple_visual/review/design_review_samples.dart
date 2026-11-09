import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/data/in_memory_appearance_preferences_store.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:borj/features/settings/presentation/appearance_section.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:borj/features/today/presentation/installment_card.dart';
import 'package:borj/features/today/presentation/timeline_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:borj/features/today/presentation/today_header.dart';
import 'package:borj/features/today/presentation/today_onboarding.dart';
import 'package:borj/features/today/presentation/today_tasks_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One design-review sample: a label, the board it is compared with (file name
/// without extension) and a builder. The review screen builds it once per side
/// (light and dark), each side with its own theme, motion and glass scopes.
final class DesignReviewSample {
  const DesignReviewSample({
    required this.label,
    required this.board,
    required this.build,
    this.darkOnly = false,
  });

  final String label;
  final String board;
  final WidgetBuilder build;

  /// When true the light side shows a placeholder instead of the sample.
  final bool darkOnly;
}

/// Add new samples here, one entry each.
final List<DesignReviewSample> designReviewSamples = <DesignReviewSample>[
  DesignReviewSample(
    label: 'GlassButton variants',
    board: 'PhoneTasks',
    build: (_) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        GlassButton(onPressed: () {}, label: 'ذخیره'),
        GlassButton(
          onPressed: () {},
          label: 'ذخیره',
          variant: GlassButtonVariant.tinted,
        ),
        GlassButton(
          onPressed: () {},
          label: 'لغو',
          variant: GlassButtonVariant.plain,
        ),
      ],
    ),
  ),
  DesignReviewSample(
    label: 'GlassButton on a panel',
    board: 'PhoneTasks',
    build: (_) => _panel(
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          GlassButton(onPressed: () {}, label: 'ذخیره'),
          GlassButton(
            onPressed: () {},
            label: 'ذخیره',
            variant: GlassButtonVariant.tinted,
          ),
          GlassButton(
            onPressed: () {},
            label: 'لغو',
            variant: GlassButtonVariant.plain,
          ),
        ],
      ),
    ),
  ),
  DesignReviewSample(
    label: 'GlassSegmented off glass',
    board: 'PhoneTasks',
    build: (_) => const _SegmentedDemo(),
  ),
  DesignReviewSample(
    label: 'GlassSegmented on glass',
    board: 'PhoneSettings',
    build: (_) => _panel(const _SegmentedDemo()),
  ),
  DesignReviewSample(
    label: 'GlassToggle',
    board: 'PhoneNotifications',
    build: (_) => const _ToggleDemo(),
  ),
  DesignReviewSample(
    label: 'GlassChip',
    board: 'PhoneTasks',
    build: (_) => const _ChipDemo(),
  ),
  DesignReviewSample(
    label: 'GlassTextField',
    board: 'PhoneQuickEntry',
    build: (_) => const _TextFieldDemo(),
  ),
  DesignReviewSample(
    label: 'ProgressTrack tones',
    board: 'PhoneBudgets',
    build: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, tone) in ProgressTone.values.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          ProgressTrack(value: 0.25 + i * 0.25, tone: tone),
        ],
      ],
    ),
  ),
  DesignReviewSample(
    label: 'RoundCheck',
    board: 'PhoneTasks',
    build: (_) => const _RoundCheckDemo(),
  ),
  DesignReviewSample(
    label: 'AnimatedNumber',
    board: 'PhoneMoney',
    build: (_) => const _AnimatedNumberDemo(),
  ),
  DesignReviewSample(
    label: 'GlassSheet',
    board: 'PhoneAddTxn',
    build: (_) => const _SheetDemo(),
  ),
  DesignReviewSample(
    label: 'Row insert / remove',
    board: 'PhoneTasks',
    build: (_) => const _RowTransitionDemo(),
  ),
  DesignReviewSample(
    label: 'Appearance section',
    board: 'PhoneSettings',
    build: (_) => ProviderScope(
      overrides: [
        // Override all three so nothing resolves in the app's root container:
        // the review page must never change the live theme or write files.
        appearancePreferencesStoreProvider.overrideWithValue(
          InMemoryAppearancePreferencesStore(),
        ),
        initialAppearancePreferencesProvider.overrideWithValue(
          AppearancePreferences.defaults,
        ),
        appearancePreferencesProvider.overrideWith(
          AppearancePreferencesController.new,
        ),
      ],
      child: const AppearanceSection(),
    ),
  ),
  DesignReviewSample(
    label: 'Glow-corner contrast',
    board: 'Main',
    darkOnly: true,
    build: (_) => const _GlowCornerDemo(),
  ),
  DesignReviewSample(
    label: 'UndoToast',
    board: 'PhoneTasks',
    build: (_) => Builder(
      builder: (context) => GlassButton(
        label: 'حذف',
        onPressed: () =>
            showUndoToast(context, message: 'کار حذف شد', onUndo: () {}),
      ),
    ),
  ),
  DesignReviewSample(
    label: 'GlassTabBar',
    board: 'Main',
    build: (_) =>
        const GlassScope(kind: GlassLayerKind.chrome, child: _TabBarDemo()),
  ),
  DesignReviewSample(
    label: 'GlassSidebar',
    board: 'MacToday',
    build: (_) => GlassScope(
      kind: GlassLayerKind.chrome,
      child: SizedBox(
        width: GlassSidebar.width,
        height: 560,
        child: GlassSidebar(
          groups: sidebarGroups(),
          selectedLocation: '/',
          onSelected: (_) {},
          onSettings: () {},
        ),
      ),
    ),
  ),
  DesignReviewSample(
    label: 'GlassSidebar rail',
    board: 'MacToday',
    build: (_) => GlassScope(
      kind: GlassLayerKind.chrome,
      child: SizedBox(
        width: GlassSidebar.railWidth,
        height: 560,
        child: GlassSidebar(
          groups: sidebarGroups(),
          selectedLocation: '/',
          rail: true,
          onSelected: (_) {},
          onSettings: () {},
        ),
      ),
    ),
  ),
  DesignReviewSample(
    label: 'ShellToolbar',
    board: 'Main',
    build: (_) => GlassScope(
      kind: GlassLayerKind.chrome,
      child: ShellToolbar(
        buttonSize: 44,
        actions: [
          ShellAction(
            icon: Icons.calendar_month_outlined,
            label: 'تقویم',
            leading: true,
            onPressed: (_) {},
          ),
          ShellAction(
            icon: Icons.settings_outlined,
            label: 'تنظیمات',
            leading: true,
            onPressed: (_) {},
          ),
          ShellAction(
            icon: Icons.add,
            label: 'ورود سریع',
            primary: true,
            onPressed: (_) {},
          ),
        ],
      ),
    ),
  ),
  DesignReviewSample(
    label: 'LargeTitleHeader',
    board: 'Main',
    build: (_) =>
        const LargeTitleHeader(title: 'امروز', subtitle: 'یکشنبه، ۱۷ آبان'),
  ),
  DesignReviewSample(
    label: 'EmptyState',
    board: 'PhoneEmptyToday',
    build: (_) => EmptyState(
      icon: Icons.wb_sunny_outlined,
      title: 'امروز کاری نداری',
      message: 'یک کار تازه اضافه کن',
      actionLabel: 'افزودن کار',
      onAction: () {},
    ),
  ),
  DesignReviewSample(
    label: 'GlassInspector',
    board: 'MacTasks',
    build: (_) => const _InspectorDemo(),
  ),
  DesignReviewSample(
    label: 'TimelineCard',
    board: 'Main',
    build: (_) => _fixedBox(
      358,
      164,
      TimelineCard(agenda: _sampleAgenda, now: _sampleNow),
    ),
  ),
  DesignReviewSample(
    label: 'TodayTasksCard large',
    board: 'Main',
    build: (_) => _fixedBox(
      358,
      340,
      TodayTasksCard(
        agenda: _sampleAgenda,
        now: _sampleNow,
        onToggle: (_) {},
        onShowAll: () {},
      ),
    ),
  ),
  DesignReviewSample(
    label: 'TodayTasksCard expanded grouping',
    board: 'MacToday',
    build: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: const Size(1440, 900)),
      child: _fixedBox(
        572,
        340,
        TodayTasksCard(
          agenda: _sampleAgenda,
          now: _sampleNow,
          onToggle: (_) {},
          onShowAll: () {},
        ),
      ),
    ),
  ),
  DesignReviewSample(
    label: 'InstallmentCard wide',
    board: 'Main',
    build: (_) => _fixedBox(
      358,
      164,
      InstallmentCard(installment: _sampleInstallment, onOpen: () {}),
    ),
  ),
  DesignReviewSample(
    label: 'InstallmentCard small',
    board: 'Main',
    build: (_) => _fixedBox(
      173,
      164,
      InstallmentCard(
        installment: _sampleInstallment,
        onOpen: () {},
        size: TodayCardSize.small,
      ),
    ),
  ),
  DesignReviewSample(
    label: 'TodayHeader date chip',
    board: 'MacToday',
    build: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: const Size(1440, 900)),
      child: TodayHeader(now: _sampleNow),
    ),
  ),
  DesignReviewSample(
    label: 'TodayOnboarding',
    board: 'PhoneEmptyToday',
    build: (_) => TodayOnboarding(onAddTask: () {}),
  ),
];

final DateTime _sampleNow = DateTime(2026, 11, 4, 14, 30);

final TodayAgenda _sampleAgenda = TodayAgenda(
  day: DateTime(2026, 11, 4),
  timed: [
    TodayEntry(
      taskId: 's1',
      title: 'جلسهٔ صبحگاهی',
      done: true,
      recurring: false,
      localStart: DateTime(2026, 11, 4, 9),
      durationMinutes: 60,
    ),
    TodayEntry(
      taskId: 's2',
      title: 'ورزش عصر',
      done: false,
      recurring: false,
      localStart: DateTime(2026, 11, 4, 15),
      durationMinutes: 60,
    ),
    TodayEntry(
      taskId: 's3',
      title: 'مرور هفتگی',
      done: false,
      recurring: false,
      localStart: DateTime(2026, 11, 4, 17),
      durationMinutes: 90,
    ),
  ],
  untimed: const [
    TodayEntry(taskId: 's4', title: 'خرید نان', done: false, recurring: false),
  ],
);

const TodayInstallment _sampleInstallment = TodayInstallment(
  planId: 'sample',
  title: 'قسط وام',
  nextNumber: 4,
  count: 12,
  amount: Money(minorUnits: 4200000, currencyCode: 'IRT', scale: 0),
);

Widget _fixedBox(double width, double height, Widget child) =>
    SizedBox(width: width, height: height, child: child);

class _TabBarDemo extends StatefulWidget {
  const _TabBarDemo();

  @override
  State<_TabBarDemo> createState() => _TabBarDemoState();
}

class _TabBarDemoState extends State<_TabBarDemo> {
  int _selected = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) setState(() => _selected = (_selected + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassTabBar(
    destinations: shellDestinations,
    selectedIndex: _selected,
    onSelected: (i) => setState(() => _selected = i),
    onSearch: () {},
  );
}

class _InspectorDemo extends StatefulWidget {
  const _InspectorDemo();

  @override
  State<_InspectorDemo> createState() => _InspectorDemoState();
}

class _InspectorDemoState extends State<_InspectorDemo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GlassButton(
        onPressed: () => setState(() => _open = !_open),
        label: _open ? 'بستن' : 'باز کردن',
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 360,
        child: GlassInspector(
          open: _open,
          onClose: () => setState(() => _open = false),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: AppText('جزئیات کار', role: AppTextRole.headline),
          ),
        ),
      ),
    ],
  );
}

Widget _panel(Widget child) => AppGlass(
  role: GlassRole.panel,
  shape: const AppleGlassShape.rounded(AppRadii.card),
  child: Padding(padding: const EdgeInsets.all(16), child: child),
);

class _SegmentedDemo extends StatefulWidget {
  const _SegmentedDemo();

  @override
  State<_SegmentedDemo> createState() => _SegmentedDemoState();
}

class _SegmentedDemoState extends State<_SegmentedDemo> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => GlassSegmented<int>(
    segments: const [
      GlassSegment(value: 0, label: 'همه'),
      GlassSegment(value: 1, label: 'امروز'),
      GlassSegment(value: 2, label: 'انجام‌شده'),
    ],
    selected: _selected,
    onChanged: (v) => setState(() => _selected = v),
  );
}

class _ToggleDemo extends StatefulWidget {
  const _ToggleDemo();

  @override
  State<_ToggleDemo> createState() => _ToggleDemoState();
}

class _ToggleDemoState extends State<_ToggleDemo> {
  bool _on = true;
  bool _off = false;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      GlassToggle(value: _on, onChanged: (v) => setState(() => _on = v)),
      const SizedBox(width: 16),
      GlassToggle(value: _off, onChanged: (v) => setState(() => _off = v)),
    ],
  );
}

class _ChipDemo extends StatefulWidget {
  const _ChipDemo();

  @override
  State<_ChipDemo> createState() => _ChipDemoState();
}

class _ChipDemoState extends State<_ChipDemo> {
  bool _selected = true;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      GlassChip(
        label: 'کار',
        selected: _selected,
        onPressed: () => setState(() => _selected = !_selected),
      ),
      GlassChip(label: 'خانه', onPressed: () {}),
      GlassChip(label: 'مهم', icon: Icons.star, onPressed: () {}),
    ],
  );
}

class _TextFieldDemo extends StatefulWidget {
  const _TextFieldDemo();

  @override
  State<_TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<_TextFieldDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassTextField(
    controller: _controller,
    label: 'عنوان',
    hint: 'مثلا خرید',
  );
}

class _RoundCheckDemo extends StatefulWidget {
  const _RoundCheckDemo();

  @override
  State<_RoundCheckDemo> createState() => _RoundCheckDemoState();
}

class _RoundCheckDemoState extends State<_RoundCheckDemo> {
  bool _a = true;
  bool _b = false;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      RoundCheck(checked: _a, onChanged: (v) => setState(() => _a = v)),
      const SizedBox(width: 16),
      RoundCheck(checked: _b, onChanged: (v) => setState(() => _b = v)),
    ],
  );
}

class _AnimatedNumberDemo extends StatefulWidget {
  const _AnimatedNumberDemo();

  @override
  State<_AnimatedNumberDemo> createState() => _AnimatedNumberDemoState();
}

class _AnimatedNumberDemoState extends State<_AnimatedNumberDemo> {
  int _value = 12500;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedNumber(
        value: _value,
        format: (v) => formatPersianInteger(v.round()),
        role: AppTextRole.title,
      ),
      const SizedBox(width: 16),
      GlassButton(
        onPressed: () => setState(() => _value += 1200),
        label: '+${formatPersianInteger(1200)}',
      ),
    ],
  );
}

class _SheetDemo extends StatelessWidget {
  const _SheetDemo();

  @override
  Widget build(BuildContext context) => Builder(
    builder: (buttonContext) => GlassButton(
      label: 'افزودن تراکنش',
      onPressed: () {
        final box = buttonContext.findRenderObject()! as RenderBox;
        final origin = box.localToGlobal(Offset.zero) & box.size;
        showGlassSheet<void>(
          buttonContext,
          origin: origin,
          builder: (_) => const _SheetForm(),
        );
      },
    ),
  );
}

class _SheetForm extends StatefulWidget {
  const _SheetForm();

  @override
  State<_SheetForm> createState() => _SheetFormState();
}

class _SheetFormState extends State<_SheetForm> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassTextField(controller: _amount, label: 'مبلغ'),
        const SizedBox(height: 12),
        GlassTextField(controller: _note, label: 'توضیح'),
        const SizedBox(height: 16),
        GlassButton(
          variant: GlassButtonVariant.tinted,
          label: 'ذخیره',
          onPressed: () => GlassSheet.close(context),
        ),
      ],
    ),
  );
}

/// Most rows kept in the list, so the scope stays at 16 shapes or fewer.
const int _maxDemoRows = 8;

class _RowTransitionDemo extends StatefulWidget {
  const _RowTransitionDemo();

  @override
  State<_RowTransitionDemo> createState() => _RowTransitionDemoState();
}

class _RowTransitionDemoState extends State<_RowTransitionDemo> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<int> _items = <int>[3, 2, 1];
  int _next = 4;

  Widget _row(int id) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: AppGlass(
      role: GlassRole.row,
      shape: const AppleGlassShape.rounded(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: AppText('ردیف ${formatPersianInteger(id)}'),
      ),
    ),
  );

  void _insert() {
    if (_items.length >= _maxDemoRows) return;
    _items.insert(0, _next++);
    _listKey.currentState!.insertItem(0, duration: glassRowDuration(context));
  }

  void _remove() {
    if (_items.isEmpty) return;
    final id = _items.removeAt(0);
    _listKey.currentState!.removeItem(
      0,
      (context, animation) => glassRowRemove(context, animation, _row(id)),
      duration: glassRowDuration(context),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassButton(onPressed: _insert, label: 'افزودن'),
          const SizedBox(width: 8),
          GlassButton(onPressed: _remove, label: 'حذف'),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 360,
        child: GlassScope(
          kind: GlassLayerKind.content,
          child: AnimatedList(
            key: _listKey,
            initialItemCount: _items.length,
            itemBuilder: (context, index, animation) =>
                glassRowInsert(context, animation, _row(_items[index])),
          ),
        ),
      ),
    ],
  );
}

/// Dark only: a panel at the top leading corner, on the warm glow, with one
/// line of text per tone.
class _GlowCornerDemo extends StatelessWidget {
  const _GlowCornerDemo();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: _panel(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText('متن اصلی'),
            const AppText('متن ثانویه', tone: AppTextTone.secondary),
            const AppText('پیوند', tone: AppTextTone.link),
            const AppText('موفق', tone: AppTextTone.success),
            const AppText('هشدار', tone: AppTextTone.warn),
            const AppText('خطر', tone: AppTextTone.danger),
            Text(
              'بنفش',
              style: AppTheme.of(
                context,
              ).text.body.copyWith(color: colors.purple),
            ),
          ],
        ),
      ),
    );
  }
}
