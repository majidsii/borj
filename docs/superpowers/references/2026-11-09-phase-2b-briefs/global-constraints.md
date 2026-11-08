## Global Constraints

Copied verbatim from the Phase 2 Part A plan (`docs/superpowers/plans/2026-11-08-redesign-phase-2a-shell.md`), which itself carries the Phase 1 Part B constraints ("Task N" inside these lines means a task of that earlier plan):

Copied verbatim from the Phase 1 Part B plan (`docs/superpowers/plans/2026-11-07-redesign-phase-1b-primitives.md`): ("Task N" inside these lines means a Part B task; those tasks are done).

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

Added for Phase 2 Part A:

- Window classes (redesign spec §5): compact `< 600`, medium `600–1023`, expanded `≥ 1024` logical px of window width. Tests cover the widths 599, 600, 1023 and 1024.
- Phone shell (boards `Main`, `PhoneTasks`, `PhoneMoney`): tab bar capsule 62 tall (items 54 + padding 4), `bottom: 24`, `inset-inline: 16`, gap 10, search circle 62 × 62 to its leading side (left in RTL); toolbar circles 44 × 44, side padding 16, at `top: 58` when the top safe-area padding is 0 (the board's frame) and at `MediaQuery.paddingOf(context).top + 14` otherwise.
- Desktop shell (board `MacToday`): sidebar on the RIGHT, width 236 (min 210), margin 8, radius 20, padding `14 vertical / 10 horizontal`, section header 12 pt bold `textSecondary` with padding `6 10 4`, item height 36, item radius 12, gap 2, selected item is `GlassInner`. Toolbar row padding `14 16 0 20`, controls 36 tall, search capsule 230 wide. The OS draws window controls: the board's traffic-light dots are not drawn. The window fills the OS window (no desk margin); its background is `AppBackground(kind: AppBackgroundKind.phone)` painted edge to edge on every class (the desk kind belongs to the boards' screenshot frame).
- Medium shell: an icon rail of width 72 on the right with the same items (icons only, tooltips with the label), settings at the bottom.
- Visible sections (decision `docs/superpowers/decisions/2026-11-08-shell-settings-entry-and-unbuilt-sections.md`): tabs امروز / کارها / مالی; sidebar groups برنامه (امروز, همهٔ کارها, تقویم) and پول (تراکنش‌ها, قسط و بدهی). عادت‌ها, هدف‌ها and بودجه are hidden behind `ShellFeatures` flags (all `false`); the زندگی header is hidden while all its items are. Settings: a glass circle in the Today toolbar on compact (next to the calendar circle); a «تنظیمات» row at the bottom of the sidebar or rail; `Ctrl+,` everywhere.
- Capture budget per window class: compact = content 1 + chrome 1 + overlays 1 = 3; medium = content 1 + chrome 1 + overlays 1 = 3; expanded = content 1 + chrome 1 + inspector 1 + overlays 1 = 4. All chrome shapes of a window class live in one `GlassScope(kind: GlassLayerKind.chrome)` (compact ≤ 5 shapes, expanded ≤ 6). Pages inside the shell never create a `GlassBackdropGroup`; the shell's content group covers the branch navigator.
- Tab / section switch: content swaps instantly (no animation on the content); only the tab bar's `GlassInner` lens slides with `AppMotion.snappy` and stretches at most 12 % along the travel axis mid-way. The sidebar's selection jumps (macOS convention; motion spec "frequency rule").
- Push (compact only, routes with `GlassPushPage`): Flutter's Cupertino page transition and back gesture (direction-aware: in RTL the new page enters from the left, the back swipe starts at the right edge), plus a `scrim` over the outgoing page that grows with the secondary animation. The dim is a colour overlay, never `Opacity` / `ColorFiltered` / `FadeTransition` over glass (Phase 1 ruling D3). Under Reduce Motion the push is instant (`Duration.zero`): a page holds glass, and a page cross-fade would bare-fade it (D3). On medium and expanded the same pages use `NoTransitionPage` semantics (instant).
- `GlassInspector` (expanded only): slides in from the LEADING edge (left in RTL) with `AppMotion.standard`; closes with `standard` × `AppMotion.exitFactor`; Reduce Motion: appears and disappears through `GlassVisibility` over `AppMotion.reduced`, no slide. Its glass is one `GlassScope(kind: GlassLayerKind.sheet)`. Width 360.
- Every location produced by `NotificationRouteLocationMapper` resolves to a page that is not the error page. The mapper is completed foundation work and is not changed.
- The debug glass-review page opens by long-pressing the Today large title (debug builds only), replacing the removed brand island.
- Pattern tests of this plan run the `glassTestVariants` matrix like the Part B ones. Where a test file shown below has no matrix loop (`glass_push_page_test.dart`, `glass_inspector_test.dart`, `app_shell_test.dart`), add one: `for (final v in glassTestVariants) testWidgets('renders (${v.name})', …)` that pumps the subject with `brightness: v.brightness, textScale: v.textScale` (for the router-based tests, pass them through `glassTestTheme(v.brightness)` and a `MediaQuery` text scaler) and asserts `tester.takeException()` is null.
- `lib/features/**` may import `package:borj/app/shell/...` and `package:borj/app/design/design.dart`; no colours or sizes in `lib/features/**` for new code.

