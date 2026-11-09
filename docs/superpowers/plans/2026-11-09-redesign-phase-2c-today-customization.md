# Redesign Phase 2 Part C — Today Customization Implementation Plan

> **Status: DRAFT, DEFERRED** (owner, 2026-11-09: «اره اوکیه» to building the main screens first). Not self-reviewed yet; before executing, re-read against the code at that time, resolve the resize-direction wording in Global Constraints, and write the bullet tests of Tasks 3, 5, 6, 7, 8, 9 and 10 as concrete code.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user arrange Today: an edit mode where cards can be moved, resized between their allowed sizes, hidden and added back, a reset to the default layout with undo, an accessible list and keyboard path, all persisted per layout class (schema 10).

**Architecture:** A pure domain model (`TodayLayout`, card catalogue, operations, exact parsing) in `lib/features/today/domain/`, a Drift table `today_layout_items` (schema 9 → 10) behind `TodayLayoutRepository`, and a `TodayLayoutController` that commits every change in one transaction and offers undo. Presentation extends Part B: the grid animates reflow, an edit-mode layer adds badges, handle and drag/resize interaction, and a separate «کارت‌های امروز» screen gives the non-drag path. Glass rules hold during interaction: the card being dragged or resized renders without real glass (flat inner material) until it settles.

**Tech Stack:** Flutter 3.47.5, Drift, Riverpod, go_router, the Phase 1/2A/2B primitives and Today widgets.

**Scope** (motion spec 2026-11-06 §5, §6, §7; Part B checkpoint deferred items for Part C):
- In: §5.2 edit mode, §5.3 move, §5.4 resize (with preview and projection), §5.5 hide / add / reset with undo and the all-hidden empty state, §5.6 the accessible list, screen-reader actions and keyboard, §5.7 persistence; §6 glass constraints and the edit-mode perf probe; the Part C items deferred by Part B (4-column dense-flow tests, `assert(columns >= 1)`, bounded width, third overlapping timeline block).
- Out: new card types — timer, weekly report, debts (their features exist, but each card is its own small design; Part D); budget, habits, goals cards (features hidden).

## Global Constraints

Copied verbatim from the Phase 2 Part B plan (`docs/superpowers/plans/2026-11-09-redesign-phase-2b-today.md`), which carries the Part A and Phase 1 Part B constraints, and its controller amendments A1–A5 ("Task N" inside these lines means a task of that earlier plan):

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

Part B decisions that bind this plan: 1 (no installment due date), 3 (installment default wide), 6 (date chip tones), 7 (grid columns follow the grid width: ≥ 720 → 4, else 2), 8 (completed untimed tasks stay).

