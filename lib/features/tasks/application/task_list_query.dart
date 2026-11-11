import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:timezone/timezone.dart' as timezone;

enum TaskSmartFilter { today, timed, overdue, all }

enum TaskSort { time, priority, newest, alphabetical }

enum TaskSectionKind {
  overdue('عقب‌افتاده'),
  today('امروز'),
  upcoming('آینده'),
  untimed('بی‌زمان'),
  done('انجام‌شده');

  const TaskSectionKind(this.title);

  final String title;
}

final class TaskListEntry {
  const TaskListEntry({required this.task, required this.localInstant});

  final TaskItem task;

  /// Wall clock of `dueAtUtc ?? startAtUtc` in the task calendar zone, held in
  /// a `DateTime.utc` used only as a zone-free carrier; null when the task has neither.
  final DateTime? localInstant;
}

final class TaskSection {
  const TaskSection({required this.kind, required this.entries});

  final TaskSectionKind kind;
  final List<TaskListEntry> entries;
}

final class TaskSmartCounts {
  const TaskSmartCounts({
    required this.today,
    required this.timed,
    required this.overdue,
    required this.all,
  });

  final int today;
  final int timed;
  final int overdue;

  /// Active tasks (planned + in progress).
  final int all;
}

/// [counts], [activeCount] and [doneCount] describe every task passed in; they
/// ignore the filter and the search query. [doneCount] counts completed and
/// canceled tasks.
final class TaskListView {
  const TaskListView({
    required this.sections,
    required this.counts,
    required this.activeCount,
    required this.doneCount,
  });

  final List<TaskSection> sections;
  final TaskSmartCounts counts;
  final int activeCount;
  final int doneCount;
}