Rulings from Part A that bind this plan (checkpoint `docs/superpowers/checkpoints/2026-11-09-redesign-phase-2a-checkpoint.md`):
- Pages inside the shell never create a `GlassBackdropGroup`; the shell's content group is the one content capture. Today's cards are separate `GlassScope`s under that group.
- No `builder:` GoRoutes; Today stays the `/` branch root (`NoTransitionPage`).
- The compact Today toolbar is at the 5-shape chrome cap (calendar, settings, quick entry, tab capsule, search circle): this plan adds no toolbar action.
- Legacy Tasks/Finance/Settings glass is printed, not asserted, in the device probe.

Added for Part B:
- Grid (motion spec §5.1): row unit 76 dp, gap 12 dp; compact 2 columns; medium and expanded 4 columns. Sizes: small = 1 col × 2 rows, wide = 2 cols × 2 rows, large = 2 cols × 4 rows. A card's height is `rows × 76 + (rows − 1) × 12` (small/wide 164, large 340). Layout is an ordered list of `(cardId, size)` packed by dense auto-flow (no overlaps; a later card fills the first gap it fits).
- Default layout (both layout classes, features that exist today): `timeline` wide, `tasks` large, `installment` wide. `installment` appears only when an active plan exists (`remainingCount > 0`). Budget and habit cards are not built.
- Card content per size, never stretched: each card declares the sizes it supports (timeline: wide, large; tasks: small, wide, large; installment: small, wide) and renders content for its size.
- Cards: `AppGlass(role: GlassRole.panel, shape: AppleGlassShape.rounded(AppRadii.cardLarge))` (26) inside `GlassScope(kind: GlassLayerKind.content)`, padding 16 (timeline `12 14 10`, tasks `4 16`, as the boards). Inner blocks and rows use `GlassInner` or flat fills (no glass on glass).
- Phone header: `LargeTitleHeader(title: 'امروز', subtitle: <weekday + Jalali day + month>)`, e.g. «چهارشنبه ۱۳ آبان». Desktop header: a `GlassRole.clear` date chip, radius 26, padding `10 26 12`, a subtitle «<Persian weekday>، <Gregorian day> <Persian name of the Gregorian month>» (e.g. «چهارشنبه، ۴ نوامبر») 15 pt w600 and a title «<Jalali day> <Jalali month> <Jalali year>» (e.g. «۱۳ آبان ۱۴۰۵») 40 pt w900, both `AppTextTone.onTint`.
- Timeline (board `Main`): header «برنامهٔ امروز» 13 pt w800 and «بعدی: <title of the next unfinished timed entry>»; an hour scale from 8 to 20 (extended to whole even hours that include every block, clamped to 0–24), labels every 2 hours; blocks are `GlassInner` positioned by local start time, width by duration (`estimatedDurationMinutes`, default 30 min, at least 30 min wide), done blocks show « ✓» after the title; the now-line is a 2 px `colors.danger` line with a «۱۴:۳۰» pill, the elapsed part of the scale is tinted (`colors.selection`), past blocks are drawn at 0.55 opacity; the line moves with the clock (recomputed each minute); no pulse. RTL: 8 is on the right.
- Today's tasks (boards `Main`, `MacToday`): timed entries sorted by time, then untimed active tasks. Expanded/medium group headers «صبح» (before 12:00), «بعدازظهر» (12:00 and later), «بی‌زمان»; compact has no headers. Each row: `RoundCheck`, title (done: `textTertiary` + line-through), time «۱۵:۰۰» (`link` tone, w800, for the next unfinished entry; `textSecondary` otherwise). Rows that do not fit the card's size are summarised in a last row «و <n> کار دیگر» that opens `/tasks`. No entries: a flat message «امروز کاری نداری» inside the card.
- Completing from Today: one-off tasks → `TaskRepository.transition(status: completed|planned, targetPosition: 0, changedAtUtc: clock.nowUtc())`; recurring occurrences → `TaskRecurrenceService.setCompleted(taskId:, originalLocalDateTime:, completed:)`. Rows stay in place (Today is not a list screen; no auto-leave, no undo toast).
- Installment (board `Main`): the first active `InstallmentPlan` by `createdAtUtc`; title w700, «قسط <paid+1> از <count>» 12 pt `textSecondary`, amount `perInstallment.formatMajorUnits()` w900; wide also shows a `ProgressTrack(value: paid / count)`. Tap → `/finance`. There is no due date in the model: none is shown.
- Onboarding (board `PhoneEmptyToday`) when the user has no tasks at all and no finance data (no transactions, debts or installment plans): a welcome card «روز تازه‌ای است» / «چند قدم کوچک، و داشبوردت زنده می‌شود.», one step card «اولین کار را بنویس» / «مثلاً «ورزش صبح» با ساعت و یادآور.» with a `GlassInner` button «افزودن کار» that goes to `/tasks`, and the footer «هر وقت خواستی، با دکمهٔ مثبت بالا چیزی اضافه کن.». The board's account and habit steps are not shown (features hidden); there is no step progress bar with one step.
- Cold start (motion spec §4 Today): the first time Today is built in the process, cards rise 8 px and fade in with `AppMotion.quick`, in layout order, delayed by `AppMotion.staggerAt(index)`; the glass fades through `GlassVisibility` (never a parent opacity); total ≤ 300 ms before content is usable; everything is tappable immediately. Later builds: no entrance. Reduce Motion: no rise, the fade only (`AppMotion.reduced`). Tracks inside cards grow from 0 with `ProgressTrack(animateIn: true)` on cold start only. Static: date header, tab bar.
- Data refresh: the agenda recomputes when the local date changes and on every task/recurrence stream event; the now-line moves every minute. Time comes from `appClockProvider` only (never `DateTime.now()` in today code).