Added for Part C:
- Card catalogue (cards whose feature exists): `timeline` «نوار زمان امروز» (sizes wide, large; default wide), `tasks` «کارهای امروز» (small, wide, large; default large), `installment` «قسط پیش‌رو» (small, wide; default wide). Default order: timeline, tasks, installment. Subtitles on the cards screen: «ساعت‌بندی کارها از ۸ تا ۲۰», «فهرست کارها با یادآور», «قسط بعدی وام‌هایت». Size labels: small «کوچک», wide «پهن», large «بزرگ».
- Layout class: `compact` when the window class is compact, `expanded` for medium and expanded. Each class has its own persisted layout; no rows = the default layout.
- Persistence (§5.7): table `today_layout_items(layout_class TEXT, card_id TEXT, position INTEGER, size TEXT, hidden INTEGER 0/1)`, primary key `(layout_class, card_id)`, CHECKs on `layout_class IN ('compact','expanded')`, `size IN ('small','wide','large')`, `hidden IN (0,1)`, `position >= 0`; schema 9 → 10, append-only migration. Parsing is exact: rows with an unknown `card_id` or `size` are ignored (no crash); a stored size not allowed for that card falls back to the card's first allowed size; positions are renumbered `0..n-1` in stored order; catalogue cards missing from the stored rows are appended, visible, at their default size.
- Every committed change (drop, resize release, hide, add, reset, list edits) writes the whole layout of that class in ONE transaction; undo writes the previous layout back (also one transaction).
- An available card is one whose content exists: `installment` only when `todayInstallmentProvider` has a plan. Unavailable cards keep their place in the stored layout but are skipped when packing (no gap); they still appear on the cards screen with the note «فعلاً چیزی برای نمایش ندارد».
- Edit mode (§5.2): enter by a 500 ms long-press on any card (haptic `HapticFeedback.mediumImpact()` on Android), by the «ویرایش» text button in the Today header row (plain `AppText` link button, not chrome glass — the compact toolbar is at its 5-shape cap), or, on medium/expanded, by a secondary click on a card. Exit: «تمام» (same place), `Escape`, or a tap on empty space outside the cards. In edit mode: cards settle to 0.965 scale with `AppMotion.quick`, card content ignores pointers, a remove badge (−) at the top START corner (top-right in RTL) and a resize handle at the bottom END corner (bottom-left in RTL), both fading/scaling from 0.9 with `quick`; no jiggle; «+ افزودن کارت» appears under the grid. Badges and handles are flat (`GlassInner` or flat fills), never glass, 44 pt hit targets.
- Move (§5.3): in edit mode a drag starts immediately; outside edit mode the 500 ms long-press enters edit mode and the same pointer continues as a drag. The lifted card scales 1.04 with `colors.knobShadow` shadow and follows the pointer 1:1 with its grab offset; when the pointer's centre is over another card, the dragged card takes that card's index and the others reflow with `AppMotion.standard`; release settles into the slot with `AppMotion.soft`, using the release velocity.
- Resize (§5.4): dragging the handle moves the frame freely (width grows toward the END side in RTL… i.e. toward the leading side of the spec = the start side? — the frame's start edge stays fixed and the end/bottom corner follows the pointer), with Apple's rubber band past the smallest and largest allowed size (`offset × 0.55 × d / (d + 0.55 × |offset|)`, d = 200); the nearest allowed size (by area of the frame against each size's slot) is chosen continuously; the card's REAL slot shows a preview: a dashed `colors.accent` outline (1.5 px, radius 26) around a flat panel with the card title and the size label at 30 % opacity (Decision 2); other cards make room live (`standard`); crossing to another size gives `HapticFeedback.selectionClick()` on Android; release springs into the preview slot with `soft` carrying the release velocity; a flick is projected (`projected = position + velocity × 0.998 / (1 − 0.998) / 1000`) so a quick flick can jump to the next size; a plain tap on the handle cycles to the next allowed size.
- Hide / add / reset (§5.5): the badge hides the card (never deletes data): it leaves the layout at once, the others close the gap (`standard`) while its ghost fades through `GlassVisibility` and shrinks to 0.96 in 180 ms; `showUndoToast(message: 'کارت پنهان شد')`. «+ افزودن کارت» opens a `GlassSheet` (from the button's rect) listing hidden and unavailable-but-hidden cards, each as a flat preview tile (title, subtitle, default size label); tapping one adds it at the end (visible) with a grow-in (`soft`) and closes the sheet; the sheet ends with «بازگردانی چیدمان پیش‌فرض» (no confirmation) → default layout + `showUndoToast(message: 'چیدمان پیش‌فرض برگشت')`; and «مدیریت کارت‌ها» → the cards screen. If every card is hidden (or every visible card is unavailable), Today shows `EmptyState(icon: Icons.dashboard_customize_outlined, title: 'کارتی روی امروز نیست', actionLabel: 'افزودن کارت')`.
- Without dragging (§5.6): route `/today/cards` (root push, `GlassPushPage`) = the `PhoneDashboardCards` board: back circle, «کارت‌های امروز» large title, the description «با کلید، کارت‌ها را نشان بده یا پنهان کن. برای تغییر ترتیب، دستگیره را بکش.», section headers «نمایان · <n> کارت» and «پنهان · <n> کارت», one glass panel per section with flat rows (title, subtitle, a `GlassToggle` for visibility, a size `GlassSegmented` of the card's allowed sizes, «بالا» / «پایین» buttons and a drag handle for reordering inside the visible section), and «بازگردانی چیدمان پیش‌فرض» at the bottom (with undo toast). Reachable from the add sheet and from Settings (a row «کارت‌های امروز» in the legacy Settings screen).
- Screen-reader actions on each card in edit mode: «جابه‌جایی به قبل», «جابه‌جایی به بعد», «تغییر اندازه», «پنهان کردن» (`CustomSemanticsAction`), each committing like the gesture.
- Desktop keyboard in edit mode: the focused card moves with arrow keys (RTL: ← = next, → = previous; ↑/↓ = previous/next row-major), `S` cycles size, `Delete`/`Backspace` hides, `Escape` exits; keyboard actions are instant (no animation).
- Glass during interaction (§6): the card being dragged or resized renders with `GlassPreferencesScope(reduceTransparency: true)` around it (FakeGlass / frosted, no real refraction) until it settles; at most one card animates its geometry at a time; other cards move by transform (their glass shapes keep their size). Budgets stay as Part B: compact 3, expanded 4, measured during drag and resize.
- Reduce Motion: no scale, lift, rubber band, reflow movement or grow-in; cards jump to their new places, badges and previews fade over `AppMotion.reduced`; the drag still follows the pointer (direct manipulation is not decorative motion).

## Decisions recorded by this plan

1. **New card types are Part D.** Timer, weekly report and debts cards exist as features but each card needs its own small design per the boards; Part C delivers the mechanics with the three existing cards.
2. **Resize preview is a flat placeholder**, not live card content at 30 %: the cards' content lives inside their glass panel, and rendering a second live copy at 30 % opacity would fade glass or add captures (§6). The preview shows the dashed outline, the card title and the size label.
3. **The «ویرایش» / «تمام» button lives in the Today header row**, not in the compact chrome toolbar (5-shape cap, Part A).
4. **Secondary click enters edit mode** on desktop instead of a context menu (one action, no menu widget yet).
5. **Layout class = compact vs. not compact** (medium shares the expanded layout).

## File structure

```
lib/features/today/domain/today_card_catalog.dart       TodayCardId, TodayCardSpec, todayCardCatalog, TodayLayoutClass   (Task 1)
lib/features/today/domain/today_layout.dart             TodayLayoutItem, TodayLayout (+ operations, parse)             (Task 1)
lib/core/database/app_database.dart                     TodayLayoutItemRows, schema 10, migration                     (Task 2)
lib/features/today/data/drift_today_layout_repository.dart  TodayLayoutRepository implementation                      (Task 2)
lib/features/today/domain/today_layout_repository.dart  TodayLayoutRepository interface                              (Task 2)
lib/features/today/application/today_layout_controller.dart  providers + TodayLayoutController (commit, undo)          (Task 3)
lib/features/today/presentation/today_grid.dart         animated reflow, assert, bounded width                         (Task 4)
lib/features/today/presentation/today_edit_mode.dart    TodayEditScope, edit chrome (badge, handle), enter/exit         (Task 5)
lib/features/today/presentation/today_add_card_sheet.dart  add sheet, reset                                           (Task 6)
lib/features/today/presentation/today_move.dart         drag-to-move                                                   (Task 7)
lib/features/today/presentation/today_resize.dart       handle drag/tap, preview, projection                           (Task 8)
lib/features/today/presentation/today_cards_screen.dart  /today/cards screen                                           (Task 9)
lib/features/today/presentation/today_page.dart         layout from the controller, edit mode, keyboard, SR actions     (Task 10)
integration_test/glass_shell_probe_test.dart            edit-mode drag/resize scenario                                 (Task 11)
```

---

### Task 1: Card catalogue and the layout model

**Files:**
- Create: `lib/features/today/domain/today_card_catalog.dart`, `lib/features/today/domain/today_layout.dart`
- Test: `test/features/today/today_layout_test.dart`

**Interfaces:**
- Consumes: `TodayCardSize` (`lib/features/today/presentation/today_grid.dart` — MOVE the enum to `lib/features/today/domain/today_card_size.dart` and re-export it from `today_grid.dart` so existing imports keep working).
- Produces:
  - `enum TodayCardId { timeline, tasks, installment; static TodayCardId? tryParse(String value); }`
  - `enum TodayLayoutClass { compact, expanded; static TodayLayoutClass forWindow(WindowClass c); static TodayLayoutClass? tryParse(String value); }`
  - `TodayCardSize.tryParse(String value)` (static on the enum) and `String get label` («کوچک», «پهن», «بزرگ»).
  - `final class TodayCardSpec { const TodayCardSpec({required this.id, required this.title, required this.subtitle, required this.sizes, required this.defaultSize}); }` and `const List<TodayCardSpec> todayCardCatalog` (timeline, tasks, installment, in default order) plus `TodayCardSpec specOf(TodayCardId id)`.
  - `final class TodayLayoutItem { const TodayLayoutItem({required this.card, required this.size, required this.hidden}); copyWith({size, hidden}); == / hashCode }`
  - `final class TodayLayout { const TodayLayout(this.items); factory TodayLayout.defaults(); final List<TodayLayoutItem> items; List<TodayLayoutItem> get visible; List<TodayLayoutItem> get hiddenItems; TodayLayout move(TodayCardId card, int toVisibleIndex); TodayLayout resize(TodayCardId card, TodayCardSize size); TodayLayout cycleSize(TodayCardId card); TodayLayout hide(TodayCardId card); TodayLayout add(TodayCardId card); /* unhide and move to the end of the visible list */ static TodayLayout parse(List<({String cardId, int position, String size, bool hidden})> rows); == / hashCode }`. Operations never mutate; they return a new layout. `move` reorders among visible items only (hidden items keep their relative place after the visible ones in `items`); `resize` asserts the size is allowed; `cycleSize` goes to the next allowed size (wrapping).

- [ ] **Step 1: Write the failing tests** `test/features/today/today_layout_test.dart`:
```dart
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/features/today/domain/today_card_catalog.dart';
import 'package:borj/features/today/domain/today_card_size.dart';
import 'package:borj/features/today/domain/today_layout.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _ids(List<TodayLayoutItem> items) => [for (final i in items) i.card.name];

void main() {
  test('catalogue: three cards in default order with allowed sizes', () {
    expect(todayCardCatalog.map((s) => s.id), [TodayCardId.timeline, TodayCardId.tasks, TodayCardId.installment]);
    expect(specOf(TodayCardId.timeline).sizes, [TodayCardSize.wide, TodayCardSize.large]);
    expect(specOf(TodayCardId.tasks).sizes, [TodayCardSize.small, TodayCardSize.wide, TodayCardSize.large]);
    expect(specOf(TodayCardId.installment).sizes, [TodayCardSize.small, TodayCardSize.wide]);
    expect(specOf(TodayCardId.tasks).title, 'کارهای امروز');
    expect(TodayCardSize.large.label, 'بزرگ');
  });

  test('layout class follows the window class', () {
    expect(TodayLayoutClass.forWindow(WindowClass.compact), TodayLayoutClass.compact);
    expect(TodayLayoutClass.forWindow(WindowClass.medium), TodayLayoutClass.expanded);
    expect(TodayLayoutClass.forWindow(WindowClass.expanded), TodayLayoutClass.expanded);
  });

  test('defaults: timeline wide, tasks large, installment wide, all visible', () {
    final d = TodayLayout.defaults();
    expect(_ids(d.visible), ['timeline', 'tasks', 'installment']);
    expect([for (final i in d.items) i.size], [TodayCardSize.wide, TodayCardSize.large, TodayCardSize.wide]);
  });

  test('move reorders visible cards only', () {
    final l = TodayLayout.defaults().hide(TodayCardId.timeline).move(TodayCardId.installment, 0);
    expect(_ids(l.visible), ['installment', 'tasks']);
    expect(_ids(l.hiddenItems), ['timeline']);
  });

  test('resize, cycleSize and the allowed-size assert', () {
    var l = TodayLayout.defaults().resize(TodayCardId.tasks, TodayCardSize.small);
    expect(l.items[1].size, TodayCardSize.small);
    l = l.cycleSize(TodayCardId.tasks);
    expect(l.items[1].size, TodayCardSize.wide);
    l = l.cycleSize(TodayCardId.tasks).cycleSize(TodayCardId.tasks);
    expect(l.items[1].size, TodayCardSize.small, reason: 'wraps');
    expect(() => l.resize(TodayCardId.timeline, TodayCardSize.small), throwsA(isA<AssertionError>()));
  });

  test('hide then add puts the card back at the end, visible', () {
    final l = TodayLayout.defaults().hide(TodayCardId.timeline).add(TodayCardId.timeline);
    expect(_ids(l.visible), ['tasks', 'installment', 'timeline']);
  });

  test('operations do not mutate', () {
    final d = TodayLayout.defaults();
    d.hide(TodayCardId.tasks);
    expect(d, TodayLayout.defaults());
  });

  test('parse is exact: unknown ids/sizes ignored, disallowed size falls back, positions renumbered, missing cards appended', () {
    final l = TodayLayout.parse([
      (cardId: 'installment', position: 7, size: 'large', hidden: false), // large not allowed -> small
      (cardId: 'weather', position: 1, size: 'wide', hidden: false), // unknown card -> ignored
      (cardId: 'tasks', position: 3, size: 'huge', hidden: true), // unknown size -> ignored row
      (cardId: 'timeline', position: 2, size: 'large', hidden: false),
    ]);
    expect(_ids(l.items), ['timeline', 'installment', 'tasks']);
    expect(l.items[0].size, TodayCardSize.large);
    expect(l.items[1].size, TodayCardSize.small);
    expect(l.items[2].hidden, isFalse, reason: 'tasks row was ignored, so tasks is appended as default');
    expect(l.items[2].size, TodayCardSize.large);
  });
}
```

- [ ] **Step 2: Run.** Expected: FAIL (missing).

- [ ] **Step 3: Implement.**

`lib/features/today/domain/today_card_size.dart` — move `TodayCardSize` here (same values `small(1,2)`, `wide(2,2)`, `large(2,4)`), add:
```dart
  static TodayCardSize? tryParse(String value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return null;
  }

  String get label => switch (this) {
    TodayCardSize.small => 'کوچک',
    TodayCardSize.wide => 'پهن',
    TodayCardSize.large => 'بزرگ',
  };
```
and in `today_grid.dart` replace the enum with `export 'package:borj/features/today/domain/today_card_size.dart';` plus its import.

`lib/features/today/domain/today_card_catalog.dart`:
```dart
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/features/today/domain/today_card_size.dart';

enum TodayCardId {
  timeline,
  tasks,
  installment;

  static TodayCardId? tryParse(String value) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    return null;
  }
}

/// Phone and desktop keep separate layouts (motion spec §5.7).
enum TodayLayoutClass {
  compact,
  expanded;

  static TodayLayoutClass forWindow(WindowClass c) =>
      c == WindowClass.compact ? TodayLayoutClass.compact : TodayLayoutClass.expanded;

  static TodayLayoutClass? tryParse(String value) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    return null;
  }
}

final class TodayCardSpec {
  const TodayCardSpec({required this.id, required this.title, required this.subtitle, required this.sizes, required this.defaultSize});

  final TodayCardId id;
  final String title;
  final String subtitle;
  final List<TodayCardSize> sizes;
  final TodayCardSize defaultSize;
}

const List<TodayCardSpec> todayCardCatalog = <TodayCardSpec>[
  TodayCardSpec(
    id: TodayCardId.timeline,
    title: 'نوار زمان امروز',
    subtitle: 'ساعت‌بندی کارها از ۸ تا ۲۰',
    sizes: [TodayCardSize.wide, TodayCardSize.large],
    defaultSize: TodayCardSize.wide,
  ),
  TodayCardSpec(
    id: TodayCardId.tasks,
    title: 'کارهای امروز',
    subtitle: 'فهرست کارها با یادآور',
    sizes: [TodayCardSize.small, TodayCardSize.wide, TodayCardSize.large],
    defaultSize: TodayCardSize.large,
  ),
  TodayCardSpec(
    id: TodayCardId.installment,
    title: 'قسط پیش‌رو',
    subtitle: 'قسط بعدی وام‌هایت',
    sizes: [TodayCardSize.small, TodayCardSize.wide],
    defaultSize: TodayCardSize.wide,
  ),
];

TodayCardSpec specOf(TodayCardId id) => todayCardCatalog.firstWhere((s) => s.id == id);
```

`lib/features/today/domain/today_layout.dart`:
```dart
import 'package:borj/features/today/domain/today_card_catalog.dart';
import 'package:borj/features/today/domain/today_card_size.dart';
import 'package:flutter/foundation.dart';

@immutable
final class TodayLayoutItem {
  const TodayLayoutItem({required this.card, required this.size, required this.hidden});

  final TodayCardId card;
  final TodayCardSize size;
  final bool hidden;

  TodayLayoutItem copyWith({TodayCardSize? size, bool? hidden}) =>
      TodayLayoutItem(card: card, size: size ?? this.size, hidden: hidden ?? this.hidden);

  @override
  bool operator ==(Object other) =>
      other is TodayLayoutItem && other.card == card && other.size == size && other.hidden == hidden;

  @override
  int get hashCode => Object.hash(card, size, hidden);
}

/// An ordered list of cards; visible ones are packed by the grid (§5.1).
@immutable
final class TodayLayout {
  const TodayLayout(this.items);

  factory TodayLayout.defaults() => TodayLayout([
    for (final s in todayCardCatalog) TodayLayoutItem(card: s.id, size: s.defaultSize, hidden: false),
  ]);

  final List<TodayLayoutItem> items;

  List<TodayLayoutItem> get visible => [for (final i in items) if (!i.hidden) i];
  List<TodayLayoutItem> get hiddenItems => [for (final i in items) if (i.hidden) i];

  int _indexOf(TodayCardId card) => items.indexWhere((i) => i.card == card);

  TodayLayout _replace(TodayCardId card, TodayLayoutItem Function(TodayLayoutItem) f) {
    final i = _indexOf(card);
    final next = [...items];
    next[i] = f(next[i]);
    return TodayLayout(List.unmodifiable(next));
  }

  /// Moves a visible card to [toVisibleIndex] among the visible cards.
  TodayLayout move(TodayCardId card, int toVisibleIndex) {
    final vis = visible;
    final item = vis.firstWhere((i) => i.card == card);
    vis.remove(item);
    vis.insert(toVisibleIndex.clamp(0, vis.length), item);
    return TodayLayout(List.unmodifiable([...vis, ...hiddenItems]));
  }

  TodayLayout resize(TodayCardId card, TodayCardSize size) {
    assert(specOf(card).sizes.contains(size), '$size is not allowed for $card');
    return _replace(card, (i) => i.copyWith(size: size));
  }

  TodayLayout cycleSize(TodayCardId card) {
    final sizes = specOf(card).sizes;
    final current = items[_indexOf(card)].size;
    final next = sizes[(sizes.indexOf(current) + 1) % sizes.length];
    return resize(card, next);
  }

  TodayLayout hide(TodayCardId card) => _replace(card, (i) => i.copyWith(hidden: true));

  /// Unhides [card] and places it at the end of the visible cards.
  TodayLayout add(TodayCardId card) {
    final item = items[_indexOf(card)].copyWith(hidden: false);
    final rest = [for (final i in items) if (i.card != card) i];
    final vis = [for (final i in rest) if (!i.hidden) i];
    final hid = [for (final i in rest) if (i.hidden) i];
    return TodayLayout(List.unmodifiable([...vis, item, ...hid]));
  }

  /// Exact parsing (§5.7): unknown card ids or sizes drop the row; a size the
  /// card does not allow falls back to its first allowed size; rows are taken
  /// in position order; catalogue cards without a row are appended visible at
  /// their default size.
  static TodayLayout parse(List<({String cardId, int position, String size, bool hidden})> rows) {
    final sorted = [...rows]..sort((a, b) => a.position.compareTo(b.position));
    final seen = <TodayCardId>{};
    final out = <TodayLayoutItem>[];
    for (final r in sorted) {
      final card = TodayCardId.tryParse(r.cardId);
      final size = TodayCardSize.tryParse(r.size);
      if (card == null || size == null || !seen.add(card)) continue;
      final spec = specOf(card);
      out.add(TodayLayoutItem(card: card, size: spec.sizes.contains(size) ? size : spec.sizes.first, hidden: r.hidden));
    }
    for (final s in todayCardCatalog) {
      if (!seen.contains(s.id)) out.add(TodayLayoutItem(card: s.id, size: s.defaultSize, hidden: false));
    }
    return TodayLayout(List.unmodifiable(out));
  }

  @override
  bool operator ==(Object other) => other is TodayLayout && listEquals(other.items, items);

  @override
  int get hashCode => Object.hashAll(items);
}
```
`parse` keeps hidden and visible items in their stored order; `visible`/`hiddenItems` filter it. In the parse test, `tasks` has an unknown size so its row is dropped and `tasks` is appended visible at the end: the expected order `timeline, installment, tasks` follows.

- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze` (fix imports that broke when the enum moved).
- [ ] **Step 5: Commit** `feat(today): card catalogue and layout model`.

---

### Task 2: Schema 10 and the layout repository

**Files:**
- Modify: `lib/core/database/app_database.dart` (+ regenerate `app_database.g.dart` with `dart run build_runner build --delete-conflicting-outputs`)
- Create: `lib/features/today/domain/today_layout_repository.dart`, `lib/features/today/data/drift_today_layout_repository.dart`
- Modify: `lib/core/providers/persistence_providers.dart` (`todayLayoutRepositoryProvider`)
- Test: `test/core/database/today_layout_migration_test.dart`, `test/features/today/drift_today_layout_repository_test.dart`

**Interfaces:**
- Produces:
  - Table `TodayLayoutItemRows` (`tableName => 'today_layout_items'`): `layoutClass` text named `layout_class`, `cardId` text named `card_id`, `position` integer, `size` text, `hidden` boolean; primary key `{layoutClass, cardId}`; `customConstraints`: `"CHECK (layout_class IN ('compact', 'expanded'))"`, `"CHECK (size IN ('small', 'wide', 'large'))"`, `'CHECK (position >= 0)'`, `"CHECK (length(trim(card_id)) > 0)"`.
  - `schemaVersion => 10`; `onUpgrade`: `if (from < 10) { await migrator.createTable(todayLayoutItemRows); }`.
  - `abstract interface class TodayLayoutRepository { Stream<TodayLayout> watch(TodayLayoutClass layoutClass); Future<TodayLayout> load(TodayLayoutClass layoutClass); Future<void> save(TodayLayoutClass layoutClass, TodayLayout layout); }`
  - `final class DriftTodayLayoutRepository implements TodayLayoutRepository` — `watch`/`load` select the class's rows and return `TodayLayout.parse(rows)` (no rows → `TodayLayout.defaults()`, which `parse([])` already yields); `save` runs ONE transaction: delete the class's rows, insert one row per item with `position` = index.
  - `final todayLayoutRepositoryProvider = Provider<TodayLayoutRepository>((ref) => DriftTodayLayoutRepository(ref.watch(appDatabaseProvider)));`

- [ ] **Step 1: Write the failing tests**

`test/core/database/today_layout_migration_test.dart`:
```dart
import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/today/data/drift_today_layout_repository.dart';
import 'package:borj/features/today/domain/today_card_catalog.dart';
import 'package:borj/features/today/domain/today_layout.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('schema 9 upgrades to 10: today_layout_items is created and existing rows survive', () async {
    final dir = await Directory.systemTemp.createTemp('borj-today-layout-');
    final file = File('${dir.path}/db.sqlite');
    try {
      // Build a current database, add a task, then turn it back into a v9 file.
      var db = AppDatabase(NativeDatabase(file));
      await db.customStatement(
        "INSERT INTO tasks (id, display_number, title, priority, status, position_in_status, created_at_utc, updated_at_utc) VALUES ('t1', 1, 'کار', 0, 'planned', 0, 0, 0)",
      );
      await db.close();
      final raw = sqlite.sqlite3.open(file.path);
      raw.execute('DROP TABLE today_layout_items');
      raw.execute('PRAGMA user_version = 9');
      raw.dispose();

      db = AppDatabase(NativeDatabase(file));
      expect(await db.customSelect("SELECT id FROM tasks").get(), hasLength(1));
      expect(
        await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'today_layout_items'").get(),
        hasLength(1),
      );
      final repo = DriftTodayLayoutRepository(db);
      expect(await repo.load(TodayLayoutClass.compact), TodayLayout.defaults());
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('CHECK constraints reject bad rows', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await expectLater(
      db.customStatement("INSERT INTO today_layout_items VALUES ('tablet', 'tasks', 0, 'wide', 0)"),
      throwsA(anything),
    );
    await expectLater(
      db.customStatement("INSERT INTO today_layout_items VALUES ('compact', 'tasks', 0, 'huge', 0)"),
      throwsA(anything),
    );
  });
}
```
Read `TaskRows` in `app_database.dart` for its real column names and NOT NULL columns, and adjust the INSERT so it satisfies them; read how `raw.dispose()`/`close()` is named in the sqlite3 version used by the existing migration tests. The column order in the CHECK test's `INSERT … VALUES` must match the table's declared column order (layout_class, card_id, position, size, hidden); if Drift orders them differently, name the columns explicitly.

`test/features/today/drift_today_layout_repository_test.dart`:
```dart
import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/today/data/drift_today_layout_repository.dart';
import 'package:borj/features/today/domain/today_card_catalog.dart';
import 'package:borj/features/today/domain/today_card_size.dart';
import 'package:borj/features/today/domain/today_layout.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftTodayLayoutRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftTodayLayoutRepository(db);
  });
  tearDown(() => db.close());

  test('no rows: the default layout', () async {
    expect(await repo.load(TodayLayoutClass.compact), TodayLayout.defaults());
  });

  test('save then load round-trips, per layout class', () async {
    final custom = TodayLayout.defaults().hide(TodayCardId.timeline).resize(TodayCardId.tasks, TodayCardSize.small);
    await repo.save(TodayLayoutClass.compact, custom);
    expect(await repo.load(TodayLayoutClass.compact), custom);
    expect(await repo.load(TodayLayoutClass.expanded), TodayLayout.defaults());
  });

  test('watch emits after save', () async {
    final stream = repo.watch(TodayLayoutClass.expanded);
    final custom = TodayLayout.defaults().move(TodayCardId.installment, 0);
    expectLater(stream, emitsThrough(custom));
    await repo.save(TodayLayoutClass.expanded, custom);
  });

  test('save is one transaction: a failure leaves the previous layout', () async {
    final first = TodayLayout.defaults().hide(TodayCardId.tasks);
    await repo.save(TodayLayoutClass.compact, first);
    await db.customStatement('CREATE TRIGGER fail_insert BEFORE INSERT ON today_layout_items WHEN NEW.card_id = \'installment\' BEGIN SELECT RAISE(ABORT, \'boom\'); END');
    await expectLater(repo.save(TodayLayoutClass.compact, TodayLayout.defaults()), throwsA(anything));
    expect(await repo.load(TodayLayoutClass.compact), first);
  });

  test('restart keeps the layout', () async {
    // covered with a file database in today_layout_migration_test; here: a second repository on the same db reads it.
    final custom = TodayLayout.defaults().hide(TodayCardId.installment);
    await repo.save(TodayLayoutClass.compact, custom);
    expect(await DriftTodayLayoutRepository(db).load(TodayLayoutClass.compact), custom);
  });
}
```

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement.** Table in `app_database.dart` after `LegacyImportRows`:
```dart
class TodayLayoutItemRows extends Table {
  @override
  String get tableName => 'today_layout_items';

