import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/presentation/today_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_layer_count.dart';
import '../../support/borj_test_app.dart';
import '../../support/glass_fade_expectations.dart';

final _nowUtc = DateTime.utc(2026, 11, 4, 11);
final _t0 = DateTime.utc(2026, 11, 1);

Future<void> _seed(ProviderContainer c) async {
  await c
      .read(taskRepositoryProvider)
      .create(
        TaskItem(
          id: 'a',
          displayNumber: 1,
          title: 'ورزش عصر',
          priority: 0,
          status: TaskStatus.planned,
          positionInStatus: 0,
          dueAtUtc: DateTime.utc(2026, 11, 4, 11, 30),
          createdAtUtc: _t0,
          updatedAtUtc: _t0,
        ),
      );
  await c
      .read(financeRepositoryProvider)
      .addInstallmentPlan(
        InstallmentPlan(
          id: 'p',
          title: 'قسط وام',
          perInstallment: Money(
            minorUnits: 4200000,
            currencyCode: 'IRT',
            scale: 0,
          ),
          installmentCount: 12,
          paidCount: 3,
          createdAtUtc: _t0,
          updatedAtUtc: _t0,
        ),
      );
}

void main() {
  setUp(TodayEntrance.reset);

  for (final (name, size) in const [
    ('compact', Size(390, 844)),
    ('expanded', Size(1440, 900)),
  ]) {
    testWidgets('$name: idle is exactly 2', (tester) async {
      useWindowSize(tester, size);
      await pumpBorjTestApp(
        tester,
        overrides: [
          appClockProvider.overrideWithValue(
            FixedAppClock(utcValue: _nowUtc, localValue: _nowUtc),
          ),
        ],
        seed: _seed,
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(countCompositedBackdrops(tester), 2);
      }
    });

    testWidgets('$name: cold-start entrance stays at 2, no bare fades', (
      tester,
    ) async {
      useWindowSize(tester, size);
      final ticks = StreamController<DateTime>();
      addTearDown(ticks.close);
      await pumpBorjTestApp(
        tester,
        overrides: [
          appClockProvider.overrideWithValue(
            FixedAppClock(utcValue: _nowUtc, localValue: _nowUtc),
          ),
        ],
        minuteTicks: ticks.stream,
        seed: _seed,
      );
      ticks.add(_nowUtc);
      final grid = find.byKey(const ValueKey('today-grid'));
      for (var i = 0; i < 5 && grid.evaluate().isEmpty; i++) {
        await tester.pump();
      }
      expect(grid, findsOneWidget);
      var worst = countCompositedBackdrops(tester);
      var sawFractional = false;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final n = countCompositedBackdrops(tester);
        if (n > worst) worst = n;
        sawFractional |= tester
            .widgetList<GlassVisibility>(
              find.descendant(of: grid, matching: find.byType(GlassVisibility)),
            )
            .any((g) => g.value > 0 && g.value < 1);
        expect(
          bareFadesAboveGlass(tester, find.byKey(const ValueKey('today-page'))),
          isEmpty,
        );
      }
      expect(sawFractional, isTrue, reason: 'an entrance ran while sampling');
      expect(worst, 2);
    });
  }
}
