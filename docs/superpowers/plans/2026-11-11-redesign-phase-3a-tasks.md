# Redesign Phase 3 Part A — Tasks List, Kanban and Quick Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy `TasksPanel` in the Tasks branch with the new Tasks screen of the `PhoneTasks`, `PhoneKanban` and `MacTasks` boards: smart filter tiles, a sectioned glass task list with swipe actions, a kanban (paged by status on phone, flex columns on desktop) with drag between statuses, the view switch, an options sheet that keeps every legacy action, and a task quick-entry sheet (also wired to Today's «ورود سریع»).

**Architecture:** A pure query layer (`lib/features/tasks/application/task_list_query.dart`) derives smart counts, sections, search and sort from the task streams and the Part B time base (task-zone wall clock). Presentation lives in `lib/features/tasks/presentation/tasks_screen/` and composes Phase 1/2 primitives only; every mutation goes through the existing repositories and `TaskBoardOperations`. Detail, calendar, timer and templates keep their legacy widgets until Parts 3B–3D, reached from the new screen.

**Tech Stack:** Flutter 3.47.5, Riverpod, go_router, Drift repositories, the Phase 1/2 primitives (`lib/app/design/`).

**Phase 3 split:** 3A (this) list + kanban + view switch + options + quick entry; 3B task detail (phone sheet, desktop shell inspector slot, same-URL adaptive detail) + reminder and recurrence editor; 3C month calendar + day timeline + timer; 3D templates manager and editor.

## Global Constraints

Copied verbatim from the Phase 2 Part B plan (`docs/superpowers/plans/2026-11-09-redesign-phase-2b-today.md`), which carries the Part A and Phase 1 Part B constraints and the Part B controller amendments A1–A5 ("Task N" inside these lines means a task of that earlier plan):

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

Part B decisions that bind this plan: 4 ("today" for tasks), 7 (grid columns follow width — not used here), 8 (completed untimed stay — Today only).

