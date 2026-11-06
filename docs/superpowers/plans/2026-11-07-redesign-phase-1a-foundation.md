# Redesign Phase 1, Part A: Foundation and Glass Budget Probe. Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lay the redesign's foundation: persisted appearance preferences, the `AppTheme` tokens, motion tokens with a reduced-motion scope, the content-glass roles with grouped scopes and a degrade path. Then measure whether content glass fits the capture and raster budget before any primitive or screen is built on it.

**Architecture:** Preferences live in a small JSON file beside `borj.sqlite`. They are loaded before `runApp`, so the first frame already has the stored theme. `AppTheme` is a `ThemeExtension` attached next to the legacy `OriginalPalette`. Screens migrate in later phases, so nothing legacy is removed here. New glass goes through `AppGlass`, `GlassScope` and `GlassBackdropGroup` in `apple_liquid_glass.dart`, the only `lib/` file besides `app_bootstrap.dart` that may import `liquid_glass_renderer`. The legacy `AppleLiquidGlass` and its 8 call sites stay as they are. A probe scene built only from the new glass API is checked for backdrop captures in ordinary `flutter test`, and for raster time on the Linux device.

**Tech Stack:** Flutter 3.47.5, Riverpod 2.6.1 (`Notifier`), `liquid_glass_renderer 1.0.0-dev.2`, `integration_test`.

**Specs:** `docs/superpowers/specs/2026-11-05-liquid-glass-redesign-design.md` (§3, §4, §7 phase 1, §8) and
`docs/superpowers/specs/2026-11-06-motion-and-today-customization-design.md` (§1, §2, §6, §7, §9).
**Part B** (primitives `AppText` … `RoundCheck`, `AnimatedNumber`, sheet/toast/row/check patterns, Settings → Appearance
UI, the review page with mockup comparison, and the Phase 1 checkpoint) is planned separately after Task 6 reports
the probe numbers, because a failed budget changes how primitives are built.

## Global Constraints

- Flutter 3.47.5: put `/home/shabin/develop/flutter-3.47.5/bin` first on `PATH`. Run `flutter pub get` once in a fresh worktree before any `dart format`.
- Only `lib/app/apple_visual/widgets/apple_liquid_glass.dart` and `lib/app/bootstrap/app_bootstrap.dart` may import `package:liquid_glass_renderer`. Tests may import it.
- Do not change `AppleLiquidGlass`, `AppleGlassRole` or their call sites, the `apple_visual/generated/*.g.dart` files, or `apple_source_motion.g.dart`.
- Do not remove `OriginalTheme`, `OriginalPalette`, `OriginalGlass` or `original_controls`. Screens migrate in phases 2–5.
- Colours come from the kit `docs/superpowers/references/2026-11-05-glass-mockups/source/kit2.css` (spec §1: the kit wins over spec §4). Light / dark:
  - background `#FFFFFF` / `#1B1C20`; window `#FFFFFF` / `#24262B`
  - text `#1B2236` / `#F4F6FC`; textSecondary `#38425E` / `#C5CCE0`; textSecondaryStrong `#2C3550` / `#E1E6F5`; textTertiary `#5A6482` / `#98A2C0`
  - link `#1F5FD0` / `#ACC9FF`; accent `#2F6FDB` / `#5B93F0`; teal `#0B857A` / `#3FD1C2`; success `#07665D` / `#66DBB0`
  - warn `#8F5400` / `#F2BE71`; danger `#B02440` / `#FFB3BE`; purple `#6B4BC0` / `#D1BFFF`; checkBorder `#6F7896` / `#AEB8D6`
  - the five dark semantic colours above are lightened from the kit (Decision 4); kit originals: link `#8DB5FF`, success `#4FD6A4`, warn `#F0B35A`, danger `#FF8A9B`, purple `#B79BFF`
  - hairline `rgba(27,34,54,.12)` / `rgba(255,255,255,.12)`; selection `rgba(47,111,219,.14)` / `rgba(255,255,255,.14)`
  - inner material: top `#FFFFFF` / `rgba(255,255,255,.26)`, bottom `rgba(236,242,255,.92)` / `rgba(255,255,255,.12)`, edge `rgba(50,72,140,.22)` / `rgba(0,0,0,.4)`, shadow `rgba(30,50,120,.26)` / `rgba(0,0,0,.45)`
  - glass text reference stops (`--g-bg-text`): light `rgba(255,255,255,.84)`, `rgba(242,246,255,.70)`, `rgba(228,236,254,.74)`; dark `rgba(120,124,150,.50)`, `rgba(86,89,110,.50)`, `rgba(66,68,86,.55)`
  - dark backdrop: vertical gradient `#232427` → `#18191C`, warm glow `rgba(255,170,95,.34)` at the top leading corner (phone) / `.30` (desk)
- Money colours: income text = `success` (as on the boards; light teal `#0B857A` would be 3.99:1 on glass), expense = `text`, over budget = `danger`.
- Motion values (spec table, not the Apple source values): press 120 ms and quick 200 ms with `Cubic(0.23, 1, 0.32, 1)`; standard spring response 0.40 / damping 1.0; snappy 0.28 / 1.0; soft 0.35 / 0.80; dataUpdate 350 ms; dataEnter 450 ms; exitFactor 0.7; stagger 0, 50, 95, 135, 170, 200, 225, 240 ms; reduced 200 ms `Curves.easeOut`. Never use ease-in curves.
- Spring construction: stiffness = (2π / response)², mass 1, `SpringDescription.withDampingRatio`.
- Capture budget per frame: ≤ 3 on phone, ≤ 4 on desktop. Raster p90 ≤ 8 ms on the Linux dev machine (profile build).
- Preferences defaults: mode خودکار (system), glass intensity 0.5, reduce motion off, reduce transparency off.
- Lints that bite: `require_trailing_commas`, `sort_constructors_first`, `directives_ordering`, `prefer_final_locals`, `unawaited_futures`, `avoid_print` (use `// ignore: avoid_print` only in integration probes), `avoid_dynamic_calls`.
- Stage explicit paths; never `git add -A`; do not push. Each commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Do not add new `tool/verify_*` scripts.
- Report every command you ran with its real result, and any test or analyzer failure verbatim.

## Decisions recorded by this plan

1. **Preferences store = JSON file, not Drift.** File `borj-preferences.json` in the same folder as `borj.sqlite`
   (`getApplicationDocumentsDirectory()`). Appearance is UI state, not user data, and a file keeps schema 10 free for
   Today layout, as the motion spec §9 assumes.
2. **New glass API beside the legacy one.** `AppGlass` (new roles) instead of extending `AppleGlassRole`, because the
   recipe resolver switches exhaustively over the source-backed roles. `CLAUDE.md` is updated in Task 4.
3. **Layer vs shape.** A `LiquidGlassLayer` carries one `LiquidGlassSettings` (frost, refraction). Shapes differ only
   by `LiquidGlassAppearance` (tint, visibility). So the layer kind sets the material, and the role picks the shape's appearance:

   - Layer kind `chrome`: material regular, `ios27Regular(brightness, tintAmount: intensity)`. Roles: `chrome`, `tinted`. Never fake.
   - Layer kind `content`: material regular, same settings. Roles: `panel`, `row`, `tinted`. Fake when reduce transparency is on.
   - Layer kind `sheet`: material sheet, `ios27Regular(brightness, tintAmount: min(1, intensity + 0.25))`. Roles: `sheet`, `tinted`. Never fake.
   - Layer kind `clear`: material clear, `ios27Clear(tintAmount: intensity)`. Role: `clear`. Never fake.

   Shape appearance: `tinted` = `LiquidGlassAppearance.ios27Regular(brightness, tint: accent at alpha 0.9)`; `clear` =
   `LiquidGlassAppearance.ios27Clear()`; every other role = `LiquidGlassAppearance.ios27Regular(brightness)`.
4. **Dark semantic text colours are lightened (owner, 2026-11-07: «پیشنهادتو برو»).** Spec §3.2 requires text on
   glass ≥ 4.5:1 in the worst case. Against the brightest kit glass stop the kit's dark link, success, warn, danger and
   purple measured 3.82, 4.30, 4.23, 3.51 and 3.43. Each is lightened in HSL (same hue and saturation) to the first
   value ≥ 4.6:1 with 8-bit alpha blending: link `#ACC9FF` 4.69, success `#66DBB0` 4.60, warn `#F2BE71` 4.62,
   danger `#FFB3BE` 4.65, purple `#D1BFFF` 4.71. Light mode is unchanged. Accent (2.58) is a fill, not text.
5. **Money colours follow the boards.** Income amounts on the boards use `var(--success)` (24 uses; `--teal` is used
   4 times, never for amounts), so `moneyIncome = success` matches the board and spec §1 (the board wins).

---

### Task 1: Appearance preferences, persisted and loaded before the first frame