## Controller amendments (binding; they override the task text below where they differ)

A1. **One time base: the task calendar zone's wall clock.** The device zone and the task calendar zone may differ, and CI (GitHub Actions) runs in UTC.
- `TodayAgendaBuilder.build` takes `required DateTime nowUtc` (not `localNow`); it computes the day and every `localStart` as wall-clock times in `timeZoneId` (naive `DateTime`s holding the zone's wall clock).
- `minuteTickProvider` emits `clock.nowUtc()` immediately and at every UTC minute boundary.
- New `final todayNowProvider = Provider<AsyncValue<DateTime>>` = the zone wall clock of the latest tick: `TZDateTime.from(tickUtc, getLocation(zone))` converted to a naive `DateTime(y, m, d, h, min)`. `todayAgendaProvider` selects the DATE of `todayNowProvider` (not of the device-local time) and passes `nowUtc` from the tick to the builder.
- `TimelineCard`, `TodayTasksCard`, `TodayHeader` and `TodayAgenda.nextAfter` receive this zone wall-clock `now`. `TodayPage` reads `todayNowProvider` (fallback while loading: render nothing for the grid, as for other loading states).
- Tests build instants with `DateTime.utc(...)` (or `TZDateTime(location, ...)`), never a naive `DateTime(...)` meant as Tehran local. Task 1 and Task 2 Step 4 also run `TZ=UTC flutter test test/features/today` and `TZ=Asia/Tokyo flutter test test/features/today`; both must pass.

A2. **No live timers in widget tests.**
- `pumpBorjTestApp` (`test/support/borj_test_app.dart`) overrides `minuteTickProvider` by default with `Stream<DateTime>.value(<the container clock's nowUtc()>)`; add an optional `Stream<DateTime>? minuteTicks` parameter for tests that drive ticks, and an optional `Future<void> Function(ProviderContainer container)? seed` callback that runs after the container is created and before `pumpWidget` (for tests and the probe that need data before Today first builds).
- `_Enter` (Task 8) uses ONE `AnimationController` per item of length `AppMotion.staggerAt(index) + m.duration` with `CurvedAnimation(curve: Interval(stagger / total, 1, curve: m.curve))` — no `Timer`.

A3. **Date chip contrast (Task 7).** Before finishing Task 7, check the `GlassRole.clear` material in LIGHT mode (its FakeGlass / reduce-transparency fill from `AppGlass` settings) against `AppTextTone.onTint`: the text must reach ≥ 4.5:1 (spec §8). Add a test that computes the contrast of `onTint` over the chip's fallback fill in light and dark. If light fails, STOP and report (needs a role/tint ruling); never add a literal colour in `lib/features/**`.

A4. **Medium widths (Task 8).** Add TodayPage tests at 600×844 and 1024×800, text scale 1.0 and 1.3, populated (task + installment): no exception, no overflow. If 600 px overflows with 4 columns, STOP and report (needs a ruling on medium columns).

A5. **Probe measures the cold start (Task 9).** Seed the task and the installment plan through `pumpBorjTestApp(seed: …)`, call `TodayEntrance.reset()` before pumping, and sample `countCompositedBackdropsDetailed` from the first frame the grid appears until the entrance settles (≥ 30 frames): worst ≤ budget (phone 3, desktop 4) and ≥ 2, plus the seeded-pass floor. Print `todayEntrance=` in `LG_COMPOSITED`.

