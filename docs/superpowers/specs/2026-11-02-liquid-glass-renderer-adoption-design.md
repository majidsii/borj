# Liquid Glass Renderer Adoption — Design

**Date:** 2026-11-02
**Status:** APPROVED BY OWNER (2026-11-02)
**Supersedes:** the Gate C custom-renderer path
(`2026-09-06-gate-c-custom-liquid-glass-renderer-design.md`,
`2026-09-06-gate-c-shader-parameter-lifecycle-design.md`) and the
pixel-golden acceptance rules of
`2026-08-09-apple-liquid-glass-fidelity-contract.md` for glass rendering.

## 1. Why the direction changes

Gate C has run since 2026-08-16 (≈40 commits). At this design's date:

- `shaders/apple_liquid_glass.frag` is a passthrough: it samples the backdrop
  and returns it unchanged. No uniform affects the output.
- No feature screen uses `AppleLiquidGlass` (`lib/features` → 0 imports of
  `apple_visual`). All screens still use `OriginalGlass`.
- The acceptance gate compares against goldens exported from the design tool's
  proprietary Custom Glass renderer. The measured gap was 61.33 % of pixels
  (`2026-09-02-gate-c-renderer-compositor-blur-blocker.md`). Pixel identity with
  another renderer's blur and refraction cannot be reached with any Flutter
  shader, so the gate cannot pass by construction.

A maintained open-source renderer now targets the same visual system:
`liquid_glass_renderer` 1.0.0-dev.2 (whynotmake-it, Apache-2.0, published
2026-10-27). It is fitted against captures of Apple's iOS 27 glass and ships
`ios27Regular` / `ios27Clear` presets, bevel refraction, frost, glint, contour,
shape blending (`GlassEffectContainer` equivalent), stretch, and glow.

## 2. Goal

The app's navigation and control layer renders Liquid Glass that a person
cannot tell apart from Apple's on-device glass in a side-by-side comparison,
on Android and on Linux desktop (primary), with macOS and Windows following.

## 3. Changed rules

These rules from `PROJECT_ROADMAP.md` and the fidelity contract are replaced
for this work. The roadmap records the change.

| Old rule | New rule |
| --- | --- |
| Do not run `flutter upgrade`. | The project moves to Flutter 3.47.x, but only after the spike passes, and only by changing `.flutter-version` on merge. The shared SDK at `~/develop/flutter` is never upgraded in place. |
| Apple design-tool goldens are the pixel acceptance authority. | Acceptance is perceptual: a side-by-side comparison with real iOS 27 / macOS 27 captures, judged by the owner. Design-kit tokens (color, typography, metrics, radii) stay source-derived. |
| Never fall back silently from custom glass. | The package falls back to `FakeGlass` where full glass is unavailable. That is allowed at runtime, but on every platform we claim as supported, a test fails if full glass is not active. |

## 4. Step 0 — Spike (go / no-go)

The spike runs before any production change. It produces a short report
(`docs/superpowers/references/<spike-date>-liquid-glass-spike-report.md`) with
numbers and screenshots.

### 4.1 Isolated SDK

- Create a second Flutter checkout at a 3.47.x tag (3.47.5 exists in the local
  Flutter clone), e.g. `git clone --shared ~/develop/flutter
  ~/develop/flutter-3.47.5 && git -C ~/develop/flutter-3.47.5 checkout 3.47.5`.
  Call it by absolute path. Do not touch `~/develop/flutter`.
- Work in a separate git worktree on a `spike/liquid-glass` branch.
- First checks:
  - its Dart version satisfies the package's `sdk: >=3.13.0 <3.14.0`;
  - the `storage.flutter-io.cn` / `pub.flutter-io.cn` mirrors serve that SDK's
    artifacts and the package's dependencies;
  - the existing suite (`flutter analyze`, `flutter test`) passes on 3.47.x.
    Regressions are listed in the report, not fixed in the spike.

### 4.2 Questions the spike must answer

Each answer is objective.

1. **Full glass on Linux, shipping configuration.** A Linux **release** build,
   launched with no CLI flags (as an installed `.deb` would be), runs Impeller
   with Flutter GPU and renders full glass, not `FakeGlass`. If no supported
   way exists to enable Impeller + Flutter GPU in the Linux runner without CLI
   flags, the Linux answer is "no".
2. **Full glass on Android release.** Enabled through the
   `io.flutter.embedding.android.EnableFlutterGPU` manifest meta-data.
3. **Build hooks.** The package's native-asset hooks (`hooks`,
   `flutter_gpu_shaders`) build on Linux and Android.
4. **Windows.** Same check as 1. If it can't be done in the spike, Windows is
   marked **unverified** in the report and the release notes.
5. **Performance.** Frame build and raster times in profile mode on a screen
   shaped like the real dashboard (sidebar + bottom bar + 4–6 glass controls
   over scrolling content). Record p50/p90 raster time on the owner's Linux
   machine and on one Android device.

### 4.3 Detecting full glass vs FakeGlass

