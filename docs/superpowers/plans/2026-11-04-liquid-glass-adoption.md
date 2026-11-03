# Liquid Glass Adoption Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the app to Flutter 3.47.5, render the navigation/control chrome with `liquid_glass_renderer` behind `AppleLiquidGlass`, delete the superseded Gate C renderer, and give the owner a side-by-side review page.

**Architecture:** `AppleVisualScope` (InheritedWidget) supplies `AppleVisualThemeData` built from the *app* theme brightness and the platform family. `AppleLiquidGlass` maps role + shape + brightness to package settings and is the only file that imports `liquid_glass_renderer`. Chrome call sites switch from `OriginalGlass` to `AppleLiquidGlass`; content cards stay `OriginalGlass`.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4, `liquid_glass_renderer` 1.0.0-dev.2, Riverpod, flutter_test, integration_test.

**Spec:** `docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md`; spike verdict GO: `docs/superpowers/references/2026-11-04-liquid-glass-spike-report.md`.

## Global Constraints

- SDK: `/home/shabin/develop/flutter-3.47.5/bin/flutter` (`$F`), Dart `$D=/home/shabin/develop/flutter-3.47.5/bin/dart`. Never modify `/home/shabin/develop/flutter` (3.44.6, shared).
- Package pin exactly `liquid_glass_renderer: 1.0.0-dev.2`. Only `lib/app/apple_visual/widgets/apple_liquid_glass.dart` and `lib/app/bootstrap/app_bootstrap.dart` (precache) import it.
- Glass brightness = `Theme.of(context).brightness` (app theme). Never `MediaQuery.platformBrightness`.
- Glass only for chrome (top bar islands, tab control, theme button, dialog/picker surfaces). Content cards and `OriginalFieldSurface` stay as they are.
- Under `flutter test` the package paints `FakeGlass`; widget tests must not assert rendering path.
- Every commit passes `PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH tool/ci.sh` locally (after Task 1) and CI on push. Push `feat/v2-complete-dashboard` is pre-approved; never force-push.
- Stage explicit paths only. Chat with the owner in Persian; repo text in English.

---

### Task 1: Move the project to Flutter 3.47.5

**Files:** Modify `.flutter-version`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `test/app/apple_visual/apple_custom_glass_impeller_test.dart` (format only), `CLAUDE.md` (Commands section).

- [ ] Step 1: `printf '3.47.5\n' > .flutter-version`.
- [ ] Step 2: Remove the unused `file_picker` dependency (no references in `lib/`, `test/`, `integration_test/`; 11.0.2 does not build on Android with 3.47): `$F pub remove file_picker`.
- [ ] Step 3: `$F pub get` (expect intl/matcher/meta/test_api/vector_math bumps and an `analyzer.exclude` block in `analysis_options.yaml`; keep both).
- [ ] Step 4: `$D format lib test` (expect exactly 1 file: `apple_custom_glass_impeller_test.dart`).
- [ ] Step 5: In `CLAUDE.md` § Commands replace the SDK paragraph with: "The Flutter SDK version is pinned in `.flutter-version` (3.47.5). Use `/home/shabin/develop/flutter-3.47.5/bin` first on `PATH` (the shared `~/develop/flutter` is 3.44.6 for other projects; never upgrade it)." and the integration-test sentence with "Shader image filters and Flutter GPU are on by default with 3.47.5 on Linux once the runner enables Flutter GPU (Task 2)."
- [ ] Step 6: `PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH TZ=UTC tool/ci.sh` → `==> all checks passed`.
- [ ] Step 7: Commit `build: move to Flutter 3.47.5 and drop unused file_picker`; push; CI green (the workflow reads `.flutter-version`).

### Task 2: Enable Flutter GPU in the platform runners (parallel with Task 1)

**Files:** `linux/runner/my_application.cc`, `windows/runner/main.cpp`, `android/app/src/main/AndroidManifest.xml`.

