# Redesign Phase 1, Part B: Primitives, Patterns, Appearance UI, Review Page. Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the L4 primitives and the L5 motion patterns of the redesign on top of Part A's glass foundation. Add the Appearance settings section and a review page that shows every primitive next to its board. Close Phase 1 with a checkpoint.

**Architecture:** Primitives live in a new design layer, `lib/app/design/`. Patterns live in `lib/app/design/patterns/`, and the barrel is `lib/app/design/design.dart`. Screens import the barrel only. Primitives read their colours from `AppTheme.of`, brightness from `Theme.of(context).brightness`, and motion from `MotionScope.reducedOf` plus `AppMotion`. A primitive drawn inside a glass shape renders flat (`GlassInner` or a solid fill), because `AppGlass` now marks its own subtree and asserts against glass on glass. Sheets and toasts share one app-level backdrop group, so together they cost one capture.

**Tech Stack:** Flutter 3.47.5, Riverpod 2.6.1, `liquid_glass_renderer 1.0.0-dev.2` (behind the adapter).

**Specs:** `docs/superpowers/specs/2026-11-05-liquid-glass-redesign-design.md` §3, §6, §7 phase 1, §8; `docs/superpowers/specs/2026-11-06-motion-and-today-customization-design.md` §1, §2, §3, §6, §7, §9.
**Part A (done):** `docs/superpowers/plans/2026-11-07-redesign-phase-1a-foundation.md`. Its WORKLOG entry lists the follow-ups this plan must honour.

## Global Constraints

- Flutter 3.47.5: put `/home/shabin/develop/flutter-3.47.5/bin` first on `PATH`. In a fresh worktree, run `flutter pub get` once.
- Only `lib/app/apple_visual/widgets/apple_liquid_glass.dart` and `lib/app/bootstrap/app_bootstrap.dart` may import `package:liquid_glass_renderer`. `test/app/apple_visual/renderer_import_boundary_test.dart` enforces this.
- New UI code imports `package:borj/app/design/design.dart`, which re-exports `package:borj/app/apple_visual/glass.dart`. Neither barrel re-exports the renderer.
- No glass on glass. Inside an `AppGlass` subtree (`GlassContext.isOnGlass(context)` is true), primitives use `GlassInner` or a flat fill. `AppGlass` asserts when it is built inside another `AppGlass`. There is no lens exception.
- Colours come only from `AppTheme.of(context).colors`. Brightness comes from `Theme.of(context).brightness`. Text styles come from `AppTheme.of(context).text`. Spacing and radii come from `AppSpacing` and `AppRadii`. No literal colours appear in `lib/app/design/**` except the ones listed here.
- New colour tokens, added in Task 1:
  - `switchOn` `#1FB5A8` (board, both modes)
  - `switchOff`: light `rgba(27,34,54,.12)` = `0x1F1B2236`, dark `rgba(255,255,255,.16)` = `0x29FFFFFF`
  - `thumbSurface` `#FFFFFF` (both)
  - `thumbText` `#1F5FD0` (both modes; it sits on the white thumb, so the light link colour is the readable one)
  - `pressShadow` `rgba(20,30,80,.20)` = `0x33141E50`
  - `knobShadow` `rgba(20,30,80,.35)` = `0x59141E50`
  - `scrim`: light `rgba(10,14,30,.25)` = `0x400A0E1E`, dark `rgba(0,0,0,.45)` = `0x73000000`
- Motion uses only `AppMotion` (`lib/app/theme/app_motion.dart`): `press` (120 ms), `quick` (200 ms), `standard`, `snappy`, `soft`, `dataUpdate` (350 ms), `dataEnter` (450 ms), `exitFactor` 0.7, `reduced` (200 ms `Curves.easeOut`). Never use ease-in curves.
- Under Reduce Motion (`MotionScope.reducedOf(context)`), patterns produce no translation, scale or size animation. Only opacity changes over `AppMotion.reduced`, and moving parts jump to their end position. Every pattern test proves this with `test/support/reduced_motion_expectations.dart` (Task 1).
- Every primitive and pattern test runs the matrix from `test/support/glass_test_app.dart` (Task 1): RTL × light/dark × text scale 1.0 and 1.3, with no exceptions and no overflow.
- Press feedback appears on pointer-down: scale 0.97 with `AppMotion.press`. Hover highlight is for mouse pointers only.
- Minimum hit target: 44 × 44 logical px.
- Persian digits, grouping separator `٬` (U+066C), percent sign `٪` (U+066A). Numbers use tabular figures (`AppTextRoles.tabular`).
- Capture budget per frame, measured during interaction and not only at settle: ≤ 3 on phone, ≤ 4 on desktop. The capture log fails on the renderer's 16-shape warning.
- Glass-intensity slider: `onChanged` calls `previewGlassIntensity`, `onChangeEnd` calls `commitGlassIntensity`. Flutter 3.47.5's `Slider` calls `onChangeEnd` on drag end, on drag cancel (`_endInteraction`) and on keyboard and semantics increase/decrease (`slider.dart:1634`, `:2008–2023`).
- Lints that bite: `require_trailing_commas`, `sort_constructors_first`, `directives_ordering`, `prefer_final_locals`, `unawaited_futures`, `avoid_print` (use `// ignore: avoid_print` in probes only), `avoid_dynamic_calls`.
- Before every commit:
  - `dart format` the changed files;
  - `dart format --output=none --set-exit-if-changed lib test integration_test` exits 0;
  - `flutter analyze` is clean;
  - run the full `flutter test --exclude-tags device` once.
- Stage explicit paths; never `git add -A`; never use bare `git stash`; do not push. Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Do not add new `tool/verify_*` scripts.
- `matchesSemantics(...)` in this Flutter version may require extra flags, such as `hasFocusAction` or `isFocusable`. Add only the flags the widget really has. Never remove the flag the test is about (`isButton`, `isToggled`, `isChecked`, `isSelected`, `isLiveRegion`, the label).
- If a test in this plan cannot pass as written for a reason outside your code, for example a framework API that differs, change it minimally so it still asserts the same behaviour, and report the change. Never weaken what it asserts.
- Report every command you ran with its real result, and any failure verbatim.

## Decisions recorded by this plan