**Files:**
- Create: `lib/features/settings/domain/appearance_preferences.dart`
- Create: `lib/features/settings/data/file_appearance_preferences_store.dart`
- Create: `lib/features/settings/data/in_memory_appearance_preferences_store.dart`
- Create: `lib/features/settings/application/appearance_preferences_controller.dart`
- Modify: `lib/app/bootstrap/app_bootstrap.dart` (load before `runApp`; `themeMode` from preferences; 300 ms theme cross-fade)
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart:95-99` (`_toggleTheme` writes the preference)
- Delete: `lib/app/theme/theme_mode_controller.dart`
- Test: `test/features/settings/appearance_preferences_test.dart`, `test/features/settings/file_appearance_preferences_store_test.dart`, `test/features/settings/appearance_preferences_controller_test.dart`, `test/app/bootstrap/borj_app_appearance_test.dart`

**Interfaces:**
- Produces:
  - `enum AppearanceMode { light, dark, system }` with `ThemeMode get themeMode`.
  - `AppearancePreferences({AppearanceMode mode, double glassIntensity, bool reduceMotion, bool reduceTransparency})` with `defaults`, `copyWith`, `toJson()` and `AppearancePreferences.fromJson(Object? json)`.
  - `abstract interface class AppearancePreferencesStore { Future<AppearancePreferences> load(); Future<void> save(AppearancePreferences value); }`
  - `FileAppearancePreferencesStore({required Future<Directory> Function() directory})` and `InMemoryAppearancePreferencesStore([AppearancePreferences initial])`.
  - Providers `appearancePreferencesStoreProvider`, `initialAppearancePreferencesProvider` and `appearancePreferencesProvider` (`NotifierProvider<AppearancePreferencesController, AppearancePreferences>`), with methods `setMode`, `setGlassIntensity`, `setReduceMotion`, `setReduceTransparency`.

- [ ] **Step 1: Write the failing domain test**

```dart
// test/features/settings/appearance_preferences_test.dart
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults follow the spec', () {
    const p = AppearancePreferences.defaults;
    expect(p.mode, AppearanceMode.system);
    expect(p.glassIntensity, 0.5);
    expect(p.reduceMotion, isFalse);
    expect(p.reduceTransparency, isFalse);
  });

  test('mode maps to ThemeMode', () {
    expect(AppearanceMode.light.themeMode, ThemeMode.light);
    expect(AppearanceMode.dark.themeMode, ThemeMode.dark);
    expect(AppearanceMode.system.themeMode, ThemeMode.system);
  });

  test('json round-trips', () {
    const p = AppearancePreferences(
      mode: AppearanceMode.dark,
      glassIntensity: 0.25,
      reduceMotion: true,
      reduceTransparency: true,
    );
    expect(AppearancePreferences.fromJson(p.toJson()), p);
  });

  test('decoding is tolerant per field', () {
    expect(AppearancePreferences.fromJson(null), AppearancePreferences.defaults);
    expect(AppearancePreferences.fromJson('x'), AppearancePreferences.defaults);
    final decoded = AppearancePreferences.fromJson(<String, Object?>{
      'mode': 'sepia',
      'glassIntensity': 3,
      'reduceMotion': 'yes',
      'reduceTransparency': true,
    });
    expect(decoded.mode, AppearanceMode.system);
    expect(decoded.glassIntensity, 1.0);
    expect(decoded.reduceMotion, isFalse);
    expect(decoded.reduceTransparency, isTrue);
    expect(
      AppearancePreferences.fromJson(<String, Object?>{'glassIntensity': -1})
          .glassIntensity,
      0.0,
    );
    expect(
      AppearancePreferences.fromJson(<String, Object?>{'glassIntensity': 'a'})
          .glassIntensity,
      0.5,
    );
  });
}
```

- [ ] **Step 2: Run it; expect a compile failure** (`appearance_preferences.dart` missing)

Run: `flutter test test/features/settings/appearance_preferences_test.dart`

- [ ] **Step 3: Implement the domain type**

```dart
// lib/features/settings/domain/appearance_preferences.dart
import 'package:flutter/material.dart';

enum AppearanceMode {
  light,
  dark,
  system;

  ThemeMode get themeMode => switch (this) {
    AppearanceMode.light => ThemeMode.light,
    AppearanceMode.dark => ThemeMode.dark,
    AppearanceMode.system => ThemeMode.system,
  };
}

@immutable
final class AppearancePreferences {
  const AppearancePreferences({
    this.mode = AppearanceMode.system,
    this.glassIntensity = 0.5,
    this.reduceMotion = false,
    this.reduceTransparency = false,
  });

  factory AppearancePreferences.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return defaults;
    }
    final mode = AppearanceMode.values
        .where((value) => value.name == json['mode'])
        .firstOrNull;
    final intensity = json['glassIntensity'];
    final reduceMotion = json['reduceMotion'];
    final reduceTransparency = json['reduceTransparency'];
    return AppearancePreferences(
      mode: mode ?? defaults.mode,
      glassIntensity: intensity is num
          ? intensity.toDouble().clamp(0.0, 1.0)
          : defaults.glassIntensity,
      reduceMotion: reduceMotion is bool ? reduceMotion : defaults.reduceMotion,
      reduceTransparency: reduceTransparency is bool
          ? reduceTransparency
          : defaults.reduceTransparency,
    );
  }

  static const AppearancePreferences defaults = AppearancePreferences();

  final AppearanceMode mode;

  /// Liquid Glass slider: 0 = clear, 1 = tinted.
  final double glassIntensity;
  final bool reduceMotion;
  final bool reduceTransparency;

  AppearancePreferences copyWith({
    AppearanceMode? mode,
    double? glassIntensity,
    bool? reduceMotion,
    bool? reduceTransparency,
  }) {
    return AppearancePreferences(
      mode: mode ?? this.mode,
      glassIntensity: (glassIntensity ?? this.glassIntensity).clamp(0.0, 1.0),
      reduceMotion: reduceMotion ?? this.reduceMotion,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'mode': mode.name,
    'glassIntensity': glassIntensity,
    'reduceMotion': reduceMotion,
    'reduceTransparency': reduceTransparency,
  };

  @override
  bool operator ==(Object other) =>
      other is AppearancePreferences &&
      other.mode == mode &&
      other.glassIntensity == glassIntensity &&
      other.reduceMotion == reduceMotion &&
      other.reduceTransparency == reduceTransparency;

  @override
  int get hashCode =>
      Object.hash(mode, glassIntensity, reduceMotion, reduceTransparency);
}

abstract interface class AppearancePreferencesStore {
  Future<AppearancePreferences> load();

  Future<void> save(AppearancePreferences value);
}
```

- [ ] **Step 4: Run the domain test; expect PASS**

- [ ] **Step 5: Write the failing file-store test**

```dart
// test/features/settings/file_appearance_preferences_store_test.dart
import 'dart:io';

import 'package:borj/features/settings/data/file_appearance_preferences_store.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late FileAppearancePreferencesStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('borj_prefs_');
    store = FileAppearancePreferencesStore(directory: () async => dir);
  });
  tearDown(() => dir.delete(recursive: true));

  File file(String name) => File('${dir.path}/$name');

  test('missing file loads defaults', () async {
    expect(await store.load(), AppearancePreferences.defaults);
  });

  test('save then load round-trips and leaves no temp file', () async {
    const p = AppearancePreferences(mode: AppearanceMode.dark, glassIntensity: 0.8);
    await store.save(p);
    expect(await store.load(), p);
    expect(file('borj-preferences.json.tmp').existsSync(), isFalse);
  });

  test('a second save replaces the first', () async {
    await store.save(const AppearancePreferences(mode: AppearanceMode.dark));
    await store.save(const AppearancePreferences(mode: AppearanceMode.light));
    expect((await store.load()).mode, AppearanceMode.light);
  });

  test('corrupt file is moved aside and defaults load', () async {
    file('borj-preferences.json').writeAsStringSync('{not json');
    expect(await store.load(), AppearancePreferences.defaults);
    expect(file('borj-preferences.json').existsSync(), isFalse);
    expect(file('borj-preferences.json.corrupt').readAsStringSync(), '{not json');
  });
}
```

- [ ] **Step 6: Run it; expect a compile failure**

- [ ] **Step 7: Implement both stores**

```dart
// lib/features/settings/data/file_appearance_preferences_store.dart
import 'dart:convert';
import 'dart:io';

import '../domain/appearance_preferences.dart';

/// Stores appearance preferences as JSON beside `borj.sqlite`.
///
/// Writes go to a temp file that is renamed over the target, so a crash never
/// leaves a half-written file. Unreadable content is moved to `.corrupt` and
/// defaults are used.
final class FileAppearancePreferencesStore implements AppearancePreferencesStore {
  const FileAppearancePreferencesStore({required this.directory});

  static const String fileName = 'borj-preferences.json';

  final Future<Directory> Function() directory;

  Future<File> _file() async => File('${(await directory()).path}/$fileName');

  @override
  Future<AppearancePreferences> load() async {
    final file = await _file();
    if (!file.existsSync()) {
      return AppearancePreferences.defaults;
    }
    try {
      return AppearancePreferences.fromJson(jsonDecode(await file.readAsString()));
    } on FormatException {
      await file.rename('${file.path}.corrupt');
      return AppearancePreferences.defaults;
    } on FileSystemException {
      return AppearancePreferences.defaults;
    }
  }

  @override
  Future<void> save(AppearancePreferences value) async {
    final file = await _file();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(value.toJson()), flush: true);
    await temp.rename(file.path);
  }
}
```

```dart
// lib/features/settings/data/in_memory_appearance_preferences_store.dart
import '../domain/appearance_preferences.dart';

/// Non-persistent store used when nothing overrides the provider (tests).
final class InMemoryAppearancePreferencesStore
    implements AppearancePreferencesStore {
  InMemoryAppearancePreferencesStore([
    this._value = AppearancePreferences.defaults,
  ]);

  AppearancePreferences _value;

  @override
  Future<AppearancePreferences> load() async => _value;

  @override
  Future<void> save(AppearancePreferences value) async => _value = value;
}
```

- [ ] **Step 8: Run the store test; expect PASS**

- [ ] **Step 9: Write the failing controller test**

```dart
// test/features/settings/appearance_preferences_controller_test.dart
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/data/in_memory_appearance_preferences_store.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FailingStore implements AppearancePreferencesStore {
  @override
  Future<AppearancePreferences> load() async => AppearancePreferences.defaults;

  @override
  Future<void> save(AppearancePreferences value) async =>
      throw StateError('disk full');
}

void main() {
  test('starts from the loaded preferences and persists changes', () async {
    final store = InMemoryAppearancePreferencesStore();
    final container = ProviderContainer(
      overrides: [
        appearancePreferencesStoreProvider.overrideWithValue(store),
        initialAppearancePreferencesProvider.overrideWithValue(
          const AppearancePreferences(mode: AppearanceMode.dark),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appearancePreferencesProvider).mode, AppearanceMode.dark);

    final controller = container.read(appearancePreferencesProvider.notifier);
    await controller.setMode(AppearanceMode.light);
    await controller.setGlassIntensity(0.9);
    await controller.setReduceMotion(true);
    await controller.setReduceTransparency(true);

    const expected = AppearancePreferences(
      mode: AppearanceMode.light,
      glassIntensity: 0.9,
      reduceMotion: true,
      reduceTransparency: true,
    );
    expect(container.read(appearancePreferencesProvider), expected);
    expect(await store.load(), expected);
  });

  test('a failed save keeps the new state and reports the error', () async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    final container = ProviderContainer(
      overrides: [appearancePreferencesStoreProvider.overrideWithValue(_FailingStore())],
    );
    addTearDown(container.dispose);

    await container
        .read(appearancePreferencesProvider.notifier)
        .setMode(AppearanceMode.dark);

    expect(container.read(appearancePreferencesProvider).mode, AppearanceMode.dark);
    expect(errors.single.exception, isA<StateError>());
  });
}
```

- [ ] **Step 10: Run it; expect a compile failure**

- [ ] **Step 11: Implement the controller**

```dart
// lib/features/settings/application/appearance_preferences_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_appearance_preferences_store.dart';
import '../domain/appearance_preferences.dart';