The package has no obvious public "active path" flag. In order of preference:

1. a public API or the package's `lgr.render*` logs that state the path, if the
   spike finds one that is stable;
2. otherwise a pixel test: a high-contrast vertical-stripe backdrop under the
   glass edge. Full glass displaces stripes inside the bevel (refraction
   amount ≈ 60, bevel ≈ 20 logical px); `FakeGlass` leaves them straight. The
   test samples the bevel zone and asserts that stripe phase has shifted.

### 4.4 Decision

- **Go:** questions 1–3 pass and performance is acceptable (≤ 8 ms p90 raster on
  the Linux machine; owner judgment on Android).
- **No-go on Linux only:** come back to the owner with the report and choose
  between `liquid_glass_renderer` 0.2.x (an `ImageFilter.shader` path, which
  the local probe showed works on Linux with Impeller), `FakeGlass` on desktop,
  or a project-owned Linux path.
- **No-go overall:** stop and re-plan.

## 5. Architecture (after Go)

```
feature screens
  → AppleLiquidGlass            (our public API, unchanged shape)
  → AppleGlassAdapter           (role/state/theme → package settings)
  → liquid_glass_renderer       (pinned: exactly 1.0.0-dev.2)
```

- Screens never import `liquid_glass_renderer`. Only the adapter does.
- `AppleGlassRole` maps to package presets:
  - `smallControl`, `overGlassControl` → `ios27Regular`, capsule/oval shapes;
  - `tintedSmallControl` → `ios27Regular` appearance with tint;
  - `mediumSurface`, `largeSurface` → `ios27Regular` (toolbar / bar sizing).
  - Clear material is exposed only if a screen needs it.
- Sibling controls share one `LiquidGlassLayer` (max 16 shapes per layer; each
  extra layer re-samples the backdrop).
- `tintAmount` (the iOS 27 "Liquid Glass" slider) becomes an app setting with
  a fixed default for now; a settings UI comes later.
- `LiquidGlass.precache()` runs during bootstrap.
- The package version is pinned exactly (no caret): its dev line has already
  replaced the whole API once.
- Kept: `lib/app/apple_visual/foundation/**` tokens that screens use (colors,
  typography, metrics, motion, platform family).
- Removed, in the implementation plan and only after Go:
  `lib/app/apple_visual/rendering/**`, `shaders/apple_liquid_glass*.frag`,
  their tests under `test/app/apple_visual`, the `integration_test` probe once
  replaced, and every `tool/verify_*` script that references them.
- Generated source files shrink to what code references (the metrics file is
  18 199 lines today). That trim is its own plan step.

## 6. Where glass goes

Following Apple's usage, glass is the navigation and control layer, never
content:

- sidebar (desktop) and tab bar (mobile);
- toolbars and primary buttons;
- sheets, dialogs, popovers, menus;
- floating action controls.

Content cards (finance summaries, task cards, lists, charts) stay solid
materials. This matches Apple and keeps the number of layers small.

## 7. Platform enablement

| Platform | Mechanism | Verified by |
| --- | --- | --- |
| Android | `EnableImpeller` (default) + `EnableFlutterGPU` manifest meta-data | spike Q2 |
| Linux | determined by spike Q1 (runner/engine switch) | spike Q1 |
| macOS | `FLTEnableFlutterGPU` (+ `FLTEnableWideGamut`) in `Info.plist` | build + manual run |
| Windows | determined by spike Q4, else unverified | spike Q4 |

## 8. Testing

- **Adapter unit tests:** role/state/theme → expected package settings.
- **Widget tests:** screens build with the adapter. `flutter test` runs without
  a GPU and the package uses `FakeGlass` there; widget tests do not assert on
  rendering path.
- **Integration test, Linux and Android:** the full-glass detection from 4.3
  runs on a real device. It fails, never skips, when full glass is not active.
- **Side-by-side review page:** a debug-only route showing our controls next to
  reference captures of iOS 27 / macOS 27 glass over the same backdrops, light
  and dark. The owner signs off from this page.
- **Performance check:** the profile-mode measurement from 4.2 Q5 is repeated
  on the real dashboard after rollout.

## 9. Out of scope

- CI / release automation (separate sub-project, scheduled first in the
  program order).
- v1 → v2 data import, renaming, packaging (v2 release readiness sub-project).
- New features (habits, goals, Task 2.9+).

## 10. Risks

- **Flutter GPU is a preview API.** Mitigation: exact version pin, adapter
  boundary, FakeGlass fallback at runtime.
- **The package is pre-1.0 and young.** Mitigation: Apache-2.0 allows a vendored
  fork if upstream breaks or stalls.
- **Linux is untested upstream.** Mitigation: the spike decides before any
  production change.
- **macOS 27 desktop look differs from iOS 27 presets.** The presets are a
  starting point; desktop tuning happens on the side-by-side page.
- **Apple design-resource license.** The kit's terms appear to limit use to
  designing for Apple platforms. The renderer reproduces the look with its own
  code, and tokens are generic values, but the owner should read the license
  before a wider public release.
