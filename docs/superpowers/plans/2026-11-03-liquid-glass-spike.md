# Liquid Glass Spike (Step 0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a go/no-go report on whether `liquid_glass_renderer` 1.0.0-dev.2 renders full Liquid Glass in shipping configuration on Linux and Android, with performance numbers.

**Architecture:** All code lives on a throwaway `spike/liquid-glass` branch in its own git worktree, built with a separate Flutter 3.47.5 checkout. A pixel probe (vertical stripes under the glass bevel) tells full glass apart from fallback. The only artifact merged into the main branch is the report.

**Tech Stack:** Flutter 3.47.5 (separate SDK), `liquid_glass_renderer` 1.0.0-dev.2, `integration_test`, Linux GTK runner (`FlDartProject`), Android manifest meta-data.

**Spec:** `docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md` §4.

## Global Constraints

- Never modify, upgrade or switch the channel of the shared SDK at `/home/shabin/develop/flutter`. Use only `/home/shabin/develop/flutter-3.47.5/bin/flutter` (called `$F` below).
- Pin the package exactly: `liquid_glass_renderer: 1.0.0-dev.2` (no caret).
- Spike code is never merged into `feat/v2-complete-dashboard`. Only the report is.
- Do not fix regressions found on 3.47.5 during the spike. List them in the report.
- Pub/storage mirrors: keep the existing environment (`PUB_HOSTED_URL=https://pub.flutter-io.cn`, `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`).
- Go threshold: Linux full glass active in a release build with no CLI flags, Android full glass active, native hooks build, Linux raster p90 ≤ 8 ms on the dashboard-shaped screen.
- Paths: main worktree `/home/shabin/projects/personal/dashboard-shakhsi-v2-integration` (`$MAIN`); spike worktree `/home/shabin/projects/personal/dashboard-shakhsi-spike-liquid-glass` (`$SPIKE`).

---

### Task 1: Isolated SDK and spike worktree, with a 3.47.5 baseline

**Files:**
- Create: `/home/shabin/develop/flutter-3.47.5/` (SDK checkout, outside any repo)
- Create: `$SPIKE` (git worktree, branch `spike/liquid-glass`)
- Create: `$SPIKE/spike-notes.md` (raw evidence log for the report)

**Interfaces:**
- Produces: `$F=/home/shabin/develop/flutter-3.47.5/bin/flutter`; worktree `$SPIKE` on branch `spike/liquid-glass`; `spike-notes.md` with the section headings used by later tasks.

- [ ] **Step 1: Create the SDK checkout**

```bash
git clone /home/shabin/develop/flutter /home/shabin/develop/flutter-3.47.5
git -C /home/shabin/develop/flutter-3.47.5 checkout 3.47.5
/home/shabin/develop/flutter-3.47.5/bin/flutter --version
```

Expected: `Flutter 3.47.5` and a `Dart 3.13.x` line. If Dart is not 3.13.x, stop: the package requires `sdk: >=3.13.0 <3.14.0`. Record the output either way.

- [ ] **Step 2: Confirm the shared SDK is untouched**

```bash
/home/shabin/develop/flutter/bin/flutter --version | head -1
```

Expected: `Flutter 3.44.6`.

- [ ] **Step 3: Create the spike worktree**

```bash
cd $MAIN
git worktree add -b spike/liquid-glass $SPIKE HEAD
```

- [ ] **Step 4: Baseline the existing project on 3.47.5**

```bash
cd $SPIKE
$F pub get
$F analyze 2>&1 | tail -20
$F format --output=none --set-exit-if-changed lib test 2>&1 | tail -5
$F test --reporter=failures-only 2>&1 | tail -40
```

Expected: record the analyzer issue count, whether the 3.47.5 formatter wants changes (CI enforces format), and every failing test name. These are 3.47.5 regressions; do not fix them.

- [ ] **Step 5: Start the evidence log**

Create `$SPIKE/spike-notes.md`:

