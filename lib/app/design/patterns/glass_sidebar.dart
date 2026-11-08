import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The desktop sidebar of the `MacToday` board (glass panel on the right in
/// RTL, flat `GlassInner` on the selected row) or, with [rail], the medium
/// window's 72 pt icon rail. Build it inside the shell's chrome `GlassScope`.
/// Selection jumps (macOS convention).
class GlassSidebar extends StatelessWidget {
  const GlassSidebar({
    required this.groups,
    required this.selectedLocation,
    required this.onSelected,
    required this.onSettings,
    this.rail = false,
    this.statusLine,
    super.key,
  });

  final List<SidebarGroup> groups;
  final String selectedLocation;
  final ValueChanged<SidebarItem> onSelected;
  final VoidCallback onSettings;
  final bool rail;
  final String? statusLine;

  static const double width = 236;
  static const double railWidth = 72;

  SidebarItem? _selected() {
    final items = [for (final g in groups) ...g.items];
    for (final i in items) {
      if (i.location == selectedLocation) return i;
    }
    final path = Uri.parse(selectedLocation).path;
    SidebarItem? best;
    for (final i in items) {
      final p = Uri.parse(i.location);
      if (p.hasQuery) continue;
      final matches = p.path == '/'
          ? path == '/'
          : path == p.path || path.startsWith('${p.path}/');
      if (matches &&
          (best == null ||
              p.path.length > Uri.parse(best.location).path.length)) {
        best = i;
      }
    }
    if (best != null) return best;
    // No row matches: fall back to the first row of the location's section.
    final section = sectionOfPath(path);
    for (final i in items) {
      if (i.section == section) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected();
    final rows = <Widget>[];
    for (final g in groups) {
      if (!rail) {
        rows.add(
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 4),
            child: AppText(
              g.label,
              role: AppTextRole.caption,
              tone: AppTextTone.secondary,
              weight: FontWeight.w700,
            ),
          ),
        );
      } else if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: AppSpacing.s12));
      }
      for (final item in g.items) {
        rows.add(
          _Row(
            key: ValueKey('sidebar-item-${item.location}'),
            label: item.label,
            icon: item.icon,
            selected: identical(item, selected),
            rail: rail,
            onTap: () => onSelected(item),
          ),
        );
        rows.add(const SizedBox(height: 2));
      }
    }
    return AppGlass(
      key: const ValueKey('sidebar'),
      role: GlassRole.chrome,
      shape: const AppleGlassShape.rounded(20),
      child: SizedBox(
        width: rail ? railWidth : width,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...rows,
              const Spacer(),
              _Row(
                key: const ValueKey('sidebar-settings'),
                label: 'تنظیمات',
                icon: Icons.settings_outlined,
                selected: Uri.parse(selectedLocation).path == '/settings',
                rail: rail,
                onTap: onSettings,
              ),
              if (!rail && statusLine != null)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 18, 10, 2),
                  child: AppText(
                    statusLine!,
                    role: AppTextRole.caption,
                    tone: AppTextTone.secondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.icon,
    required this.selected,
    required this.rail,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool rail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: rail ? 44 : 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: rail
            ? Center(child: AppIcon(icon, size: 20))
            : Row(
                children: [
                  AppIcon(icon, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppText(
                      label,
                      role: AppTextRole.subheadline,
                      weight: FontWeight.w700,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
    final row = Pressable(
      onPressed: onTap,
      semanticLabel: label,
      selected: selected,
      hoverRadius: BorderRadius.circular(12),
      child: selected
          ? GlassInner(shape: const AppleGlassShape.rounded(12), child: content)
          : content,
    );
    return rail
        ? Tooltip(message: label, excludeFromSemantics: true, child: row)
        : row;
  }
}