/// Overridden in `bootstrapApp` with the file store.
final appearancePreferencesStoreProvider = Provider<AppearancePreferencesStore>(
  (ref) => InMemoryAppearancePreferencesStore(),
);

/// Overridden in `bootstrapApp` with the value loaded before `runApp`.
final initialAppearancePreferencesProvider = Provider<AppearancePreferences>(
  (ref) => AppearancePreferences.defaults,
);

final appearancePreferencesProvider =
    NotifierProvider<AppearancePreferencesController, AppearancePreferences>(
      AppearancePreferencesController.new,
    );

final class AppearancePreferencesController
    extends Notifier<AppearancePreferences> {
  @override
  AppearancePreferences build() =>
      ref.watch(initialAppearancePreferencesProvider);

  Future<void> setMode(AppearanceMode mode) =>
      _update(state.copyWith(mode: mode));

  Future<void> setGlassIntensity(double value) =>
      _update(state.copyWith(glassIntensity: value));

  Future<void> setReduceMotion(bool value) =>
      _update(state.copyWith(reduceMotion: value));

  Future<void> setReduceTransparency(bool value) =>
      _update(state.copyWith(reduceTransparency: value));

  Future<void> _update(AppearancePreferences next) async {
    state = next;
    try {
      await ref.read(appearancePreferencesStoreProvider).save(next);
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'appearance preferences',
          context: ErrorDescription('while saving appearance preferences'),
        ),
      );
    }
  }
}
```

- [ ] **Step 12: Run the controller test; expect PASS**

- [ ] **Step 13: Write the failing app-level test**

```dart
// test/app/bootstrap/borj_app_appearance_test.dart
import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('the first frame already uses the stored mode', (tester) async {
    final database = openTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          initialAppearancePreferencesProvider.overrideWithValue(
            const AppearancePreferences(mode: AppearanceMode.dark),
          ),
        ],
        child: const BorjApp(),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.themeAnimationDuration, const Duration(milliseconds: 300));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
```

- [ ] **Step 14: Run it; expect FAIL** (`themeMode` is `system` and the duration is 400 ms).

- [ ] **Step 15: Wire the app**

In `lib/app/bootstrap/app_bootstrap.dart`:

1. Replace the `theme_mode_controller.dart` import with imports of
   `package:borj/features/settings/application/appearance_preferences_controller.dart`,
   `package:borj/features/settings/data/file_appearance_preferences_store.dart` and `package:path_provider/path_provider.dart`.
2. In `bootstrapApp()`, before `final container = ...`:

```dart
  const preferencesStore = FileAppearancePreferencesStore(
    directory: getApplicationDocumentsDirectory,
  );
  final initialPreferences = await preferencesStore.load();

  final container = ProviderContainer(
    overrides: [
      appearancePreferencesStoreProvider.overrideWithValue(preferencesStore),
      initialAppearancePreferencesProvider.overrideWithValue(
        initialPreferences,
      ),
    ],
  );
```

3. In `BorjApp.build`:

```dart
      themeMode: ref.watch(
        appearancePreferencesProvider.select((p) => p.mode.themeMode),
      ),
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeOut,
```

In `dashboard_screen.dart`, replace the `theme_mode_controller.dart` import with the controller and domain imports,
add `import 'dart:async';` if missing, and replace the body of `_toggleTheme`:

```dart
  void _toggleTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    unawaited(
      ref
          .read(appearancePreferencesProvider.notifier)
          .setMode(isDark ? AppearanceMode.light : AppearanceMode.dark),
    );
  }
```

Delete `lib/app/theme/theme_mode_controller.dart`. Confirm with `rtk grep -rn dashboardThemeModeProvider lib test` that nothing references it.

- [ ] **Step 16: Run the task's tests, `test/app/bootstrap/` and `test/features/dashboard/`; expect PASS. Then run `flutter analyze`; expect no issues.**

- [ ] **Step 17: Commit**

```bash
git add lib/features/settings/domain/appearance_preferences.dart \
  lib/features/settings/data/file_appearance_preferences_store.dart \
  lib/features/settings/data/in_memory_appearance_preferences_store.dart \
  lib/features/settings/application/appearance_preferences_controller.dart \
  lib/app/bootstrap/app_bootstrap.dart lib/features/dashboard/presentation/dashboard_screen.dart \
  lib/app/theme/theme_mode_controller.dart \
  test/features/settings/appearance_preferences_test.dart \
  test/features/settings/file_appearance_preferences_store_test.dart \
  test/features/settings/appearance_preferences_controller_test.dart \
  test/app/bootstrap/borj_app_appearance_test.dart
git commit -m "feat(settings): persisted appearance preferences loaded before the first frame"
```

---

### Task 2: `AppTheme` tokens and the app background

**Files:**
- Create: `lib/app/theme/app_theme.dart` (`AppColors`, `AppTextRoles`, `AppSpacing`, `AppRadii`, `AppTheme`)
- Create: `lib/app/theme/app_background.dart`
- Modify: `lib/app/theme/original_theme.dart:24` (add `AppTheme` to `extensions`)
- Test: `test/app/theme/app_theme_test.dart`, `test/app/theme/app_theme_contrast_test.dart`, `test/app/theme/app_background_test.dart`

**Interfaces:**
- Produces:
  - `AppTheme extends ThemeExtension<AppTheme>` with `colors` and `text`. Constants `AppTheme.light` and `AppTheme.dark`. `static AppTheme of(BuildContext)` returns the extension, or falls back to the theme matching `Theme.of(context).brightness`.
  - `AppColors` fields: `background`, `window`, `text`, `textSecondary`, `textSecondaryStrong`, `textTertiary`, `link`, `accent`, `teal`, `success`, `warn`, `danger`, `purple`, `checkBorder`, `hairline`, `selection`, `innerTop`, `innerBottom`, `innerEdge`, `innerShadow`, `backdropTop`, `backdropBottom`, `warmGlow`, `glassTextStops` (`List<Color>`), and the getters `moneyIncome`, `moneyExpense`, `moneyOverBudget`.
  - `AppTextRoles` fields: `largeTitle`, `title`, `headline`, `body`, `callout`, `subheadline`, `footnote`, `caption`, `caption2`, plus `TextStyle tabular(TextStyle)`.
  - `AppSpacing` constants `s4` … `s32`; `AppRadii` constants `capsule`, `card`, `cardLarge`, `inner`, `innerSmall`, `sheet`, `small`.
  - `AppBackground({required AppBackgroundKind kind, required Widget child})` with `enum AppBackgroundKind { phone, desk }`.

- [ ] **Step 1: Write the failing contrast test.** It encodes the measured kit numbers. `textTertiary` is exempt by
  name: the kit marks finished/disabled text as intentionally low contrast. Accent and teal are fills, not text roles.

```dart
// test/app/theme/app_theme_contrast_test.dart
import 'dart:math' as math;

import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _worst(Color text, AppColors colors) {
  var worst = double.infinity;
  for (final base in <Color>{colors.background, colors.window}) {
    for (final stop in colors.glassTextStops) {
      worst = math.min(worst, _contrast(text, Color.alphaBlend(stop, base)));
    }
  }
  return worst;
}

void main() {
  final cases = <String, (AppColors, List<String>)>{
    'light': (
      AppTheme.light.colors,
      ['text', 'textSecondary', 'textSecondaryStrong', 'link', 'success', 'warn', 'danger', 'purple'],
    ),
    'dark': (
      AppTheme.dark.colors,
      ['text', 'textSecondary', 'textSecondaryStrong', 'link', 'success', 'warn', 'danger', 'purple'],
    ),
  };

  for (final MapEntry(key: mode, value: (colors, roles)) in cases.entries) {
    for (final role in roles) {
      test('$mode $role is at least 4.5:1 on the brightest glass stop', () {
        final color = colors.byName(role);
        expect(_worst(color, colors), greaterThanOrEqualTo(4.5));
      });
    }
  }

  test('income text uses success, not teal', () {
    expect(AppTheme.light.colors.moneyIncome, AppTheme.light.colors.success);
    expect(AppTheme.dark.colors.moneyIncome, AppTheme.dark.colors.success);
  });
}
```

`AppColors.byName(String)` is a small switch returning the named field (throws `ArgumentError` for unknown names). It exists only so tests can iterate over roles.

- [ ] **Step 2: Write the failing theme test**

```dart
// test/app/theme/app_theme_test.dart
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/original_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kit values', () {
    expect(AppTheme.light.colors.background, const Color(0xFFFFFFFF));
    expect(AppTheme.dark.colors.background, const Color(0xFF1B1C20));
    expect(AppTheme.dark.colors.window, const Color(0xFF24262B));
    expect(AppTheme.light.colors.accent, const Color(0xFF2F6FDB));
    expect(AppTheme.dark.colors.accent, const Color(0xFF5B93F0));
    expect(AppTheme.light.colors.text, const Color(0xFF1B2236));
  });

  test('type roles use Vazirmatn, no letter spacing, Persian line heights', () {
    final roles = AppTheme.light.text;
    for (final style in [roles.body, roles.callout, roles.subheadline, roles.footnote]) {
      expect(style.fontFamily, 'Vazirmatn');
      expect(style.letterSpacing, 0);
      expect(style.height, inInclusiveRange(1.5, 1.7));
    }
    expect(roles.largeTitle.fontSize, 34);
    expect(roles.body.fontSize, 15);
    expect(
      roles.tabular(roles.body).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('legacy themes carry AppTheme for their brightness', () {
    expect(OriginalTheme.light().extension<AppTheme>(), AppTheme.light);
    expect(OriginalTheme.dark().extension<AppTheme>(), AppTheme.dark);
  });

  testWidgets('of() falls back by brightness when no extension', (tester) async {
    late AppTheme resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            resolved = AppTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, AppTheme.dark);
  });

  test('lerp endpoints', () {
    expect(AppTheme.light.lerp(AppTheme.dark, 0).colors.text, AppTheme.light.colors.text);
    expect(AppTheme.light.lerp(AppTheme.dark, 1).colors.text, AppTheme.dark.colors.text);
  });
}
```

- [ ] **Step 3: Run both tests; expect compile failures**

- [ ] **Step 4: Implement `app_theme.dart`**

```dart
// lib/app/theme/app_theme.dart
import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
}