- [ ] Step 1: Linux: after `g_autoptr(FlDartProject) project = fl_dart_project_new();` add `  fl_dart_project_set_enable_flutter_gpu(project, TRUE);`.
- [ ] Step 2: Windows: after `flutter::DartProject project(L"data");` add `  project.set_enable_flutter_gpu(true);`.
- [ ] Step 3: Android: inside `<application>` add `<meta-data android:name="io.flutter.embedding.android.EnableFlutterGPU" android:value="true" />`.
- [ ] Step 4: `$F build linux --release` succeeds.
- [ ] Step 5: Commit `build: enable Flutter GPU on Linux, Windows and Android`.

### Task 3: AppleVisualScope + package-backed AppleLiquidGlass (after Tasks 1–2)

**Files:**
- Create: `lib/app/apple_visual/foundation/apple_visual_scope.dart`, `lib/app/apple_visual/foundation/apple_glass_shape.dart`
- Replace: `lib/app/apple_visual/widgets/apple_liquid_glass.dart`
- Modify: `pubspec.yaml`, `lib/app/bootstrap/app_bootstrap.dart`, `test/app/apple_visual/apple_liquid_glass_test.dart`
- Create test: `test/app/apple_visual/apple_visual_scope_test.dart`, `test/app/apple_visual/apple_liquid_glass_adapter_test.dart`

**Interfaces (Produces):**
- `final class AppleGlassShape { const AppleGlassShape.capsule(); const AppleGlassShape.rounded(double radius); const AppleGlassShape.circle(); }`
- `final class AppleVisualScope extends InheritedWidget { static AppleVisualThemeData of(BuildContext context); }` — falls back to a theme resolved from `Theme.of(context).brightness` and `AppleVisualPlatformResolver.resolve(defaultTargetPlatform)` when no scope is present.
- `AppleLiquidGlass({required AppleGlassRole role, required Widget child, AppleGlassShape shape = const AppleGlassShape.capsule(), AppleControlState state = AppleControlState.idle, AppleVisualThemeData? theme, Key? key})`
- `@visibleForTesting static LiquidGlassSettings settingsFor(AppleGlassRole role, Brightness brightness)`

- [ ] Step 1: Add `liquid_glass_renderer: 1.0.0-dev.2` to `pubspec.yaml`; `$F pub get`.
- [ ] Step 2: Write failing tests.

`test/app/apple_visual/apple_visual_scope_test.dart`:
```dart
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('falls back to the app theme brightness, not the platform', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    late Brightness seen;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      home: Builder(builder: (context) {
        seen = AppleVisualScope.of(context).brightness;
        return const SizedBox();
      }),
    ));
    expect(seen, Brightness.light);
  });

  testWidgets('maps desktop platforms to macos27', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    late AppleVisualFamily family;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      family = AppleVisualScope.of(context).family;
      return const SizedBox();
    })));
    expect(family, AppleVisualFamily.macos27);
  });
}
```

`test/app/apple_visual/apple_liquid_glass_adapter_test.dart`:
```dart
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark and light settings differ for the same role', () {
    expect(
      AppleLiquidGlass.settingsFor(AppleGlassRole.smallControl, Brightness.light),
      isNot(AppleLiquidGlass.settingsFor(AppleGlassRole.smallControl, Brightness.dark)),
    );
  });

  testWidgets('renders its child for every role', (tester) async {
    for (final role in AppleGlassRole.values) {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: AppleLiquidGlass(
            role: role,
            shape: const AppleGlassShape.rounded(20),
            child: Text('child-${role.name}'),
          ),
        ),
      ));
      expect(find.text('child-${role.name}'), findsOneWidget);
    }
  });
}
```

- [ ] Step 3: `$F test test/app/apple_visual/apple_visual_scope_test.dart test/app/apple_visual/apple_liquid_glass_adapter_test.dart` → FAIL (files missing).
- [ ] Step 4: Implement.