```markdown
# Liquid Glass spike — raw notes

## SDK
<paste flutter --version for 3.47.5 and 3.44.6>

## 3.47.5 baseline (existing project)
- analyze: <N issues>
- format: <clean | N files would change>
- tests: <pass/fail counts>, failing: <names>

## Q3 native hooks build

## Q1 Linux full glass (release, no flags)

## Q5 performance

## Q2 Android

## Q4 Windows
```

- [ ] **Step 6: Commit**

```bash
cd $SPIKE
git add spike-notes.md
git commit -m "spike: record Flutter 3.47.5 baseline"
```

---

### Task 2: Add the package and prove native hooks build (Q3)

**Files:**
- Modify: `$SPIKE/pubspec.yaml` (dependencies)
- Modify: `$SPIKE/spike-notes.md` (Q3 section)

**Interfaces:**
- Consumes: `$F`, `$SPIKE` from Task 1.
- Produces: the package resolvable as `package:liquid_glass_renderer/liquid_glass_renderer.dart`.

- [ ] **Step 1: Add the exact pin**

In `$SPIKE/pubspec.yaml`, under `dependencies:`, add:

```yaml
  liquid_glass_renderer: 1.0.0-dev.2
```

- [ ] **Step 2: Resolve**

```bash
cd $SPIKE && $F pub get
```

Expected: resolves. If it fails on a mirror 404 for `flutter_gpu_shaders` or the hooks' downloads, record the exact error under Q3 and retry once without the mirror (`PUB_HOSTED_URL= FLUTTER_STORAGE_BASE_URL= $F pub get`). Record which worked.

- [ ] **Step 3: Build Linux release**

```bash
cd $SPIKE && $F build linux --release 2>&1 | tail -20
```

Expected: `✓ Built build/linux/x64/release/bundle/dashboard_shakhsi`. Record success or the exact hook error under Q3.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock spike-notes.md
git commit -m "spike: add liquid_glass_renderer 1.0.0-dev.2"
```

---

### Task 3: Full-glass pixel probe with negative control

The probe puts 8 px black / 8 px white vertical stripes under a glass shape with frost, glint, contour and bevel shadow all 0, so it measures refraction only. In the left bevel, full glass shifts stripe edges off the 8 px grid; refraction 0 (and the FakeGlass fallback) leaves them on it.

**Files:**
- Create: `$SPIKE/integration_test/liquid_glass_full_glass_probe_test.dart`

**Interfaces:**
- Produces: test names `negative control keeps stripes on grid` and `full glass displaces stripes in the bevel`. Later tasks run this file per platform.

- [ ] **Step 1: Write the probe**

```dart
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

const _halfPeriod = 8;
const _canvas = Size(320, 176);
const _glass = Rect.fromLTWH(40, 40, 240, 96);
const _bevelScan = 30;
const _offGridThreshold = 3;