1. **On-glass detection.** `AppGlass` wraps its child in a private inherited marker. `GlassContext.isOnGlass(context)` reads it. `AppGlass` asserts if a marker is already above it. A `GlassScope` does not mark anything, because only real glass shapes do.
2. **Backdrop groups use our own marker.** `AppGlass` and `GlassScope` set `useBackdropGroup` from a private `_GlassGroupMarker`, which `GlassBackdropGroup` installs. They no longer use `BackdropGroup.of(context) != null`. The app root gets `GlassOverlayBackdrop`, a bare Flutter `BackdropGroup` with no marker, so screen glass does not silently join it. Sheets and toasts wrap their content in `GlassOverlayContent`, which installs the marker without a new `BackdropGroup`. Their glass therefore shares the root group: one capture for every overlay. Phone total: content 1 + chrome 1 + overlays 1 = 3. Overlay members read one snapshot, so a toast does not refract a sheet under it. This is accepted.
3. **Sheets are routes.** `showGlassSheet` pushes a `PopupRoute` on the root navigator. That gives system back, a focus scope and a modal barrier. The route drives its own `AnimationController`: it opens with a spring curve (`soft`) from the trigger rect, closes with `standard` at 0.7 of the open time, follows drags 1:1, dismisses on velocity > 0.11 px/ms or below 60 % open, and otherwise springs back with the release velocity. Upward drag stops at fully open; a rubber band is deferred, because the controller is bounded.
4. **Toasts live in the root `Overlay`.** One toast at a time; a new one replaces the old.
5. **Switch off colour.** The boards show only "on" switches, so off is `switchOff`, the kit's `--fill-3`.
6. **Appearance section.** It contains the board's segmented control and slider, plus two switch rows the spec requires and the board lacks: «کاهش حرکت» and «کاهش شفافیت». The rows are styled like the switch row on the `PhoneNotifications` board. The section is inserted into the existing settings screen; rebuilding that screen is Phase 5.
7. **AnimatedNumber.** It counts from the old value to the new value with `dataUpdate`, formatted on every frame with tabular figures. Screen readers get only the final value.
8. **Board images for the review page.** `source/shoot.py` renders board PNGs with headless Chrome, into a directory outside the repo. The review page pairs samples with board PNGs by file name through `GLASS_REFERENCE_DIR`, which is never committed.
9. **Open (owner's phone).** The Samsung A34 profile run (spec §8) needs the owner's device. It is asked at the checkpoint and does not block this plan.

## File structure

```
lib/app/apple_visual/glass.dart                 barrel of the glass API (Task 1)
lib/app/design/design.dart                      barrel of primitives + patterns (grows per task)
lib/app/design/app_text.dart                    AppText, AppTextRole, AppTextTone (Task 2)
lib/app/design/app_icon.dart                    AppIcon (Task 2)
lib/app/design/pressable.dart                   Pressable: press scale / reduced opacity, hover, focus, semantics (Task 2)
lib/app/design/glass_button.dart                GlassButton (Task 2)
lib/app/design/glass_toggle.dart                GlassToggle (Task 3)
lib/app/design/glass_segmented.dart             GlassSegmented, GlassSegment (Task 3)
lib/app/design/glass_chip.dart                  GlassChip (Task 3)
lib/app/design/glass_text_field.dart            GlassTextField (Task 4)
lib/app/design/progress_track.dart              ProgressTrack, ProgressTone (Task 4)
lib/app/design/round_check.dart                 RoundCheck (Task 4)
lib/app/design/animated_number.dart             AnimatedNumber (Task 5)
lib/core/formatting/persian_number.dart         formatPersianInteger, formatPersianPercent (Task 5)
lib/app/design/patterns/glass_overlay.dart      GlassOverlayBackdrop, GlassOverlayContent (Task 6)
lib/app/design/patterns/spring_curve.dart       SpringCurve, settleDuration (Task 6)
lib/app/design/patterns/glass_sheet.dart        showGlassSheet, GlassSheet.close (Task 6)
lib/app/design/patterns/undo_toast.dart         showUndoToast (Task 7)
lib/app/design/patterns/glass_row_transitions.dart  GlassRowInsert, GlassRowRemove (Task 8)
lib/features/settings/presentation/appearance_section.dart  (Task 9)
lib/app/apple_visual/review/design_review_samples.dart      (Task 10)
```

---

### Task 1: Glass marker, overlay-ready grouping, tokens, capture log v2, test helpers

**Files:**
- Modify: `lib/app/apple_visual/widgets/apple_liquid_glass.dart` (marker, `GlassContext`, nested-glass assert, `_GlassGroupMarker`, `GlassOverlayContent` support)
- Create: `lib/app/apple_visual/glass.dart` (barrel)
- Modify: `lib/app/theme/app_theme.dart` (the 7 new tokens)
- Modify: `test/support/backdrop_capture_log.dart` (returns `CaptureRecord`)
- Modify: `test/app/apple_visual/glass_capture_counter_sanity_test.dart`, `glass_capture_budget_phone_test.dart`, `glass_capture_budget_desktop_test.dart`, `integration_test/glass_perf_probe_test.dart` (use `CaptureRecord`; assert no shape-limit warning)
- Create: `test/support/glass_test_app.dart`, `test/support/reduced_motion_expectations.dart`
- Test: `test/app/apple_visual/glass_context_test.dart`, `test/app/apple_visual/glass_shape_limit_sanity_test.dart`, additions to `test/app/theme/app_theme_test.dart`

**Interfaces:**
- Produces:
  - `abstract final class GlassContext { static bool isOnGlass(BuildContext context); }`
  - `GlassOverlayContent({required Widget child})`, defined in `apple_liquid_glass.dart` and exported through the barrel. It marks its subtree's glass to join the nearest Flutter `BackdropGroup`.
  - `GlassOverlayBackdrop({required Widget child})`: a bare Flutter `BackdropGroup` for the app root.
  - `AppColors` fields `switchOn`, `switchOff`, `thumbSurface`, `thumbText`, `pressShadow`, `knobShadow`, `scrim`.
  - `CaptureRecord { int maxCaptures; bool shapeLimitExceeded; }` and `BackdropCaptureLog.record(...)`, which returns `Future<CaptureRecord>`.
  - `Widget glassTestApp(Widget child, {Brightness brightness, double textScale, bool reduceMotion, bool reduceTransparency, double intensity, bool overlayBackdrop})`.
  - `const List<GlassTestVariant> glassTestVariants`, where `GlassTestVariant` is `({String name, Brightness brightness, double textScale})`.
  - `Future<void> expectNoMovement(WidgetTester tester, {required Finder within, required Future<void> Function() trigger, Duration span})`.

- [ ] **Step 1: Write the failing glass-context tests**

```dart
// test/app/apple_visual/glass_context_test.dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../support/glass_test_app.dart';

void main() {
  testWidgets('AppGlass marks its subtree as on glass', (tester) async {
    late bool inside;
    late bool outside;
    await tester.pumpWidget(glassTestApp(Column(children: [
      Builder(builder: (context) {
        outside = GlassContext.isOnGlass(context);
        return const SizedBox();
      }),
      AppGlass(
        role: GlassRole.panel,
        child: Builder(builder: (context) {
          inside = GlassContext.isOnGlass(context);
          return const SizedBox(width: 10, height: 10);
        }),
      ),
    ])));
    expect(outside, isFalse);
    expect(inside, isTrue);
  });

  testWidgets('a GlassScope alone does not mark its subtree', (tester) async {
    late bool value;
    await tester.pumpWidget(glassTestApp(GlassScope(
      kind: GlassLayerKind.content,
      child: Builder(builder: (context) {
        value = GlassContext.isOnGlass(context);
        return const SizedBox();
      }),
    )));
    expect(value, isFalse);
  });

  testWidgets('glass inside glass asserts', (tester) async {
    await tester.pumpWidget(glassTestApp(const AppGlass(
      role: GlassRole.panel,
      child: AppGlass(role: GlassRole.row, child: SizedBox(width: 10, height: 10)),
    )));
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('a bare Flutter BackdropGroup does not enlist screen glass', (tester) async {
    await tester.pumpWidget(glassTestApp(
      const GlassScope(kind: GlassLayerKind.chrome, child: AppGlass(role: GlassRole.chrome, child: SizedBox(width: 10, height: 10))),
      overlayBackdrop: true,
    ));
    final layer = tester.widget<LiquidGlassLayer>(find.byType(LiquidGlassLayer));
    expect(layer.useBackdropGroup, isFalse);
  });

  testWidgets('GlassOverlayContent joins the root group', (tester) async {
    await tester.pumpWidget(glassTestApp(
      const GlassOverlayContent(child: AppGlass(role: GlassRole.sheet, child: SizedBox(width: 10, height: 10))),
      overlayBackdrop: true,
    ));
    final layer = tester.widget<LiquidGlassLayer>(find.byType(LiquidGlassLayer));
    expect(layer.useBackdropGroup, isTrue);
  });
}
```

- [ ] **Step 2: Write the test helpers.** Their behaviour is the contract for every later task.

```dart
// test/support/glass_test_app.dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

typedef GlassTestVariant = ({String name, Brightness brightness, double textScale});

const List<GlassTestVariant> glassTestVariants = [
  (name: 'light 1.0', brightness: Brightness.light, textScale: 1.0),
  (name: 'dark 1.0', brightness: Brightness.dark, textScale: 1.0),
  (name: 'light 1.3', brightness: Brightness.light, textScale: 1.3),
  (name: 'dark 1.3', brightness: Brightness.dark, textScale: 1.3),
];

/// RTL app with AppTheme, the appearance scopes and the app background, as
/// BorjApp provides them. `overlayBackdrop` adds the app-root group.
Widget glassTestApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool reduceMotion = false,
  bool reduceTransparency = false,
  double intensity = 0.5,
  bool overlayBackdrop = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: brightness,
      extensions: [brightness == Brightness.dark ? AppTheme.dark : AppTheme.light],
    ),
    builder: (context, navigator) {
      Widget app = MotionScope(
        reduceMotionSetting: false,
        child: GlassPreferencesScope(
          intensity: intensity,
          reduceTransparency: reduceTransparency,
          child: navigator ?? const SizedBox.shrink(),
        ),
      );
      if (overlayBackdrop) {
        app = GlassOverlayBackdrop(child: app);
      }
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Directionality(textDirection: TextDirection.rtl, child: app),
      );
    },
    home: AppBackground(
      kind: AppBackgroundKind.phone,
      child: Material(type: MaterialType.transparency, child: Center(child: child)),
    ),
  );
}
```

```dart
// test/support/reduced_motion_expectations.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs [trigger], then pumps 16 ms frames for [span]. Every frame, it checks
/// that nothing inside [within] translates, scales or resizes. Under Reduce
/// Motion only opacity may change (motion spec §7).
Future<void> expectNoMovement(
  WidgetTester tester, {
  required Finder within,
  required Future<void> Function() trigger,
  Duration span = const Duration(milliseconds: 600),
}) async {
  await trigger();
  for (var t = Duration.zero; t < span; t += const Duration(milliseconds: 16)) {
    await tester.pump(const Duration(milliseconds: 16));
    if (within.evaluate().isEmpty) {
      return; // the subject left the tree (for example a closed sheet)
    }
    for (final w in tester.widgetList<Transform>(find.descendant(of: within, matching: find.byType(Transform)))) {
      expect(w.transform.isIdentity(), isTrue, reason: 'Transform moved under Reduce Motion at $t');
    }
    for (final w in tester.widgetList<FractionalTranslation>(
      find.descendant(of: within, matching: find.byType(FractionalTranslation)),
    )) {
      expect(w.translation, Offset.zero, reason: 'translation under Reduce Motion at $t');
    }
    for (final w in tester.widgetList<SizeTransition>(find.descendant(of: within, matching: find.byType(SizeTransition)))) {
      final v = w.sizeFactor.value;
      expect(v == 0 || v == 1, isTrue, reason: 'size animated under Reduce Motion at $t ($v)');
    }
  }
}
```

The helper inspects `Transform`, `FractionalTranslation` and `SizeTransition`. Motion that moves through `Align` or `Positioned` cannot be caught this way. Each task that uses such motion adds an explicit "the end position is reached after one frame" check, and its test code names that check.

- [ ] **Step 3: Run the new tests; expect a compile failure** (`glass.dart`, `GlassContext`, `GlassOverlayContent` and `GlassOverlayBackdrop` do not exist).

- [ ] **Step 4: Implement in `apple_liquid_glass.dart`.** Keep everything already in the file. Change and add:

```dart
/// Marks the subtree of one glass shape (spec: no glass on glass).
final class _OnGlassMarker extends InheritedWidget {
  const _OnGlassMarker({required super.child});

  @override
  bool updateShouldNotify(_OnGlassMarker oldWidget) => false;
}

/// Marks a subtree whose glass joins the nearest Flutter BackdropGroup.
final class _GlassGroupMarker extends InheritedWidget {
  const _GlassGroupMarker({required super.child});

  @override
  bool updateShouldNotify(_GlassGroupMarker oldWidget) => false;
}

abstract final class GlassContext {
  /// True inside an [AppGlass]: draw with GlassInner or a flat fill there.
  static bool isOnGlass(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_OnGlassMarker>() != null;

  static bool _joinsGroup(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_GlassGroupMarker>() != null;
}

/// Bare backdrop group at the app root, for overlays (sheets, toasts). Screen
/// glass does not join it; only [GlassOverlayContent] does.
final class GlassOverlayBackdrop extends StatelessWidget {
  const GlassOverlayBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BackdropGroup(child: child);
}

/// Wraps overlay content (a sheet, a toast) so its glass shares the root group.
final class GlassOverlayContent extends StatelessWidget {
  const GlassOverlayContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => _GlassGroupMarker(child: child);
}
```

- `GlassBackdropGroup.build` returns `BackdropGroup(child: _GlassGroupMarker(child: child))`.
- In `AppGlass.build` and `GlassScope.build`, replace `BackdropGroup.of(context) != null` with `GlassContext._joinsGroup(context)`.
- In `AppGlass.build`, first `assert(!GlassContext.isOnGlass(context), 'AppGlass inside another AppGlass: use GlassInner (no glass on glass)')`. Then wrap `child` in `_OnGlassMarker(child: child)` in both branches (grouped and own layer).

- [ ] **Step 5: Create the barrel**

```dart
// lib/app/apple_visual/glass.dart
export 'foundation/apple_glass_shape.dart' show AppleGlassShape, AppleGlassShapeKind;
export 'foundation/glass_preferences_scope.dart';
export 'widgets/apple_liquid_glass.dart'
    show AppGlass, GlassBackdropGroup, GlassContext, GlassLayerKind, GlassOverlayBackdrop, GlassOverlayContent, GlassRole, GlassScope;
export 'widgets/glass_inner.dart';
```

- [ ] **Step 6: Add the tokens.** In `app_theme.dart`, add the 7 fields from Global Constraints to `AppColors`: constructor, both constants, `lerp`. Also add these expectations to `test/app/theme/app_theme_test.dart`:

```dart
  test('Part B tokens', () {
    expect(AppTheme.light.colors.switchOn, const Color(0xFF1FB5A8));
    expect(AppTheme.dark.colors.switchOn, const Color(0xFF1FB5A8));
    expect(AppTheme.light.colors.switchOff, const Color(0x1F1B2236));
    expect(AppTheme.dark.colors.switchOff, const Color(0x29FFFFFF));
    expect(AppTheme.dark.colors.thumbSurface, const Color(0xFFFFFFFF));
    expect(AppTheme.dark.colors.thumbText, const Color(0xFF1F5FD0));
    expect(AppTheme.light.colors.pressShadow, const Color(0x33141E50));
    expect(AppTheme.light.colors.knobShadow, const Color(0x59141E50));
    expect(AppTheme.light.colors.scrim, const Color(0x400A0E1E));
    expect(AppTheme.dark.colors.scrim, const Color(0x73000000));
  });
```

- [ ] **Step 7: Capture log v2.** Replace the helper's return type:

```dart
final class CaptureRecord {
  const CaptureRecord({required this.maxCaptures, required this.shapeLimitExceeded});

  final int maxCaptures;

  /// The renderer printed "a LiquidGlassLayer has more than 16 glass shapes".
  final bool shapeLimitExceeded;
}
```

`record` also matches `RegExp(r'liquid_glass_renderer: a LiquidGlassLayer has more than \d+ glass shapes')` and sets `shapeLimitExceeded`. Update the four callers: they read `.maxCaptures`, and they assert `record.shapeLimitExceeded` is false, with reason `'a GlassScope holds more than 16 shapes'`.

- [ ] **Step 8: Shape-limit sanity, in its own file.**

```dart
// test/app/apple_visual/glass_shape_limit_sanity_test.dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';
import '../../support/glass_test_app.dart';

void main() {
  testWidgets('17 shapes in one scope are reported', (tester) async {
    final record = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(glassTestApp(GlassScope(
        kind: GlassLayerKind.content,
        child: Wrap(children: [
          for (var i = 0; i < 17; i++)
            const AppGlass(role: GlassRole.row, child: SizedBox(width: 8, height: 8)),
        ]),
      )));
      await tester.pump();
    });
    expect(record.shapeLimitExceeded, isTrue);
  });
}
```

If this fails because the FakeGlass path never warns, STOP and report NEEDS_CONTEXT with the evidence. The guard would then have to move to the device probe.

- [ ] **Step 9: Run the task's tests, `test/app/apple_visual/` and `test/app/theme/`; expect PASS.** Then run the full suite, `flutter analyze` and the format check.

- [ ] **Step 10: Commit** with the message `feat(glass): on-glass marker, overlay backdrop group, Part B tokens, capture log v2, test helpers`, staging the files listed above.

---

### Task 2: `AppText`, `AppIcon`, `Pressable`, `GlassButton`

**Files:**
- Create: `lib/app/design/app_text.dart`, `lib/app/design/app_icon.dart`, `lib/app/design/pressable.dart`, `lib/app/design/glass_button.dart`, `lib/app/design/design.dart`
- Test: `test/app/design/app_text_test.dart`, `test/app/design/glass_button_test.dart`

**Interfaces:**
- Consumes: Task 1 (`glass.dart`, `GlassContext`, tokens, helpers).
- Produces:
  - `enum AppTextRole { largeTitle, title, headline, body, callout, subheadline, footnote, caption, caption2 }`
  - `enum AppTextTone { primary, secondary, secondaryStrong, tertiary, link, success, warn, danger, onTint }`. `onTint` is white.
  - `AppText(String data, {AppTextRole role = AppTextRole.body, AppTextTone tone = AppTextTone.primary, FontWeight? weight, TextAlign? textAlign, int? maxLines, bool tabular = false})`
  - `Color AppTextTone.resolve(AppColors colors)`, as an extension
  - `AppIcon(IconData icon, {double size = 20, AppTextTone tone = AppTextTone.primary, bool directional = false, String? semanticLabel})`
  - `Pressable({required Widget child, required VoidCallback? onPressed, String? semanticLabel, bool selected = false, bool button = true})`
  - `enum GlassButtonVariant { chrome, tinted, plain }`
  - `GlassButton({required VoidCallback? onPressed, String? label, IconData? icon, GlassButtonVariant variant = GlassButtonVariant.chrome, AppleGlassShape? shape, String? semanticLabel})`. It needs at least one of `label` and `icon`. An icon-only button is a 44 × 44 circle.

Behaviour:
- **`AppText`:** the style is `AppTheme.of(context).text.<role>` with `color: tone.resolve(colors)`. `weight` overrides the weight. `tabular` applies `text.tabular`.
- **`AppIcon`:** an `Icon` whose `IconData` is rebuilt with `matchTextDirection: directional`, so it flips in RTL. No `Transform` is used. Its colour comes from the tone. With no `semanticLabel`, it is excluded from semantics.
- **`Pressable`:**
  - A `Listener` sets `_pressed` on pointer-down and clears it on up or cancel.
  - The child sits in `AnimatedScale(scale: _pressed ? 0.97 : 1, duration: AppMotion.press.duration, curve: AppMotion.press.curve)`.
  - Under reduced motion the `AnimatedScale` is replaced by `AnimatedOpacity(opacity: _pressed ? 0.7 : 1, duration: AppMotion.reduced.duration, curve: AppMotion.reduced.curve)`.
  - A `MouseRegion` sets hover only when the pointer kind is mouse. Hover paints a `colors.selection` foreground at 50 % alpha, with a radius taken from the nearest `ClipRRect`. The simplest working approach is a `DecoratedBox` with `position: foreground` inside the child's clip; `GlassButton` passes the shape.
  - A `FocusableActionDetector` makes Enter and Space activate. Focus shows a 2 px `colors.accent` ring.
  - Semantics: `button`, `enabled`, `selected` and `label`.
  - When `onPressed` is null, the widget sits at opacity 0.4, with no press and no hover.
- **`GlassButton`** surface:
  - Off glass: `chrome` is `AppGlass(role: chrome)`, `tinted` is `AppGlass(role: tinted)`, `plain` has no surface.
  - On glass: `chrome` is `GlassInner`, `tinted` is a flat `DecoratedBox` with a `colors.accent` fill, `plain` has no surface.
  - Content colour: `onTint` for tinted, `link` for plain, `primary` for chrome.
  - Label: `callout` w700.
  - Padding: horizontal 16, minimum size 44 × 44. Default shape: capsule, or circle when there is an icon and no label.
  - The order is `Pressable(child: surface(child: content))`, so the whole surface scales.

- [ ] **Step 1: Write the failing tests**

```dart
// test/app/design/glass_button_test.dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders every variant without errors (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(
        Column(mainAxisSize: MainAxisSize.min, children: [
          GlassButton(onPressed: () {}, label: 'ذخیره'),
          GlassButton(onPressed: () {}, label: 'ذخیره', variant: GlassButtonVariant.tinted),
          GlassButton(onPressed: () {}, label: 'لغو', variant: GlassButtonVariant.plain),
          GlassButton(onPressed: () {}, icon: Icons.add, semanticLabel: 'افزودن'),
        ]),
        brightness: v.brightness,
        textScale: v.textScale,
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('ذخیره'), findsNWidgets(2));
    });
  }

  testWidgets('tap, disabled, keyboard', (tester) async {
    var taps = 0;
    await tester.pumpWidget(glassTestApp(Column(mainAxisSize: MainAxisSize.min, children: [
      GlassButton(onPressed: () => taps++, label: 'یک'),
      const GlassButton(onPressed: null, label: 'دو'),
    ])));
    await tester.tap(find.text('یک'));
    await tester.tap(find.text('دو'));
    expect(taps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 2);
  });

  testWidgets('press scales to 0.97 on pointer-down and back on up', (tester) async {
    await tester.pumpWidget(glassTestApp(GlassButton(onPressed: () {}, label: 'یک')));
    final gesture = await tester.startGesture(tester.getCenter(find.text('یک')));
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.97);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('reduced motion: press only fades', (tester) async {
    await tester.pumpWidget(glassTestApp(GlassButton(onPressed: () {}, label: 'یک'), reduceMotion: true));
    late TestGesture gesture;
    await expectNoMovement(
      tester,
      within: find.byType(GlassButton),
      trigger: () async => gesture = await tester.startGesture(tester.getCenter(find.text('یک'))),
    );
    expect(find.byType(AnimatedScale), findsNothing);
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0.7);
    await gesture.up();
  });

  testWidgets('on glass: chrome is flat GlassInner, no nested glass', (tester) async {
    await tester.pumpWidget(glassTestApp(AppGlass(
      role: GlassRole.panel,
      shape: const AppleGlassShape.rounded(24),
      child: Padding(padding: const EdgeInsets.all(16), child: GlassButton(onPressed: () {}, label: 'ویرایش')),
    )));
    expect(tester.takeException(), isNull);
    expect(find.byType(AppGlass), findsOneWidget);
    expect(find.byType(GlassInner), findsOneWidget);
  });

  testWidgets('off glass: chrome and tinted are AppGlass', (tester) async {
    await tester.pumpWidget(glassTestApp(Column(mainAxisSize: MainAxisSize.min, children: [
      GlassButton(onPressed: () {}, label: 'a'),
      GlassButton(onPressed: () {}, label: 'b', variant: GlassButtonVariant.tinted),
    ])));
    final roles = tester.widgetList<AppGlass>(find.byType(AppGlass)).map((g) => g.role).toList();
    expect(roles, [GlassRole.chrome, GlassRole.tinted]);
  });

  testWidgets('hit target ≥ 44 and semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(GlassButton(onPressed: () {}, icon: Icons.add, semanticLabel: 'افزودن')));
    final size = tester.getSize(find.byType(GlassButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(
      tester.getSemantics(find.byType(GlassButton)),
      matchesSemantics(label: 'افزودن', isButton: true, isEnabled: true, hasEnabledState: true, hasTapAction: true, isFocusable: true, hasFocusAction: true),
    );
    handle.dispose();
  });

  testWidgets('hover highlight only for a mouse', (tester) async {
    await tester.pumpWidget(glassTestApp(GlassButton(onPressed: () {}, label: 'یک')));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('یک')));
    await tester.pump();
    expect(find.byKey(const ValueKey('pressable-hover')), findsOneWidget);
    await mouse.removePointer();
  });
}
```

```dart
// test/app/design/app_text_test.dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  testWidgets('role and tone resolve from AppTheme', (tester) async {
    await tester.pumpWidget(glassTestApp(
      const AppText('سلام', role: AppTextRole.headline, tone: AppTextTone.secondary),
      brightness: Brightness.dark,
    ));
    final text = tester.widget<Text>(find.text('سلام'));
    expect(text.style!.fontSize, AppTheme.dark.text.headline.fontSize);
    expect(text.style!.color, AppTheme.dark.colors.textSecondary);
  });

  testWidgets('tabular digits', (tester) async {
    await tester.pumpWidget(glassTestApp(const AppText('۱۲۳', tabular: true)));
    expect(tester.widget<Text>(find.text('۱۲۳')).style!.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('directional icon flips in RTL without a Transform', (tester) async {
    await tester.pumpWidget(glassTestApp(const AppIcon(Icons.chevron_left, directional: true)));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon!.matchTextDirection, isTrue);
    expect(find.descendant(of: find.byType(AppIcon), matching: find.byType(Transform)), findsNothing);
  });
}
```

The hover test expects `Pressable` to show its hover foreground under `ValueKey('pressable-hover')`. Add that key in the implementation.

- [ ] **Step 2: Run them; expect compile failures**

- [ ] **Step 3: Implement the four widgets as specified above, and start the barrel:**

```dart
// lib/app/design/design.dart
export '../apple_visual/glass.dart';
export 'app_icon.dart';
export 'app_text.dart';
export 'glass_button.dart';
export 'pressable.dart';
```

- [ ] **Step 4: Run `test/app/design/`; expect PASS. Then run the full suite, analyze and format.**

- [ ] **Step 5: Commit** with the message `feat(design): AppText, AppIcon, Pressable and GlassButton`.

---

### Task 3: `GlassToggle`, `GlassSegmented`, `GlassChip`

**Files:**
- Create: `lib/app/design/glass_toggle.dart`, `lib/app/design/glass_segmented.dart`, `lib/app/design/glass_chip.dart`. Modify `design.dart` (exports).
- Test: `test/app/design/glass_toggle_test.dart`, `test/app/design/glass_segmented_test.dart`, `test/app/design/glass_chip_test.dart`

**Interfaces:**
- Consumes: `Pressable`, `AppText`, `AppIcon` (Task 2), and the tokens (Task 1).
- Produces:
  - `GlassToggle({required bool value, required ValueChanged<bool>? onChanged, String? semanticLabel})`.
  - `GlassSegment<T>({required T value, required String label, IconData? icon})`.
  - `GlassSegmented<T>({required List<GlassSegment<T>> segments, required T selected, required ValueChanged<T>? onChanged, String? semanticLabel})`.
  - `GlassChip({required String label, VoidCallback? onPressed, bool selected = false, IconData? icon})`.

Behaviour (board values):

**`GlassToggle`** (the `PhoneNotifications` board switch). It is always flat; a switch is never a glass shape.
- Layout: track 52 × 32, radius 999. Knob 26 × 26, white `thumbSurface`, with shadow `knobShadow` at offset (0, 1) blur 4. Inset 3.
- `value == true` puts the knob at the **end** (left in RTL), via `AlignmentDirectional.centerEnd`. False puts it at `centerStart`.
- Track colour is `switchOn` or `switchOff`, animated with `AppMotion.quick`.
- Knob motion uses `AnimatedAlign` with `AppMotion.quick`. Under reduced motion the duration is zero, so the knob jumps.
- Input: tapping anywhere on the 52 × 44 hit area toggles. Space and Enter toggle.
- Semantics: `toggled: value`, `label`.
- The outer `Pressable` gives press feedback.

**`GlassSegmented`** (the board's appearance and «نما» controls).
- Off glass: the track is `AppGlass(role: row, shape: capsule)` with padding 3. The thumb is `GlassInner` (capsule). Segment labels are `subheadline` 13 px; the selected one is w800 in `primary`, the others w400 in `primary`.
- On glass: the track is `GlassInner` with padding 3. The thumb is a flat capsule `thumbSurface` with shadow `pressShadow` (0, 1) blur 4. The selected label is w800 `thumbText`, the others w400 `primary`.
- Segments are `Expanded` and equal width, 34 tall, with a 2 px gap.
- The thumb is positioned with a `Positioned.directional` whose `start` is driven by an unbounded `AnimationController`, running a `SpringSimulation` from the current position and velocity to the new target (`AppMotion.snappy`). Interrupting mid-flight starts from the current value. Under reduced motion the position jumps.
- Arrow keys move the selection; in RTL, ArrowLeft means "next". Each segment is a `Pressable` with `selected:` set and `button: true`. The group has `Semantics(container: true, label: semanticLabel)`.

```dart
// The interruptible thumb motion (core of glass_segmented.dart)
final class _ThumbMotion {
  _ThumbMotion(TickerProvider vsync) : controller = AnimationController.unbounded(vsync: vsync);

  final AnimationController controller;

  void moveTo(double target, {required bool reduced}) {
    if (reduced) {
      controller.value = target;
      return;
    }
    final simulation = SpringSimulation(
      AppMotion.snappy.description,
      controller.value,
      target,
      controller.velocity,
    );
    controller.animateWith(simulation);
  }

  void dispose() => controller.dispose();
}
```

The thumb's `start` is `controller.value × (segmentWidth + gap)`, where the segment width comes from a `LayoutBuilder`. On the first build, and whenever the segment width changes, set `controller.value` directly to the selected index without animating.

**`GlassChip`**
- Off glass: `AppGlass(role: row, shape: capsule)`. On glass: `GlassInner` (capsule).
- Height 32, horizontal padding 12, label `footnote` w600, optional 16 px icon with a 6 px gap.
- When selected, a `colors.selection` fill sits over the surface (a flat foreground) and the label tone is `link`.
- `Pressable` gives the press feedback, and the hit target is padded to 44 tall.

- [ ] **Step 1: Write the failing tests**

```dart
// test/app/design/glass_toggle_test.dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _toggle(bool value, ValueChanged<bool> onChanged) =>
    GlassToggle(value: value, onChanged: onChanged, semanticLabel: 'کاهش حرکت');

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(_toggle(true, (_) {}), brightness: v.brightness, textScale: v.textScale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tap toggles; size 52×32; colours from tokens', (tester) async {
    var value = false;
    await tester.pumpWidget(glassTestApp(StatefulBuilder(
      builder: (context, setState) => _toggle(value, (v) => setState(() => value = v)),
    )));
    final track = find.byKey(const ValueKey('glass-toggle-track'));
    expect(tester.getSize(track), const Size(52, 32));
    await tester.tap(find.byType(GlassToggle));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    final box = tester.widget<AnimatedContainer>(track);
    expect((box.decoration! as BoxDecoration).color, AppTheme.light.colors.switchOn);
  });

  testWidgets('on puts the knob at the end (left in RTL)', (tester) async {
    await tester.pumpWidget(glassTestApp(_toggle(true, (_) {})));
    await tester.pumpAndSettle();
    final track = tester.getRect(find.byKey(const ValueKey('glass-toggle-track')));
    final knob = tester.getRect(find.byKey(const ValueKey('glass-toggle-knob')));
    expect(knob.left, closeTo(track.left + 3, 0.5));
  });

  testWidgets('reduced motion: knob reaches its end after one frame', (tester) async {
    var value = false;
    await tester.pumpWidget(glassTestApp(
      StatefulBuilder(builder: (context, setState) => _toggle(value, (v) => setState(() => value = v))),
      reduceMotion: true,
    ));
    await expectNoMovement(tester, within: find.byType(GlassToggle), trigger: () => tester.tap(find.byType(GlassToggle)));
    final track = tester.getRect(find.byKey(const ValueKey('glass-toggle-track')));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.getRect(find.byKey(const ValueKey('glass-toggle-knob'))).left, closeTo(track.left + 3, 0.5));
  });

  testWidgets('semantics toggled state', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_toggle(true, (_) {})));
    expect(tester.getSemantics(find.byType(GlassToggle)), matchesSemantics(label: 'کاهش حرکت', isToggled: true, hasToggledState: true, hasTapAction: true, isEnabled: true, hasEnabledState: true, isFocusable: true, hasFocusAction: true));
    handle.dispose();
  });
}
```

The keys `glass-toggle-track` (the `AnimatedContainer`) and `glass-toggle-knob` (the knob box) are part of the contract.

```dart
// test/app/design/glass_segmented_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

enum _Mode { light, dark, auto }

Widget _segmented(_Mode selected, ValueChanged<_Mode> onChanged) => SizedBox(
  width: 300,
  child: GlassSegmented<_Mode>(
    semanticLabel: 'حالت ظاهری',
    selected: selected,
    onChanged: onChanged,
    segments: const [
      GlassSegment(value: _Mode.light, label: 'روشن'),
      GlassSegment(value: _Mode.dark, label: 'تیره'),
      GlassSegment(value: _Mode.auto, label: 'خودکار'),
    ],
  ),
);

Rect _thumb(WidgetTester tester) => tester.getRect(find.byKey(const ValueKey('glass-segmented-thumb')));

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(_segmented(_Mode.auto, (_) {}), brightness: v.brightness, textScale: v.textScale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tap selects; thumb springs under the selected label', (tester) async {
    var selected = _Mode.light;
    await tester.pumpWidget(glassTestApp(StatefulBuilder(
      builder: (context, setState) => _segmented(selected, (m) => setState(() => selected = m)),
    )));
    await tester.tap(find.text('خودکار'));
    await tester.pump(const Duration(milliseconds: 50));
    final mid = _thumb(tester).center.dx;
    await tester.pumpAndSettle();
    final end = _thumb(tester).center.dx;
    expect(selected, _Mode.auto);
    expect(end, closeTo(tester.getCenter(find.text('خودکار')).dx, 2));
    expect(mid, isNot(closeTo(end, 2)), reason: 'thumb should be travelling, not jumping');
  });

  testWidgets('reduced motion: thumb jumps', (tester) async {
    var selected = _Mode.light;
    await tester.pumpWidget(glassTestApp(
      StatefulBuilder(builder: (context, setState) => _segmented(selected, (m) => setState(() => selected = m))),
      reduceMotion: true,
    ));
    await tester.tap(find.text('خودکار'));
    await tester.pump();
    expect(_thumb(tester).center.dx, closeTo(tester.getCenter(find.text('خودکار')).dx, 2));
  });

  testWidgets('on glass the track is flat and the thumb is a solid surface', (tester) async {
    await tester.pumpWidget(glassTestApp(AppGlass(
      role: GlassRole.panel,
      shape: const AppleGlassShape.rounded(24),
      child: Padding(padding: const EdgeInsets.all(16), child: _segmented(_Mode.auto, (_) {})),
    )));
    expect(tester.takeException(), isNull);
    expect(find.byType(AppGlass), findsOneWidget);
    expect(find.byType(GlassInner), findsOneWidget); // the track
  });

  testWidgets('arrow keys move the selection (RTL: left = next)', (tester) async {
    var selected = _Mode.light;
    await tester.pumpWidget(glassTestApp(StatefulBuilder(
      builder: (context, setState) => _segmented(selected, (m) => setState(() => selected = m)),
    )));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(selected, _Mode.dark);
  });

  testWidgets('selected semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_segmented(_Mode.dark, (_) {})));
    expect(tester.getSemantics(find.text('تیره')), matchesSemantics(label: 'تیره', isSelected: true, hasSelectedState: true, isButton: true, hasTapAction: true, isEnabled: true, hasEnabledState: true, isFocusable: true, hasFocusAction: true));
    handle.dispose();
  });
}
```

```dart
// test/app/design/glass_chip_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(
        GlassChip(label: 'امروز', selected: true, onPressed: () {}, icon: Icons.today),
        brightness: v.brightness,
        textScale: v.textScale,
      ));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('off glass is a row glass capsule; on glass is flat', (tester) async {
    await tester.pumpWidget(glassTestApp(GlassChip(label: 'a', onPressed: () {})));
    expect(tester.widget<AppGlass>(find.byType(AppGlass)).role, GlassRole.row);
    await tester.pumpWidget(glassTestApp(AppGlass(
      role: GlassRole.panel,
      child: Padding(padding: const EdgeInsets.all(8), child: GlassChip(label: 'a', onPressed: () {})),
    )));
    expect(find.byType(AppGlass), findsOneWidget);
    expect(find.byType(GlassInner), findsOneWidget);
  });

  testWidgets('hit target is at least 44 tall; tap works', (tester) async {
    var taps = 0;
    await tester.pumpWidget(glassTestApp(GlassChip(label: 'a', onPressed: () => taps++)));
    expect(tester.getSize(find.byType(GlassChip)).height, greaterThanOrEqualTo(44));
    await tester.tap(find.text('a'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run them; expect compile failures. Step 3: implement. Step 4: run `test/app/design/` (PASS), then the full suite, analyze and format.**

- [ ] **Step 5: Commit** with the message `feat(design): GlassToggle, GlassSegmented and GlassChip`.

---

### Task 4: `GlassTextField`, `ProgressTrack`, `RoundCheck`

**Files:**
- Create: `lib/app/design/glass_text_field.dart`, `lib/app/design/progress_track.dart`, `lib/app/design/round_check.dart`. Modify `design.dart`.
- Test: `test/app/design/glass_text_field_test.dart`, `test/app/design/progress_track_test.dart`, `test/app/design/round_check_test.dart`

**Interfaces:**
- Produces:
  - `GlassTextField({required TextEditingController controller, String? label, String? hint, TextInputType? keyboardType, ValueChanged<String>? onChanged, ValueChanged<String>? onSubmitted, FocusNode? focusNode, bool autofocus = false, TextDirection? textDirection})`.
  - `enum ProgressTone { accent, success, warn, danger }`.
  - `ProgressTrack({required double value, ProgressTone tone = ProgressTone.accent, double height = 6, bool animateIn = false, String? semanticLabel})`.
  - `RoundCheck({required bool checked, required ValueChanged<bool>? onChanged, double size = 24, String? semanticLabel})`.

Behaviour:

**`GlassTextField`**
- The surface depends on context. Off glass it is `AppGlass(role: row, shape: rounded(AppRadii.innerSmall))`. On glass it is `GlassInner` with the same shape.
- Layout:
  - minimum height 44, padding horizontal 14 and vertical 10;
  - the optional `label` sits above the field (`footnote` w700, `secondary`, 6 px gap);
  - the inner `TextField` uses `InputDecoration.collapsed(hintText: hint)`, so the field draws no border of its own;
  - the hint uses `textSecondary`, and the text style is `body` in the `primary` colour.
- Focus: show a 1.5 px `colors.accent` ring around the surface. The ring is a foreground `DecoratedBox` whose border alpha animates with `AppMotion.quick`; under reduced motion it changes instantly.
- Text direction defaults to the ambient direction (RTL).

**`ProgressTrack`**
- Shape: the track is a capsule filled with `colors.hairline`, and the fill is a capsule in the tone colour.
- Direction: the fill starts at the start edge, which is the right edge in RTL.
- Animation:
  - a value change animates from the previous value with `AppMotion.dataUpdate`;
  - on first build, `animateIn: true` grows the fill from 0 with `AppMotion.dataEnter`, while `false` (the default) shows the value directly;
  - under reduced motion the fill jumps to the final value.
- Use a `TweenAnimationBuilder<double>`. Its `tween.begin` is the previous end, or 0 for animate-in. Its `duration` is `Duration.zero` under reduced motion. Its builder returns `FractionallySizedBox(widthFactor:, alignment: AlignmentDirectional.centerStart)`.
- Semantics: value `formatPersianPercent(value)` (from Task 5). Until Task 5 lands, use `'${(value * 100).round()}%'`, and Task 5 switches the call over. Semantics are not tested before Task 5.

**`RoundCheck`** (completing a task)
- Unchecked: a circle of size `size` with a 1.5 px `checkBorder` stroke and a transparent fill.
- Checked: a `colors.success` fill with a white check mark.
- Check animation:
  1. The fill grows with `ScaleTransition` from 0 to 1, driven by a spring (`AppMotion.soft`, so it bounces).
  2. When the fill is within 5 % of landing, the check mark draws over 200 ms. This is a `CustomPaint` that extracts a path segment by progress, using `PathMetric.extractPath`.
- Uncheck: fill and mark fade out over `AppMotion.quick`.
- Under reduced motion, both directions are a 200 ms cross-fade between the two states (`AnimatedSwitcher` with `FadeTransition` only), with no scale.
- Hit target: 44 × 44. Semantics: `checked`, `label`, tap action. Space toggles.

- [ ] **Step 1: Write the failing tests**

```dart
// test/app/design/progress_track_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

double _fill(WidgetTester tester) => tester.getSize(find.byKey(const ValueKey('progress-fill'))).width;

Widget _track(double value, {bool animateIn = false}) =>
    SizedBox(width: 200, child: ProgressTrack(value: value, animateIn: animateIn));

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(_track(0.7), brightness: v.brightness, textScale: v.textScale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the value directly without animateIn', (tester) async {
    await tester.pumpWidget(glassTestApp(_track(0.5)));
    expect(_fill(tester), closeTo(100, 0.5));
  });

  testWidgets('animates from the previous value over dataUpdate', (tester) async {
    await tester.pumpWidget(glassTestApp(_track(0.2)));
    await tester.pumpWidget(glassTestApp(_track(0.8)));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _fill(tester);
    expect(mid, greaterThan(40));
    expect(mid, lessThan(160));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_fill(tester), closeTo(160, 0.5));
  });

  testWidgets('animateIn grows from 0 over dataEnter', (tester) async {
    await tester.pumpWidget(glassTestApp(_track(1, animateIn: true)));
    expect(_fill(tester), lessThan(5));
    await tester.pump(const Duration(milliseconds: 460));
    expect(_fill(tester), closeTo(200, 0.5));
  });

  testWidgets('fill starts at the right edge in RTL', (tester) async {
    await tester.pumpWidget(glassTestApp(_track(0.5)));
    final track = tester.getRect(find.byType(ProgressTrack));
    expect(tester.getRect(find.byKey(const ValueKey('progress-fill'))).right, closeTo(track.right, 0.5));
  });

  testWidgets('reduced motion: value change lands in one frame', (tester) async {
    await tester.pumpWidget(glassTestApp(_track(0.2), reduceMotion: true));
    await tester.pumpWidget(glassTestApp(_track(0.8), reduceMotion: true));
    await tester.pump();
    expect(_fill(tester), closeTo(160, 0.5));
  });
}
```

```dart
// test/app/design/round_check_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _check(bool value, ValueChanged<bool> onChanged) =>
    RoundCheck(checked: value, onChanged: onChanged, semanticLabel: 'خرید نان');

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders both states (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(
        Row(mainAxisSize: MainAxisSize.min, children: [_check(false, (_) {}), _check(true, (_) {})]),
        brightness: v.brightness,
        textScale: v.textScale,
      ));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('checking grows the fill with a spring, then draws the mark', (tester) async {
    var value = false;
    await tester.pumpWidget(glassTestApp(StatefulBuilder(
      builder: (context, setState) => _check(value, (v) => setState(() => value = v)),
    )));
    await tester.tap(find.byType(RoundCheck));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final scale = tester.widget<ScaleTransition>(find.byKey(const ValueKey('round-check-fill'))).scale.value;
    expect(scale, greaterThan(0));
    expect(scale, lessThan(1));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(tester.widget<ScaleTransition>(find.byKey(const ValueKey('round-check-fill'))).scale.value, 1);
  });

  testWidgets('reduced motion: cross-fade only', (tester) async {
    var value = false;
    await tester.pumpWidget(glassTestApp(
      StatefulBuilder(builder: (context, setState) => _check(value, (v) => setState(() => value = v))),
      reduceMotion: true,
    ));
    await expectNoMovement(tester, within: find.byType(RoundCheck), trigger: () => tester.tap(find.byType(RoundCheck)));
    expect(value, isTrue);
  });

  testWidgets('44 px target and checked semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_check(true, (_) {})));
    expect(tester.getSize(find.byType(RoundCheck)), const Size(44, 44));
    expect(tester.getSemantics(find.byType(RoundCheck)), matchesSemantics(label: 'خرید نان', isChecked: true, hasCheckedState: true, hasTapAction: true, isEnabled: true, hasEnabledState: true, isFocusable: true, hasFocusAction: true));
    handle.dispose();
  });
}
```

```dart
// test/app/design/glass_text_field_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders with label and hint (${v.name})', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(glassTestApp(
        SizedBox(width: 300, child: GlassTextField(controller: controller, label: 'عنوان', hint: 'مثلاً خرید نان')),
        brightness: v.brightness,
        textScale: v.textScale,
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('عنوان'), findsOneWidget);
      expect(find.text('مثلاً خرید نان'), findsOneWidget);
    });
  }

  testWidgets('typing updates the controller; focus shows the ring', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(glassTestApp(SizedBox(width: 300, child: GlassTextField(controller: controller, hint: 'h'))));
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.enterText(find.byType(TextField), 'نان');
    expect(controller.text, 'نان');
    expect(find.byKey(const ValueKey('glass-field-focus-ring')), findsOneWidget);
  });

  testWidgets('off glass is a row glass; on glass is flat', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(glassTestApp(SizedBox(width: 300, child: GlassTextField(controller: controller))));
    expect(tester.widget<AppGlass>(find.byType(AppGlass)).role, GlassRole.row);
    await tester.pumpWidget(glassTestApp(AppGlass(
      role: GlassRole.sheet,
      child: Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: 300, child: GlassTextField(controller: controller))),
    )));
    expect(find.byType(AppGlass), findsOneWidget);
    expect(find.byType(GlassInner), findsOneWidget);
  });
}
```

The keys `progress-fill`, `round-check-fill` (the `ScaleTransition`) and `glass-field-focus-ring` (the ring box) are part of the contract.

- [ ] **Steps 2–4:** RED, implement, GREEN. Then the full suite, analyze and format.

- [ ] **Step 5: Commit** with the message `feat(design): GlassTextField, ProgressTrack and RoundCheck`.

---

### Task 5: Persian number formatting and `AnimatedNumber`

**Files:**
- Create: `lib/core/formatting/persian_number.dart` and `lib/app/design/animated_number.dart`. Modify `design.dart`.
- Modify: `lib/app/design/progress_track.dart`, so its semantics value comes from `formatPersianPercent`.
- Test: `test/core/formatting/persian_number_test.dart`, `test/app/design/animated_number_test.dart`, and a semantics case in `progress_track_test.dart`.

**Interfaces:**
- Produces:
  - `String formatPersianInteger(int value)`.
  - `String formatPersianPercent(double fraction)` (rounded to a whole percent).
  - `AnimatedNumber({required num value, required String Function(num value) format, AppTextRole role = AppTextRole.body, AppTextTone tone = AppTextTone.primary, FontWeight? weight, bool animateIn = false})`.

```dart
// lib/core/formatting/persian_number.dart
import 'package:borj/core/money/money.dart';