  TextColumn get layoutClass => text().named('layout_class')();
  TextColumn get cardId => text().named('card_id')();
  IntColumn get position => integer()();
  TextColumn get size => text()();
  BoolColumn get hidden => boolean()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (layout_class IN ('compact', 'expanded'))",
    "CHECK (size IN ('small', 'wide', 'large'))",
    'CHECK (position >= 0)',
    'CHECK (length(trim(card_id)) > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{layoutClass, cardId};
}
```
Add it to `@DriftDatabase(tables: …)`, bump `schemaVersion` to 10, add the `from < 10` step, regenerate. Then the repository:
```dart
import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/today/domain/today_card_catalog.dart';
import 'package:borj/features/today/domain/today_layout.dart';
import 'package:borj/features/today/domain/today_layout_repository.dart';
import 'package:drift/drift.dart';

final class DriftTodayLayoutRepository implements TodayLayoutRepository {
  DriftTodayLayoutRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$TodayLayoutItemRowsTable, TodayLayoutItemRow> _query(TodayLayoutClass c) =>
      _db.select(_db.todayLayoutItemRows)..where((t) => t.layoutClass.equals(c.name));

  TodayLayout _parse(List<TodayLayoutItemRow> rows) => TodayLayout.parse([
    for (final r in rows) (cardId: r.cardId, position: r.position, size: r.size, hidden: r.hidden),
  ]);