final class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
    final black = Paint()..color = const Color(0xFF000000);
    for (var x = 0; x < size.width; x += _halfPeriod * 2) {
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), 0, _halfPeriod.toDouble(), size.height),
        black,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _scene(GlobalKey boundaryKey, LiquidGlassSettings settings) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox.fromSize(
          size: _canvas,
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _StripePainter())),
              Positioned.fromRect(
                rect: _glass,
                child: LiquidGlassLayer(
                  settings: settings,
                  child: const LiquidGlass(
                    shape: LiquidRoundedSuperellipse(borderRadius: 40),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Canvas x positions of black/white edges along the glass's vertical
/// center, scanning [_bevelScan] px inward from its left edge.
Future<List<int>> _bevelEdges(GlobalKey boundaryKey) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final width = image.width;
  image.dispose();

  final y = _glass.center.dy.round();
  final x0 = _glass.left.round() + 1;
  final luminance = <int>[];
  for (var x = x0; x < x0 + _bevelScan; x++) {
    final o = (y * width + x) * 4;
    luminance.add(
      (bytes.getUint8(o) * 299 + bytes.getUint8(o + 1) * 587 + bytes.getUint8(o + 2) * 114) ~/ 1000,
    );
  }
  final lo = luminance.reduce((a, b) => a < b ? a : b);
  final hi = luminance.reduce((a, b) => a > b ? a : b);
  final threshold = (lo + hi) / 2;

  final edges = <int>[];
  for (var i = 1; i < luminance.length; i++) {
    if ((luminance[i] >= threshold) != (luminance[i - 1] >= threshold)) {
      edges.add(x0 + i);
    }
  }
  return edges;
}

int _offGrid(int x) {
  final r = x % _halfPeriod;
  return r < _halfPeriod - r ? r : _halfPeriod - r;
}

Future<List<int>> _render(WidgetTester tester, LiquidGlassSettings settings) async {
  final key = GlobalKey();
  await tester.pumpWidget(_scene(key, settings));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return _bevelEdges(key);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(LiquidGlass.precache);

  testWidgets('negative control keeps stripes on grid', (tester) async {
    final edges = await _render(
      tester,
      const LiquidGlassSettings(
        refractionAmount: 0,
        frost: 0,
        highlight: 0,
        contourStrength: 0,
        bevelShadowStrength: 0,
      ),
    );
    // ignore: avoid_print
    print('LG_PROBE negative edges=$edges');
    expect(edges, isNotEmpty, reason: 'stripes washed out; probe is invalid');
    expect(edges.map(_offGrid), everyElement(lessThan(_offGridThreshold)));
  });

  testWidgets('full glass displaces stripes in the bevel', (tester) async {
    final edges = await _render(
      tester,
      const LiquidGlassSettings(
        refractionAmount: 60,
        refractionHeight: 20,
        frost: 0,
        highlight: 0,
        contourStrength: 0,
        bevelShadowStrength: 0,
      ),
    );
    // ignore: avoid_print
    print('LG_PROBE full edges=$edges');
    expect(edges, isNotEmpty, reason: 'stripes washed out; probe is invalid');
    expect(
      edges.map(_offGrid).any((d) => d >= _offGridThreshold),
      isTrue,
      reason: 'no displaced stripe edge: full glass is not active (FakeGlass fallback?)',
    );
  });
}
```

- [ ] **Step 2: Run on Linux with the current runner (Flutter GPU not enabled)**

```bash
cd $SPIKE && $F test integration_test/liquid_glass_full_glass_probe_test.dart -d linux 2>&1 | grep -E "LG_PROBE|passed|failed|Expected|reason"
```

Expected: `negative control` PASS; `full glass` FAIL with "no displaced stripe edge". This proves the probe detects the fallback. Record both `LG_PROBE` lines.

If the negative control fails, `toImage` does not reproduce the glass faithfully. In that case, record the edges, take a manual screenshot of the spike screen from Task 5 instead, and mark the probe "manual only" in the notes.

- [ ] **Step 3: Run with the GPU flags on the command line**

```bash
cd $SPIKE && $F test integration_test/liquid_glass_full_glass_probe_test.dart -d linux --enable-impeller --enable-flutter-gpu 2>&1 | grep -E "LG_PROBE|passed|failed|Expected|reason"
```

Expected: both PASS. If `flutter test` rejects `--enable-flutter-gpu` (the README documents it for `flutter run` only), that is a tooling limit, not a Linux answer: record it and go to Task 4, where the runner enables the GPU API. If the flag is accepted and the full-glass test still fails, record the `LG_PROBE` output and still go to Task 4; Q1 is decided there, not here.

- [ ] **Step 4: Commit**

```bash
git add integration_test/liquid_glass_full_glass_probe_test.dart spike-notes.md
git commit -m "spike: add full-glass stripe probe"
```

---

### Task 4: Linux shipping configuration (Q1)

Flutter 3.47.5's Linux embedder enables Impeller by default (`fl_dart_project.cc`: `self->enable_impeller = TRUE`). It exposes `fl_dart_project_set_enable_flutter_gpu()`, which `fl_engine.cc` forwards as `--enable-flutter-gpu`.

**Files:**
- Modify: `$SPIKE/linux/runner/my_application.cc` (after `fl_dart_project_new()`, line 57)

**Interfaces:**
- Consumes: the probe from Task 3.

- [ ] **Step 1: Enable Flutter GPU in the runner**

In `$SPIKE/linux/runner/my_application.cc`, directly after
`g_autoptr(FlDartProject) project = fl_dart_project_new();` add:

```cpp
  fl_dart_project_set_enable_flutter_gpu(project, TRUE);
```

- [ ] **Step 2: Run the probe with no flags**

```bash
cd $SPIKE && $F test integration_test/liquid_glass_full_glass_probe_test.dart -d linux 2>&1 | grep -E "LG_PROBE|passed|failed|reason"
```

Expected: both PASS. This is the shipping configuration: the runner, not the CLI, enables the GPU API. (Integration tests run a debug build; Task 5 Step 3 confirms a release bundle.)

- [ ] **Step 3: Commit**

```bash
git add linux/runner/my_application.cc spike-notes.md
git commit -m "spike: enable Flutter GPU in Linux runner"
```

---

### Task 5: Dashboard-shaped performance screen (Q5)

**Files:**
- Create: `$SPIKE/lib/spike/liquid_glass_spike_main.dart`

**Interfaces:**
- Produces: a log line `SPIKE_FRAMES n=<int> build_p50_ms=<d> build_p90_ms=<d> raster_p50_ms=<d> raster_p90_ms=<d>` after 20 s of auto-scroll.

- [ ] **Step 1: Write the spike screen**

```dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlass.precache();
  runApp(const _SpikeApp());
}

final class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
    final black = Paint()..color = const Color(0xFF000000);
    for (var x = 0.0; x < size.width; x += 16) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 8, size.height), black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final class _SpikeApp extends StatelessWidget {
  const _SpikeApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: _SpikeScreen());
  }
}

