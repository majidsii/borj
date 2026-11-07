import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/data/in_memory_appearance_preferences_store.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:borj/features/settings/presentation/appearance_section.dart';
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
];

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