const String _groupSeparator = '٬'; // ٬
const String _percentSign = '٪'; // ٪

/// 12400 → '۱۲٬۴۰۰'; -5 → '-۵'.
String formatPersianInteger(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    groups.insert(0, digits.substring(end - 3 < 0 ? 0 : end - 3, end));
  }
  final text = Money.toPersianDigits(groups.join(_groupSeparator));
  return negative ? '-$text' : text;
}

/// 0.7 → '۷۰٪'.
String formatPersianPercent(double fraction) =>
    '${formatPersianInteger((fraction * 100).round())}$_percentSign';
```

`AnimatedNumber` counts from the previous value to the new one:

```dart
// core of animated_number.dart (State)
@override
Widget build(BuildContext context) {
  final reduced = MotionScope.reducedOf(context);
  final motion = _first && widget.animateIn ? AppMotion.dataEnter : AppMotion.dataUpdate;
  return Semantics(
    label: widget.format(widget.value),
    child: ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: _from, end: widget.value.toDouble()),
        duration: reduced ? Duration.zero : motion.duration,
        curve: motion.curve,
        onEnd: () => _from = widget.value.toDouble(),
        builder: (context, v, _) => AppText(
          widget.format(widget.value is int ? v.round() : v),
          role: widget.role,
          tone: widget.tone,
          weight: widget.weight,
          tabular: true,
        ),
      ),
    ),
  );
}
```

`_from` starts at `animateIn ? 0 : value`. On `didUpdateWidget`, `_from` is set to the value currently displayed, read from a field the builder updates each frame. That way an update that lands mid-roll continues from where the number is now.

- [ ] **Step 1: Write the failing tests**

```dart
// test/core/formatting/persian_number_test.dart
import 'package:borj/core/formatting/persian_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('integers group with U+066C', () {
    expect(formatPersianInteger(0), '۰');
    expect(formatPersianInteger(999), '۹۹۹');
    expect(formatPersianInteger(1000), '۱٬۰۰۰');
    expect(formatPersianInteger(154400000), '۱۵۴٬۴۰۰٬۰۰۰');
    expect(formatPersianInteger(-12400), '-۱۲٬۴۰۰');
  });

  test('percent uses U+066A', () {
    expect(formatPersianPercent(0.7), '۷۰٪');
    expect(formatPersianPercent(0.004), '۰٪');
    expect(formatPersianPercent(1), '۱۰۰٪');
  });
}
```

```dart
// test/app/design/animated_number_test.dart
import 'package:borj/app/design/design.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

