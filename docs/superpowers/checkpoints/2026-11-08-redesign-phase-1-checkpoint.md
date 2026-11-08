# Checkpoint — Redesign Phase 1 (foundation + primitives), 2026-11-08

Spec: `docs/superpowers/specs/2026-11-05-liquid-glass-redesign-design.md` (§10 Phase 1)
and `docs/superpowers/specs/2026-11-06-motion-and-today-customization-design.md`.
Plans: `docs/superpowers/plans/2026-11-07-redesign-phase-1a-foundation.md` (Part A),
`docs/superpowers/plans/2026-11-07-redesign-phase-1b-primitives.md` (Part B).
Ledger (every agent, review, ruling and deferred minor):
`docs/superpowers/references/2026-11-07-phase-1b-progress-ledger.md`.

## What Phase 1 delivered

**Part A — foundation** (commits `b12e53b`..`ec144d4`, merged before Part B; base `410076d`):
- appearance preferences (`borj-preferences.json`, loaded before `runApp`, never throws, serialized saves);
- `AppTheme` tokens and `AppBackground`; `AppMotion` and `MotionScope`;
- `AppGlass`, `GlassScope`, `GlassBackdropGroup`, `GlassInner`, `GlassPreferencesScope`, reduce-transparency fallback, renderer import boundary test;
- probe scenes, capture-budget tests and the device perf probe.

**Part B — primitives and patterns** (branch `feat/redesign-phase-1b`, `410076d..HEAD`):
- Task 1: on-glass marker (`GlassContext.isOnGlass`, no glass on glass, asserted), overlay backdrop group (`GlassOverlayBackdrop` + `GlassOverlayContent`), Part B colour tokens, capture log v2 (fails on the 16-shape warning), test helpers.
- Task 2: `AppText`, `AppIcon`, `Pressable`, `GlassButton`.
- Task 3: `GlassToggle`, `GlassSegmented`, `GlassChip`.
- Task 4: `GlassTextField`, `ProgressTrack`, `RoundCheck`.
- Task 5: Persian formatting (`٬`, `٪`, Persian digits) and `AnimatedNumber`.
- Task 6: `GlassSheet` (a `PopupRoute`: grows from the trigger, 1:1 drag from the painted pose, velocity/60 % dismiss, spring-back).
- Task 7: `UndoToast` (root overlay, one at a time) and `GlassVisibility` (multiplicative; glass fades through the renderer, never a parent opacity).
- Task 8: row insert/remove transitions with `SpringCurve`.
- Task 9: Appearance section in Settings (mode, glass intensity with preview/commit, reduce motion, reduce transparency).
- Task 10 + samples: review page design samples (board pairing, glow-corner contrast, sheet, toast, rows).
- Task 11: device probe during interaction (sheet open + toast on phone, toast on desktop).
- Final whole-branch review (opus) and fix wave (see below).

## Verification (at `1d4f747`, the merge of the final fix wave)

- `dart format --output=none --set-exit-if-changed lib test integration_test`: exit 0.
- `flutter analyze`: no issues.
- `flutter test --exclude-tags device`: 1619 passed, 1 skipped.
- `tool/ci.sh --device`: exit 0 (`glass_perf_probe_test` +4, `glass_shape_limit_sanity_test` +1, `liquid_glass_full_glass_test` +2).

### Captures per frame (budget: phone ≤ 3, desktop ≤ 4)

FakeGlass (`flutter test`): Part A phone 2 / desktop 3; Part B phone + sheet + toast 3, desktop + toast 4, reduced-motion sheet 3.

Real glass (Linux device, `tool/ci.sh --device`):
```
LG_CAPTURES scene=phone path=real max=2
LG_CAPTURES scene=desktop path=real max=3
LG_COMPOSITED scene=phoneWithSheetTrigger sheet=3 sheet_naive=4 toast=3 toast_naive=5 active_seeded_passes=4
LG_CAPTURES scene=phoneWithSheetTrigger path=real max=3
LG_COMPOSITED scene=desktopWithToastTrigger toast=4 toast_naive=6 active_seeded_passes=6
LG_CAPTURES scene=desktopWithToastTrigger path=real max=4
```
`*_naive` is the pre-`b5a7120` count, kept in the output to show why the two differ (see Decisions, D4).

### Raster p90 (gate: ≤ 8 ms on the Linux dev machine)
```
debug:   phone 1.77  desktop 1.205  phoneWithSheetTrigger 1.952  desktopWithToastTrigger 1.439
profile: phone 1.075  desktop 1.331  phoneWithSheetTrigger 2.119  desktopWithToastTrigger 1.152
```
Profile: `flutter drive --profile -d linux --driver=test_driver/integration_test.dart --target=integration_test/glass_perf_probe_test.dart` at `1d4f747`, +6 passed. Capture counts print 0/1 in profile because `debugLayer` and the renderer's counter exist only in debug builds; the capture `expect`s are debug-only by design.
Part A profile: phone 1.028 ms, desktop 0.864 ms.