/// Radii from the boards (`screens/*.html`) and the 2026-11-06 Apple size alignment.
abstract final class AppRadii {
  static const double capsule = 999;
  static const double cardLarge = 26;
  static const double card = 24;
  static const double inner = 16;
  static const double innerSmall = 14;
  static const double sheet = 34;
  static const double small = 8;
}

@immutable
final class AppColors {
  const AppColors({
    required this.background,
    required this.window,
    required this.text,
    required this.textSecondary,
    required this.textSecondaryStrong,
    required this.textTertiary,
    required this.link,
    required this.accent,
    required this.teal,
    required this.success,
    required this.warn,
    required this.danger,
    required this.purple,
    required this.checkBorder,
    required this.hairline,
    required this.selection,
    required this.innerTop,
    required this.innerBottom,
    required this.innerEdge,
    required this.innerShadow,
    required this.backdropTop,
    required this.backdropBottom,
    required this.warmGlow,
    required this.glassTextStops,
  });

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    window: Color(0xFFFFFFFF),
    text: Color(0xFF1B2236),
    textSecondary: Color(0xFF38425E),
    textSecondaryStrong: Color(0xFF2C3550),
    textTertiary: Color(0xFF5A6482),
    link: Color(0xFF1F5FD0),
    accent: Color(0xFF2F6FDB),
    teal: Color(0xFF0B857A),
    success: Color(0xFF07665D),
    warn: Color(0xFF8F5400),
    danger: Color(0xFFB02440),
    purple: Color(0xFF6B4BC0),
    checkBorder: Color(0xFF6F7896),
    hairline: Color(0x1F1B2236), // rgba(27,34,54,.12)
    selection: Color(0x242F6FDB), // rgba(47,111,219,.14)
    innerTop: Color(0xFFFFFFFF),
    innerBottom: Color(0xEBECF2FF), // rgba(236,242,255,.92)
    innerEdge: Color(0x3832488C), // rgba(50,72,140,.22)
    innerShadow: Color(0x421E3278), // rgba(30,50,120,.26)
    backdropTop: Color(0xFFFFFFFF),
    backdropBottom: Color(0xFFFFFFFF),
    warmGlow: Color(0x00FFAA5F),
    glassTextStops: <Color>[
      Color(0xD6FFFFFF), // rgba(255,255,255,.84)
      Color(0xB3F2F6FF), // rgba(242,246,255,.70)
      Color(0xBDE4ECFE), // rgba(228,236,254,.74)
    ],
  );

  static const dark = AppColors(
    background: Color(0xFF1B1C20),
    window: Color(0xFF24262B),
    text: Color(0xFFF4F6FC),
    textSecondary: Color(0xFFC5CCE0),
    textSecondaryStrong: Color(0xFFE1E6F5),
    textTertiary: Color(0xFF98A2C0),
    link: Color(0xFFACC9FF), // kit #8DB5FF, lightened (Decision 4)
    accent: Color(0xFF5B93F0),
    teal: Color(0xFF3FD1C2),
    success: Color(0xFF66DBB0), // kit #4FD6A4, lightened
    warn: Color(0xFFF2BE71), // kit #F0B35A, lightened
    danger: Color(0xFFFFB3BE), // kit #FF8A9B, lightened
    purple: Color(0xFFD1BFFF), // kit #B79BFF, lightened
    checkBorder: Color(0xFFAEB8D6),
    hairline: Color(0x1FFFFFFF),
    selection: Color(0x24FFFFFF),
    innerTop: Color(0x42FFFFFF), // rgba(255,255,255,.26)
    innerBottom: Color(0x1FFFFFFF), // rgba(255,255,255,.12)
    innerEdge: Color(0x66000000), // rgba(0,0,0,.4)
    innerShadow: Color(0x73000000), // rgba(0,0,0,.45)
    backdropTop: Color(0xFF232427),
    backdropBottom: Color(0xFF18191C),
    warmGlow: Color(0x57FFAA5F), // rgba(255,170,95,.34)
    glassTextStops: <Color>[
      Color(0x80787C96), // rgba(120,124,150,.50)
      Color(0x8056596E), // rgba(86,89,110,.50)
      Color(0x8C424456), // rgba(66,68,86,.55)
    ],
  );

  final Color background;
  final Color window;
  final Color text;
  final Color textSecondary;
  final Color textSecondaryStrong;

  /// Finished/disabled text. Intentionally below 4.5:1 (kit rule 5).
  final Color textTertiary;
  final Color link;
  final Color accent;
  final Color teal;
  final Color success;
  final Color warn;
  final Color danger;
  final Color purple;
  final Color checkBorder;
  final Color hairline;
  final Color selection;
  final Color innerTop;
  final Color innerBottom;
  final Color innerEdge;
  final Color innerShadow;
  final Color backdropTop;
  final Color backdropBottom;
  final Color warmGlow;

  /// The kit's `--g-bg-text` stops: the reference surfaces for text contrast.
  final List<Color> glassTextStops;

  Color get moneyIncome => success;
  Color get moneyExpense => text;
  Color get moneyOverBudget => danger;

  Color byName(String name) => switch (name) {
    'text' => text,
    'textSecondary' => textSecondary,
    'textSecondaryStrong' => textSecondaryStrong,
    'textTertiary' => textTertiary,
    'link' => link,
    'accent' => accent,
    'teal' => teal,
    'success' => success,
    'warn' => warn,
    'danger' => danger,
    'purple' => purple,
    _ => throw ArgumentError.value(name, 'name'),
  };

  AppColors lerp(AppColors other, double t) {
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: c(background, other.background),
      window: c(window, other.window),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textSecondaryStrong: c(textSecondaryStrong, other.textSecondaryStrong),
      textTertiary: c(textTertiary, other.textTertiary),
      link: c(link, other.link),
      accent: c(accent, other.accent),
      teal: c(teal, other.teal),
      success: c(success, other.success),
      warn: c(warn, other.warn),
      danger: c(danger, other.danger),
      purple: c(purple, other.purple),
      checkBorder: c(checkBorder, other.checkBorder),
      hairline: c(hairline, other.hairline),
      selection: c(selection, other.selection),
      innerTop: c(innerTop, other.innerTop),
      innerBottom: c(innerBottom, other.innerBottom),
      innerEdge: c(innerEdge, other.innerEdge),
      innerShadow: c(innerShadow, other.innerShadow),
      backdropTop: c(backdropTop, other.backdropTop),
      backdropBottom: c(backdropBottom, other.backdropBottom),
      warmGlow: c(warmGlow, other.warmGlow),
      glassTextStops: <Color>[
        for (var i = 0; i < glassTextStops.length; i++)
          c(glassTextStops[i], other.glassTextStops[i]),
      ],
    );
  }
}
```

The `0xAARRGGBB` literals above were checked against the rgba values in Global Constraints (alpha byte =
round(a × 255)). Copy them exactly.

Continue the same file:

```dart
@immutable
final class AppTextRoles {
  const AppTextRoles({
    required this.largeTitle,
    required this.title,
    required this.headline,
    required this.body,
    required this.callout,
    required this.subheadline,
    required this.footnote,
    required this.caption,
    required this.caption2,
  });

  factory AppTextRoles.forColor(Color color) {
    TextStyle s(double size, FontWeight weight, double height) => TextStyle(
      fontFamily: 'Vazirmatn',
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      color: color,
    );
    return AppTextRoles(
      largeTitle: s(34, FontWeight.w800, 1.25),
      title: s(23, FontWeight.w700, 1.3),
      headline: s(17, FontWeight.w700, 1.45),
      body: s(15, FontWeight.w400, 1.6),
      callout: s(14, FontWeight.w400, 1.55),
      subheadline: s(13, FontWeight.w500, 1.5),
      footnote: s(12, FontWeight.w400, 1.5),
      caption: s(11, FontWeight.w500, 1.45),
      caption2: s(10, FontWeight.w500, 1.4),
    );
  }

  final TextStyle largeTitle;
  final TextStyle title;
  final TextStyle headline;
  final TextStyle body;
  final TextStyle callout;
  final TextStyle subheadline;
  final TextStyle footnote;
  final TextStyle caption;
  final TextStyle caption2;

  /// Equal-width digits (Vazirmatn `tnum`: every Persian digit 0.659 em).
  TextStyle tabular(TextStyle style) => style.copyWith(
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );

  AppTextRoles lerp(AppTextRoles other, double t) {
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTextRoles(
      largeTitle: l(largeTitle, other.largeTitle),
      title: l(title, other.title),
      headline: l(headline, other.headline),
      body: l(body, other.body),
      callout: l(callout, other.callout),
      subheadline: l(subheadline, other.subheadline),
      footnote: l(footnote, other.footnote),
      caption: l(caption, other.caption),
      caption2: l(caption2, other.caption2),
    );
  }
}

@immutable
final class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({required this.colors, required this.text});

  static final AppTheme light = AppTheme(
    colors: AppColors.light,
    text: AppTextRoles.forColor(AppColors.light.text),
  );

  static final AppTheme dark = AppTheme(
    colors: AppColors.dark,
    text: AppTextRoles.forColor(AppColors.dark.text),
  );

  final AppColors colors;
  final AppTextRoles text;

  static AppTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppTheme>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppTheme copyWith({AppColors? colors, AppTextRoles? text}) =>
      AppTheme(colors: colors ?? this.colors, text: text ?? this.text);

  @override
  AppTheme lerp(covariant AppTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return AppTheme(
      colors: colors.lerp(other.colors, t),
      text: text.lerp(other.text, t),
    );
  }
}
```

`AppTheme.light`/`dark` are `static final` (the text roles are built by a factory). Equality in the
`legacy themes` test therefore relies on identity: `OriginalTheme` must attach these exact instances.

- [ ] **Step 5: Attach the extension.** In `original_theme.dart`, add the import and change the extensions list to:

```dart
      extensions: <ThemeExtension<dynamic>>[
        palette,
        if (brightness == Brightness.dark) AppTheme.dark else AppTheme.light,
      ],
