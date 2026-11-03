import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/theme/theme_mode_controller.dart';
import 'package:dashboard_shakhsi/app/widgets/aurora_background.dart';
import 'package:dashboard_shakhsi/app/widgets/original_controls.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/app/widgets/original_icon.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/finance_panel.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

final class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedPanel = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              OriginalDesignTokens.pageHorizontalPadding,
              OriginalDesignTokens.pageTopPadding,
              OriginalDesignTokens.pageHorizontalPadding,
              OriginalDesignTokens.pageBottomPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: OriginalDesignTokens.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _TopBar(
                      selectedPanel: _selectedPanel,
                      onPanelSelected: (value) {
                        setState(() => _selectedPanel = value);
                      },
                      onThemePressed: () => _toggleTheme(context),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      reverseDuration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .018),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _selectedPanel == 0
                          ? const TasksPanel(
                              key: ValueKey<String>('tasks-panel'),
                            )
                          : const FinancePanel(
                              key: ValueKey<String>('finance-panel'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleTheme(BuildContext context) {
    final currentBrightness = Theme.of(context).brightness;
    ref.read(dashboardThemeModeProvider.notifier).state =
        currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.selectedPanel,
    required this.onPanelSelected,
    required this.onThemePressed,
  });

  final int selectedPanel;
  final ValueChanged<int> onPanelSelected;
  final VoidCallback onThemePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hideBrandText = constraints.maxWidth <= 560;
          final compactTabs = constraints.maxWidth <= 480;

          final brandIsland = _BrandIsland(hideText: hideBrandText);
          // Debug builds only: long-press the brand to open the glass review.
          final brand = kDebugMode
              ? GestureDetector(
                  onLongPress: () =>
                      GoRouter.maybeOf(context)?.go('/debug/glass-review'),
                  child: brandIsland,
                )
              : brandIsland;
          final tabs = _TopTabs(
            selectedPanel: selectedPanel,
            compact: compactTabs,
            onPanelSelected: onPanelSelected,
          );
          final theme = _ThemeIsland(onPressed: onThemePressed);

          if (constraints.maxWidth >= 520) {
            return Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[brand, tabs, theme],
            );
          }

          return Wrap(
            textDirection: TextDirection.rtl,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[brand, tabs, theme],
          );
        },
      ),
    );
  }
}

final class _BrandIsland extends StatelessWidget {
  const _BrandIsland({required this.hideText});

  final bool hideText;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return OriginalGlass(
      radius: OriginalDesignTokens.pillRadius,
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: hideText ? 10 : 15,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: <Widget>[
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[palette.accent, palette.accent2],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.accent.withValues(alpha: .35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                const BoxShadow(
                  color: Color(0x8CFFFFFF),
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: const Center(
              child: OriginalIcon(
                OriginalIconType.check,
                color: Colors.white,
                size: 16,
                strokeWidth: 2.6,
              ),
            ),
          ),
          if (!hideText) ...<Widget>[
            const SizedBox(width: 9),
            Text(
              'داشبورد شخصی',
              key: const ValueKey<String>('brand-label'),
              style: TextStyle(
                color: palette.ink,
                fontSize: 15.5,
                letterSpacing: -.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _TopTabs extends StatelessWidget {
  const _TopTabs({
    required this.selectedPanel,
    required this.compact,
    required this.onPanelSelected,
  });

  final int selectedPanel;
  final bool compact;
  final ValueChanged<int> onPanelSelected;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final tasksTabWidth = compact ? 79.0 : 91.0;
    final financeTabWidth = compact ? 74.0 : 86.0;
    const gap = 2.0;
    const tabHeight = 37.0;

    return OriginalGlass(
      radius: OriginalDesignTokens.pillRadius,
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: tasksTabWidth + financeTabWidth + gap,
        height: tabHeight,
        child: Stack(
          textDirection: TextDirection.rtl,
          children: <Widget>[
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 500),
              curve: const Cubic(.32, 1.35, .4, 1),
              top: 0,
              bottom: 0,
              start: selectedPanel == 0 ? 0 : tasksTabWidth + gap,
              width: selectedPanel == 0 ? tasksTabWidth : financeTabWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.thumb,
                  borderRadius: BorderRadius.circular(
                    OriginalDesignTokens.pillRadius,
                  ),
                  border: Border.all(color: palette.hair, width: 1),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: palette.shadowSecondary,
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: palette.hairTop,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: tasksTabWidth,
              child: _TopTabButton(
                label: 'کارها',
                icon: OriginalIconType.tasks,
                selected: selectedPanel == 0,
                onTap: () => onPanelSelected(0),
              ),
            ),
            PositionedDirectional(
              start: tasksTabWidth + gap,
              top: 0,
              bottom: 0,
              width: financeTabWidth,
              child: _TopTabButton(
                label: 'مالی',
                icon: OriginalIconType.wallet,
                selected: selectedPanel == 1,
                onTap: () => onPanelSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TopTabButton extends StatelessWidget {
  const _TopTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final OriginalIconType icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final color = selected ? palette.ink : palette.muted;

    return OriginalPressable(
      onPressed: onTap,
      pressedScale: .96,
      borderRadius: BorderRadius.circular(OriginalDesignTokens.pillRadius),
      semanticLabel: label,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: <Widget>[
            OriginalIcon(icon, color: color, size: 15),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ThemeIsland extends StatelessWidget {
  const _ThemeIsland({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return OriginalGlass(
      radius: OriginalDesignTokens.pillRadius,
      child: OriginalPressable(
        onPressed: onPressed,
        pressedScale: .92,
        borderRadius: BorderRadius.circular(OriginalDesignTokens.pillRadius),
        semanticLabel: dark ? 'تم روشن' : 'تم تاریک',
        child: SizedBox.square(
          dimension: 42,
          child: Center(
            child: OriginalIcon(
              dark ? OriginalIconType.sun : OriginalIconType.moon,
              color: palette.ink,
              size: 19,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }
}