String _fmt(num v) => formatPersianInteger(v.round());

Widget _number(int value, {bool animateIn = false}) =>
    AnimatedNumber(value: value, format: _fmt, animateIn: animateIn);

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(_number(12400), brightness: v.brightness, textScale: v.textScale));
      expect(find.text('۱۲٬۴۰۰'), findsOneWidget);
    });
  }

  testWidgets('counts from the old value to the new one over dataUpdate', (tester) async {
    await tester.pumpWidget(glassTestApp(_number(0)));
    await tester.pumpWidget(glassTestApp(_number(1000)));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.widget<Text>(find.byType(Text)).data!;
    expect(mid, isNot('۰'));
    expect(mid, isNot('۱٬۰۰۰'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('۱٬۰۰۰'), findsOneWidget);
  });

  testWidgets('screen readers get only the final value', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_number(0)));
    await tester.pumpWidget(glassTestApp(_number(1000)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('۱٬۰۰۰'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tabular figures; reduced motion jumps', (tester) async {
    await tester.pumpWidget(glassTestApp(_number(0), reduceMotion: true));
    await tester.pumpWidget(glassTestApp(_number(1000), reduceMotion: true));
    await tester.pump();
    expect(find.text('۱٬۰۰۰'), findsOneWidget);
    expect(tester.widget<Text>(find.byType(Text)).style!.fontFeatures, contains(const FontFeature.tabularFigures()));
  });
}
```

Add a case to `progress_track_test.dart`: with semantics enabled, `ProgressTrack(value: 0.7, semanticLabel: 'بودجه')` exposes the value `'۷۰٪'`.

- [ ] **Steps 2–4:** RED, implement, GREEN. Then the full suite, analyze and format.

- [ ] **Step 5: Commit** with the message `feat(design): Persian number formatting and AnimatedNumber`.

---

### Task 6: Overlay backdrop, spring curve, `GlassSheet`, overlay capture budget

**Files:**
- Create: `lib/app/design/patterns/spring_curve.dart` and `lib/app/design/patterns/glass_sheet.dart`. Modify `design.dart`.
- Modify: `lib/app/bootstrap/app_bootstrap.dart`. `_AppearanceScopes` wraps its result in `GlassOverlayBackdrop`, outermost.
- Modify: `lib/app/apple_visual/review/glass_probe_scene.dart`. Add `GlassProbeScene.phoneWithSheetTrigger()`, which places a `GlassButton` keyed `probe-open-sheet` over the phone scene; the button opens a sheet with 3 `GlassTextField`s and a tinted button.
- Test: `test/app/design/spring_curve_test.dart`, `test/app/design/glass_sheet_test.dart`, and `test/app/apple_visual/glass_capture_budget_phone_overlay_test.dart` (its own file).

**Interfaces:**
- Produces:
  - `SpringCurve(AppSpring spring)` is a `Curve`. `static Duration SpringCurve.settleDuration(AppSpring spring)` returns the first time the simulation is done at tolerance 0.001, rounded up to whole milliseconds.
  - `Future<T?> showGlassSheet<T>(BuildContext context, {required WidgetBuilder builder, Rect? origin, String? semanticLabel})`. `origin` is the trigger's global rect.
  - `abstract final class GlassSheet { static void close<T>(BuildContext context, [T? result]); }`.

```dart
// lib/app/design/patterns/spring_curve.dart
import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

