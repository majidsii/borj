import 'dart:io';
import 'dart:typed_data';

import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/legacy_import/application/legacy_file_picker.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:dashboard_shakhsi/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

final class _FakePicker implements LegacyFilePicker {
  _FakePicker(this.bytes);

  final Uint8List? bytes;

  @override
  Future<Uint8List?> pickJsonBytes() async => bytes;
}

void main() {
  late Uint8List fixtureBytes;

  setUpAll(() async {
    fixtureBytes = await File(
      'test/fixtures/legacy_v1/data_v1_2_desktop.json',
    ).readAsBytes();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<AppDatabase> pumpSettings(
    WidgetTester tester, {
    required LegacyFilePicker picker,
  }) async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 11, 4, 10);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          appClockProvider.overrideWithValue(
            FixedAppClock(utcValue: now, localValue: now),
          ),
          legacyFilePickerProvider.overrideWithValue(picker),
          legacyV1SourceLocatorProvider.overrideWithValue(
            const LegacyV1SourceLocator(
              operatingSystem: 'android',
              environment: <String, String>{},
            ),
          ),
        ],
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SettingsScreen(onBack: () {}),
          ),
        ),
      ),
    );
    await settle(tester);
    return database;
  }

  testWidgets('pick, preview, confirm and report import the file', (
    tester,
  ) async {
    final database = await pumpSettings(
      tester,
      picker: _FakePicker(fixtureBytes),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-import-pick-file')),
    );
    await settle(tester);

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey<String>('legacy-count-task')))
          .data,
      '۴',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-import-confirm')),
    );
    await settle(tester);

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('legacy-report-count-task')),
          )
          .data,
      '۴',
    );
    final tasks = await database.select(database.taskRows).get();
    expect(tasks, hasLength(4));

    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-close')));
    await settle(tester);
  });

  testWidgets('cancelling the preview writes nothing', (tester) async {
    final database = await pumpSettings(
      tester,
      picker: _FakePicker(fixtureBytes),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-import-pick-file')),
    );
    await settle(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-import-cancel')),
    );
    await settle(tester);

    expect(await database.select(database.taskRows).get(), isEmpty);
    expect(await database.select(database.legacyImportRows).get(), isEmpty);
  });

  testWidgets('an unreadable file shows a message and writes nothing', (
    tester,
  ) async {
    final database = await pumpSettings(
      tester,
      picker: _FakePicker(Uint8List.fromList(<int>[0x7b, 0x22])),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-import-pick-file')),
    );
    await settle(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(await database.select(database.taskRows).get(), isEmpty);
  });

  testWidgets('a cancelled picker does nothing', (tester) async {
    final database = await pumpSettings(tester, picker: _FakePicker(null));

    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-import-pick-file')),
    );
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(await database.select(database.taskRows).get(), isEmpty);
  });
}
