import 'package:flutter/material.dart';

/// Sections whose feature does not exist yet stay hidden until it ships
/// (decision 2026-11-08-shell-settings-entry-and-unbuilt-sections).
abstract final class ShellFeatures {
  static const bool habits = false;
  static const bool goals = false;
  static const bool budgets = false;
}

/// The shell's branches, in tab order. The branch index is [index].
enum ShellSection { today, tasks, finance }

final class ShellDestination {
  const ShellDestination({
    required this.section,
    required this.label,
    required this.icon,
    required this.location,
  });

  final ShellSection section;
  final String label;
  final IconData icon;
  final String location;
}

const List<ShellDestination> shellDestinations = <ShellDestination>[
  ShellDestination(
    section: ShellSection.today,
    label: 'امروز',
    icon: Icons.wb_sunny_outlined,
    location: '/',
  ),
  ShellDestination(
    section: ShellSection.tasks,
    label: 'کارها',
    icon: Icons.check_circle_outline,
    location: '/tasks',
  ),
  ShellDestination(
    section: ShellSection.finance,
    label: 'مالی',
    icon: Icons.account_balance_wallet_outlined,
    location: '/finance',
  ),
];

String sectionLocation(ShellSection section) =>
    shellDestinations[section.index].location;

final class SidebarItem {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.location,
    required this.section,
  });

  final String label;
  final IconData icon;
  final String location;
  final ShellSection section;
}

final class SidebarGroup {
  const SidebarGroup({required this.label, required this.items});

  final String label;
  final List<SidebarItem> items;
}

/// The sidebar of the `MacToday` board, without the hidden features. A group
/// whose items are all hidden is dropped (its header too).
List<SidebarGroup> sidebarGroups() {
  final groups = <SidebarGroup>[
    const SidebarGroup(
      label: 'برنامه',
      items: <SidebarItem>[
        SidebarItem(
          label: 'امروز',
          icon: Icons.wb_sunny_outlined,
          location: '/',
          section: ShellSection.today,
        ),
        SidebarItem(
          label: 'همهٔ کارها',
          icon: Icons.check_circle_outline,
          location: '/tasks',
          section: ShellSection.tasks,
        ),
        SidebarItem(
          label: 'تقویم',
          icon: Icons.calendar_month_outlined,
          location: '/tasks?view=calendar',
          section: ShellSection.tasks,
        ),
      ],
    ),
    SidebarGroup(
      label: 'پول',
      items: <SidebarItem>[
        const SidebarItem(
          label: 'تراکنش‌ها',
          icon: Icons.receipt_long_outlined,
          location: '/finance/transactions',
          section: ShellSection.finance,
        ),
        if (ShellFeatures.budgets)
          const SidebarItem(
            label: 'بودجه',
            icon: Icons.pie_chart_outline,
            location: '/finance/budgets',
            section: ShellSection.finance,
          ),
        const SidebarItem(
          label: 'قسط و بدهی',
          icon: Icons.handshake_outlined,
          location: '/finance/debts',
          section: ShellSection.finance,
        ),
      ],
    ),
    const SidebarGroup(
      label: 'زندگی',
      items: <SidebarItem>[
        // عادت‌ها and هدف‌ها return here when ShellFeatures.habits / goals
        // turn on (with their own ShellSection and branch).
      ],
    ),
  ];
  return [
    for (final g in groups)
      if (g.items.isNotEmpty) g,
  ];
}