## Decisions

Plan decisions (Part B plan §"Decisions recorded by this plan"): 1 on-glass marker; 2 own group marker + root `GlassOverlayBackdrop` (one capture for all overlays); 3 sheets are routes; 4 toasts in the root overlay; 5 switch-off colour `switchOff`; 6 Appearance section rows; 7 `AnimatedNumber`; 8 board PNGs outside the repo; 9 A34 run open. Part A decisions are in its plan.

Controller rulings during Part B:
- D1. The shape-limit sanity check runs on real glass (`integration_test/glass_shape_limit_sanity_test.dart`); budget tests use a structural guard.
- D2. Captures are counted on the composited layer tree (`test/support/backdrop_layer_count.dart`), because the renderer's debug counter misses layers that do not repaint (a page under a popup).
- D3. Glass is never faded by a parent `Opacity`/`FadeTransition` (it seeds an extra capture and only fades the children): sheet, toast, rows and disabled/pressed glass buttons fade through `GlassVisibility`. This superseded an earlier "+1 capture during a reduced fade" allowance; all budgets are plain.
- D4. On a device the renderer paints glass inside seeded passes: the inner filter drops its key and reads the pass; the pass's seed carries the key and is the one root capture. The counter mirrors `SeededBackdropPassLayer.addToScene` (`b5a7120`). The spec's "independent captures" means root reads; in-pass reads are pass-sized and covered by the raster gate.
- D5. Mid-open sheet dismiss is relative to the drag (accepted at Task 6 round 2).
- D6. Owner, 2026-11-07: «همه چیز باید کامل بشه بعدا منتشر میکنیم» — v2 ships only after the full redesign (phases 1–5) and release readiness; no interim release with the current look.

## Final review and fix wave

Whole-branch review (opus): approved with fixes. Fixed and merged:
- Row transitions bare-faded glass → `GlassVisibility` (`df4ee41`).
- `Pressable` dimmed glass with `Opacity` (+1 capture when disabled; label-only dim in scopes) → `dimsGlass` through `GlassVisibility`, constant wrapper (`a47141f`).
- Reduced-motion sheet drag release still moved → snaps / holds pose (`88f36c6`); reduced fade keeps its curve direction mid-run (`73f1074`).
- Non-flipped reduced reverse curves (read as ease-in) at sheet, rows and `RoundCheck` (`88f36c6`, `df4ee41`, `5d4eae2`).
- Toast replaced in the old toast's last exit frame removed its entry twice (`2c0af6a`).
- Tokens: `RoundCheck` duration, Appearance section colours and spacing (`5d4eae2`, `287cc2f`; spacing 6→8 and 10→12, Phase 5 rebuilds the screen).
- Tests: variant matrix for rows and `AppText`, reduce-transparency per primitive family, structural bare-fade check (`64d92a9`); probe scene `toastTrigger` (`7a7d404`).

## Deferred minors (accepted, not blocking)

From the ledger, still open after the fix wave:
- a11y: sheet semantics rects frozen under `Flow` transforms; `GestureDetector` may duplicate tap semantics on the text field; segment icon uses a raw `Icon`.
- Sheet: drag starting on an inner button does not move the sheet; drag-dismiss / close-during-settle slide is linear; settle stops dead after an upward fling; no budget sampling of drag/dismiss phases.
- Toast ignores the keyboard inset (`viewPadding` only).
- `AppText` on-tint uses literal white (should be `thumbSurface`/an on-tint token); `RoundCheck` literal white was fixed in Task 4.
- Overlay inset 6 duplicated in chip and toggle; segmented doesn't resync when the segment list changes at the same index.
- `ProgressTrack`: NaN asserts; `_first` cleared on parent rebuild during enter.
- Missing tests: Space key on `Pressable`, disabled opacity on flat children, touch-no-hover, icon-only circle under stretched constraints, toggle focus ring, segmented resize tracking, `AnimatedNumber` same-value rebuild mid-roll.
- Review page uses own-layer glass per sample (debug page only).
- `CaptureRecord.bareFadeWarned` only trips on a device (FakeGlass has no renderer check); the structural check covers unit tests.

## Open items

- A34 profile run (owner's phone; spec §8 gate ≤ 16 ms).
- Owner's perceptual sign-off on the review page (design section, light and dark, next to the boards; glow-corner sample).
- Merge `feat/redesign-phase-1b` into `feat/v2-complete-dashboard` (fast-forward possible).

## Owner sign-off (2026-11-08)

Asked to look at the review page's design section and the Appearance settings, and to agree to run the A34 profile build after Phase 2 (recommended, since real screens exist then). The owner noted that the main screens still look like the previous version (expected: Phase 1 only builds the primitives; screens move in Phases 2–5), then replied «اوکیه». Recorded as Phase 1 sign-off; the A34 run moves to the Phase 2 checkpoint.
