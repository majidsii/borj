import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';

/// Pumps the real [BorjApp] over an in-memory database, with no v1 data and
/// no file IO for preferences (the appearance store defaults to in-memory).
/// [seed] runs after the container exists and before the first frame.
/// Tears everything down after the test.
Future<ProviderContainer> pumpBorjTestApp(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  Widget Function(Widget app)? wrap,
  Stream<DateTime>? minuteTicks,
  Future<void> Function(ProviderContainer container)? seed,
}) async {
  final database = openTestDatabase();
  final container = ProviderContainer(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      legacyV1SourceLocatorProvider.overrideWithValue(
        const LegacyV1SourceLocator(
          operatingSystem: 'android',
          environment: <String, String>{},
        ),
      ),
      // No live timers in widget tests: one tick of the container clock,
      // unless the test drives its own ticks.
      minuteTickProvider.overrideWith(
        (ref) =>
            minuteTicks ?? Stream.value(ref.read(appClockProvider).nowUtc()),
      ),
      ...overrides,
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await database.close();
  });
  if (seed != null) await seed(container);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: wrap == null ? const BorjApp() : wrap(const BorjApp()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Sizes the test window to [size] logical px (device pixel ratio 1).
void useWindowSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Settles frames for pages that run an endless animation (the aurora of
/// Settings and the glass review), where `pumpAndSettle` would time out.
Future<void> pumpPage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