`lib/app/apple_visual/foundation/apple_glass_shape.dart`:
```dart
enum AppleGlassShapeKind { capsule, rounded, circle }

final class AppleGlassShape {
  const AppleGlassShape.capsule() : kind = AppleGlassShapeKind.capsule, radius = 0;
  const AppleGlassShape.rounded(this.radius) : kind = AppleGlassShapeKind.rounded;
  const AppleGlassShape.circle() : kind = AppleGlassShapeKind.circle, radius = 0;

  final AppleGlassShapeKind kind;
  final double radius;
}
```

`lib/app/apple_visual/foundation/apple_visual_scope.dart`:
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'apple_source_token_mapper.dart';
import 'apple_visual_platform_resolver.dart';
import 'apple_visual_theme.dart';

final class AppleVisualScope extends InheritedWidget {
  const AppleVisualScope({required this.data, required super.child, super.key});

  final AppleVisualThemeData data;

  static AppleVisualThemeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppleVisualScope>();
    if (scope != null) {
      return scope.data;
    }
    return resolve(
      brightness: Theme.of(context).brightness,
      platform: defaultTargetPlatform,
    );
  }

  static AppleVisualThemeData resolve({
    required Brightness brightness,
    required TargetPlatform platform,
  }) {
    final family = AppleVisualPlatformResolver.resolve(platform);
    return AppleVisualThemeData(
      family: family,
      brightness: brightness,
      colors: AppleSourceTokenMapper.colors(family: family, brightness: brightness),
      typography: AppleSourceTokenMapper.typography(family: family),
      metrics: AppleSourceTokenMapper.metrics(family: family),
      materials: AppleSourceTokenMapper.materials(family: family),
      motion: AppleSourceTokenMapper.motion(family: family),
    );
  }

  @override
  bool updateShouldNotify(AppleVisualScope oldWidget) => oldWidget.data != data;
}
```
(If `AppleVisualPlatformResolver.resolve` has a different signature, adapt the one call and note it in the report.)

`lib/app/apple_visual/widgets/apple_liquid_glass.dart` (replace the file; the Gate C strategy path is no longer used):
```dart
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../foundation/apple_glass_shape.dart';
import '../foundation/apple_liquid_glass_recipe.dart';
import '../foundation/apple_visual_scope.dart';
import '../foundation/apple_visual_state.dart';
import '../foundation/apple_visual_theme.dart';

final class AppleLiquidGlass extends StatelessWidget {
  const AppleLiquidGlass({
    required this.role,
    required this.child,
    this.shape = const AppleGlassShape.capsule(),
    this.state = AppleControlState.idle,
    this.theme,
    super.key,
  });

  final AppleGlassRole role;
  final Widget child;
  final AppleGlassShape shape;
  final AppleControlState state;
  final AppleVisualThemeData? theme;

  @visibleForTesting
  static LiquidGlassSettings settingsFor(AppleGlassRole role, Brightness brightness) {
    return switch (role) {
      AppleGlassRole.overGlassControl => LiquidGlassSettings.ios27Clear(),
      _ => LiquidGlassSettings.ios27Regular(brightness: brightness),
    };
  }