final class _SpikeScreen extends StatefulWidget {
  const _SpikeScreen();

  @override
  State<_SpikeScreen> createState() => _SpikeScreenState();
}

final class _SpikeScreenState extends State<_SpikeScreen> {
  final _scroll = ScrollController();
  final _build = <int>[];
  final _raster = <int>[];
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll());
    Timer(const Duration(seconds: 20), _report);
  }

  void _onTimings(List<ui.FrameTiming> timings) {
    for (final t in timings) {
      _build.add(t.buildDuration.inMicroseconds);
      _raster.add(t.rasterDuration.inMicroseconds);
    }
  }

  Future<void> _autoScroll() async {
    while (mounted && !_reported) {
      await _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(seconds: 4), curve: Curves.linear);
      await _scroll.animateTo(0, duration: const Duration(seconds: 4), curve: Curves.linear);
    }
  }

  static String _p(List<int> values, int percentile) {
    final sorted = [...values]..sort();
    final i = ((percentile / 100) * (sorted.length - 1)).round();
    return (sorted[i] / 1000).toStringAsFixed(2);
  }

  void _report() {
    _reported = true;
    // ignore: avoid_print
    print('SPIKE_FRAMES n=${_raster.length} '
        'build_p50_ms=${_p(_build, 50)} build_p90_ms=${_p(_build, 90)} '
        'raster_p50_ms=${_p(_raster, 50)} raster_p90_ms=${_p(_raster, 90)}');
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final settings = LiquidGlassSettings.ios27Regular(brightness: brightness);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(296, 152, 24, 120),
              itemCount: 60,
              itemBuilder: (context, i) => Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [
                    HSLColor.fromAHSL(1, (i * 37) % 360, 0.7, 0.55).toColor(),
                    HSLColor.fromAHSL(1, (i * 37 + 90) % 360, 0.7, 0.45).toColor(),
                  ]),
                ),
                child: Center(
                  child: Text('کارت محتوا $i',
                      style: const TextStyle(fontSize: 22, color: Colors.white)),
                ),
              ),
            ),
          ),
          // Probe strip: 8 px stripes under a glass pill, for eyeballing
          // refraction in a release bundle (Q1).
          Positioned(
            left: 296, right: 24, top: 0, height: 136,
            child: const CustomPaint(painter: _StripePainter()),
          ),
          Positioned(
            left: 336, top: 20, width: 240, height: 96,
            child: LiquidGlassLayer(
              settings: const LiquidGlassSettings(
                frost: 0,
                highlight: 0,
                contourStrength: 0,
                bevelShadowStrength: 0,
              ),
              child: const LiquidGlass(
                shape: LiquidRoundedSuperellipse(borderRadius: 40),
                child: SizedBox.expand(),
              ),
            ),
          ),
          // Sidebar: one layer, one shape.
          Positioned(
            left: 16, top: 16, bottom: 16, width: 256,
            child: LiquidGlassLayer(
              settings: settings,
              child: const LiquidGlass(
                shape: LiquidRoundedSuperellipse(borderRadius: 28),
                child: SizedBox.expand(),
              ),
            ),
          ),
          // Bottom control bar: one layer, six blended controls.
          Positioned(
            left: 296, right: 24, bottom: 24, height: 64,
            child: LiquidGlassLayer(
              settings: settings,
              child: LiquidGlassBlendGroup(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      const LiquidGlass.grouped(
                        shape: LiquidRoundedSuperellipse(borderRadius: 28),
                        child: SizedBox(width: 56, height: 56),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Measure on Linux (profile mode, no flags)**

```bash
cd $SPIKE && $F run --profile -d linux -t lib/spike/liquid_glass_spike_main.dart 2>&1 | grep -m1 SPIKE_FRAMES
```

Expected: one `SPIKE_FRAMES` line. Run three times and record all three under Q5. Pass if the median of the three `raster_p90_ms` is ≤ 8.00.

- [ ] **Step 3: Confirm full glass in a release bundle launched without flags (Q1)**

```bash
cd $SPIKE && $F build linux --release -t lib/spike/liquid_glass_spike_main.dart
./build/linux/x64/release/bundle/dashboard_shakhsi
```

Expected: in the stripe band at the top (same geometry as the probe: 240×96 pill, radius 40), stripes inside the pill's rounded ends bend; with fallback they stay straight. Take a window screenshot with the system screenshot tool (Print Screen → Window), save it as `$SPIKE/q1-linux-release.png`, and record the observation under Q1.

- [ ] **Step 4: Measure the same screen with glass removed (baseline)**

Temporarily replace the three `LiquidGlassLayer(...)` widgets with `const SizedBox.shrink()`, rerun Step 2 once, record it as "no-glass baseline", then revert with `git checkout lib/spike/liquid_glass_spike_main.dart`.

- [ ] **Step 5: Commit**

```bash
git add lib/spike/liquid_glass_spike_main.dart spike-notes.md q1-linux-release.png
git commit -m "spike: add dashboard-shaped performance screen"
```

---

### Task 6: Android (Q2)

Needs the owner's Android phone with USB debugging (`adb devices` shows it). Emulators are not valid evidence for Impeller. If no device is available, mark Q2 "not run" and continue.

**Files:**
- Modify: `$SPIKE/android/app/src/main/AndroidManifest.xml` (inside `<application>`)

- [ ] **Step 1: Enable Flutter GPU**

Inside `<application ...>` add:

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableFlutterGPU"
    android:value="true" />
```

- [ ] **Step 2: Run the probe on the device**

```bash
cd $SPIKE && $F devices && $F test integration_test/liquid_glass_full_glass_probe_test.dart -d <android-device-id> 2>&1 | grep -E "LG_PROBE|passed|failed|reason"
```

Expected: both PASS. Record the device model and Android version.

- [ ] **Step 3: Measure performance**

```bash
cd $SPIKE && $F run --profile -d <android-device-id> -t lib/spike/liquid_glass_spike_main.dart 2>&1 | grep -m1 SPIKE_FRAMES
```

Record three runs under Q2. The owner judges whether it feels smooth while it runs.

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml spike-notes.md
git commit -m "spike: enable Flutter GPU on Android"
```

---

### Task 7: Windows configuration (Q4, code only)

Flutter 3.47.5's Windows `flutter::DartProject` has `set_enable_flutter_gpu(bool)`; Impeller is on by default there. There is no Windows machine in this setup, so Q4 is recorded as **unverified** unless the owner runs it.

**Files:**
- Modify: `$SPIKE/windows/runner/main.cpp` (after the `flutter::DartProject project(L"data");` line)

- [ ] **Step 1: Add the call**

```cpp
  project.set_enable_flutter_gpu(true);
```

- [ ] **Step 2: Record**

Under Q4 in `spike-notes.md`: "Runner change prepared; not built or run (no Windows machine). Status: unverified."

- [ ] **Step 3: Commit**

```bash
git add windows/runner/main.cpp spike-notes.md
git commit -m "spike: prepare Flutter GPU on Windows runner"
```

---

### Task 8: Report and decision

**Files:**
- Create: `$MAIN/docs/superpowers/references/2026-11-DD-liquid-glass-spike-report.md` (DD = the day the spike finishes)
- Modify: `$MAIN/PROJECT_ROADMAP.md` (§7 status line and §14 handoff)

- [ ] **Step 1: Write the report**

Use this structure, filled from `spike-notes.md`:

```markdown
# Liquid Glass Spike Report

**Date:** <date>  **SDK:** Flutter 3.47.5 / Dart <x>  **Package:** liquid_glass_renderer 1.0.0-dev.2
**Spike branch:** spike/liquid-glass @ <sha>

## Verdict
GO | NO-GO (Linux only) | NO-GO

## Answers
- Q1 Linux full glass, release, no flags: YES/NO — <probe output, screenshot path>
- Q2 Android full glass: YES/NO/NOT RUN — <device, probe output>
- Q3 native hooks build (Linux, Android): YES/NO — <errors if any>
- Q4 Windows: UNVERIFIED (runner change prepared)
- Q5 performance: Linux raster p90 <a>/<b>/<c> ms (median <m>), no-glass baseline <n> ms; Android <…>

## 3.47.5 regressions in the existing project
<list, or "none">

## Mechanisms confirmed
- Linux: `fl_dart_project_set_enable_flutter_gpu(project, TRUE)` in `linux/runner/my_application.cc`
- Android: `io.flutter.embedding.android.EnableFlutterGPU` meta-data
- Windows: `project.set_enable_flutter_gpu(true)` in `windows/runner/main.cpp`

## Next step
<GO: write the adoption implementation plan. NO-GO: options from spec §4.4 with a recommendation.>
```

- [ ] **Step 2: Update the roadmap**

In `$MAIN/PROJECT_ROADMAP.md` §7, replace `**Status: DESIGN APPROVED (2026-11-02) — NEXT: STEP 0 SPIKE**` with `**Status: SPIKE COMPLETE (<date>) — VERDICT: <GO|NO-GO> — report: docs/superpowers/references/<file>**`. In §14, replace the line starting `- CURRENT TASK is` to state the verdict and the next action.

- [ ] **Step 3: Commit on the main branch**

```bash
cd $MAIN
git add docs/superpowers/references/*-liquid-glass-spike-report.md PROJECT_ROADMAP.md
git commit -m "docs: record liquid glass spike verdict"
```

- [ ] **Step 4: Leave the spike branch in place**

Do not delete `spike/liquid-glass` or `$SPIKE`; the adoption plan reuses the runner and manifest changes. Do not push without the owner's go-ahead.
