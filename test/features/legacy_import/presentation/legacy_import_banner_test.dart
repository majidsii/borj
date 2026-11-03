import 'dart:io';

import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_banner.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rdf-banner-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<ProviderContainer> pumpBanner(
    WidgetTester tester, {
    required bool fileExists,
    bool alreadyImported = false,
  }) async {
    if (fileExists) {
      final file = File('${directory.path}/dashboard-shakhsi/data.json');
      await tester.runAsync(() async {
        await file.create(recursive: true);
        await file.writeAsString('{}');
      });
    }
    final database = openTestDatabase();
    addTearDown(database.close);
    if (alreadyImported) {
      await database
          .into(database.legacyImportRows)
          .insert(
            LegacyImportRowsCompanion.insert(
              sourceKind: LegacySourceKind.dataJson.storageValue,
              entityType: 'task',
              v1Id: 'seen',
              v2Id: 'v2-seen',
              importedAtUtc: DateTime.utc(2026, 11, 4),
              sourceSha256: 'hash',
            ),
          );
    }

    final container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        legacyV1SourceLocatorProvider.overrideWithValue(
          LegacyV1SourceLocator(
            operatingSystem: 'linux',
            environment: <String, String>{'XDG_DATA_HOME': directory.path},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Real file IO must complete outside the fake-async zone.
    await tester.runAsync(
      () => container.read(legacyBannerFileProvider.future),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: LegacyImportBanner()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    return container;
  }

  testWidgets('shows when a v1 file exists and nothing was imported', (
    tester,
  ) async {
    await pumpBanner(tester, fileExists: true);

    expect(
      find.byKey(const ValueKey<String>('legacy-banner-import')),
      findsOneWidget,
    );
  });

  testWidgets('hidden when no v1 file is found', (tester) async {
    await pumpBanner(tester, fileExists: false);

    expect(
      find.byKey(const ValueKey<String>('legacy-banner-import')),
      findsNothing,
    );
  });

  testWidgets('hidden once something was imported', (tester) async {
    await pumpBanner(tester, fileExists: true, alreadyImported: true);

    expect(
      find.byKey(const ValueKey<String>('legacy-banner-import')),
      findsNothing,
    );
  });

  testWidgets('later hides it for the session', (tester) async {
    final container = await pumpBanner(tester, fileExists: true);

    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-banner-dismiss')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(container.read(legacyBannerDismissedProvider), isTrue);
    expect(
      find.byKey(const ValueKey<String>('legacy-banner-import')),
      findsNothing,
    );
  });
}