  static LiquidShape _shapeFor(AppleGlassShape shape) {
    return switch (shape.kind) {
      AppleGlassShapeKind.capsule => const LiquidRoundedSuperellipse(borderRadius: 999),
      AppleGlassShapeKind.rounded => LiquidRoundedSuperellipse(borderRadius: shape.radius),
      AppleGlassShapeKind.circle => const LiquidOval(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? AppleVisualScope.of(context);
    final brightness = resolved.brightness;
    return LiquidGlass.withOwnLayer(
      settings: settingsFor(role, brightness),
      shape: _shapeFor(shape),
      child: child,
    );
  }
}
```
Check `LiquidGlass.withOwnLayer` / `LiquidShape` / `LiquidOval` names against the package source in the pub cache (`liquid_glass_renderer-1.0.0-dev.2/lib/src/liquid_glass.dart`, `liquid_shape.dart`); fix only call-site names if they differ and record them. `state` is accepted for API stability; pressed feedback comes from the caller's `OriginalPressable`.

- [ ] Step 5: In `lib/app/bootstrap/app_bootstrap.dart`, after `WidgetsFlutterBinding.ensureInitialized();` add `await LiquidGlass.precache();` (import the package there).
- [ ] Step 6: In `test/app/apple_visual/apple_liquid_glass_test.dart` delete the `source-consumption contract` tests that reference `debugRenderDiagnostics` or the recipe resolver output of the old widget; keep the forbidden-parameter test but change its list to `['blurSigma', 'opacity', 'borderColor']` (radius now only through `AppleGlassShape`). If the file ends up with no tests, delete it.
- [ ] Step 7: Run the two new test files + `$F test test/app/apple_visual` → the only failures allowed are tests of the Gate C `rendering/**` code that import removed APIs; list them in the report (Task 4 deletes them). `$F analyze lib` clean.
- [ ] Step 8: Commit `feat: back AppleLiquidGlass with liquid_glass_renderer`.

### Task 4: Delete the Gate C renderer (after Task 3; parallel with 5–7)

**Files:** delete `lib/app/apple_visual/rendering/` (whole tree), `shaders/apple_liquid_glass.frag`, `shaders/apple_liquid_glass_identity.frag`, the `flutter: shaders:` entries in `pubspec.yaml`, every test under `test/app/apple_visual/` that imports `rendering/`, `integration_test/apple_glass_shader_backend_probe_test.dart`, `test/app/apple_visual/apple_glass_shader_identity_visual_test.dart`, and every `tool/verify_*.py` that references `apple_visual/rendering` or `apple_liquid_glass.frag` (`grep -l`).

- [ ] Step 1: `git rm -r -f` the paths above (the uncommitted WIP edits in `apple_custom_glass_filter.dart` / `apple_custom_glass_impeller_test.dart` are discarded by deleting the files; that is intended).
- [ ] Step 2: `grep -rn "apple_visual/rendering\|apple_liquid_glass.frag" lib test tool integration_test pubspec.yaml` → no hits.
- [ ] Step 3: `PATH=...3.47.5/bin:$PATH tool/ci.sh` green.
- [ ] Step 4: Commit `refactor: remove superseded Gate C glass renderer`.

### Task 5: Chrome uses AppleLiquidGlass (after Task 3)

**Files:** `lib/features/dashboard/presentation/dashboard_screen.dart` (`_BrandIsland` :152, `_TopTabs` :232, `_ThemeIsland` :355), `lib/features/tasks/presentation/task_details/task_details_dialog.dart:178`, `lib/features/tasks/presentation/task_timer/task_manual_time_entry_dialog.dart:77`, `lib/features/tasks/presentation/task_details/task_jalali_date_time_field.dart:526`, `lib/app/bootstrap/app_bootstrap.dart` (scope), affected tests.

- [ ] Step 1: Write a failing widget test `test/features/dashboard/dashboard_chrome_glass_test.dart` that pumps the app shell the same way `original_dashboard_screen_test.dart` does and asserts `find.byType(AppleLiquidGlass)` finds 3 widgets in the top bar and `find.byType(OriginalGlass)` finds none inside `_TopBar` (use `find.descendant(of: find.byKey(const ValueKey('top-bar')), …)`; add `key: const ValueKey('top-bar')` to the `_TopBar` root).
- [ ] Step 2: Replace each top-bar `OriginalGlass(radius: OriginalDesignTokens.pillRadius, padding: P, child: C)` with `AppleLiquidGlass(role: AppleGlassRole.smallControl, shape: const AppleGlassShape.capsule(), child: Padding(padding: P, child: C))`. The tabs container uses `AppleGlassRole.mediumSurface`. Keep the thumb as is.
- [ ] Step 3: Dialog/picker surfaces: `OriginalGlass(radius: R, padding: P, child: C)` → `AppleLiquidGlass(role: AppleGlassRole.largeSurface, shape: AppleGlassShape.rounded(R), child: Padding(padding: P, child: C))`.
- [ ] Step 4: In `app_bootstrap.dart` nothing else is needed (scope falls back to `Theme.of`); do not add a scope.
- [ ] Step 5: Update existing tests that find `OriginalGlass` at these sites to find `AppleLiquidGlass` instead. Run `$F test test/features` → green.
- [ ] Step 6: Commit `feat: render top bar and dialog chrome as Liquid Glass`.

### Task 6: Linux full-glass integration check (after Task 3)

**Files:** Create `integration_test/liquid_glass_full_glass_test.dart`; modify `tool/ci.sh` (`--device` branch).

- [ ] Step 1: Copy the stripe probe from the spike branch (`git show spike/liquid-glass:integration_test/liquid_glass_full_glass_probe_test.dart`). Change the scene to place the stripe canvas and glass at screen origin (0,0) and capture that boundary (origin-0 capture is required; nested offset boundaries miss the glass — spike report). Glass via `AppleLiquidGlass` is not used here; keep the raw package widgets with the probe settings so the test measures the engine path.
- [ ] Step 2: In `tool/ci.sh` `--device` branch run `flutter test integration_test -d linux` after the tagged tests.
- [ ] Step 3: `PATH=...3.47.5/bin:$PATH tool/ci.sh --device` → both probe tests pass (negative on grid, full off grid).
- [ ] Step 4: Commit `test: verify full Liquid Glass on Linux`.

### Task 7: Side-by-side review page (after Task 3)

**Files:** Create `lib/app/apple_visual/review/glass_review_screen.dart`; modify `lib/app/router/app_router.dart` (debug-only route `/debug/glass-review`, registered only when `kDebugMode`); test `test/app/apple_visual/glass_review_screen_test.dart`.

- [ ] Step 1: Test: pump `GlassReviewScreen(referenceDir: null)` → shows the four sample chrome rows (top-bar capsule, tab control, circle button, dialog surface) in light and dark and the text `No reference images` when `referenceDir` is null.
- [ ] Step 2: Implement: a `ListView` of rows; each row shows our sample over a backdrop (gradient + stripes + `AuroraBackground`) in light and dark side by side. If `const String.fromEnvironment('GLASS_REFERENCE_DIR')` is non-empty, list `*.png` files from that directory with `Image.file` beneath the samples (captures stay outside the repo: `/home/shabin/projects/personal/dashboard-shakhsi-reference-captures/`).
- [ ] Step 3: Route `/debug/glass-review` only `if (kDebugMode)`.
- [ ] Step 4: Tests green; commit `feat: add debug Liquid Glass review page`.

### Task 8: Checkpoint and docs (last)

- [ ] Step 1: `PATH=...3.47.5/bin:$PATH tool/ci.sh` and `--device` green; CI green on the pushed head.
- [ ] Step 2: Checkpoint `docs/superpowers/checkpoints/2026-11-04-liquid-glass-adoption-checkpoint.md` (commits, CI URL, test counts, device run, deferred items: buttons/pills glass, scroll edge effect, macOS 27 desktop tuning, Windows run, owner visual sign-off).
- [ ] Step 3: `PROJECT_ROADMAP.md` §7/§14 and `docs/WORKLOG.md` entry; `CLAUDE.md` Visual system paragraph: `rendering/` removed; `AppleVisualScope` + `AppleGlassShape` usage.
- [ ] Step 4: Keep the private draft release 432096821 (it holds the Windows spike build the owner still has to run); list it under deferred items.
- [ ] Step 5: Commit `docs: checkpoint Liquid Glass adoption`; push.