  @override
  Stream<TodayLayout> watch(TodayLayoutClass layoutClass) => _query(layoutClass).watch().map(_parse);

  @override
  Future<TodayLayout> load(TodayLayoutClass layoutClass) async => _parse(await _query(layoutClass).get());

  @override
  Future<void> save(TodayLayoutClass layoutClass, TodayLayout layout) => _db.transaction(() async {
    await (_db.delete(_db.todayLayoutItemRows)..where((t) => t.layoutClass.equals(layoutClass.name))).go();
    for (var i = 0; i < layout.items.length; i++) {
      final item = layout.items[i];
      await _db.into(_db.todayLayoutItemRows).insert(
        TodayLayoutItemRowsCompanion.insert(
          layoutClass: layoutClass.name,
          cardId: item.card.name,
          position: i,
          size: item.size.name,
          hidden: item.hidden,
        ),
      );
    }
  });
}
```
Generated names (`$TodayLayoutItemRowsTable`, `TodayLayoutItemRow`, `TodayLayoutItemRowsCompanion`) follow Drift's convention for this codebase — check them in the regenerated `app_database.g.dart` (the existing tables use a `@DataClassName` or the default; follow what `LegacyImportRows` produces). The interface file holds the three-method interface above. Update `CLAUDE.md`'s "schema version 9" line to 10.

- [ ] **Step 4: Run** the two test files, then the full `flutter test --exclude-tags device` (existing schema tests may assert the version number; update them minimally and report). `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): today_layout_items table (schema 10) and repository`.

---

### Task 3: Layout controller with commit and undo

**Files:**
- Create: `lib/features/today/application/today_layout_controller.dart`
- Test: `test/features/today/today_layout_controller_test.dart`

**Interfaces:**
- Consumes: Tasks 1–2; `todayInstallmentProvider`.
- Produces:
  - `final todayLayoutProvider = StreamProvider.family<TodayLayout, TodayLayoutClass>((ref, c) => ref.watch(todayLayoutRepositoryProvider).watch(c));`
  - `final todayAvailableCardsProvider = Provider<Set<TodayCardId>>(...)` — timeline and tasks always; installment when `todayInstallmentProvider` has a plan.
  - `final class TodayLayoutController { TodayLayoutController(TodayLayoutRepository repository); Future<void> commit(TodayLayoutClass c, TodayLayout next); Future<void> undo(TodayLayoutClass c); bool canUndo(TodayLayoutClass c); }` — `commit` loads the current layout first (or uses the last committed value), saves `next`, and keeps the previous layout as the single undo step for that class; `undo` saves the kept previous layout and clears it. Commits of an identical layout are no-ops (no write, undo slot unchanged).
  - `final todayLayoutControllerProvider = Provider<TodayLayoutController>((ref) => TodayLayoutController(ref.watch(todayLayoutRepositoryProvider)));`

- [ ] **Step 1: Write the failing tests** (`ProviderContainer` with `appDatabaseProvider` overridden by an in-memory database):
```dart
// 1. todayLayoutProvider(compact) emits the defaults on an empty database.
// 2. commit(compact, hidden timeline) → the provider emits it; repository.load returns it; expanded unchanged.
// 3. undo(compact) → the defaults again; canUndo false afterwards.
// 4. two commits then undo → the FIRST commit's result (single-step undo restores the state before the last commit).
// 5. committing an identical layout writes nothing (count rows' updates via a counting repository wrapper) and keeps canUndo as it was.
// 6. todayAvailableCardsProvider: no installment plan → {timeline, tasks}; with an active plan → all three.
```
Write each as a concrete `test(...)` with real `await`s and `expect`s.

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** as specified (store the undo slots in a `Map<TodayLayoutClass, TodayLayout>`; read the current layout with `repository.load` before saving).
- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): layout controller with commit and undo`.