Added for Part A of Phase 3:
- Boards: `PhoneTasks`, `PhoneKanban`, `MacTasks` (layout wins), `PhoneQuickEntry` (sheet geometry only; its expense variant is Phase 4).
- Hidden features (spec §1: the board is the target of a future spec): task lists/categories («کار», «خانه», «شخصی» chips, the list tag on rows and cards), subtasks (progress bar, «زیروظیفه»), natural-language parsing in quick entry, the quick-entry type switch («هزینه / درآمد / کار / عادت»). None of these are built or drawn.
- Nothing the legacy panel can do is lost (inventory in the 3A plan's Decision 1): search, filter, sort, priority change, delete, clear completed, export, templates, add with details, kanban moves (between statuses, within a status, prev/next, up/down), canceled status.
- Time: every "now", "today", "overdue" uses the Part B time base (`todayNowProvider` wall clock in the task calendar zone, `taskCalendarTimeZoneProvider`). Never `DateTime.now()` in tasks code (the legacy panel's `DateTime.now()` calls are not copied).
- Phone screen (board `PhoneTasks`): toolbar actions (shell `ShellAction`s for the Tasks branch on compact): «گزینه‌ها» (`Icons.more_horiz`, leading) and «کار جدید» (`Icons.add`, primary) — 2 + capsule + search = 4 chrome shapes. Header: subtitle «<n> کار باز» (15 pt w600; n = active tasks), large title «کارها» (`LargeTitleHeader`, key `tasks-title`). View segmented (`GlassSegmented`, key `tasks-view`): «فهرست», «کانبان», «تقویم» with icons; the selection is the route query `?view=list|board|calendar` (default list). Smart tiles (list view only): a 2 × 2 grid, gap 10, each tile `AppGlass(role: row, rounded 22)`, 56 tall, a 32 pt flat colour disc with an icon, label 14 w700, count 22 w900 tabular; tiles «امروز» (accent), «زمان‌دار» (warn), «عقب‌افتاده» (danger, count in danger tone), «همه» (secondary); the selected tile shows a `GlassInner` lens (only one tile selected; default «همه»).
- Desktop (board `MacTasks`, medium/expanded): toolbar actions «کار جدید» (primary); the page shows a header chip like Today's date chip (clear glass, primary/secondaryStrong tones, Part B Decision 6) with subtitle «<n> کار باز» and title «همهٔ کارها», then the view segmented and the content; the default view on medium/expanded is `board` (the board's kanban), on compact `list`.
- List (board `PhoneTasks`): one `GlassScope(content)` + one `AppGlass(role: panel, rounded 26, padding 2/16/4)` per section group of ≤ 15 rows (a scope holds ≤ 16 shapes; rows inside are flat, so one panel per page of rows is one shape); section headers 12 pt w700 (`textSecondary`; «عقب‌افتاده» in danger tone): «عقب‌افتاده», «امروز», «آینده», «بی‌زمان», «انجام‌شده». Row: `RoundCheck` 24, title (w600; done: tertiary + line-through), subline 12 pt (time «۱۵:۰۰» or date «۱۴ آبان», and the priority label when priority > 0: «اولویت بالا» danger, «اولویت متوسط» warn, «اولویت پایین» secondary), min height 48 (52 with a subline), 0.5 px hairline between rows. Swipe actions (end-to-start drag reveals, 58 pt each, 10 pt label): «تکمیل» (teal; completes / reopens) and «حذف» (danger; deletes, then `showUndoToast(message: 'کار حذف شد')` whose undo re-creates the task with the same id, title, fields, status and position). Tap on a row opens the edit (legacy dialog until 3B; via `context.push('/tasks/<id>')` which shows the legacy dialog route until 3B — see Task 6). Long-press (and secondary click) opens a row menu: «ویرایش», «اولویت» (cycles), «در حال انجام» / «برنامه‌ریزی‌شده» (status toggle), «لغو کار» / «بازگردانی» (canceled toggle), «حذف».
- Sections: «عقب‌افتاده» = not done, not canceled, due (else start) before the start of today; «امروز» = Today's agenda definition (Part B Decision 4, untimed excluded here); «آینده» = dated after today; «بی‌زمان» = no start and no due, active; «انجام‌شده» = completed (and canceled ones last, labelled «لغوشده» in the subline), collapsed behind «نمایش انجام‌شده‌ها (<n>)». Within a section: by time, then priority desc, then displayNumber. Smart tile filters: «امروز» = the «امروز» section; «زمان‌دار» = active tasks with a start or due; «عقب‌افتاده» = the «عقب‌افتاده» section; «همه» = all sections.
- Search: a `GlassTextField` (hint «جست‌وجو در کارها…», key `tasks-search`) under the tiles on compact and in the header row on desktop; matches title and description, Arabic ي/ك normalised to ی/ک (legacy `_normalize`), applies to list and kanban.
- Options sheet («گزینه‌ها», `showGlassSheet`): «مرتب‌سازی» (`GlassSegmented` «زمان» / «اولویت» / «جدیدترین» / «الفبا»; default «زمان»), «پاک کردن انجام‌شده‌ها (<n>)» (disabled when 0; `TaskRepository.deleteCompleted()` with an undo toast that re-creates them), «خروجی» (the legacy export handler — reuse it exactly; read `_TasksToolbar` in the legacy panel), «افزودن با جزئیات» (legacy details dialog in create mode, same calls as `_addTaskWithDetails`), «انتخاب قالب» and «مدیریت قالب‌ها» (legacy template picker / manager dialogs, same calls), «تقویم» (switches to `?view=calendar`). On desktop the same items are a «گزینه‌ها» glass button in the header row that opens the same sheet.
- Kanban phone (board `PhoneKanban`): status segmented (role tablist, `GlassSegmented`, 4 segments 50 tall: count 15 w900 over the label 10.5): «برنامه‌ریزی‌شده», «در حال انجام», «انجام‌شده», «لغوشده»; column header: a 10 pt status dot (planned accent, inProgress warn, completed teal, canceled secondary), title 17 w900, «<n> کار», and «ستون <i> از ۴» at the end; a `PageView` with one column per page (swiping pages and tapping a segment stay in sync); cards: `AppGlass(role: row, rounded 22, padding 12/14)` inside one content scope per page (≤ 16 cards per scope; more → additional scopes), title 15 w800, meta row 12 pt (date/time, priority label), no list tag, no subtask bar. Drag: long-press a card lifts it (scale 1.04, shadow, FakeGlass material while moving, same rules as Part C §6), the drop hint row «نگه دارید و بکشید تا به ستون دیگر بروید» (48 tall, dashed accent) appears; dropping on a status segment moves the task to the END of that status (`TaskBoardOperations.move` → `transition`); dropping within the visible column reorders (`reorderWithinStatus`). Each card also has an overflow menu (same as the row menu, plus «انتقال به ستون قبلی / بعدی», «بالا» / «پایین») so every move is possible without dragging (accessibility).
- Kanban desktop (board `MacTasks`): four columns side by side, each `AppGlass(role: panel)` 260 min width (flex), header dot + title + count; cards are flat `GlassInner` rows inside the column glass (radius 16, padding 10/11) — on desktop the column is the glass and cards are inner (board `lg-in`); drag and drop between and within columns with `Draggable`/`DragTarget` (mouse), the same menu actions, keyboard: a focused card moves with arrow keys (←/→ status in RTL order, ↑/↓ within a status) and Enter opens it.
- Empty states (flat `EmptyState` inside the content): no tasks «هنوز کاری اضافه نکرده‌اید» / «با دکمهٔ «کار جدید» اولین کارت را بنویس.»; search with no match «چیزی پیدا نشد» / «عبارت دیگری را جست‌وجو کنید.»; tile «امروز» empty «امروز کاری نداری»; tile «عقب‌افتاده» empty «کار عقب‌افتاده‌ای نداری»; tile «زمان‌دار» empty «کار زمان‌داری نداری»; empty kanban column: the legacy per-column texts («کاری برای برنامه‌ریزی وجود ندارد.», «کاری در حال انجام نیست.», «کاری انجام نشده است.», «کاری لغو نشده است.»).
- Quick entry (sheet `showGlassSheet`, from «کار جدید», Today's «ورود سریع»/«افزودن» and the Tasks toolbar): title «کار جدید», a `GlassTextField` (label «عنوان کار», autofocus, submit = «ثبت»), a «زمان» chip row: «امروز», «فردا», «بدون تاریخ» (default «بدون تاریخ»; «امروز» / «فردا» set `dueAtUtc` to 23:59 of that local day in the task calendar zone, converted to UTC), an «اولویت» `GlassSegmented` («بدون», «پایین», «متوسط», «بالا»), buttons «ثبت» (tinted, 54 tall, disabled while the title is empty) and «ویرایش جزئیات» (`GlassInner`, opens the legacy details dialog prefilled with the typed title, priority and due). «ثبت» creates the task exactly like the legacy `_addTask` (`create` + `transition(planned, 0)`), closes the sheet and shows `showUndoToast(message: 'کار اضافه شد')` (undo deletes it).
- Budgets as Phase 2: compact ≤ 3, expanded ≤ 4, measured during scrolling, swiping, paging and dragging. The Tasks screen is no longer legacy, so the device probe ASSERTS its budget (Part A Decision 7 no longer covers Tasks).

## Decisions recorded by this plan

1. **Inventory first.** The legacy `TasksPanel` feature inventory (delivered 2026-11-11 by the survey agent; summarised in the Global Constraints) is the checklist for "nothing is lost". Every legacy action has a home: list rows, row menu, kanban card menu, options sheet, quick entry.
2. **Lists and subtasks stay hidden** (no domain model; their own spec later).
3. **Quick entry is task-only and simple** (title, day chip, priority). Natural-language parsing and the expense/income/habit tabs are separate specs (redesign spec §7 "out of scope").
4. **Search stays on the Tasks screen** (a field), although the board relies on the global search tab: the global search engine does not exist yet (Part A search shell is a placeholder).
5. **Desktop default view is the kanban** (board `MacTasks`); phone default is the list (board `PhoneTasks`).
6. **Detail is still the legacy dialog** (3B rebuilds it). `/tasks/:taskId` opens the legacy edit dialog over the Tasks screen instead of the Part A `PendingScreen`, so notification deep links and row taps reach a real editor now.
7. **Calendar, timer, templates keep their legacy widgets** inside the new screen until 3C/3D: `?view=calendar` shows the legacy `TaskCalendarBoard`; the legacy `TaskActiveTimerStrip` stays above the content when a timer runs; templates open the legacy dialogs. Their glass is printed, not asserted, in the probe.
8. **Delete gets an undo toast** (legacy deleted without confirmation or undo).

## File structure

```
lib/features/tasks/application/task_list_query.dart           TaskSmartFilter, TaskSort, TaskSection, TaskListView, buildTaskListView (pure)   (Task 1)
lib/features/tasks/application/tasks_screen_providers.dart    tasksScreenProvider (view, filter, sort, search state) + TaskActions            (Task 2)
lib/features/tasks/presentation/tasks_screen/task_glass_row.dart        TaskGlassRow (row, swipe, menu)                                      (Task 3)
lib/features/tasks/presentation/tasks_screen/task_smart_tiles.dart      TaskSmartTiles                                                       (Task 4)
lib/features/tasks/presentation/tasks_screen/task_list_view.dart        TaskSectionList                                                      (Task 4)
lib/features/tasks/presentation/tasks_screen/task_kanban_phone.dart     paged kanban                                                         (Task 5)
lib/features/tasks/presentation/tasks_screen/task_kanban_desktop.dart   flex kanban                                                          (Task 6)
lib/features/tasks/presentation/tasks_screen/task_quick_entry.dart      showTaskQuickEntry                                                   (Task 7)
lib/features/tasks/presentation/tasks_screen/tasks_options_sheet.dart   showTasksOptions                                                     (Task 8)
lib/features/tasks/presentation/tasks_screen/tasks_screen.dart          TasksScreen (header, view switch, composition)                       (Task 8)
lib/app/router/app_router.dart                                          /tasks → TasksScreen, /tasks/:taskId → legacy edit, actions          (Task 9)
lib/features/today/presentation/today_page.dart / app_router.dart       «ورود سریع» → quick entry                                            (Task 9)
integration_test/glass_shell_probe_test.dart                            Tasks budgets asserted                                               (Task 10)
```

---

### Task 1: The pure task list query

**Files:** Create `lib/features/tasks/application/task_list_query.dart`; Test `test/features/tasks/application/task_list_query_test.dart`.

**Interfaces:**
- Consumes: `TaskItem`, `TaskStatus`, `TodayAgendaBuilder` (Part B; for the «امروز» section use the same day range), `package:timezone`.
- Produces:
  - `enum TaskSmartFilter { today, timed, overdue, all }`, `enum TaskSort { time, priority, newest, alphabetical }`.
  - `enum TaskSectionKind { overdue, today, upcoming, untimed, done }` with `String get title` («عقب‌افتاده», «امروز», «آینده», «بی‌زمان», «انجام‌شده»).
  - `final class TaskListEntry { final TaskItem task; final DateTime? localInstant; /* zone wall clock of due ?? start */ }` and `final class TaskSection { final TaskSectionKind kind; final List<TaskListEntry> entries; }`.
  - `final class TaskSmartCounts { final int today, timed, overdue, all; }` (all = active = planned + inProgress).
  - `final class TaskListView { final List<TaskSection> sections; final TaskSmartCounts counts; final int activeCount; final int doneCount; }`
  - `String normalizeTaskSearch(String s)` (trim, lower, ي→ی, ك→ک, collapse spaces) and `bool taskMatches(TaskItem t, String query)` (title or description contain the normalized query; empty query matches all).
  - `TaskListView buildTaskListView({required List<TaskItem> tasks, required DateTime nowUtc, required String timeZoneId, TaskSmartFilter filter = TaskSmartFilter.all, TaskSort sort = TaskSort.time, String query = ''})`. Section membership and ordering per the Global Constraints ("Sections"). `TaskSort` reorders WITHIN sections (time: by localInstant, then priority desc, then displayNumber; priority: priority desc, then time; newest: createdAtUtc desc; alphabetical: title by Persian collation `compareTo` on the normalized title). Recurring tasks: the list shows each task once (its series anchor by start/due), not occurrences (occurrences are the calendar's job).

- [ ] **Step 1: Write the failing tests** (instants with `DateTime.utc`, zone `Asia/Tehran`, `tzdata.initializeTimeZones()` in `setUpAll`; now = `DateTime.utc(2026, 11, 4, 11, 0)` = 14:30 Tehran):
```dart
// sections:
// - due yesterday 20:00 local, planned → overdue; due today 09:00 (past) → today (not overdue: overdue is BEFORE today);
//   due tomorrow → upcoming; no dates → untimed; completed → done (last), canceled → done after completed.
// - an overdue task with only startAtUtc (no due) counts by its start.
// counts: today/timed/overdue/all with a mixed set; completed/canceled never counted in today/timed/overdue/all.
// filter: today → only the today section; overdue → only overdue; timed → dated active tasks across overdue/today/upcoming; all → all sections.
// sort: time order within a section; priority (3 before 1); newest (createdAt desc); alphabetical (Persian).
// search: 'كار' matches 'کار' in the title; description matches; no match → sections empty.
// time base: the same tasks with TZ of the test process changed do not move sections (run this file under TZ=UTC in Step 4).
```
Write each as a concrete `test(...)` with a `_task(...)` helper like `test/features/today/today_agenda_builder_test.dart`.
- [ ] **Step 2:** run → FAIL. **Step 3:** implement. **Step 4:** run (also `TZ=UTC` and `TZ=Asia/Tokyo`) → PASS; `flutter analyze`. **Step 5:** commit `feat(tasks): task list query (sections, smart filters, sort, search)`.

---

### Task 2: Screen state and task actions

**Files:** Create `lib/features/tasks/application/tasks_screen_providers.dart`; Test `test/features/tasks/application/tasks_screen_providers_test.dart`.

**Interfaces:**
- Produces:
  - `final tasksFilterProvider = StateProvider<TaskSmartFilter>((ref) => TaskSmartFilter.all);`, `final tasksSortProvider = StateProvider<TaskSort>((ref) => TaskSort.time);`, `final tasksQueryProvider = StateProvider<String>((ref) => '');`
  - `final taskListViewProvider = Provider<AsyncValue<TaskListView>>` combining `taskItemsProvider`, `taskCalendarTimeZoneProvider`, the minute tick (`minuteTickProvider` from Part B) and the three state providers.
  - `final class TaskActions { TaskActions({required TaskRepository repository, required AppClock clock}); Future<void> create({required String title, required int priority, DateTime? dueAtUtc}); /* create + transition(planned, 0); returns the id via a Future<String> variant createAndReturnId */ Future<String> createAndReturnId(...); Future<void> toggleDone(TaskItem t); Future<void> setStatus(TaskItem t, TaskStatus s); Future<void> cyclePriority(TaskItem t); Future<TaskItem?> delete(String id); /* returns the deleted task for undo */ Future<void> restore(TaskItem t); /* re-create with the same id and fields, then transition to its status at its position */ Future<List<TaskItem>> deleteCompleted(); Future<void> move(String taskId, TaskStatus status, int targetPosition); /* via TaskBoardOperations semantics: transition across statuses, reorderWithinStatus within */ }` — ids from the legacy generator (UuidV7; read the panel's `_idGenerator`), times from `AppClock.nowUtc()`, `displayNumber` handled as the legacy `_addTask` does.
  - `final taskActionsProvider = Provider<TaskActions>(...)`.

- [ ] **Step 1: Write the failing tests** (in-memory database via `ProviderContainer` + `appDatabaseProvider` override, `FixedAppClock`):
```dart
// create → repository has a planned task with title/priority/due; the id is a UUID v7 string.
// toggleDone planned → completed (completedAtUtc = clock); toggleDone completed → planned.
// setStatus(inProgress), setStatus(canceled) → status and positions contiguous (read positions back: 0..n-1).
// cyclePriority 0→1→2→3→0.
// delete returns the task; restore brings it back with the same id, title, priority, due, status and the same position (contiguity kept).
// deleteCompleted returns the deleted list; restoring each brings them back.
// move across statuses → transition to the end; move within → reorderWithinStatus order; no-op when unchanged.
// taskListViewProvider reflects filter/sort/query changes.
```
Concrete tests.
- [ ] **Steps 2–5:** run FAIL → implement → PASS (+ `flutter analyze`) → commit `feat(tasks): tasks screen state and task actions`.

---

### Task 3: TaskGlassRow (row, swipe actions, menu)

**Files:** Create `lib/features/tasks/presentation/tasks_screen/task_glass_row.dart`; Test `test/features/tasks/presentation/task_glass_row_test.dart`.

**Interfaces:**
- Produces: `class TaskGlassRow extends StatefulWidget { const TaskGlassRow({required TaskListEntry entry, required VoidCallback onToggle, required VoidCallback onOpen, required VoidCallback onDelete, required TaskRowMenuActions menu, bool divider = true, Key? key}); }` — flat row content (it sits inside a section panel's glass; no glass of its own) per the Global Constraints row line; key `task-row-<id>`. Swipe: a horizontal drag toward the start side reveals «تکمیل» and «حذف» (58 pt each, flat fills `colors.teal` / `colors.danger`, labels `AppTextTone.inverse`); release past 50 % of the actions' width keeps them open; tapping an action triggers it and closes; a fling past 80 % triggers «تکمیل»? — no: flings only open/close (no destructive fling). Reduce Motion: the reveal jumps. `TaskRowMenuActions` holds callbacks for the row menu items; long-press (and secondary click) opens a `showGlassSheet` menu with those items (on desktop a `MenuAnchor` is acceptable only if it renders flat; prefer the sheet everywhere for one code path). Semantics: one node per row (title، time/date، priority، done state) with custom actions «تکمیل» / «حذف» / «ویرایش»; RoundCheck keeps its own checked state (follow the Part B tasks card pattern: RoundCheck carries the label, the row content is `ExcludeSemantics` + `ExcludeFocus`).

- [ ] **Step 1: Write the failing tests:** row anatomy (title, «۱۵:۰۰» or «۱۴ آبان», «اولویت بالا» in danger); done → line-through tertiary; check tap → onToggle once; row tap → onOpen once; swipe reveal (drag −80 px) shows «تکمیل» and «حذف»; tapping «حذف» → onDelete once and the row closes; a short drag snaps back closed; long-press opens the menu with «ویرایش», «اولویت», «در حال انجام», «لغو کار», «حذف»; semantics single node + custom actions; reduce motion: no animation of the reveal (expectNoMovement after release); glassTestVariants matrix; no AppGlass inside the row; 44 pt targets.
- [ ] **Steps 2–5:** FAIL → implement → PASS → commit `feat(tasks): glass task row with swipe actions and menu`.

---

### Task 4: Smart tiles and the sectioned list

**Files:** Create `task_smart_tiles.dart`, `task_list_view.dart` under `lib/features/tasks/presentation/tasks_screen/`; Tests alongside in `test/features/tasks/presentation/`.

**Interfaces:**
- `class TaskSmartTiles extends StatelessWidget { const TaskSmartTiles({required TaskSmartCounts counts, required TaskSmartFilter selected, required ValueChanged<TaskSmartFilter> onSelected, Key? key}); }` — 2 × 2 tiles per the Global Constraints; one `GlassScope(content)` for the four tiles; keys `task-tile-<filter>`; the selected tile has a `GlassInner` lens (flat) and `Semantics(selected: true)`.
- `class TaskSectionList extends StatelessWidget { const TaskSectionList({required TaskListView view, required TaskSmartFilter filter, required TaskRowCallbacks callbacks, Key? key}); }` — a `SliverList`-friendly column of section headers and panels (one `GlassScope(content)` + `AppGlass(panel)` per chunk of ≤ 15 rows), the collapsed «انجام‌شده» section behind «نمایش انجام‌شده‌ها (<n>)» (`ValueKey('tasks-show-done')`), the empty states per filter/search.
- [ ] **Step 1: Tests:** tiles show counts in Persian digits; tapping «عقب‌افتاده» reports the filter; RTL: «امروز» top-right; sections order and headers; done collapsed then expanded; a section of 20 rows renders two panels (two `AppGlass`), each scope ≤ 16 shapes; empty states for no tasks / search / each filter; budget: `countCompositedBackdrops` == 2 idle (content + chrome is the page's job — here assert the list adds ONE content key: no `GlassBackdropGroup` inside); glassTestVariants matrix.
- [ ] **Steps 2–5:** FAIL → implement → PASS → commit `feat(tasks): smart tiles and sectioned task list`.

---

### Task 5: Phone kanban (paged by status)

**Files:** Create `task_kanban_phone.dart`; Test `test/features/tasks/presentation/task_kanban_phone_test.dart`.

**Interfaces:** `class TaskKanbanPhone extends StatefulWidget { const TaskKanbanPhone({required List<TaskItem> tasks /* already searched */, required TaskActions actions, required void Function(TaskItem) onOpen, Key? key}); }` per the Global Constraints (status segmented with counts, column header with «ستون <i> از ۴», PageView synced with the segmented, cards, long-press drag with drop on a segment = move to the end of that status, drag within the page = reorder, card menu with every move, FakeGlass while dragging, drop hint). Card key `kanban-card-<id>`, segment keys `kanban-status-<status>`.
- [ ] **Step 1: Tests:** segments show counts; tapping «انجام‌شده» pages to column 3 and the header reads «ستون ۳ از ۴»; swiping the PageView updates the segmented; long-press drag a card onto «در حال انجام» → the task's status becomes inProgress at the end (repository read-back); drag within a column reorders (positions read back); card menu «انتقال به ستون بعدی» / «پایین» move without dragging; empty column text per status; while dragging the moved card is under `GlassPreferencesScope(reduceTransparency: true)`; budget ≤ 3 during a drag (compact, overlay backdrop on); reduce motion: paging jumps, no lift scale.
- [ ] **Steps 2–5:** FAIL → implement → PASS → commit `feat(tasks): phone kanban paged by status`.

---

### Task 6: Desktop kanban (flex columns)

**Files:** Create `task_kanban_desktop.dart`; Test `test/features/tasks/presentation/task_kanban_desktop_test.dart`.

**Interfaces:** `class TaskKanbanDesktop extends StatefulWidget { const TaskKanbanDesktop({required List<TaskItem> tasks, required TaskActions actions, required void Function(TaskItem) onOpen, Key? key}); }` — four flex columns (min 260; horizontal scroll if the width is below 4 × 260 + gaps), each column one `GlassScope(content)` + `AppGlass(panel)`, cards `GlassInner` (flat), mouse drag between/within columns, the card menu, keyboard moves (Global Constraints), Enter → onOpen.
- [ ] **Step 1: Tests:** four columns in RTL order (planned rightmost), counts; drag a card to another column → status changed (read back), within → reordered; keyboard: focus a card, ← moves it to the next status column (RTL), ↓ moves it down; Enter → onOpen; narrow width (800) scrolls horizontally without overflow; no glass on glass (cards are GlassInner); budget ≤ 4 during a drag (expanded).
- [ ] **Steps 2–5:** FAIL → implement → PASS → commit `feat(tasks): desktop kanban with flex columns`.

---

### Task 7: Task quick entry

**Files:** Create `task_quick_entry.dart`; Test `test/features/tasks/presentation/task_quick_entry_test.dart`.

**Interfaces:** `Future<void> showTaskQuickEntry(BuildContext context, {Rect? origin})` per the Global Constraints (title field, day chips, priority segmented, «ثبت», «ویرایش جزئیات», undo toast). The due for «امروز»/«فردا» is computed from `todayNowProvider`'s wall clock and the task zone: the LOCAL day's 23:59 converted to UTC with `TZDateTime(location, y, m, d, 23, 59).toUtc()`.
- [ ] **Step 1: Tests:** «ثبت» disabled with an empty title; typing «خرید نان» + «فردا» + «بالا» + «ثبت» creates a planned task with priority 3 and due tomorrow 23:59 Tehran (`DateTime.utc` check), closes the sheet and shows «کار اضافه شد»; undo deletes it; Enter in the field submits; «ویرایش جزئیات» opens the legacy details dialog with the title and priority prefilled (find its title field text); under `TZ=UTC` the due is still Tehran 23:59.
- [ ] **Steps 2–5:** FAIL → implement → PASS → commit `feat(tasks): task quick entry sheet`.

---

### Task 8: Options sheet and the Tasks screen

**Files:** Create `tasks_options_sheet.dart`, `tasks_screen.dart`; Tests `test/features/tasks/presentation/tasks_screen_test.dart`.

**Interfaces:**
- `Future<void> showTasksOptions(BuildContext context)` with every item of the Global Constraints options line; the legacy export, template picker/manager and add-with-details flows are moved out of `tasks_panel.dart` into small reusable functions (`lib/features/tasks/presentation/legacy_task_flows.dart`: `exportTasks(context, ref)`, `addTaskWithDetails(context, ref, {TaskDetailsDraft? initialDraft})`, `openTemplatePicker(context, ref)`, `openTemplateManager(context, ref)`, `editTask(context, ref, TaskItem task)`) — copied VERBATIM in behaviour from the panel (same repository/service calls), so the panel and the new screen share them until the panel is deleted in Task 9.
- `class TasksScreen extends ConsumerWidget { const TasksScreen({required String view /* list|board|calendar */, Key? key}); }` — compact: subtitle + large title, view segmented, (list) tiles + search + `TaskSectionList`, (board) search + `TaskKanbanPhone`, (calendar) the legacy `TaskCalendarBoard` (wired exactly as the panel wires it); medium/expanded: the header chip, a header row with the view segmented, search field and «گزینه‌ها» button, then list/board/calendar (`TaskKanbanDesktop` for board). The legacy `TaskActiveTimerStrip` above the content when a timer is active. Padding: body only (Part B lesson), `MediaQuery.paddingOf` for the shell insets.
- [ ] **Step 1: Tests** (`pumpBorjTestApp`, seeded tasks): compact list shows «<n> کار باز», the tiles and sections; switching the segmented to «کانبان» changes the route query to `?view=board` and shows the phone kanban; «تقویم» shows the legacy calendar; expanded defaults to board with four columns; options sheet: sort change reorders, clear completed with undo, export calls the legacy handler (verify its observable effect as the legacy test does; read `test/features/dashboard/**` or the panel's tests for how export was tested), «افزودن با جزئیات» opens the legacy dialog; search filters list and kanban; every legacy panel string action reachable (assert the presence of each entry point); no `DateTime.now()` in `lib/features/tasks/presentation/tasks_screen/**` (a grep-style test reading the files); A4-style sizes 390, 600, 1024, 1440 at text scale 1.0 and 1.3 without exception; budgets: compact idle 2, expanded idle 2.
- [ ] **Steps 2–5:** FAIL → implement → PASS → commit `feat(tasks): tasks screen with options sheet`.

---

### Task 9: Router and entry points

**Files:** Modify `lib/app/router/app_router.dart`, delete `lib/features/dashboard/presentation/widgets/tasks_panel.dart` (after moving the flows in Task 8; delete its now-dead tests, mapping each assertion to a new home in the report), modify Today's quick-entry action.
- `/tasks` → `NoTransitionPage(child: TasksScreen(view: state.uri.queryParameters['view'] ?? <default by window class>))`; the shell's `actionsFor` for the Tasks branch: compact «گزینه‌ها» (leading) + «کار جدید» (primary); medium/expanded «کار جدید» (primary). The sidebar items «همهٔ کارها» (`/tasks`) and «تقویم» (`/tasks?view=calendar`) select correctly.
- `/tasks/:taskId` → shows the Tasks screen with the legacy edit dialog opened for that task (a page that pushes the dialog on first frame and pops back to `/tasks` when it closes; a missing id shows a toast «این کار پیدا نشد» and returns to `/tasks`).
- Today's «ورود سریع» (compact toolbar) and «افزودن» (desktop) open `showTaskQuickEntry` instead of the Part A placeholder.
- [ ] **Step 1: Tests:** notification deep link `/tasks/<existing id>` opens the edit dialog (its title shows the task title); a missing id returns to `/tasks` with the toast; sidebar «تقویم» shows the calendar view; Today's quick entry creates a task that then appears on Today; the route walker test still finds no `builder:` routes; `notification_locations_resolve_test` still passes; no reference to `TasksPanel` remains (`grep`).
- [ ] **Steps 2–5:** FAIL → implement → PASS (full `flutter test --exclude-tags device`, `TZ=UTC`) → commit `feat(tasks): tasks route, deep links and quick entry entry points`.

---

### Task 10: Review samples and the device probe

- [ ] Review samples (fixed data): `TaskGlassRow` (normal, done, swiped open), `TaskSmartTiles`, `TaskSectionList` (board `PhoneTasks`), `TaskKanbanPhone` (board `PhoneKanban`), `TaskKanbanDesktop` (board `MacTasks`), quick entry content (board `PhoneQuickEntry`).
- [ ] Probe (`integration_test/glass_shell_probe_test.dart`): seed 30 tasks (mixed sections and statuses); phone: Tasks list idle, scroll, swipe a row open, page the kanban, drag a card onto a segment; desktop: kanban idle and a drag; ASSERT budgets (phone ≤ 3, desktop ≤ 4) with the ≥ 2 and seeded-pass floors; print `tasksList=… tasksSwipe=… tasksKanban=… tasksDrag=…`; perf: 3 s of list scrolling and kanban paging (`glass_tasks_<phone|desktop>`), profile p90 ≤ 8 ms with the floors.
- [ ] Run `tool/ci.sh --device` and the profile drive; commit `test(tasks): review samples and device probe`.

---

### Task 11 (controller): 3A checkpoint

- [ ] Final whole-branch review (most capable model), one fix wave, checkpoint `docs/superpowers/checkpoints/<date>-redesign-phase-3a-checkpoint.md`, WORKLOG, roadmap, merge into `feat/v2-complete-dashboard`; tell the owner in Persian what the Tasks tab now does and how to try it.