```

- [ ] **Step 6: Run both theme tests; expect PASS.** If a contrast case fails, the colour literal is wrong. Recheck it
  against Global Constraints; do not lower the bound.

- [ ] **Step 7: Write the failing background test**

```dart
// test/app/theme/app_background_test.dart
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Brightness b) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: b, extensions: [b == Brightness.dark ? AppTheme.dark : AppTheme.light]),
      home: const AppBackground(kind: AppBackgroundKind.phone, child: Text('x')),
    ),
  );

  testWidgets('light is plain white', (tester) async {
    await pump(tester, Brightness.light);
    final box = tester.widget<ColoredBox>(
      find.descendant(of: find.byType(AppBackground), matching: find.byType(ColoredBox)).first,
    );
    expect(box.color, const Color(0xFFFFFFFF));
    expect(find.text('x'), findsOneWidget);
  });

  testWidgets('dark has the charcoal gradient and a warm glow', (tester) async {
    await pump(tester, Brightness.dark);
    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(of: find.byType(AppBackground), matching: find.byType(DecoratedBox)),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .toList();
    final linear = decorations.map((d) => d.gradient).whereType<LinearGradient>().single;
    expect(linear.colors, [const Color(0xFF232427), const Color(0xFF18191C)]);
    final radial = decorations.map((d) => d.gradient).whereType<RadialGradient>().single;
    expect(radial.colors.first, AppTheme.dark.colors.warmGlow);
  });
}
```

- [ ] **Step 8: Implement `app_background.dart`**

```dart
// lib/app/theme/app_background.dart
import 'package:flutter/material.dart';

import 'app_theme.dart';

enum AppBackgroundKind { phone, desk }

/// Light: pure white. Dark: charcoal gradient with warm light from the top
/// leading corner (top-right in RTL), as on the boards (`source/build.py`).
final class AppBackground extends StatelessWidget {
  const AppBackground({required this.kind, required this.child, super.key});

  final AppBackgroundKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    if (Theme.of(context).brightness == Brightness.light) {
      return ColoredBox(color: colors.background, child: child);
    }
    final glow = kind == AppBackgroundKind.phone
        ? colors.warmGlow
        : colors.warmGlow.withValues(alpha: 0.30);
    final corner = AlignmentDirectional.topStart.resolve(Directionality.of(context));
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.backdropTop, colors.backdropBottom],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: corner,
            radius: kind == AppBackgroundKind.phone ? 0.95 : 0.8,
            colors: [glow, glow.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ),
        ),
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 9: Run the background test, then `flutter analyze`; expect PASS and no issues.**

- [ ] **Step 10: Commit**

```bash
git add lib/app/theme/app_theme.dart lib/app/theme/app_background.dart lib/app/theme/original_theme.dart \
  test/app/theme/app_theme_test.dart test/app/theme/app_theme_contrast_test.dart test/app/theme/app_background_test.dart
git commit -m "feat(theme): AppTheme tokens from the glass kit and the app background"
```

---

### Task 3: Motion tokens and `MotionScope`

**Files:**
- Create: `lib/app/theme/app_motion.dart`
- Create: `lib/app/theme/motion_scope.dart`
- Modify: `lib/app/bootstrap/app_bootstrap.dart` (`MaterialApp.router(builder: ...)` provides `MotionScope`)
- Test: `test/app/theme/app_motion_test.dart`, `test/app/theme/motion_scope_test.dart`

**Interfaces:**
- Consumes: `appearancePreferencesProvider` (Task 1).
- Produces:
  - `AppSpring(response, dampingRatio)` with `SpringDescription get description`.
  - `AppCurveMotion(duration, curve)`.
  - `abstract final class AppMotion` with constants `emphasized`, `press`, `quick`, `standard`, `snappy`, `soft`, `dataUpdate`, `dataEnter`, `exitFactor`, `stagger`, `reduced`, and the methods `Duration exit(Duration entrance)` and `Duration staggerAt(int index)`.
  - `MotionScope({required bool reduceMotionSetting, required Widget child})`, where `static bool reducedOf(BuildContext)` is true when the system disables animations or the setting is on.

- [ ] **Step 1: Write the failing tests**

```dart
// test/app/theme/app_motion_test.dart
import 'dart:math' as math;

import 'package:borj/app/theme/app_motion.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spring tokens follow the spec table', () {
    expect(AppMotion.standard.response, 0.40);
    expect(AppMotion.standard.dampingRatio, 1.0);
    expect(AppMotion.snappy.response, 0.28);
    expect(AppMotion.snappy.dampingRatio, 1.0);
    expect(AppMotion.soft.response, 0.35);
    expect(AppMotion.soft.dampingRatio, 0.80);
  });

  test('stiffness is (2π/response)² with mass 1', () {
    final d = AppMotion.standard.description;
    expect(d.mass, 1);
    expect(d.stiffness, closeTo(math.pow(2 * math.pi / 0.40, 2), 1e-9));
    // critically damped: c = 2·ζ·√(k·m)
    expect(d.damping, closeTo(2 * math.sqrt(d.stiffness), 1e-9));
  });

  test('curve tokens', () {
    expect(AppMotion.press.duration, const Duration(milliseconds: 120));
    expect(AppMotion.quick.duration, const Duration(milliseconds: 200));
    expect(AppMotion.press.curve, const Cubic(0.23, 1, 0.32, 1));
    expect(AppMotion.dataUpdate.duration, const Duration(milliseconds: 350));
    expect(AppMotion.dataEnter.duration, const Duration(milliseconds: 450));
    expect(AppMotion.reduced.duration, const Duration(milliseconds: 200));
    expect(AppMotion.reduced.curve, Curves.easeOut);
  });

  test('exit is 70% of the entrance; stagger caps at 240 ms', () {
    expect(AppMotion.exit(const Duration(milliseconds: 400)), const Duration(milliseconds: 280));
    expect(AppMotion.staggerAt(0), Duration.zero);
    expect(AppMotion.staggerAt(3), const Duration(milliseconds: 135));
    expect(AppMotion.staggerAt(20), const Duration(milliseconds: 240));
  });
}
```

```dart
// test/app/theme/motion_scope_test.dart
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<bool> _reduced(WidgetTester tester, {required bool system, required bool setting}) async {
  late bool value;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: system),
      child: MotionScope(
        reduceMotionSetting: setting,
        child: Builder(builder: (context) {
          value = MotionScope.reducedOf(context);
          return const SizedBox();
        }),
      ),
    ),
  );
  return value;
}

void main() {
  testWidgets('system flag OR app setting', (tester) async {
    expect(await _reduced(tester, system: false, setting: false), isFalse);
    expect(await _reduced(tester, system: true, setting: false), isTrue);
    expect(await _reduced(tester, system: false, setting: true), isTrue);
  });

  testWidgets('without a scope only the system flag counts', (tester) async {
    late bool value;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (context) {
          value = MotionScope.reducedOf(context);
          return const SizedBox();
        }),
      ),
    );
    expect(value, isTrue);
  });
}
```

- [ ] **Step 2: Run them; expect compile failures**

- [ ] **Step 3: Implement**

```dart
// lib/app/theme/app_motion.dart
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Spring defined by Apple-style response (seconds) and damping ratio.
final class AppSpring {
  const AppSpring({required this.response, required this.dampingRatio});

  final double response;
  final double dampingRatio;

  SpringDescription get description => SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: math.pow(2 * math.pi / response, 2).toDouble(),
    ratio: dampingRatio,
  );
}

final class AppCurveMotion {
  const AppCurveMotion(this.duration, this.curve);

  final Duration duration;
  final Curve curve;
}

/// Motion tokens of `2026-11-06-motion-and-today-customization-design.md` §2.
/// Mapped by name from the Apple presets (`defaultSpring` → [standard],
/// `interactiveSpring` → [snappy]); the values are the spec's.
abstract final class AppMotion {
  static const Curve emphasized = Cubic(0.23, 1, 0.32, 1);

  static const AppCurveMotion press = AppCurveMotion(Duration(milliseconds: 120), emphasized);
  static const AppCurveMotion quick = AppCurveMotion(Duration(milliseconds: 200), emphasized);
  static const AppSpring standard = AppSpring(response: 0.40, dampingRatio: 1.0);
  static const AppSpring snappy = AppSpring(response: 0.28, dampingRatio: 1.0);
  static const AppSpring soft = AppSpring(response: 0.35, dampingRatio: 0.80);
  static const AppCurveMotion dataUpdate = AppCurveMotion(Duration(milliseconds: 350), emphasized);
  static const AppCurveMotion dataEnter = AppCurveMotion(Duration(milliseconds: 450), emphasized);
  static const double exitFactor = 0.7;
  static const List<Duration> stagger = <Duration>[
    Duration.zero,
    Duration(milliseconds: 50),
    Duration(milliseconds: 95),
    Duration(milliseconds: 135),
    Duration(milliseconds: 170),
    Duration(milliseconds: 200),
    Duration(milliseconds: 225),
    Duration(milliseconds: 240),
  ];
  static const AppCurveMotion reduced = AppCurveMotion(Duration(milliseconds: 200), Curves.easeOut);

  static Duration exit(Duration entrance) => entrance * exitFactor;

  static Duration staggerAt(int index) => stagger[math.min(index, stagger.length - 1)];
}
```

```dart
// lib/app/theme/motion_scope.dart
import 'package:flutter/widgets.dart';

/// Answers "should motion be reduced?" for every widget: the system flag
/// (`MediaQuery.disableAnimations`) OR the in-app «کاهش حرکت» setting, which
/// Linux needs because it has no reliable system flag.
final class MotionScope extends InheritedWidget {
  const MotionScope({
    required this.reduceMotionSetting,
    required super.child,
    super.key,
  });

  final bool reduceMotionSetting;

  static bool reducedOf(BuildContext context) {
    final system = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scope = context.dependOnInheritedWidgetOfExactType<MotionScope>();
    return system || (scope?.reduceMotionSetting ?? false);
  }

  @override
  bool updateShouldNotify(MotionScope oldWidget) =>
      oldWidget.reduceMotionSetting != reduceMotionSetting;
}
```

- [ ] **Step 4: Provide the scope in the app.** In `BorjApp.build`, read the preferences once and add a `builder` to
  `MaterialApp.router`. Task 4 extends this same builder:

