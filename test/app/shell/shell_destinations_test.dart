import 'package:borj/app/shell/shell_destinations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('three visible tabs in board order', () {
    expect(shellDestinations.map((d) => d.label), ['امروز', 'کارها', 'مالی']);
    expect(shellDestinations.map((d) => d.section), ShellSection.values);
    expect(shellDestinations.map((d) => d.location), [
      '/',
      '/tasks',
      '/finance',
    ]);
  });

  test('sidebar shows برنامه and پول; زندگی and بودجه stay hidden', () {
    final groups = sidebarGroups();
    expect(groups.map((g) => g.label), ['برنامه', 'پول']);
    expect(groups[0].items.map((i) => i.label), [
      'امروز',
      'همهٔ کارها',
      'تقویم',
    ]);
    expect(groups[1].items.map((i) => i.label), ['تراکنش‌ها', 'قسط و بدهی']);
    expect(groups.expand((g) => g.items).map((i) => i.location), [
      '/',
      '/tasks',
      '/tasks?view=calendar',
      '/finance/transactions',
      '/finance/debts',
    ]);
  });

  test('hidden features are off until they ship', () {
    expect(ShellFeatures.habits, isFalse);
    expect(ShellFeatures.goals, isFalse);
    expect(ShellFeatures.budgets, isFalse);
  });

  test('sectionLocation', () {
    expect(sectionLocation(ShellSection.today), '/');
    expect(sectionLocation(ShellSection.tasks), '/tasks');
    expect(sectionLocation(ShellSection.finance), '/finance');
  });
}
