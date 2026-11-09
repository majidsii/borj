import 'dart:async';

import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/application/today_completion.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as timezone;

/// Emits `clock.nowUtc()` immediately, then at every UTC minute boundary.
final minuteTickProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(appClockProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  void scheduleNext() {
    final now = clock.nowUtc().toUtc();
    final next = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    timer = Timer(next.difference(now), () {
      controller.add(clock.nowUtc());
      scheduleNext();
    });
  }

  controller.add(clock.nowUtc());
  scheduleNext();
  ref.onDispose(() {
    timer?.cancel();
    unawaited(controller.close());
  });
  return controller.stream;
});

/// The latest tick as a naive wall-clock value in the task calendar zone.
final todayNowProvider = Provider<AsyncValue<DateTime>>((ref) {
  final tick = ref.watch(minuteTickProvider);
  final zone = ref.watch(taskCalendarTimeZoneProvider);
  if (tick.hasError) {
    return AsyncValue.error(tick.error!, tick.stackTrace ?? StackTrace.current);
  }
  if (zone.hasError) {
    return AsyncValue.error(zone.error!, zone.stackTrace ?? StackTrace.current);
  }
  if (!tick.hasValue || !zone.hasValue) return const AsyncValue.loading();
  final timezone.Location location;
  try {
    location = timezone.getLocation(zone.requireValue);
  } on timezone.LocationNotFoundException catch (error, stack) {
    return AsyncValue.error(error, stack);
  }
  final local = timezone.TZDateTime.from(tick.requireValue.toUtc(), location);
  return AsyncValue.data(
    DateTime(local.year, local.month, local.day, local.hour, local.minute),
  );
});

final todayAgendaBuilderProvider = Provider<TodayAgendaBuilder>(
  (ref) => const TodayAgendaBuilder(),
);

final todayAgendaProvider = Provider<AsyncValue<TodayAgenda>>((ref) {
  final day = ref.watch(
    todayNowProvider.select(
      (v) => v.whenData((t) => DateTime(t.year, t.month, t.day)),
    ),
  );
  final tasks = ref.watch(taskItemsProvider);
  final rules = ref.watch(taskRecurrenceRulesProvider);
  final exceptions = ref.watch(taskRecurrenceExceptionsProvider);
  final completions = ref.watch(taskOccurrenceCompletionsProvider);
  final zone = ref.watch(taskCalendarTimeZoneProvider);
  final inputs = <AsyncValue<Object?>>[
    day,
    tasks,
    rules,
    exceptions,
    completions,
    zone,
  ];
  for (final v in inputs) {
    if (v.hasError) {
      return AsyncValue.error(v.error!, v.stackTrace ?? StackTrace.current);
    }
    if (!v.hasValue) return const AsyncValue.loading();
  }
  // The tick only decides the day here; it is read, not watched.
  final tickUtc = ref.read(minuteTickProvider).requireValue;
  try {
    return AsyncValue.data(
      ref
          .watch(todayAgendaBuilderProvider)
          .build(
            tasks: tasks.requireValue,
            rules: rules.requireValue,
            exceptions: exceptions.requireValue,
            completions: completions.requireValue,
            nowUtc: tickUtc,
            timeZoneId: zone.requireValue,
          ),
    );
  } on timezone.LocationNotFoundException catch (error, stack) {
    return AsyncValue.error(error, stack);
  }
});

@immutable
final class TodayInstallment {
  const TodayInstallment({
    required this.planId,
    required this.title,
    required this.nextNumber,
    required this.count,
    required this.amount,
  });

  final String planId;
  final String title;
  final int nextNumber;
  final int count;
  final Money amount;

  /// Paid fraction, 0..1.
  double get progress => count == 0 ? 0 : (nextNumber - 1) / count;
}

final todayInstallmentProvider = Provider<AsyncValue<TodayInstallment?>>((ref) {
  return ref.watch(installmentPlansProvider).whenData((plans) {
    final active =
        [
          for (final p in plans)
            if (p.remainingCount > 0) p,
        ]..sort((a, b) {
          final byCreated = a.createdAtUtc.compareTo(b.createdAtUtc);
          return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
        });
    if (active.isEmpty) return null;
    final p = active.first;
    return TodayInstallment(
      planId: p.id,
      title: p.title,
      nextNumber: p.paidCount + 1,
      count: p.installmentCount,
      amount: p.perInstallment,
    );
  });
});

final todayIsNewUserProvider = Provider<AsyncValue<bool>>((ref) {
  final values = <AsyncValue<List<Object?>>>[
    ref.watch(taskItemsProvider),
    ref.watch(financeTransactionsProvider),
    ref.watch(debtsProvider),
    ref.watch(installmentPlansProvider),
  ];
  for (final v in values) {
    if (v.hasError) {
      return AsyncValue.error(v.error!, v.stackTrace ?? StackTrace.current);
    }
    if (!v.hasValue) return const AsyncValue.loading();
  }
  return AsyncValue.data(values.every((v) => v.requireValue.isEmpty));
});

final todayCompletionProvider = Provider<TodayCompletion>(
  (ref) => TodayCompletion(
    repository: ref.watch(taskRepositoryProvider),
    recurrence: ref.watch(taskRecurrenceServiceProvider),
    clock: ref.watch(appClockProvider),
  ),
);