import '../../theme/app_motion.dart';

/// A spring as a [Curve] over its settle time, so routes can use it. Values
/// may overshoot 1 (damping < 1) before landing exactly on 1 at t = 1.
final class SpringCurve extends Curve {
  SpringCurve(this.spring) : _settle = settleDuration(spring);

  final AppSpring spring;
  final Duration _settle;

  static Duration settleDuration(AppSpring spring) {
    final sim = SpringSimulation(spring.description, 0, 1, 0, tolerance: const Tolerance(distance: 0.001, velocity: 0.001));
    var ms = 1;
    while (!sim.isDone(ms / 1000) && ms < 3000) {
      ms++;
    }
    return Duration(milliseconds: ms);
  }

  Duration get duration => _settle;

  @override
  double transformInternal(double t) {
    final sim = SpringSimulation(spring.description, 0, 1, 0);
    return sim.x(t * _settle.inMicroseconds / Duration.microsecondsPerSecond);
  }
}
```

The `GlassSheet` route covers decision 3:

```dart
// core of glass_sheet.dart
final class _GlassSheetRoute<T> extends PopupRoute<T> {
  _GlassSheetRoute({required this.builder, required this.origin, required this.reduced, required this.scrim, this.semanticLabel});

  final WidgetBuilder builder;
  final Rect? origin;
  final bool reduced;
  final Color scrim;
  final String? semanticLabel;