```dart
    final preferences = ref.watch(appearancePreferencesProvider);
    ...
      builder: (context, child) => MotionScope(
        reduceMotionSetting: preferences.reduceMotion,
        child: child ?? const SizedBox.shrink(),
      ),
```

  Replace the `themeMode:` line with `themeMode: preferences.mode.themeMode,` (a single watch).

- [ ] **Step 5: Run the motion tests and `test/app/bootstrap/`; expect PASS. Then run `flutter analyze`.**

- [ ] **Step 6: Commit**

```bash
git add lib/app/theme/app_motion.dart lib/app/theme/motion_scope.dart lib/app/bootstrap/app_bootstrap.dart \
  test/app/theme/app_motion_test.dart test/app/theme/motion_scope_test.dart
git commit -m "feat(theme): motion tokens and MotionScope with the reduce-motion setting"
```

---

### Task 4: Content-glass roles, `GlassScope`, backdrop groups, inner material and the degrade path

**Files:**
- Create: `lib/app/apple_visual/foundation/glass_preferences_scope.dart`
- Modify: `lib/app/apple_visual/widgets/apple_liquid_glass.dart` (append `GlassRole`, `GlassLayerKind`, `AppGlass`, `GlassScope`, `GlassBackdropGroup`; leave `AppleLiquidGlass` unchanged)
- Modify: `lib/app/apple_visual/foundation/apple_glass_shape.dart` (add `concentricInner`)
- Create: `lib/app/apple_visual/widgets/glass_inner.dart`
- Modify: `lib/app/bootstrap/app_bootstrap.dart` (builder adds `GlassPreferencesScope`)
- Modify: `CLAUDE.md` (Visual system: new glass API)
- Test: `test/app/apple_visual/app_glass_test.dart`, `test/app/apple_visual/glass_inner_test.dart`, `test/app/apple_visual/renderer_import_boundary_test.dart`

**Interfaces:**
- Consumes: `AppTheme.of` (Task 2) and `appearancePreferencesProvider` (Task 1).
- Produces:
  - `enum GlassRole { chrome, tinted, panel, row, sheet, clear }`.
  - `enum GlassLayerKind { chrome, content, sheet, clear }`, with `GlassLayerKind.forRole(GlassRole)` returning the default kind for a standalone shape.
  - `GlassPreferencesScope({required double intensity, required bool reduceTransparency, required Widget child})` with `static GlassPreferences of(BuildContext)`, which returns defaults when absent.
  - `AppGlass({required GlassRole role, required Widget child, AppleGlassShape shape = const AppleGlassShape.capsule()})`. Inside a `GlassScope` it is grouped. Outside one it gets its own layer.
  - `GlassScope({required GlassLayerKind kind, required Widget child})`. It is one `LiquidGlassLayer`, holding up to 16 shapes.
  - `GlassBackdropGroup({required Widget child})`, so scopes under one group capture once.
  - `@visibleForTesting static LiquidGlassSettings AppGlass.settingsFor(GlassLayerKind, Brightness, double intensity)`.
  - `AppleGlassShape.concentricInner(double padding)`.
  - `GlassInner({required Widget child, AppleGlassShape shape})`.

- [ ] **Step 1: Write the failing import-boundary test**

```dart
// test/app/apple_visual/renderer_import_boundary_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the adapter and bootstrap import liquid_glass_renderer', () {
    const allowed = {
      'lib/app/apple_visual/widgets/apple_liquid_glass.dart',
      'lib/app/bootstrap/app_bootstrap.dart',
    };
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('package:liquid_glass_renderer'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .where((p) => !allowed.contains(p))
        .toList();
    expect(offenders, isEmpty);
  });
}
```

- [ ] **Step 2: Run it; expect PASS** (it locks the current state; it must stay green after this task).

- [ ] **Step 3: Write the failing glass tests**

```dart
// test/app/apple_visual/app_glass_test.dart
import 'package:borj/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:borj/app/apple_visual/foundation/glass_preferences_scope.dart';
import 'package:borj/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

Widget _app(Widget child, {bool reduceTransparency = false, Brightness b = Brightness.light}) => MaterialApp(
  theme: ThemeData(brightness: b, extensions: [b == Brightness.dark ? AppTheme.dark : AppTheme.light]),
  home: GlassPreferencesScope(
    intensity: 0.5,
    reduceTransparency: reduceTransparency,
    child: Center(child: child),
  ),
);

Widget _contentScope() => GlassScope(
  kind: GlassLayerKind.content,
  child: Column(
    children: const [
      AppGlass(role: GlassRole.panel, shape: AppleGlassShape.rounded(24), child: SizedBox(width: 100, height: 40)),
      AppGlass(role: GlassRole.row, child: SizedBox(width: 100, height: 40)),
    ],
  ),
);

void main() {
  test('layer settings per kind follow the intensity slider', () {
    expect(
      AppGlass.settingsFor(GlassLayerKind.content, Brightness.light, 0.5),
      LiquidGlassSettings.ios27Regular(brightness: Brightness.light, tintAmount: 0.5),
    );
    expect(
      AppGlass.settingsFor(GlassLayerKind.sheet, Brightness.dark, 0.9),
      LiquidGlassSettings.ios27Regular(brightness: Brightness.dark, tintAmount: 1.0),
    );
    expect(
      AppGlass.settingsFor(GlassLayerKind.clear, Brightness.light, 0.2),
      LiquidGlassSettings.ios27Clear(tintAmount: 0.2),
    );
  });

  testWidgets('a scope is one layer for all its shapes', (tester) async {
    await tester.pumpWidget(_app(_contentScope()));
    expect(find.byType(LiquidGlassLayer), findsOneWidget);
    expect(find.byType(AppGlass), findsNWidgets(2));
  });

  testWidgets('standalone glass gets its own layer', (tester) async {
    await tester.pumpWidget(_app(const AppGlass(role: GlassRole.chrome, child: SizedBox(width: 40, height: 40))));
    expect(find.byType(LiquidGlassLayer), findsOneWidget);
  });

  testWidgets('reduce transparency fakes content layers only', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            _contentScope(),
            const GlassScope(
              kind: GlassLayerKind.chrome,
              child: AppGlass(role: GlassRole.chrome, child: SizedBox(width: 40, height: 40)),
            ),
          ],
        ),
        reduceTransparency: true,
      ),
    );
    final layers = tester.widgetList<LiquidGlassLayer>(find.byType(LiquidGlassLayer)).toList();
    expect(layers.map((l) => l.fake), [true, false]);
  });

  testWidgets('scopes under a backdrop group share the backdrop', (tester) async {
    await tester.pumpWidget(_app(GlassBackdropGroup(child: Column(children: [_contentScope(), _contentScope()]))));
    final layers = tester.widgetList<LiquidGlassLayer>(find.byType(LiquidGlassLayer));
    expect(layers.every((l) => l.useBackdropGroup), isTrue);
  });

  testWidgets('a role that does not belong to the scope kind asserts', (tester) async {
    await tester.pumpWidget(
      _app(const GlassScope(
        kind: GlassLayerKind.content,
        child: AppGlass(role: GlassRole.chrome, child: SizedBox()),
      )),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  test('concentric inner radius', () {
    expect(const AppleGlassShape.rounded(24).concentricInner(8).radius, 16);
    expect(const AppleGlassShape.rounded(6).concentricInner(8).radius, 0);
    expect(const AppleGlassShape.capsule().concentricInner(8).kind, AppleGlassShapeKind.capsule);
  });
}
```

```dart
// test/app/apple_visual/glass_inner_test.dart
import 'package:borj/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:borj/app/apple_visual/widgets/glass_inner.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() {
  testWidgets('inner material is flat: no glass layer, kit fill and edge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppTheme.light]),
        home: const GlassInner(shape: AppleGlassShape.rounded(16), child: Text('in')),
      ),
    );
    expect(find.byType(LiquidGlassLayer), findsNothing);
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(GlassInner), matching: find.byType(DecoratedBox)).first,
    );
    final d = box.decoration as BoxDecoration;
    final g = d.gradient! as LinearGradient;
    expect(g.colors, [AppTheme.light.colors.innerTop, AppTheme.light.colors.innerBottom]);
    expect((d.border! as Border).top.color, AppTheme.light.colors.innerEdge);
    expect(d.borderRadius, BorderRadius.circular(16));
  });
}
```

- [ ] **Step 4: Run them; expect compile failures**

- [ ] **Step 5: Implement the preferences scope**

```dart
// lib/app/apple_visual/foundation/glass_preferences_scope.dart
import 'package:flutter/widgets.dart';

@immutable
final class GlassPreferences {
  const GlassPreferences({this.intensity = 0.5, this.reduceTransparency = false});

  final double intensity;
  final bool reduceTransparency;
}

/// Carries the glass intensity slider and «کاهش شفافیت» to every glass widget,
/// so the glass constructors take no visual parameters.
final class GlassPreferencesScope extends InheritedWidget {
  const GlassPreferencesScope({
    required this.intensity,
    required this.reduceTransparency,
    required super.child,
    super.key,
  });

  final double intensity;
  final bool reduceTransparency;

  static GlassPreferences of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GlassPreferencesScope>();
    return scope == null
        ? const GlassPreferences()
        : GlassPreferences(intensity: scope.intensity, reduceTransparency: scope.reduceTransparency);
  }

  @override
  bool updateShouldNotify(GlassPreferencesScope oldWidget) =>
      oldWidget.intensity != intensity || oldWidget.reduceTransparency != reduceTransparency;
}
```

- [ ] **Step 6: Add `concentricInner` to `AppleGlassShape`**

```dart
  /// Inner shape for content inset by [padding] (concentric corners).
  AppleGlassShape concentricInner(double padding) => switch (kind) {
    AppleGlassShapeKind.rounded => AppleGlassShape.rounded(math.max(0.0, radius - padding)),
    _ => this,
  };
```

  (add `import 'dart:math' as math;` at the top)

- [ ] **Step 7: Append the new glass API to `apple_liquid_glass.dart`.** Add the imports
  `foundation/glass_preferences_scope.dart` and `../../theme/app_theme.dart`; keep everything already in the file.