---

### Task 4: Grid robustness and animated reflow

**Files:**
- Modify: `lib/features/today/presentation/today_grid.dart`
- Test: `test/features/today/today_grid_test.dart`

**Interfaces:**
- Produces: `TodayGrid` gains `bool animate = true` and animates a card's slot change (position and, for the card being resized only, size) with `SpringCurve(AppMotion.standard)` over its settle time; Reduce Motion or `animate: false`: jumps. `packTodayGrid` asserts `columns >= 1`. `TodayGrid` asserts a bounded width (`assert(constraints.hasBoundedWidth)` with a message). Item identity is `TodayGridItem.id` (slots keyed `today-slot-<id>`, keys stable across reorders).

- [ ] **Step 1: Write the failing tests** (add to `today_grid_test.dart`):
```dart
// Deferred from Part B:
// - packTodayGrid([small, large, small, small], columns: 4) → '0,0 1,0 3,0 0,2'
// - packTodayGrid([wide, small, small], columns: 2) → '0,0 0,2 1,2'
// - packTodayGrid([...], columns: 0) throws AssertionError
// - TodayGrid under an unbounded width (inside a horizontal ListView) throws a FlutterError/AssertionError mentioning bounded width
// Reflow:
// - swapping two items' order animates: 1 frame after the rebuild the moved card is between its old and new top; after settle it is exactly at the new slot
// - reduce motion: the card is at the new slot on the first frame after the rebuild (expectNoMovement-style: getRect equals the target immediately)
// - the State of a card's child survives a reorder (a counter child keeps its count)
```
Write them concretely with `slots(...)` as in the existing file and `tester.getRect(find.byKey(ValueKey('today-slot-<id>')))`.

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Convert `TodayGrid` to a `StatefulWidget` that keeps the last slot rect per id; each child is wrapped in an `_AnimatedSlot` (`ImplicitlyAnimatedWidget`-style or a per-item `AnimationController`) driving `PositionedDirectional` from the previous rect to the new one with the standard spring curve; a newly appearing id starts at its target (no fly-in); a removed id disappears at once (the hide ghost is Task 6's job).
- [ ] **Step 4: Run.** Expected: PASS; the existing grid and TodayPage tests stay green. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): grid reflow animation and robustness`.

---

### Task 5: Edit mode — enter, exit, badges and handle

**Files:**
- Create: `lib/features/today/presentation/today_edit_mode.dart`
- Test: `test/features/today/today_edit_mode_test.dart`

**Interfaces:**
- Produces:
  - `class TodayEditScope extends InheritedNotifier<ValueNotifier<bool>>` with `static bool of(BuildContext)` / `static ValueNotifier<bool> controllerOf(BuildContext)`.
  - `class TodayEditableCard extends StatefulWidget { const TodayEditableCard({required TodayCardId card, required Widget child, required VoidCallback onRemove, required VoidCallback onCycleSize, required VoidCallback onEnterEdit, Widget? dragHandle, Widget? resizeHandle, Key? key}); }` — outside edit mode: the child, plus a 500 ms long-press (`RawGestureDetector` with `LongPressGestureRecognizer(duration: Duration(milliseconds: 500))`) calling `onEnterEdit` (+ `HapticFeedback.mediumImpact()` on Android) and, on medium/expanded, a secondary-tap calling `onEnterEdit`. In edit mode: `AnimatedScale(0.965, quick)` (no scale under Reduce Motion), `IgnorePointer` over the child, a remove badge at `PositionedDirectional(top: -6, start: -6)` (a 28 pt flat circle `colors.textSecondary` with a white «−», inside a 44 pt hit box, `Semantics(label: 'پنهان کردن <title>')`, key `today-remove-<card>`), a resize handle at `PositionedDirectional(bottom: -6, end: -6)` (flat 28 pt circle with `Icons.open_in_full`, 44 pt hit box, key `today-resize-<card>`, tap → `onCycleSize`); both appear with `quick` fade + scale 0.9 → 1 (fade only when reduced).
  - `class TodayEditToggle extends StatelessWidget` — the «ویرایش» / «تمام» link-tone text button (`ValueKey('today-edit-toggle')`, 44 pt hit target) for the header row.

- [ ] **Step 1: Write the failing tests** `test/features/today/today_edit_mode_test.dart`:
```dart
// 1. long-press 500 ms on a card → onEnterEdit called; a 300 ms press → not called.
// 2. secondary tap on medium/expanded → onEnterEdit; on compact → nothing.
// 3. in edit mode: the child does not receive taps (a button inside the child is not pressed); badge and handle exist with 44 pt hit boxes;
//    the badge is top-right and the handle bottom-left in RTL (compare to the card rect).
// 4. badge tap → onRemove; handle tap → onCycleSize.
// 5. card scale settles to 0.965 with quick; reduce motion: no scale change (expectNoMovement), badges fade only.
// 6. no glass on glass: badge and handle contain no AppGlass.
// 7. TodayEditToggle shows «ویرایش» when off and «تمام» when on, toggling the notifier.
// 8. glassTestVariants matrix: renders in edit mode without exception.
```
Write each concretely.

- [ ] **Step 2–5:** run (FAIL), implement, run (PASS), `flutter analyze`, commit `feat(today): edit mode with badges and handle`.

---

### Task 6: Hide, add sheet, reset and the empty state

**Files:**
- Create: `lib/features/today/presentation/today_add_card_sheet.dart`
- Modify: `lib/features/today/presentation/today_page.dart` (wiring only where needed for tests; the full page integration is Task 10)
- Test: `test/features/today/today_add_card_sheet_test.dart`

**Interfaces:**
- Consumes: Tasks 1, 3; `showGlassSheet`, `showUndoToast`, `GlassVisibility`.
- Produces:
  - `Future<void> showTodayAddCardSheet(BuildContext context, {required TodayLayoutClass layoutClass, Rect? origin})` — sheet content: title «افزودن کارت», one flat tile per hidden card (`ValueKey('today-add-<card>')`: title, subtitle, default size label; unavailable cards add the note «فعلاً چیزی برای نمایش ندارد»), «بازگردانی چیدمان پیش‌فرض» (`ValueKey('today-reset')`), «مدیریت کارت‌ها» (`ValueKey('today-manage-cards')` → `context.push('/today/cards')`). Tapping a tile commits `layout.add(card)` and pops; reset commits `TodayLayout.defaults()`, pops, and shows `showUndoToast(message: 'چیدمان پیش‌فرض برگشت', onUndo: controller.undo)`. No hidden cards: the sheet says «همهٔ کارت‌ها روی امروز هستند».
  - `TodayHideGhost`: a widget the page shows in place of a hidden card for 180 ms — the card's last frame with `GlassVisibility` going 1 → 0 and scale 1 → 0.96 (`AppMotion.quick` curve), removed afterwards; Reduce Motion: fade only.
  - The hide flow (page-level helper `Future<void> hideTodayCard(BuildContext, {required TodayLayoutClass c, required TodayCardId card})`): commit `layout.hide(card)`, then `showUndoToast(message: 'کارت پنهان شد', onUndo: …undo)`.

- [ ] **Step 1: Write the failing tests** (`pumpBorjTestApp` with seed data; `TodayEntrance.reset()`):
```dart
// 1. sheet lists only hidden cards; tapping one adds it to the END of the visible cards, persists it (read via the repository), and closes the sheet.
// 2. reset → the default layout is persisted; the undo toast appears; tapping «برگرداندن» restores the previous layout (repository read-back).
// 3. hide helper → the card is gone from the grid, the repository shows it hidden, the undo toast's action restores it.
// 4. the ghost fades through GlassVisibility (value goes below 1) and is removed after 180 ms; bareFadesAboveGlass is empty during the fade.
// 5. «مدیریت کارت‌ها» pushes /today/cards (until Task 9 exists, assert the location only).
// 6. all cards hidden → Today shows «کارتی روی امروز نیست» with «افزودن کارت», which opens the sheet.
```
Write each concretely.

- [ ] **Step 2–5:** run (FAIL), implement, run (PASS), `flutter analyze`, commit `feat(today): hide, add, reset and the empty state`.

---

### Task 7: Drag to move

**Files:**
- Create: `lib/features/today/presentation/today_move.dart`
- Test: `test/features/today/today_move_test.dart`

**Interfaces:**
- Produces: `class TodayMoveLayer extends StatefulWidget { const TodayMoveLayer({required List<TodayGridItem> items, required ValueChanged<List<String>> onReorder /* new visible id order */, required bool editing, required VoidCallback onEnterEdit, Key? key}); }` — wraps the `TodayGrid`: a pointer down on a card in edit mode starts a drag at once; outside edit mode a 500 ms long-press enters edit mode and the same pointer continues as the drag (one gesture arena winner). While dragging: the card is drawn in an overlay copy at the pointer minus the grab offset, scaled 1.04 (no scale under Reduce Motion), with a `knobShadow` shadow, wrapped in `GlassPreferencesScope(reduceTransparency: true)` (FakeGlass material while moving, §6); its slot in the grid is held by the live reflow (the other cards reflow with `standard` as the order changes: the dragged card takes the index of the card whose rect contains the pointer). On release: the overlay springs to the slot with `soft` using the release velocity (instant under Reduce Motion), then real glass returns; `onReorder` is called once with the final order (only if it changed). Keys: `today-drag-overlay`.

- [ ] **Step 1: Write the failing tests:**
```dart
// 1. edit mode: drag the first card over the third → onReorder([second, third, first]) once; the overlay follows the pointer 1:1 (rect offset == drag delta at each move).
// 2. not editing: a 500 ms long-press then a move without lifting → onEnterEdit called and the drag reorders.
// 3. a short tap does not start a drag.
// 4. while dragging the overlay is under GlassPreferencesScope(reduceTransparency: true); after release and settle it is gone and the grid card has real glass settings again.
// 5. countCompositedBackdrops ≤ 3 (compact, overlay backdrop on) sampled every frame of a 1 s drag.
// 6. reduce motion: no scale on lift (overlay size == slot size), release jumps to the slot.
// 7. dropping on the same index → onReorder not called.
```
Write each concretely with `tester.startGesture`, `moveBy` in small steps and `pump(16 ms)`.

- [ ] **Step 2–5:** run (FAIL), implement, run (PASS), `flutter analyze`, commit `feat(today): drag cards to reorder`.

---

### Task 8: Resize by handle

**Files:**
- Create: `lib/features/today/presentation/today_resize.dart`
- Test: `test/features/today/today_resize_test.dart`

**Interfaces:**
- Produces:
  - Pure helpers (unit-tested): `double rubberBand(double offset, {double dimension = 200})` → `offset * 0.55 * dimension / (dimension + 0.55 * offset.abs())` with the offset's sign; `double projectRelease(double position, double velocityPxPerS)` → `position + velocityPxPerS / 1000 * 0.998 / (1 - 0.998)`; `TodayCardSize nearestSize(Size frame, List<TodayCardSize> allowed, double columnWidth)` → the allowed size whose slot size (columns × colWidth + gaps, `todayCardHeight`) is nearest to the frame (Euclidean distance between the two sizes).
  - `class TodayResizeHandle extends StatefulWidget { const TodayResizeHandle({required TodayCardId card, required TodayCardSize size, required double columnWidth, required ValueChanged<TodayCardSize?> onPreview /* null when done */, required ValueChanged<TodayCardSize> onCommit, required VoidCallback onCycle, Key? key}); }` — a pan on the handle grows the frame from the card's fixed start/top corner (the handle is at the bottom-END corner): frame = slot size + pointer delta, rubber-banded past the smallest/largest allowed slot; it reports `onPreview(nearestSize)` whenever the nearest size changes (+ `HapticFeedback.selectionClick()` on Android); on release it projects the frame with the release velocity, takes `nearestSize` of the projected frame, calls `onCommit(size)` (only if changed) and `onPreview(null)`; a tap calls `onCycle`. While resizing, the card is under `GlassPreferencesScope(reduceTransparency: true)`.
  - `class TodayResizePreview extends StatelessWidget { const TodayResizePreview({required String title, required TodayCardSize size, Key? key}); }` — the flat placeholder in the card's real slot (Decision 2): dashed `colors.accent` 1.5 px outline radius 26, inside a flat panel at 30 % opacity with the title and `size.label` (`ValueKey('today-resize-preview')`). A dashed border needs a small `CustomPainter` (`_DashedRRectPainter`, dash 6 gap 4).
  - The page (Task 10) feeds `onPreview` into the grid so the other cards make room live for the preview size.

- [ ] **Step 1: Write the failing tests:**
```dart
// Pure:
// - rubberBand(0) == 0; rubberBand(100) ≈ 100*0.55*200/(200+55) ; sign kept for negatives; |rubberBand(x)| < |x| for x != 0 and < 0.55*200 for any x.
// - projectRelease(100, 0) == 100; projectRelease(100, 1000) ≈ 100 + 499.
// - nearestSize: a frame of a wide slot → wide; between wide and large but closer to large → large; a frame for a disallowed size picks the nearest ALLOWED one.
// Widget:
// - dragging the handle of the tasks card (large) up by a small card's height reports onPreview(wide) then onPreview(small) as it crosses; release commits small.
// - a quick downward flick from small (small move, high velocity) commits a larger size because of projection.
// - tap → onCycle.
// - past the largest size the frame grows less than the pointer (rubber band) — compare the frame rect growth to the drag delta.
// - while resizing the card is under GlassPreferencesScope(reduceTransparency: true); preview shows title and «کوچک».
// - countCompositedBackdrops ≤ 3 (compact) sampled every frame of a 1 s resize.
// - reduce motion: release jumps to the committed size (no spring).
```
Write each concretely.

- [ ] **Step 2–5:** run (FAIL), implement, run (PASS), `flutter analyze`, commit `feat(today): resize cards by handle with preview and projection`.

---

### Task 9: The «کارت‌های امروز» screen

**Files:**
- Create: `lib/features/today/presentation/today_cards_screen.dart`
- Modify: `lib/app/router/app_router.dart` (root route `/today/cards`, `GlassPushPage`), the legacy Settings screen (`lib/features/settings/presentation/settings_screen.dart`: add a row «کارت‌های امروز» that pushes `/today/cards`; follow that screen's existing row style)
- Test: `test/features/today/today_cards_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 1, 3; `GlassToggle`, `GlassSegmented`, `GlassButton`, `LargeTitleHeader`, `showUndoToast`; the layout class of the CURRENT window (`TodayLayoutClass.forWindow(WindowClass.of(context))`).
- Produces: `class TodayCardsScreen extends ConsumerWidget` per the Global Constraints line (board `PhoneDashboardCards`). Row keys `today-cards-row-<card>`, toggle `today-cards-toggle-<card>`, size segmented `today-cards-size-<card>`, «بالا» `today-cards-up-<card>`, «پایین» `today-cards-down-<card>`, drag handle `today-cards-handle-<card>` (a `ReorderableListView` or `ReorderableDragStartListener` inside the visible section only), reset `today-cards-reset`. Every change commits through `TodayLayoutController`; reset shows the undo toast. Rows of unavailable cards show «فعلاً چیزی برای نمایش ندارد» under the subtitle. Things inside the section panels are flat or on-glass variants (no glass on glass).