  static final SpringCurve _open = SpringCurve(AppMotion.soft);
  static final SpringCurve _close = SpringCurve(AppMotion.standard);

  @override
  Duration get transitionDuration => reduced ? AppMotion.reduced.duration : _open.duration;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? AppMotion.reduced.duration : AppMotion.exit(_close.duration);

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => scrim; // the modal barrier fades with the route animation

  @override
  String? get barrierLabel => 'بستن';

  AnimationController get sheetController => controller!;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) {
    return GlassOverlayContent(
      child: _GlassSheetFrame(route: this, child: Builder(builder: builder)),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) {
    if (reduced) {
      return FadeTransition(opacity: animation, child: child);
    }
    final curved = CurvedAnimation(parent: animation, curve: _open, reverseCurve: _close.flipped);
    return _GrowFromOrigin(animation: curved, origin: origin, child: child);
  }
}
```

The remaining pieces:
- **`_GrowFromOrigin`** maps `t` to a `Transform` that interpolates from the origin rect to the sheet's laid-out rect. It applies the scale and translation of the rect lerp; the scale is clamped to at least 0.2. Opacity is `t.clamp(0, 1)` over the first 30 %. When `origin` is null, the origin is a rect 40 px tall at the bottom centre of the screen. During a drag (`route.sheetController.isAnimating == false` while the user drags), it uses a plain vertical translation, so the 1:1 drag stays exact.
- **`_GlassSheetFrame`**: aligned bottom, inset 8 px on each side and at the bottom, plus the safe area. It is `AppGlass(role: GlassRole.sheet, shape: AppleGlassShape.rounded(AppRadii.sheet))`, followed by a 36 × 5 grabber in `GlassInner` style (`colors.hairline` capsule), then the content.
- **Drag**: a vertical drag on the frame sets `sheetController.value -= delta.dy / sheetHeight`, which follows the finger 1:1. On release:
  - if `velocity.pixelsPerSecond.dy > 110` (0.11 px/ms) or `sheetController.value < 0.6`, the route pops;
  - otherwise it runs `sheetController.animateWith(SpringSimulation(AppMotion.soft.description, value, 1, -velocity.dy / sheetHeight))`.
  - Under reduced motion, drag-to-dismiss still works, and the spring-back is replaced by `animateTo(1, duration: AppMotion.reduced.duration)`.
- **Keys**: Escape closes the sheet. System back pops it, because the sheet is a route.
- **`GlassSheet.close`** is `Navigator.of(context).pop(result)`.
- **`showGlassSheet`** reads `MotionScope.reducedOf(context)` and `colors.scrim` at call time, then pushes onto `Navigator.of(context, rootNavigator: true)`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/app/design/spring_curve_test.dart
import 'package:borj/app/design/patterns/spring_curve.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts at 0, ends at 1, soft overshoots, standard does not', () {
    final soft = SpringCurve(AppMotion.soft);
    final standard = SpringCurve(AppMotion.standard);
    expect(soft.transform(0), 0);
    expect(soft.transform(1), 1);
    final samples = [for (var i = 1; i < 100; i++) soft.transform(i / 100)];
    expect(samples.any((v) => v > 1.0), isTrue);
    final std = [for (var i = 1; i < 100; i++) standard.transform(i / 100)];
    expect(std.every((v) => v <= 1.0001), isTrue);
  });

  test('settle durations are finite and ordered', () {
    final snappy = SpringCurve.settleDuration(AppMotion.snappy);
    final standard = SpringCurve.settleDuration(AppMotion.standard);
    expect(snappy, lessThan(standard));
    expect(standard, lessThan(const Duration(seconds: 1)));
  });
}
```

```dart
// test/app/design/glass_sheet_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _launcher({void Function(Object?)? onResult}) => Builder(
  builder: (context) => GlassButton(
    label: 'باز کن',
    onPressed: () async {
      final box = context.findRenderObject()! as RenderBox;
      final origin = box.localToGlobal(Offset.zero) & box.size;
      final result = await showGlassSheet<String>(
        context,
        origin: origin,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: GlassButton(label: 'تأیید', variant: GlassButtonVariant.tinted, onPressed: () => GlassSheet.close(context, 'ok')),
        ),
      );
      onResult?.call(result);
    },
  ),
);

void main() {
  for (final v in glassTestVariants) {
    testWidgets('opens and settles (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(_launcher(), brightness: v.brightness, textScale: v.textScale, overlayBackdrop: true));
      await tester.tap(find.text('باز کن'));
      await tester.pumpAndSettle();
      expect(find.text('تأیید'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('grows from the trigger, then closes with a result', (tester) async {
    Object? result;
    await tester.pumpWidget(glassTestApp(_launcher(onResult: (r) => result = r), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final early = tester.getRect(find.byType(AppGlass).last);
    await tester.pumpAndSettle();
    final settled = tester.getRect(find.byType(AppGlass).last);
    expect(early.width, lessThan(settled.width));
    await tester.tap(find.text('تأیید'));
    await tester.pumpAndSettle();
    expect(result, 'ok');
    expect(find.text('تأیید'), findsNothing);
  });

  testWidgets('drag follows 1:1; a slow short drag springs back; a fling dismisses', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    final sheet = find.byType(AppGlass).last;
    final top = tester.getRect(sheet).top;
    final gesture = await tester.startGesture(tester.getRect(sheet).topCenter + const Offset(0, 10));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(tester.getRect(sheet).top, closeTo(top + 30, 1.5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getRect(sheet).top, closeTo(top, 1));
    await tester.fling(sheet, const Offset(0, 200), 1500);
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsNothing);
  });

  testWidgets('scrim tap, Escape and back close the sheet', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsNothing);
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsNothing);
  });

  testWidgets('sheet glass joins the overlay group; content inside is flat', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // tinted button inside sheet glass must not nest glass
    expect(find.byType(AppGlass), findsNWidgets(2)); // launcher + sheet; the inner button is flat
  });

  testWidgets('reduced motion: fade only', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(), reduceMotion: true, overlayBackdrop: true));
    await expectNoMovement(
      tester,
      within: find.byType(Navigator),
      trigger: () => tester.tap(find.text('باز کن')),
    );
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsOneWidget);
  });
}
```

Note on the reduced-motion test: `within: find.byType(Navigator)` covers the route. The launcher's own `Pressable` is not animating at that moment.