```dart
enum GlassRole { chrome, tinted, panel, row, sheet, clear }

enum GlassLayerKind {
  chrome,
  content,
  sheet,
  clear;

  static GlassLayerKind forRole(GlassRole role) => switch (role) {
    GlassRole.chrome || GlassRole.tinted => GlassLayerKind.chrome,
    GlassRole.panel || GlassRole.row => GlassLayerKind.content,
    GlassRole.sheet => GlassLayerKind.sheet,
    GlassRole.clear => GlassLayerKind.clear,
  };

  bool allows(GlassRole role) => switch (this) {
    GlassLayerKind.chrome => role == GlassRole.chrome || role == GlassRole.tinted,
    GlassLayerKind.content => role == GlassRole.panel || role == GlassRole.row || role == GlassRole.tinted,
    GlassLayerKind.sheet => role == GlassRole.sheet || role == GlassRole.tinted,
    GlassLayerKind.clear => role == GlassRole.clear,
  };
}

LiquidShape _liquidShape(AppleGlassShape shape) => switch (shape.kind) {
  AppleGlassShapeKind.capsule => const LiquidRoundedSuperellipse(borderRadius: 999),
  AppleGlassShapeKind.rounded => LiquidRoundedSuperellipse(borderRadius: shape.radius),
  AppleGlassShapeKind.circle => const LiquidOval(),
};

/// Inherited marker so [AppGlass] knows it sits inside a [GlassScope].
final class _GlassScopeMarker extends InheritedWidget {
  const _GlassScopeMarker({required this.kind, required super.child});

  final GlassLayerKind kind;

  @override
  bool updateShouldNotify(_GlassScopeMarker oldWidget) => oldWidget.kind != kind;
}

/// One glass shape of the redesign (spec §3.1). Visuals come from the role,
/// the theme and [GlassPreferencesScope]; the constructor takes none.
final class AppGlass extends StatelessWidget {
  const AppGlass({
    required this.role,
    required this.child,
    this.shape = const AppleGlassShape.capsule(),
    super.key,
  });

  final GlassRole role;
  final Widget child;
  final AppleGlassShape shape;

  @visibleForTesting
  static LiquidGlassSettings settingsFor(GlassLayerKind kind, Brightness brightness, double intensity) {
    return switch (kind) {
      GlassLayerKind.chrome || GlassLayerKind.content =>
        LiquidGlassSettings.ios27Regular(brightness: brightness, tintAmount: intensity),
      GlassLayerKind.sheet => LiquidGlassSettings.ios27Regular(
        brightness: brightness,
        tintAmount: math.min(1.0, intensity + 0.25),
      ),
      GlassLayerKind.clear => LiquidGlassSettings.ios27Clear(tintAmount: intensity),
    };
  }

  static bool _fake(GlassLayerKind kind, GlassPreferences preferences) =>
      kind == GlassLayerKind.content && preferences.reduceTransparency;

  LiquidGlassAppearance _appearance(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return switch (role) {
      GlassRole.tinted => LiquidGlassAppearance.ios27Regular(
        brightness: brightness,
        tint: AppTheme.of(context).colors.accent.withValues(alpha: 0.9),
      ),
      GlassRole.clear => const LiquidGlassAppearance.ios27Clear(),
      _ => LiquidGlassAppearance.ios27Regular(brightness: brightness),
    };
  }

  @override
  Widget build(BuildContext context) {
    final marker = context.dependOnInheritedWidgetOfExactType<_GlassScopeMarker>();
    if (marker != null) {
      assert(marker.kind.allows(role), 'GlassRole.${role.name} does not belong in a ${marker.kind.name} GlassScope');
      return LiquidGlass.grouped(shape: _liquidShape(shape), appearance: _appearance(context), child: child);
    }
    final kind = GlassLayerKind.forRole(role);
    final preferences = GlassPreferencesScope.of(context);
    return LiquidGlass.withOwnLayer(
      settings: settingsFor(kind, Theme.of(context).brightness, preferences.intensity),
      fake: _fake(kind, preferences),
      useBackdropGroup: BackdropGroup.of(context) != null,
      shape: _liquidShape(shape),
      appearance: _appearance(context),
      child: child,
    );
  }
}

/// One `LiquidGlassLayer` for a section of up to 16 shapes (renderer cap).
final class GlassScope extends StatelessWidget {
  const GlassScope({required this.kind, required this.child, super.key});

  final GlassLayerKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final preferences = GlassPreferencesScope.of(context);
    return LiquidGlassLayer(
      settings: AppGlass.settingsFor(kind, Theme.of(context).brightness, preferences.intensity),
      fake: AppGlass._fake(kind, preferences),
      useBackdropGroup: BackdropGroup.of(context) != null,
      child: _GlassScopeMarker(kind: kind, child: child),
    );
  }
}

/// Scopes below one group read one shared backdrop: one capture per frame.
final class GlassBackdropGroup extends StatelessWidget {
  const GlassBackdropGroup({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BackdropGroup(child: child);
}
```

  Add `import 'dart:math' as math;` and `import 'package:flutter/material.dart' show Theme;` if `flutter/widgets.dart`
  is the only Flutter import (or switch the file to `package:flutter/material.dart`). If `AssertionError` is not
  surfaced by `tester.takeException()` because the renderer catches build errors differently, report it rather than
  weakening the test.

- [ ] **Step 8: Implement `GlassInner`**

```dart
// lib/app/apple_visual/widgets/glass_inner.dart
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../foundation/apple_glass_shape.dart';

/// Flat material for anything drawn on glass (spec §2.2: never glass on glass).
final class GlassInner extends StatelessWidget {
  const GlassInner({
    required this.child,
    this.shape = const AppleGlassShape.capsule(),
    super.key,
  });

  final Widget child;
  final AppleGlassShape shape;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final radius = switch (shape.kind) {
      AppleGlassShapeKind.rounded => BorderRadius.circular(shape.radius),
      _ => BorderRadius.circular(999),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.innerTop, colors.innerBottom],
        ),
        border: Border.all(color: colors.innerEdge, width: 0.75),
        boxShadow: [BoxShadow(color: colors.innerShadow, offset: const Offset(0, 2), blurRadius: 6, spreadRadius: -1)],
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 9: Provide the glass preferences in the app.** Extend the Task 3 builder:

```dart
      builder: (context, child) => MotionScope(
        reduceMotionSetting: preferences.reduceMotion,
        child: GlassPreferencesScope(
          intensity: preferences.glassIntensity,
          reduceTransparency: preferences.reduceTransparency,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
```

- [ ] **Step 10: Run the new tests, the boundary test and `test/app/apple_visual/` (the legacy adapter tests must stay green); expect PASS. Then run `flutter analyze`.**

- [ ] **Step 11: Update `CLAUDE.md` → Visual system.** Replace the sentence that begins "Use `AppleLiquidGlass(role:, shape: AppleGlassShape..., child:)`" with:

  > New code uses `AppGlass(role: GlassRole..., shape: AppleGlassShape..., child:)` inside a
  > `GlassScope(kind: GlassLayerKind...)` (one layer, ≤ 16 shapes), with the scopes of one surface under one
  > `GlassBackdropGroup`. Things drawn on glass use `GlassInner`. The legacy `AppleLiquidGlass` remains only for
  > screens not yet migrated.

- [ ] **Step 12: Commit**

```bash
git add lib/app/apple_visual/foundation/glass_preferences_scope.dart lib/app/apple_visual/widgets/apple_liquid_glass.dart \
  lib/app/apple_visual/foundation/apple_glass_shape.dart lib/app/apple_visual/widgets/glass_inner.dart \
  lib/app/bootstrap/app_bootstrap.dart CLAUDE.md \
  test/app/apple_visual/app_glass_test.dart test/app/apple_visual/glass_inner_test.dart \
  test/app/apple_visual/renderer_import_boundary_test.dart
git commit -m "feat(glass): content roles, grouped scopes, backdrop groups, inner material, reduce-transparency fallback"
```

---

### Task 5: Probe scenes and the capture budget in ordinary `flutter test`

The renderer counts distinct backdrop captures after each debug frame and prints
`liquid_glass_renderer: N independent backdrop captures in this frame…` when N > 1. It prints again only when N
grows. So the largest N a test sees is an upper bound for every frame of that test file, as long as the file starts
from a fresh isolate (each test file does). The message text belongs to this prerelease version, so it is matched in
one helper.

**Files:**
- Create: `lib/app/apple_visual/review/glass_probe_scene.dart`
- Create: `test/support/backdrop_capture_log.dart`
- Test: `test/app/apple_visual/glass_capture_counter_sanity_test.dart`, `test/app/apple_visual/glass_capture_budget_phone_test.dart`, `test/app/apple_visual/glass_capture_budget_desktop_test.dart`

**Interfaces:**
- Consumes: `AppGlass`, `GlassScope`, `GlassLayerKind`, `GlassBackdropGroup`, `GlassRole` (Task 4), `AppBackground` (Task 2).
- Produces:
  - `GlassProbeScene.phone()` and `GlassProbeScene.desktop()`.
  - `static const Key GlassProbeScene.scrollKey`.
  - `BackdropCaptureLog.record(Future<void> Function() body)`, which returns `Future<int>`: the largest count reported, or 1 when nothing was reported.

- [ ] **Step 1: Write the helper**

```dart
// test/support/backdrop_capture_log.dart
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Reads the debug capture counter of liquid_glass_renderer 1.0.0-dev.2.
abstract final class BackdropCaptureLog {
  static final RegExp _message = RegExp(
    r'liquid_glass_renderer: (\d+) independent backdrop captures in this frame',
  );

  /// Runs [body] and returns the largest capture count printed meanwhile, or 1
  /// if nothing was printed (the renderer only prints counts above 1).
  static Future<int> record(Future<void> Function() body) async {
    final previous = debugPrint;
    var largest = 1;
    debugPrint = (String? message, {int? wrapWidth}) {
      final match = message == null ? null : _message.firstMatch(message);
      if (match != null) {
        largest = math.max(largest, int.parse(match.group(1)!));
      }
      previous(message, wrapWidth: wrapWidth);
    };
    try {
      await body();
    } finally {
      debugPrint = previous;
    }
    return largest;
  }
}
```

- [ ] **Step 2: Write the sanity test first.** It runs in its own file, because a high count here would mask lower counts in the same isolate:

```dart
// test/app/apple_visual/glass_capture_counter_sanity_test.dart
import 'package:borj/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';

void main() {
  testWidgets('five ungrouped glass shapes are counted as five captures', (tester) async {
    final count = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              for (var i = 0; i < 5; i++)
                const AppGlass(role: GlassRole.chrome, child: SizedBox(width: 40, height: 40)),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    });
    expect(count, greaterThanOrEqualTo(5), reason: 'the debug counter is not observable; the budget tests are invalid');
  });
}
```

- [ ] **Step 3: Run it.** Expect PASS. If it fails (the counter does not see FakeGlass captures under
  `flutter test`), STOP and report: the budget must then be measured only in Task 6.

- [ ] **Step 4: Implement the probe scenes.** They mirror the Today board's glass structure (spec §3.3). Phone: a
  content group with 4 scroll sections of 6 rows each, and a chrome scope with the tab bar and the search circle.
  That is expected to be 2 captures. Desktop: a chrome group (sidebar + toolbar scopes), a content group with 2
  panel scopes, and an inspector sheet. That is expected to be 3 captures.

```dart
// lib/app/apple_visual/review/glass_probe_scene.dart
import 'package:flutter/material.dart';