- [ ] **Step 1: Write the failing tests** (`pumpBorjTestApp`, push `/today/cards`):
```dart
// 1. sections «نمایان · ۳ کارت» / «پنهان · ۰ کارت» on the default layout; toggling timeline off moves it to «پنهان · ۱ کارت» and persists.
// 2. «پایین» on timeline → order tasks, timeline, installment (persisted); «بالا» on the first row is disabled.
// 3. the size segmented of tasks offers exactly کوچک / پهن / بزرگ and selecting کوچک persists small; installment offers only کوچک / پهن.
// 4. dragging the handle of installment above tasks reorders (persisted).
// 5. reset → defaults + undo toast; undo restores.
// 6. Settings has a «کارت‌های امروز» row that opens this screen.
// 7. glassTestVariants matrix renders; no AppGlass inside another AppGlass.
```
Write each concretely.

- [ ] **Step 2–5:** run (FAIL), implement, run (PASS), `flutter analyze`, commit `feat(today): today cards screen (accessible path)`.

---

### Task 10: TodayPage integration, screen-reader actions and keyboard

**Files:**
- Modify: `lib/features/today/presentation/today_page.dart`, `lib/features/today/presentation/today_header.dart` (edit toggle in the header row), `lib/app/apple_visual/review/design_review_samples.dart` (edit-mode sample)
- Test: `test/features/today/today_page_customization_test.dart`, `test/features/today/today_budget_test.dart` (extend)