```dart
// test/app/apple_visual/glass_capture_budget_phone_overlay_test.dart
import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';

void main() {
  testWidgets('phone with a sheet opening stays within 3 captures', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final record = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, extensions: [AppTheme.dark]),
        builder: (context, child) => GlassOverlayBackdrop(child: child!),
        home: const GlassProbeScene.phoneWithSheetTrigger(),
      ));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('probe-open-sheet')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // count during the open animation
      }
    });
    // ignore: avoid_print
    print('LG_CAPTURES scene=phone+sheet path=fake max=${record.maxCaptures}');
    expect(record.shapeLimitExceeded, isFalse);
    expect(record.maxCaptures, lessThanOrEqualTo(3));
  });
}
```

- [ ] **Steps 2–4:** RED, implement, GREEN. If the overlay budget fails, report the count and which layers produced it. Do not reshape the scene.

- [ ] **Step 5: Run `test/app/bootstrap/`.** The app now has `GlassOverlayBackdrop` at the root, and the existing tests must still pass. Then run the full suite, analyze and format.

- [ ] **Step 6: Commit** with the message `feat(design): GlassSheet route with spring open, 1:1 drag and overlay backdrop group`.

---

### Task 7: `UndoToast` and the toast capture budget

**Files:**
- Create: `lib/app/design/patterns/undo_toast.dart`. Modify `design.dart`.
- Modify: `lib/app/apple_visual/review/glass_probe_scene.dart`. Add `GlassProbeScene.desktopWithToastTrigger()` (button key `probe-show-toast`). Extend `phoneWithSheetTrigger` with a second button, key `probe-show-toast`.
- Test: `test/app/design/undo_toast_test.dart`, `test/app/apple_visual/glass_capture_budget_toast_test.dart`. The toast test is its own file, with one test: phone sheet + toast.
- Test: `test/app/apple_visual/glass_capture_budget_desktop_toast_test.dart`, its own file.

**Interfaces:**
- Produces: `void showUndoToast(BuildContext context, {required String message, required VoidCallback onUndo, String undoLabel = 'برگرداندن', Duration visibleFor = const Duration(seconds: 5), double bottomOffset = 24})`.

Behaviour:
- **Where it goes:** an `OverlayEntry` in `Overlay.of(context, rootOverlay: true)`, wrapped in `GlassOverlayContent`.
- **One at a time:** a module-level `_current` entry is removed immediately when a new toast is shown.
- **Layout:** positioned bottom-centre at `bottomOffset + viewPadding.bottom`, max width 420, horizontal inset 16.
  - Surface: `AppGlass(role: GlassRole.chrome, shape: capsule)`, padding horizontal 16, vertical 10.
  - Content: the message (`callout`, `primary`), then a `GlassButton(variant: plain, label: undoLabel)`. That button is flat, because it sits on glass.
- **Entrance:** it rises 16 px and fades in, both driven by one controller with `SpringCurve(AppMotion.standard)`.
- **Auto-hide:** after `visibleFor`, it exits along the same path in 0.7 × the entrance time.
- **Undo:** pressing it calls `onUndo` and exits immediately.
- **Reduced motion:** opacity only, over `AppMotion.reduced`.
- **Semantics:** `liveRegion: true`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/app/design/undo_toast_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _launcher(VoidCallback onUndo, {String message = 'کار حذف شد'}) => Builder(
  builder: (context) => GlassButton(label: 'حذف', onPressed: () => showUndoToast(context, message: message, onUndo: onUndo)),
);

void main() {
  for (final v in glassTestVariants) {
    testWidgets('shows (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(_launcher(() {}), brightness: v.brightness, textScale: v.textScale, overlayBackdrop: true));
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(find.text('کار حذف شد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rises from 16 px below, auto-hides after 5 s', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(() {}), overlayBackdrop: true));
    await tester.tap(find.text('حذف'));
    await tester.pump();
    final start = tester.getRect(find.text('کار حذف شد')).top;
    await tester.pumpAndSettle();
    final settled = tester.getRect(find.text('کار حذف شد')).top;
    expect(start - settled, closeTo(16, 1.5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('کار حذف شد'), findsNothing);
  });

  testWidgets('undo calls back and closes; a new toast replaces the old', (tester) async {
    var undone = 0;
    await tester.pumpWidget(glassTestApp(_launcher(() => undone++), overlayBackdrop: true));
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(find.text('کار حذف شد'), findsOneWidget);
    await tester.tap(find.text('برگرداندن'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('کار حذف شد'), findsNothing);
  });

  testWidgets('glass is one chrome capsule; the undo button is flat', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(() {}), overlayBackdrop: true));
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppGlass), findsNWidgets(2)); // launcher + toast
  });

  testWidgets('reduced motion: fade only', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(() {}), reduceMotion: true, overlayBackdrop: true));
    await expectNoMovement(tester, within: find.byType(Overlay).first, trigger: () => tester.tap(find.text('حذف')));
    expect(find.text('کار حذف شد'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('live region semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_launcher(() {}), overlayBackdrop: true));
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('کار حذف شد')), matchesSemantics(isLiveRegion: true, label: 'کار حذف شد'));
    handle.dispose();
    await tester.pump(const Duration(seconds: 6));
  });
}
```

Both budget files follow the overlay budget test from Task 6.
- **`glass_capture_budget_toast_test.dart`:** phone with the sheet open (settled), then the toast shown, counting 30 frames during the toast's entrance. Assert `≤ 3`.
- **`glass_capture_budget_desktop_toast_test.dart`:** `GlassProbeScene.desktopWithToastTrigger()` at 1440 × 900, with the toast shown and 30 frames counted. Assert `≤ 4`.
- Each prints `LG_CAPTURES scene=… path=fake max=N`.

The semantics matcher may need extra flags in this Flutter version. Add only flags the toast really has. Never drop `isLiveRegion`.

- [ ] **Steps 2–4:** RED, implement, GREEN. Then the full suite, analyze and format.

- [ ] **Step 5: Commit** with the message `feat(design): UndoToast in the overlay backdrop group`.

---

### Task 8: Row insert and remove transitions

**Files:**
- Create: `lib/app/design/patterns/glass_row_transitions.dart`. Modify `design.dart`.
- Test: `test/app/design/glass_row_transitions_test.dart`

**Interfaces:**
- Produces:
  - `Widget glassRowInsert(BuildContext context, Animation<double> animation, Widget child)` and `Widget glassRowRemove(BuildContext context, Animation<double> animation, Widget child)`. Both are builders for `AnimatedList` and `SliverAnimatedList`.
  - `const Duration glassRowInsertDuration` and `const Duration glassRowRemoveDuration`.

Behaviour (motion spec §3, GlassRow insert and remove):
- **Insert.** Use `SizeTransition` (axis vertical, `axisAlignment: -1`) driven by `CurvedAnimation(parent: animation, curve: SpringCurve(AppMotion.standard))`. Inside it, a `FadeTransition` runs over the first `AppMotion.quick` portion (`Interval(0, quick / insertDuration)`). Set `glassRowInsertDuration = SpringCurve.settleDuration(AppMotion.standard)`. Because `settleDuration` is not const, expose it as a `final` top-level and say so in the doc comment.
- **Remove.** The ghost fades out and shrinks to scale 0.96 over its first 180 ms. Its slot collapses with `SizeTransition` (standard spring). Visually, siblings close the gap with `standard` while the ghost fades. `glassRowRemoveDuration` is the same as insert.
- **Reduced motion.** Both builders check `MotionScope.reducedOf(context)`:
  - insert: `FadeTransition` only, with the slot at full size immediately (no `SizeTransition`, or `sizeFactor` pinned at 1);
  - remove: `FadeTransition` only, and the slot is removed at the end of the fade, so siblings jump once.
  - Callers pass `AppMotion.reduced.duration` as the `AnimatedList` duration under reduced motion. Expose `Duration glassRowDuration(BuildContext context)` to make that easy.

- [ ] **Step 1: Write the failing tests**

```dart
// test/app/design/glass_row_transitions_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

final _listKey = GlobalKey<AnimatedListState>();

Widget _row(String label) => SizedBox(
  height: 56,
  child: AppGlass(role: GlassRole.row, child: Center(child: AppText(label))),
);

Widget _list(List<String> items) => SizedBox(
  height: 400,
  width: 300,
  child: GlassScope(
    kind: GlassLayerKind.content,
    child: AnimatedList(
      key: _listKey,
      initialItemCount: items.length,
      itemBuilder: (context, i, animation) => glassRowInsert(context, animation, _row(items[i])),
    ),
  ),
);