import '../../theme/app_background.dart';
import '../../theme/app_theme.dart';
import '../foundation/apple_glass_shape.dart';
import '../widgets/apple_liquid_glass.dart';

/// Glass layout of the Today boards, used by the capture-budget tests and the
/// device perf probe. Content is placeholder; only the glass structure matters.
final class GlassProbeScene extends StatelessWidget {
  const GlassProbeScene.phone({super.key}) : desktop = false;
  const GlassProbeScene.desktop({super.key}) : desktop = true;

  static const Key scrollKey = Key('glass-probe-scroll');

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppBackground(
        kind: desktop ? AppBackgroundKind.desk : AppBackgroundKind.phone,
        child: desktop ? const _Desktop() : const _Phone(),
      ),
    );
  }
}

Widget _section(GlassRole role, int rows) => GlassScope(
  kind: GlassLayerKind.content,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
    child: Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: AppGlass(
              role: role,
              shape: const AppleGlassShape.rounded(AppRadii.card),
              child: const SizedBox(height: 56, width: double.infinity),
            ),
          ),
      ],
    ),
  ),
);

final class _Phone extends StatelessWidget {
  const _Phone();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GlassBackdropGroup(
            child: ListView.builder(
              key: GlassProbeScene.scrollKey,
              padding: const EdgeInsets.only(top: 60, bottom: 120),
              itemCount: 4,
              itemBuilder: (context, i) => _section(i.isEven ? GlassRole.panel : GlassRole.row, 6),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          bottom: 24,
          child: GlassScope(
            kind: GlassLayerKind.chrome,
            child: Row(
              children: [
                const Expanded(child: AppGlass(role: GlassRole.chrome, child: SizedBox(height: 62))),
                const SizedBox(width: AppSpacing.s12),
                const AppGlass(
                  role: GlassRole.chrome,
                  shape: AppleGlassShape.circle(),
                  child: SizedBox.square(dimension: 62),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 260,
          child: GlassBackdropGroup(
            child: Column(
              children: [
                const GlassScope(
                  kind: GlassLayerKind.chrome,
                  child: AppGlass(
                    role: GlassRole.chrome,
                    shape: AppleGlassShape.rounded(AppRadii.card),
                    child: SizedBox(height: 600, width: 240),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                GlassScope(
                  kind: GlassLayerKind.chrome,
                  child: Row(
                    children: const [
                      AppGlass(role: GlassRole.chrome, child: SizedBox(width: 36, height: 36)),
                      AppGlass(role: GlassRole.tinted, child: SizedBox(width: 72, height: 36)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GlassBackdropGroup(
            child: ListView(
              key: GlassProbeScene.scrollKey,
              children: [_section(GlassRole.panel, 6), _section(GlassRole.row, 6)],
            ),
          ),
        ),
        const SizedBox(
          width: 320,
          child: AppGlass(
            role: GlassRole.sheet,
            shape: AppleGlassShape.rounded(AppRadii.sheet),
            child: SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Write the budget tests**

```dart
// test/app/apple_visual/glass_capture_budget_phone_test.dart
import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';

void main() {
  // One test per file: the renderer prints a count only when it rises within
  // the process, so a second test in this file could report a lower number.
  // The capture structure does not depend on brightness.
  testWidgets('phone Today glass stays within 3 captures', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final count = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, extensions: [AppTheme.dark]),
        home: const GlassProbeScene.phone(),
      ));
      await tester.pump();
      await tester.drag(find.byKey(GlassProbeScene.scrollKey), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    });
    // ignore: avoid_print
    print('LG_CAPTURES scene=phone path=fake max=$count');
    expect(count, lessThanOrEqualTo(3));
  });
}
```

  The desktop file is the same with `Size(1440, 900)`, `GlassProbeScene.desktop()`, `scene=desktop` and `lessThanOrEqualTo(4)`.
  This measures the FakeGlass path. Task 6 repeats the count on real glass.

- [ ] **Step 6: Run the three files; expect PASS. Note the printed `LG_CAPTURES` lines for the report.** If a budget
  fails, do not change the scene to pass: report the count and which groups produced it.

- [ ] **Step 7: Run the full suite (`flutter test --exclude-tags device`) and `flutter analyze`; expect PASS.**

- [ ] **Step 8: Commit**

```bash
git add lib/app/apple_visual/review/glass_probe_scene.dart test/support/backdrop_capture_log.dart \
  test/app/apple_visual/glass_capture_counter_sanity_test.dart \
  test/app/apple_visual/glass_capture_budget_phone_test.dart test/app/apple_visual/glass_capture_budget_desktop_test.dart
git commit -m "test(glass): probe scenes and per-frame capture budget"
```

---

### Task 6: Device perf probe (real glass, raster p90)

**Files:**
- Create: `integration_test/glass_perf_probe_test.dart`
- Create: `test_driver/integration_test.dart`
- Modify: `tool/ci.sh` (nothing: `--device` already runs every file in `integration_test/`; confirm by reading it)

**Interfaces:**
- Consumes: `GlassProbeScene` (Task 5).

- [ ] **Step 1: Write the probe**

```dart
// integration_test/glass_perf_probe_test.dart
import 'dart:ui' as ui;

import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../test/support/backdrop_capture_log.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(LiquidGlass.precache);

  // The renderer prints a count only when it rises within the process. Phone
  // (budget 3) runs first; if desktop prints nothing, its count is at most the
  // phone's, so still within 4. The reverse order could hide a phone count of 4.
  for (final (name, scene, size, budget) in [
    ('phone', const GlassProbeScene.phone(), const Size(390, 844), 3),
    ('desktop', const GlassProbeScene.desktop(), const Size(1440, 900), 4),
  ]) {
    testWidgets('$name probe scrolls within budget on real glass', (tester) async {
      expect(ui.ImageFilter.isShaderFilterSupported, isTrue,
          reason: 'shader filters unavailable: real glass is not active, the probe would measure FakeGlass');
      await binding.setSurfaceSize(size);
      final captures = await BackdropCaptureLog.record(() async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: Brightness.dark, extensions: [AppTheme.dark]),
          home: scene,
        ));
        await tester.pumpAndSettle();
      });
      // ignore: avoid_print
      print('LG_CAPTURES scene=$name path=real max=$captures');
      if (!kProfileMode) {
        // The counter only exists in debug builds.
        expect(captures, lessThanOrEqualTo(budget));
      }

      await binding.watchPerformance(() async {
        final watch = Stopwatch()..start();
        var up = true;
        while (watch.elapsed < const Duration(seconds: 3)) {
          await tester.fling(find.byKey(GlassProbeScene.scrollKey), Offset(0, up ? -600 : 600), 2400);
          await tester.pumpAndSettle();
          up = !up;
        }
      }, reportKey: 'glass_probe_$name');

      final summary = binding.reportData!['glass_probe_$name']! as Map<String, dynamic>;
      final p90 = (summary['90th_percentile_frame_rasterizer_time_millis'] as num).toDouble();
      // ignore: avoid_print
      print('LG_PERF scene=$name mode=${kProfileMode ? 'profile' : 'debug'} raster_p90_ms=$p90');
      if (kProfileMode) {
        expect(p90, lessThanOrEqualTo(8.0));
      }
    });
  }
}
```

  If the `reportData` keys differ in this Flutter version, print the whole summary map and use its 90th-percentile
  rasterizer key. Report the key you used.

```dart
// test_driver/integration_test.dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

- [ ] **Step 2: Run the debug probe together with the full-glass proof, on the desktop session**

`isShaderFilterSupported` alone does not prove real glass: the layer also falls back to FakeGlass when Flutter GPU is
unavailable (`liquid_glass_layer.dart:301`). The existing bevel-displacement test is the proof, so it runs in the same
command and must pass. The Linux runner enables Flutter GPU (`linux/runner/my_application.cc:58`). Pass no extra
flags, exactly as `tool/ci.sh --device` does.

Run: `flutter test integration_test/liquid_glass_full_glass_test.dart integration_test/glass_perf_probe_test.dart -d linux`
Expected: all tests PASS. Two `LG_CAPTURES … path=real` lines within budget. Two `LG_PERF … mode=debug` lines
(debug numbers are reported, not gated). If the full-glass test fails, the probe numbers are FakeGlass numbers:
report that, and do not use them.

- [ ] **Step 3: Run the profile probe (raster gate)**

Run: `flutter drive --profile -d linux --driver=test_driver/integration_test.dart --target=integration_test/glass_perf_probe_test.dart`
Expected: PASS, with `LG_PERF … mode=profile raster_p90_ms=… ≤ 8`. Real glass in this run rests on Step 2 passing on
the same machine. If profile drive does not work on this Linux setup, report the exact error and the debug numbers;
do not gate on debug.

- [ ] **Step 4: Run `tool/ci.sh --device`; expect PASS (the existing full-glass test and this probe).**

- [ ] **Step 5: Commit**

```bash
git add integration_test/glass_perf_probe_test.dart test_driver/integration_test.dart
git commit -m "test(glass): device perf probe for content glass (raster p90, real glass asserted)"
```

- [ ] **Step 6: Report** `LG_CAPTURES` (Task 5) and `LG_PERF` (both modes) to the main session. The main session
  writes the `docs/WORKLOG.md` entry and decides Part B. If the budget passed, Part B proceeds as planned. If it
  failed, Part B starts with the degrade path (spec §3.3) before the primitives.