String normalizeTaskSearch(String s) {
  return s
      .trim()
      .toLowerCase()
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll('\u200C', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const _persianAlphabet = 'ابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی';
const _persianBase = {
  'أ': 'ا',
  'إ': 'ا',
  'آ': 'ا',
  'ء': 'ا',
  'ؤ': 'و',
  'ئ': 'ی',
  'ة': 'ه',
  'ي': 'ی',
  'ى': 'ی',
  'ك': 'ک',
};

List<int> _persianKeys(String s) {
  final keys = <int>[];
  for (final rune in s.toLowerCase().runes) {
    if (rune == 0x200C ||
        rune == 0x20 ||
        rune == 0x640 ||
        rune == 0x670 ||
        (rune >= 0x64B && rune <= 0x65F)) {
      continue;
    }
    final ch = String.fromCharCode(rune);
    final index = _persianAlphabet.indexOf(_persianBase[ch] ?? ch);
    keys.add(index >= 0 ? index : 1000 + rune);
  }
  return keys;
}

/// Compares in Persian alphabet order, letter by letter. Hamza forms fold to
/// their base letter; other characters sort after Persian letters by code
/// point; spaces and ZWNJ are ignored.
int comparePersian(String a, String b) {
  final x = _persianKeys(a);
  final y = _persianKeys(b);
  final n = x.length < y.length ? x.length : y.length;
  for (var i = 0; i < n; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return x.length.compareTo(y.length);
}

bool taskMatches(TaskItem t, String query) {
  final q = normalizeTaskSearch(query);
  if (q.isEmpty) return true;
  return normalizeTaskSearch(t.title).contains(q) ||
      normalizeTaskSearch(t.description ?? '').contains(q);
}

/// Builds the task list. Every "today" is the task calendar zone's day, so the
/// device zone never matters. A recurring task appears once, by its own
/// start/due.
TaskListView buildTaskListView({
  required List<TaskItem> tasks,
  required DateTime nowUtc,
  required String timeZoneId,
  TaskSmartFilter filter = TaskSmartFilter.all,
  TaskSort sort = TaskSort.time,
  String query = '',
}) {
  final location = timezone.getLocation(timeZoneId);
  final zonedNow = timezone.TZDateTime.from(nowUtc.toUtc(), location);
  final today = DateTime.utc(zonedNow.year, zonedNow.month, zonedNow.day);
  final tomorrow = DateTime.utc(
    zonedNow.year,
    zonedNow.month,
    zonedNow.day + 1,
  );

  TaskListEntry entryOf(TaskItem t) {
    final at = t.dueAtUtc ?? t.startAtUtc;
    if (at == null) return TaskListEntry(task: t, localInstant: null);
    final l = timezone.TZDateTime.from(at, location);
    return TaskListEntry(
      task: t,
      localInstant: DateTime.utc(l.year, l.month, l.day, l.hour, l.minute),
    );
  }

  TaskSectionKind kindOf(TaskListEntry e) {
    switch (e.task.status) {
      case TaskStatus.completed:
      case TaskStatus.canceled:
        return TaskSectionKind.done;
      case TaskStatus.planned:
      case TaskStatus.inProgress:
        final at = e.localInstant;
        if (at == null) return TaskSectionKind.untimed;
        if (at.isBefore(today)) return TaskSectionKind.overdue;
        if (at.isBefore(tomorrow)) return TaskSectionKind.today;
        return TaskSectionKind.upcoming;
    }
  }

  final all = [for (final t in tasks) entryOf(t)];
  final byKind = {for (final k in TaskSectionKind.values) k: <TaskListEntry>[]};
  for (final e in all) {
    byKind[kindOf(e)]!.add(e);
  }

  final todayCount = byKind[TaskSectionKind.today]!.length;
  final overdueCount = byKind[TaskSectionKind.overdue]!.length;
  final upcomingCount = byKind[TaskSectionKind.upcoming]!.length;
  final untimedCount = byKind[TaskSectionKind.untimed]!.length;
  final counts = TaskSmartCounts(
    today: todayCount,
    timed: overdueCount + todayCount + upcomingCount,
    overdue: overdueCount,
    all: overdueCount + todayCount + upcomingCount + untimedCount,
  );

  final visible = switch (filter) {
    TaskSmartFilter.all => TaskSectionKind.values,
    TaskSmartFilter.today => const [TaskSectionKind.today],
    TaskSmartFilter.overdue => const [TaskSectionKind.overdue],
    TaskSmartFilter.timed => const [
      TaskSectionKind.overdue,
      TaskSectionKind.today,
      TaskSectionKind.upcoming,
    ],
  };

  final comparator = _comparator(sort);
  final sections = <TaskSection>[];
  for (final kind in visible) {
    final entries = [
      for (final e in byKind[kind]!)
        if (taskMatches(e.task, query)) e,
    ];
    if (entries.isEmpty) continue;
    if (kind == TaskSectionKind.done) {
      entries.sort((a, b) {
        final aCanceled = a.task.status == TaskStatus.canceled;
        final bCanceled = b.task.status == TaskStatus.canceled;
        if (aCanceled != bCanceled) return aCanceled ? 1 : -1;
        return comparator(a, b);
      });
    } else {
      entries.sort(comparator);
    }
    sections.add(TaskSection(kind: kind, entries: entries));
  }

  return TaskListView(
    sections: sections,
    counts: counts,
    activeCount: counts.all,
    doneCount: byKind[TaskSectionKind.done]!.length,
  );
}

int Function(TaskListEntry, TaskListEntry) _comparator(TaskSort sort) {
  int byTime(TaskListEntry a, TaskListEntry b) {
    final x = a.localInstant;
    final y = b.localInstant;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }

  int byPriority(TaskListEntry a, TaskListEntry b) =>
      b.task.priority.compareTo(a.task.priority);

  int byNumber(TaskListEntry a, TaskListEntry b) =>
      a.task.displayNumber.compareTo(b.task.displayNumber);

  int chain(
    List<int Function(TaskListEntry, TaskListEntry)> steps,
    TaskListEntry a,
    TaskListEntry b,
  ) {
    for (final step in steps) {
      final r = step(a, b);
      if (r != 0) return r;
    }
    return byNumber(a, b);
  }

  switch (sort) {
    case TaskSort.time:
      return (a, b) => chain([byTime, byPriority], a, b);
    case TaskSort.priority:
      return (a, b) => chain([byPriority, byTime], a, b);
    case TaskSort.newest:
      return (a, b) => chain(
        [(a, b) => b.task.createdAtUtc.compareTo(a.task.createdAtUtc)],
        a,
        b,
      );
    case TaskSort.alphabetical:
      return (a, b) =>
          chain([(a, b) => comparePersian(a.task.title, b.task.title)], a, b);
  }
}