**Interfaces:**
- Consumes: Tasks 1–9; Part B cards (size-specific content: `TimelineCard(size:)`, `TodayTasksCard(size:)`, `InstallmentCard(size:)`).
- Produces: TodayPage builds the grid from `todayLayoutProvider(layoutClass).visible`, filtered by `todayAvailableCardsProvider`, each item with its stored size, wrapped in `TodayEditableCard` inside `TodayMoveLayer`, with the resize handle, the preview and the hide ghost; `TodayEditScope` above; `TodayEditToggle` in the header row (end side); «+ افزودن کارت» (`ValueKey('today-add-card')`, a tinted-free `GlassButton(variant: chrome)` on the background, not on glass) under the grid in edit mode; tap on empty space and `Escape` exit edit mode; the empty state when nothing is visible. Screen-reader actions on each card in edit mode (`Semantics(customSemanticsActions: {...})`): «جابه‌جایی به قبل», «جابه‌جایی به بعد», «تغییر اندازه», «پنهان کردن». Keyboard in edit mode (a `Focus` per card, `FocusTraversalGroup` for the grid): arrows move (RTL mapping in Global Constraints), `S` cycles size, `Delete`/`Backspace` hides, `Escape` exits — instant (no animation, `TodayGrid(animate: false)` for keyboard-driven commits).