void main() {
  testWidgets('insert opens the slot while fading in', (tester) async {
    final items = ['یک', 'دو'];
    await tester.pumpWidget(glassTestApp(_list(items)));
    items.insert(1, 'نو');
    _listKey.currentState!.insertItem(1, duration: glassRowDuration(tester.element(find.byType(AnimatedList))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = tester.widget<SizeTransition>(find.byType(SizeTransition).at(1)).sizeFactor.value;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));
    await tester.pumpAndSettle();
    expect(find.text('نو'), findsOneWidget);
  });

  testWidgets('remove: ghost fades and shrinks, slot collapses', (tester) async {
    final items = ['یک', 'دو', 'سه'];
    await tester.pumpWidget(glassTestApp(_list(items)));
    final removed = items.removeAt(1);
    _listKey.currentState!.removeItem(
      1,
      (context, animation) => glassRowRemove(context, animation, _row(removed)),
      duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final ghost = find.ancestor(of: find.text('دو'), matching: find.byType(ScaleTransition));
    final scale = tester.widget<ScaleTransition>(ghost.first).scale.value;
    expect(scale, lessThan(1));
    expect(scale, greaterThanOrEqualTo(0.96));
    await tester.pumpAndSettle();
    expect(find.text('دو'), findsNothing);
    expect(tester.getTopLeft(find.text('سه')).dy, lessThan(120));
  });

  testWidgets('reduced motion: fade only, no size or scale', (tester) async {
    final items = ['یک', 'دو'];
    await tester.pumpWidget(glassTestApp(_list(items), reduceMotion: true));
    await expectNoMovement(
      tester,
      within: find.byType(AnimatedList),
      trigger: () async {
        items.insert(1, 'نو');
        _listKey.currentState!.insertItem(1, duration: glassRowDuration(tester.element(find.byType(AnimatedList))));
      },
    );
    await tester.pumpAndSettle();
    expect(find.text('نو'), findsOneWidget);
  });
}
```

- [ ] **Steps 2–4:** RED, implement, GREEN. Then the full suite, analyze and format.

- [ ] **Step 5: Commit** with the message `feat(design): row insert and remove transitions`.

---

### Task 9: Appearance section in Settings

**Files:**
- Create: `lib/features/settings/presentation/appearance_section.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`. Insert `const AppearanceSection()` above `LegacyImportSection()`, with a 20 px gap.
- Test: `test/features/settings/appearance_section_test.dart`

**Interfaces:**
- Consumes:
  - `appearancePreferencesProvider` with `setMode`, `previewGlassIntensity`, `commitGlassIntensity`, `setReduceMotion` and `setReduceTransparency`;
  - `GlassSegmented`, `GlassToggle`, `AppText` and `AppIcon`;
  - `formatPersianPercent`.

Layout (the `PhoneSettings` board «ظاهر» section):
- **Section title** «ظاهر»: `footnote` w800 in `primary`, margin 0 12 6.
- **Panel**: `AppGlass(role: GlassRole.panel, shape: rounded(AppRadii.card))` with horizontal padding 16. Inside the panel:
  1. **Theme mode.** `GlassSegmented<AppearanceMode>` with the labels روشن / تیره / خودکار, `semanticLabel: 'حالت ظاهری'`, margin 12 top and 10 bottom. It is on glass, so it renders flat with a white thumb.
  2. **Glass intensity.**
     - A row with «شدت شیشه» (`callout` w600) and the value `formatPersianPercent(intensity)` (`textSecondary`).
     - Below it, 6 px down, a row: `AppIcon(Icons.blur_on, tone: secondary)`, a `Slider` (expanded) and `AppIcon(Icons.blur_off, tone: secondary)`.
     - The `Slider` takes `value: intensity`, `onChanged: previewGlassIntensity`, `onChangeEnd: (_) => commitGlassIntensity()` and `semanticFormatterCallback: formatPersianPercent`.
     - Style it with a `SliderTheme`: active track `colors.accent`, inactive track `colors.switchOff`, thumb `colors.thumbSurface`, track height 4, thumb radius 12, overlay transparent.
     - Below that, the caption «کم‌شدت‌تر یعنی شفاف‌تر و ساده‌تر؛ پرشدت‌تر یعنی خواناتر.» (`footnote`, `textSecondary`), margin top 4 and bottom 12.
  3. **Switch rows.** Two rows styled like the `PhoneNotifications` switch row: minimum height 56, a hairline top border (`colors.hairline` 0.5 px), title `callout` w700, subtitle `footnote` `textSecondary`, and a `GlassToggle` at the end.
     - «کاهش حرکت», with the subtitle «حرکت‌ها به محو شدن ساده تبدیل می‌شوند»;
     - «کاهش شفافیت», with the subtitle «کارت‌ها و ردیف‌ها مات می‌شوند؛ نوارها شیشه می‌مانند».

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/settings/appearance_section_test.dart
import 'package:borj/app/design/design.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/data/in_memory_appearance_preferences_store.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:borj/features/settings/presentation/appearance_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

Future<InMemoryAppearancePreferencesStore> _pump(WidgetTester tester, {Brightness b = Brightness.light, double scale = 1}) async {
  final store = InMemoryAppearancePreferencesStore();
  await tester.pumpWidget(ProviderScope(
    overrides: [appearancePreferencesStoreProvider.overrideWithValue(store)],
    child: glassTestApp(const SizedBox(width: 390, child: SingleChildScrollView(child: AppearanceSection())), brightness: b, textScale: scale),
  ));
  return store;
}

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders the board section (${v.name})', (tester) async {
      await _pump(tester, b: v.brightness, scale: v.textScale);
      expect(tester.takeException(), isNull);
      for (final t in ['ظاهر', 'روشن', 'تیره', 'خودکار', 'شدت شیشه', '۵۰٪', 'کاهش حرکت', 'کاهش شفافیت']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });
  }

  testWidgets('one panel glass; everything inside is flat', (tester) async {
    await _pump(tester);
    expect(find.byType(AppGlass), findsOneWidget);
  });

  testWidgets('mode segment and switches write preferences', (tester) async {
    final store = await _pump(tester);
    await tester.tap(find.text('تیره'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GlassToggle).first);
    await tester.tap(find.byType(GlassToggle).last);
    await tester.pumpAndSettle();
    final saved = await store.load();
    expect(saved.mode, AppearanceMode.dark);
    expect(saved.reduceMotion, isTrue);
    expect(saved.reduceTransparency, isTrue);
  });

  testWidgets('slider previews while dragging and saves on release', (tester) async {
    final store = await _pump(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(AppearanceSection)));
    final slider = find.byType(Slider);
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(const Offset(-60, 0)); // RTL: left increases
    await tester.pump();
    final previewed = container.read(appearancePreferencesProvider).glassIntensity;
    expect(previewed, isNot(0.5));
    expect((await store.load()).glassIntensity, 0.5, reason: 'no save while dragging');
    await gesture.up();
    await tester.pump();
    expect((await store.load()).glassIntensity, previewed);
  });

  testWidgets('semantics increase commits', (tester) async {
    final handle = tester.ensureSemantics();
    final store = await _pump(tester);
    final id = tester.getSemantics(find.byType(Slider)).id;
    tester.binding.pipelineOwner.semanticsOwner!.performAction(id, SemanticsAction.increase);
    await tester.pump();
    expect((await store.load()).glassIntensity, greaterThan(0.5));
    handle.dispose();
  });
}
```

If `semanticsOwner!.performAction` is not reachable this way in 3.47.5, use `tester.semantics.performAction` with `find.semantics.byLabel('شدت شیشه')` and report the API you used. The assertion stays the same.

- [ ] **Steps 2–4:** RED, implement, GREEN. Also run `test/features/settings/` and the existing settings-screen tests. Then the full suite, analyze and format.

- [ ] **Step 5: Commit** with the message `feat(settings): appearance section (mode, glass intensity, reduce motion, reduce transparency)`.

---

### Task 10: Review page for primitives and patterns, plus board images

**Files:**
- Create: `lib/app/apple_visual/review/design_review_samples.dart`
- Modify: `lib/app/apple_visual/review/glass_review_screen.dart`. Add a "Design" section that renders every sample in light and dark side by side, over `AppBackground`, and pairs each with its board PNG.
- Modify: `docs/superpowers/references/2026-11-05-glass-mockups/source/shoot.py`. Fix the source path (see below).
- Test: extend `test/app/apple_visual/glass_review_screen_test.dart`.

**Interfaces:**
- Produces:
  - `final class DesignReviewSample { const DesignReviewSample({required this.label, required this.board, required this.build}); final String label; final String board; final WidgetBuilder build; }`. `board` is a board file name without its extension, for example `PhoneSettings`.
  - `const List<DesignReviewSample> designReviewSamples`, or `final` if the builders are closures.

Samples, at least these, each with its board:
- `GlassButton` ×3 variants off glass, and on a panel (`PhoneTasks`);
- `GlassSegmented` off glass (`PhoneTasks`) and on glass (`PhoneSettings`);
- `GlassToggle` on and off (`PhoneNotifications`);
- `GlassChip` (`PhoneTasks`);
- `GlassTextField` (`PhoneQuickEntry`);
- `ProgressTrack` with 4 tones (`PhoneBudgets`);
- `RoundCheck` (`PhoneTasks`);
- `AnimatedNumber` with a button that adds ۱٬۲۰۰ (`PhoneMoney`);
- the sheet, from a button (`PhoneAddTxn`);
- the toast, from a button (`PhoneTasks`);
- the row insert/remove demo (`PhoneTasks`);
- the Appearance section (`PhoneSettings`);
- **Glow-corner contrast** (`Main`): in dark only, a `GlassRole.panel` placed at the top leading corner of a dark `AppBackground`, so it sits on the warm glow. It holds a line of text in each tone: primary, secondary, link, success, warn, danger and purple. The owner judges readability there (final review M2).

The board image: when `GLASS_REFERENCE_DIR` is set, the screen looks for `<dir>/<board>.png` and `<dir>/<board>Dark.png` and shows them under the pair. When they are missing, it shows the text `board: <board>`.

`shoot.py` path fix: replace `P=os.path.join(D,'..','allscreens','project')` with
`P=os.path.join(D,'..') if os.path.exists(os.path.join(D,'..','Main.dc.html')) else os.path.join(D,'..','allscreens','project')`.
Then document the command in the screen's doc comment:
`python3 docs/superpowers/references/2026-11-05-glass-mockups/source/shoot.py /tmp/borj-boards PhoneTasks PhoneTasksDark …` and run with `--dart-define=GLASS_REFERENCE_DIR=/tmp/borj-boards`.

- [ ] **Step 1: Write the failing test additions**

```dart
  testWidgets('design section renders every sample in light and dark', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: GlassReviewScreen(referenceDir: null)));
    await tester.pump();
    for (final sample in designReviewSamples) {
      await tester.scrollUntilVisible(find.text(sample.label), 300);
      expect(find.text(sample.label), findsOneWidget);
      expect(find.text('board: ${sample.board}'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  test('every sample names an existing board', () {
    for (final s in designReviewSamples) {
      expect(File('docs/superpowers/references/2026-11-05-glass-mockups/${s.board}.dc.html').existsSync(), isTrue, reason: s.board);
    }
  });
```

Add `import 'dart:io';` and the samples import. If the review screen is a `ListView` with off-screen children, `scrollUntilVisible` needs the scrollable finder; pass `scrollable: find.byType(Scrollable).first`.

- [ ] **Step 2: Run the board shooter once to check the path fix.** Run `python3 docs/superpowers/references/2026-11-05-glass-mockups/source/shoot.py /tmp/claude-1000/borj-boards PhoneSettings`. Expect `/tmp/claude-1000/borj-boards/PhoneSettings.png`. If `google-chrome` is missing, report that; do not install anything.

- [ ] **Steps 3–4:** implement, then GREEN. Run the full suite, analyze and format.

- [ ] **Step 5: Commit** with the message `feat(review): design samples with board pairing and glow-corner contrast`.

---

### Task 11: Device probe during interaction

**Files:**
- Modify: `integration_test/glass_perf_probe_test.dart`

Add two cases to the probe file, after the existing two. Keep phone before desktop, which the rising-count rule requires.
1. `phoneWithSheetTrigger`: open the sheet and count captures through 30 frames of the open animation, then show the toast and count again. Budget ≤ 3. Then fling the content behind the open sheet for 3 s inside `watchPerformance` (`reportKey: 'glass_probe_phone_overlay'`).
2. `desktopWithToastTrigger`: show the toast and count captures. Budget ≤ 4. Then run `watchPerformance` for 3 s of flings (`reportKey: 'glass_probe_desktop_overlay'`).

The capture `expect` stays debug-only, and the raster gate (≤ 8 ms) stays profile-only, as in Part A. Each case prints `LG_CAPTURES … path=real` and `LG_PERF …`.

- [ ] **Step 1: Implement**, following the existing cases in the file.
- [ ] **Step 2: Run `tool/ci.sh --device`**. Expect PASS, with every `LG_CAPTURES path=real` line within budget.
- [ ] **Step 3: Run** `flutter drive --profile -d linux --driver=test_driver/integration_test.dart --target=integration_test/glass_perf_probe_test.dart`. Expect every profile `raster_p90_ms` ≤ 8.
- [ ] **Step 4: Commit** with the message `test(glass): device probe with sheet and toast during interaction`.
- [ ] **Step 5: Report** all `LG_CAPTURES` and `LG_PERF` lines.

---

### Task 12 (controller): Phase 1 checkpoint and owner sign-off

Done by the main session, not by a subagent.

- [ ] Write `docs/superpowers/checkpoints/2026-11-0X-redesign-phase-1-checkpoint.md`. It records:
  - what Phase 1 delivered (Parts A and B);
  - commits;
  - test counts;
  - the analyzer, format and `tool/ci.sh --device` results;
  - every `LG_CAPTURES` and `LG_PERF` number, both fake and real;
  - the decisions of both plans;
  - deferred minors, with their rulings;
  - the open items: the A34 profile run (owner's phone), and the owner's perceptual sign-off on the review page.
- [ ] Add a WORKLOG entry and update the roadmap (§0 item 2 redesign status, §14 resume line).
- [ ] Ask the owner, in Persian:
  - review the design section of the review page, both light and dark, next to the board images;
  - check the glow-corner sample;
  - and say whether an A34 profile build should be prepared now or after Phase 2.
