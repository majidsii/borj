import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// The app shell (redesign spec §5). Content first under one backdrop group,
/// then every chrome shape of the window class in one chrome scope, so chrome
/// refracts the content scrolling under it (plan Decision 2).
class AppShell extends StatefulWidget {
  const AppShell({
    required this.navigationShell,
    required this.location,
    required this.actionsFor,
    required this.onSettings,
    required this.onSearch,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final String location;
  final List<ShellAction> Function(
    BuildContext context,
    WindowClass windowClass,
  )
  actionsFor;
  final VoidCallback onSettings;
  final VoidCallback onSearch;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey _navigatorKey = GlobalKey(debugLabel: 'shell-navigator');

  static const double _phoneToolbarTop = 58;
  static const double _phoneButton = 44;
  static const double _tabBottom = 24;
  static const double _side = 16;

  void _goBranch(int index) => widget.navigationShell.goBranch(
    index,
    initialLocation: index == widget.navigationShell.currentIndex,
  );

  void _goItem(SidebarItem item) {
    final uri = Uri.parse(item.location);
    if (uri.hasQuery || uri.path != sectionLocation(item.section)) {
      GoRouter.of(context).go(item.location);
    } else {
      _goBranch(item.section.index);
    }
  }

  Widget _content(EdgeInsets extraPadding, {bool removeStart = false}) {
    final media = MediaQuery.of(context);
    var padding = media.padding;
    if (removeStart) {
      // The chrome rail already sits inside the safe area on this side.
      final rtl = Directionality.of(context) == TextDirection.rtl;
      padding = rtl ? padding.copyWith(right: 0) : padding.copyWith(left: 0);
    }
    return GlassBackdropGroup(
      key: const ValueKey('shell-content'),
      child: MediaQuery(
        data: media.copyWith(padding: padding + extraPadding),
        child: KeyedSubtree(key: _navigatorKey, child: widget.navigationShell),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wc = WindowClass.of(context);
    final actions = widget.actionsFor(context, wc);
    final layout = switch (wc) {
      WindowClass.compact => _compact(context, actions),
      WindowClass.medium => _desktop(context, actions, rail: true),
      WindowClass.expanded => _desktop(context, actions, rail: false),
    };
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            widget.onSettings,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            widget.onSearch,
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: AppBackground(
          kind: AppBackgroundKind.phone,
          child: Material(type: MaterialType.transparency, child: layout),
        ),
      ),
    );
  }

  Widget _compact(BuildContext context, List<ShellAction> actions) {
    final top = MediaQuery.paddingOf(context).top;
    final toolbarTop = top == 0 ? _phoneToolbarTop : top + 14;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      key: const ValueKey('shell-stack'),
      children: [
        Positioned.fill(
          child: _content(
            EdgeInsets.only(
              top: toolbarTop + _phoneButton - top,
              bottom: _tabBottom + GlassTabBar.height + _side,
            ),
          ),
        ),
        Positioned.fill(
          child: GlassScope(
            key: const ValueKey('shell-compact'),
            kind: GlassLayerKind.chrome,
            child: Stack(
              children: [
                Positioned(
                  top: toolbarTop,
                  left: _side,
                  right: _side,
                  child: ShellToolbar(
                    actions: actions,
                    buttonSize: _phoneButton,
                  ),
                ),
                Positioned(
                  bottom: _tabBottom + bottom,
                  left: _side,
                  right: _side,
                  child: GlassTabBar(
                    destinations: shellDestinations,
                    selectedIndex: widget.navigationShell.currentIndex,
                    onSelected: _goBranch,
                    onSearch: widget.onSearch,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktop(
    BuildContext context,
    List<ShellAction> actions, {
    required bool rail,
  }) {
    final sideWidth = (rail ? GlassSidebar.railWidth : GlassSidebar.width) + 16;
    const toolbarHeight = 14.0 + 44;
    final pad = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final startPad = rtl ? pad.right : pad.left;
    final endPad = rtl ? pad.left : pad.right;
    return Stack(
      key: const ValueKey('shell-stack'),
      children: [
        PositionedDirectional(
          start: sideWidth + startPad,
          end: 0,
          top: 0,
          bottom: 0,
          child: _content(
            const EdgeInsets.only(top: toolbarHeight),
            removeStart: true,
          ),
        ),
        Positioned.fill(
          child: GlassScope(
            key: ValueKey(rail ? 'shell-medium' : 'shell-expanded'),
            kind: GlassLayerKind.chrome,
            child: Stack(
              children: [
                PositionedDirectional(
                  start: 8 + startPad,
                  top: 8 + pad.top,
                  bottom: 8 + pad.bottom,
                  child: GlassSidebar(
                    groups: sidebarGroups(),
                    selectedLocation: widget.location,
                    rail: rail,
                    onSelected: _goItem,
                    onSettings: widget.onSettings,
                  ),
                ),
                PositionedDirectional(
                  start: sideWidth + 16 + startPad,
                  end: 20 + endPad,
                  top: 14 + pad.top,
                  child: ShellToolbar(actions: actions, buttonSize: 44),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