- [ ] **Step 1: Write the failing tests:**
```dart
// 1. a persisted custom layout (tasks small first, timeline hidden) renders in that order and size on compact; the expanded layout is independent (resize the window → the expanded layout, default).
// 2. installment hidden in the stored layout stays hidden even with a plan; available-filter: with no plan the installment card is skipped without a gap.
// 3. «ویرایش» enters edit mode (badges visible); «تمام», Escape and a tap on empty space each exit.
// 4. screen-reader actions: invoking «جابه‌جایی به بعد» on the first card moves it to index 1 (persisted); «تغییر اندازه» cycles; «پنهان کردن» hides with the undo toast.
// 5. keyboard (expanded, RTL): focus the first card, press ← → it moves to index 1; S cycles its size; Delete hides; Escape exits; each change is on the next frame (no animation).
// 6. a long-press and drag on a card outside edit mode enters edit mode and reorders (end-to-end through the page).
// 7. budgets: countCompositedBackdrops == 2 idle in edit mode; ≤ 3 during a drag and during a resize on compact; ≤ 4 on expanded.
// 8. reduce motion: entering edit mode moves nothing (no scale), badges fade.
```
Write each concretely with `pumpBorjTestApp(seed: …)`, `useWindowSize`, `TodayEntrance.reset()` in setUp, `tester.binding.pipelineOwner.semanticsOwner!.performAction(…)` for custom actions (or `tester.semantics.performAction` if available in this Flutter), and `sendKeyEvent`.

- [ ] **Step 2–5:** run (FAIL), implement, run (PASS); full `flutter test --exclude-tags device`; `TZ=UTC flutter test test/features/today`; `flutter analyze`; commit `feat(today): customizable Today with screen-reader and keyboard paths`.

---

### Task 11: Device probe — edit-mode drag and resize

**Files:**
- Modify: `integration_test/glass_shell_probe_test.dart`

- [ ] **Step 1:** In the phone and desktop Today cases, after the existing sampling: enter edit mode («ویرایش»), drag the first card over the second for 1.5 s in 16 ms steps, then drag the tasks card's resize handle through two sizes for 1.5 s, sampling `countCompositedBackdropsDetailed` every frame: worst ≤ budget (phone 3, desktop 4) and ≥ 2 plus the seeded-pass floor; print `LG_COMPOSITED … editDrag=<n> editResize=<n>`. Then `watchPerformance` 3 s of the same drag back and forth (`reportKey: 'glass_today_edit_<phone|desktop>'`) with the profile p90 ≤ 8 ms and the Part A floors (p90 > 0, ≥ 60 frames).
- [ ] **Step 2:** Run `flutter test integration_test/glass_shell_probe_test.dart -d linux`, `tool/ci.sh --device`, and the profile drive. If a budget fails, stop and report (do not loosen).
- [ ] **Step 3: Commit** `test(today): device probe for edit-mode drag and resize`.

---

### Task 12 (controller): Phase 2 checkpoint and owner sign-off

- [ ] Final whole-branch review (most capable model) and one fix wave.
- [ ] `docs/superpowers/checkpoints/2026-11-XX-redesign-phase-2-checkpoint.md` (Parts A, B, C), WORKLOG, roadmap; merge into `feat/v2-complete-dashboard`.
- [ ] Ask the owner, in Persian: try Today on Linux (phone-size and desktop windows, light and dark), the edit mode (move, resize, hide, add, reset), the review page samples next to the boards; and whether to prepare the A34 profile build now.
