import 'package:borj/app/design/design.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:borj/features/today/presentation/installment_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_fade_expectations.dart';
import '../../support/glass_test_app.dart';

final _plan = TodayInstallment(
  planId: 'p',
  title: 'قسط وام مسکن',
  nextNumber: 25,
  count: 60,
  amount: Money(minorUnits: 4200000, currencyCode: 'IRT', scale: 0),
);

Widget _card({
  TodayCardSize size = TodayCardSize.wide,
  VoidCallback? onOpen,
  Brightness b = Brightness.light,
  double s = 1.0,
}) => glassTestApp(
  brightness: b,
  textScale: s,
  SizedBox(
    width: size == TodayCardSize.small ? 173 : 358,
    height: todayCardHeight(size),
    child: InstallmentCard(
      installment: _plan,
      size: size,
      onOpen: onOpen ?? () {},
    ),
  ),
);

void main() {
  for (final v in glassTestVariants) {
    for (final size in [TodayCardSize.small, TodayCardSize.wide]) {
      testWidgets('renders $size (${v.name})', (tester) async {
        await tester.pumpWidget(
          _card(size: size, b: v.brightness, s: v.textScale),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('wide: title, «قسط ۲۵ از ۶۰», amount, track at 24/60', (
    tester,
  ) async {
    await tester.pumpWidget(_card());
    expect(find.text('قسط وام مسکن'), findsOneWidget);
    expect(find.text('قسط ۲۵ از ۶۰'), findsOneWidget);
    expect(find.text('۴٬۲۰۰٬۰۰۰'), findsOneWidget);
    expect(
      tester.widget<ProgressTrack>(find.byType(ProgressTrack)).value,
      closeTo(24 / 60, 1e-9),
    );
  });

  testWidgets('the card announces title, progress and amount once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_card());
    expect(
      find.bySemanticsLabel('قسط وام مسکن، قسط ۲۵ از ۶۰، ۴٬۲۰۰٬۰۰۰'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('small: no track', (tester) async {
    await tester.pumpWidget(_card(size: TodayCardSize.small));
    expect(find.byType(ProgressTrack), findsNothing);
  });

  testWidgets('tap opens; no fade above the card glass', (tester) async {
    var opened = false;
    await tester.pumpWidget(_card(onOpen: () => opened = true));
    await tester.tap(find.text('قسط وام مسکن'));
    expect(opened, isTrue);
    expect(bareFadesAboveGlass(tester, find.byType(InstallmentCard)), isEmpty);
  });

  testWidgets('the Pressable is inside the glass, never around it', (
    tester,
  ) async {
    await tester.pumpWidget(_card());
    expect(
      find.descendant(
        of: find.byType(AppGlass),
        matching: find.byType(Pressable),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byType(AppGlass),
        matching: find.byType(Pressable),
      ),
      findsNothing,
    );
  });
}
