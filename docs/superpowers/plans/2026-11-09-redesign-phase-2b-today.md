# Redesign Phase 2 Part B — Today Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the interim Today page with the real Today screen of the `Main` / `MacToday` / `PhoneEmptyToday` boards: a date header, a timeline card, a today's-tasks card and an installment card on a fixed-size card grid, an onboarding state for a new user, and the cold-start entrance.

**Architecture:** A pure application layer (`lib/features/today/application/`) turns tasks, recurrence data, installment plans and the clock into a `TodayAgenda` and `TodayInstallment`; Riverpod providers wire it to the existing streams. Presentation (`lib/features/today/presentation/`) composes Phase 1/2A primitives only: each card is one `GlassScope(kind: content)` holding one `AppGlass(role: panel)` with flat `GlassInner` contents, laid out by a small grid engine (spec §5.1: row unit 76, gap 12, 2 columns compact / 4 columns medium+expanded, sizes small 1×2, wide 2×2, large 2×4). The default layout is fixed here; Part C adds editing and persistence on top of the same grid engine.

**Tech Stack:** Flutter 3.47.5, Riverpod, go_router, `timezone`, the Phase 1 primitives and Phase 2A shell patterns in `lib/app/design/`.

**Scope** (spec 2026-11-06 §4 Today, §5.1 grid; redesign spec §7 item 2):
- In: phone and desktop Today to the boards; cards whose feature exists (timeline, today's tasks, upcoming installment); empty/onboarding state; cold-start entrance; review samples; budget tests and the device probe on a populated Today.
- Out: budget and habit cards (features hidden, decision 2026-11-08); editing, move/resize/hide/add, persistence and schema 10 (Part C); quick entry (Phase 3); task detail (Phase 3); the board's day arrows and view segmented control on desktop (Phase 3, they belong to Tasks).

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

## Decisions recorded by this plan

1. **Installment without a date.** `InstallmentPlan` has no due date; the card shows «قسط n از m» and the amount, not the board's «۱۰ آذر». A due date needs its own finance spec (Phase 4).
2. **Onboarding has one step.** The account and habit steps return when those features ship.
3. **Default installment size is wide**, not the catalogue's small: with the budget card hidden, a lone small card would leave a gap beside it.
4. **"Today" for tasks** = occurrences whose instant (due, else start) falls in the local calendar day `[00:00, 24:00)` in the task calendar time zone (`taskCalendarTimeZoneProvider`), excluding skipped and canceled occurrences, plus active one-off tasks with no start and no due time (untimed). Overdue tasks from earlier days are not shown (Phase 3 decides overdue handling with the Tasks screen).
5. **Desktop has a timeline card too.** The `MacToday` board shows only tasks, budget and habits; with budget and habits hidden, the catalogue's timeline card keeps the desktop Today useful. The board wins again when those features ship.

6. **Date chip text follows the theme** (controller, 2026-11-09, from the A3 contrast check): white `onTint` on the near-transparent clear glass over the white light background is 1.00:1. The chip keeps `GlassRole.clear` and uses `AppTextTone.primary` / `secondaryStrong`. The board's navy-tinted chip with white text needs a tinted-dark glass role and token: deferred.

7. **Grid columns follow the grid's own width** (controller, 2026-11-09, from the A4 check): 4 columns when the grid is at least 720 px wide, otherwise 2. A 600 px medium window (grid ≈ 456 px) gets 2 columns; four would make a wide card ≈ 222 px and overflow its content. Deviation from motion spec §5.1 ("medium 4 columns"); Part C's customization uses the same rule.

## File structure

```
lib/core/date_time/persian_date_label.dart                 + short(), gregorianShort(), jalaliLong()      (Task 1)
lib/features/today/domain/today_entry.dart                 TodayEntry, TodayAgenda                        (Task 1)
lib/features/today/application/today_agenda_builder.dart   TodayAgendaBuilder (pure)                      (Task 1)
lib/features/today/application/today_providers.dart        minuteTickProvider, todayAgendaProvider, todayInstallmentProvider, todayIsNewUserProvider, todayCompletionProvider (Task 2)
lib/features/today/application/today_completion.dart       TodayCompletion.toggle                         (Task 2)
lib/features/today/presentation/today_grid.dart            TodayCardSize, TodayGridItem, packTodayGrid(), TodayGrid (Task 3)
lib/features/today/presentation/today_card.dart            TodayCard (glass panel shell for a card)       (Task 3)
lib/features/today/presentation/timeline_card.dart         TimelineCard                                   (Task 4)
lib/features/today/presentation/today_tasks_card.dart      TodayTasksCard                                 (Task 5)
lib/features/today/presentation/installment_card.dart      InstallmentCard                                (Task 6)
lib/features/today/presentation/today_header.dart          TodayHeader (phone large title / desktop date chip) (Task 7)
lib/features/today/presentation/today_onboarding.dart      TodayOnboarding                                (Task 7)
lib/features/today/presentation/today_page.dart            TodayPage + TodayEntrance                      (Task 8)
lib/app/router/app_router.dart                             '/' → TodayPage                                (Task 8)
lib/app/shell/today_interim_page.dart                      deleted                                        (Task 8)
lib/app/apple_visual/review/design_review_samples.dart     + Today samples                                (Task 9)
integration_test/glass_shell_probe_test.dart               populated Today                                (Task 9)
```

---

### Task 1: Date labels, TodayEntry and the agenda builder

**Files:**
- Modify: `lib/core/date_time/persian_date_label.dart`
- Create: `lib/features/today/domain/today_entry.dart`, `lib/features/today/application/today_agenda_builder.dart`
- Test: `test/core/date_time/persian_date_label_test.dart` (extend or create), `test/features/today/today_agenda_builder_test.dart`

**Interfaces:**
- Consumes: `TaskItem`, `TaskStatus`, `TaskRecurrenceRule`, `TaskRecurrenceException`, `TaskOccurrenceCompletion`, `TaskOccurrenceProjector.project(...)`, `TaskCalendarOccurrence` (`isCompleted`, `status`, `instantUtc`, `originalLocalDateTime`, `recurring`, `task`), `RecurrenceLocalDateTime`, `package:timezone`.
- Produces:
  - `PersianDateLabel.short(DateTime local)` → «چهارشنبه ۱۳ آبان»; `PersianDateLabel.gregorianShort(DateTime local)` → «چهارشنبه، ۴ نوامبر»; `PersianDateLabel.jalaliLong(DateTime local)` → «۱۳ آبان ۱۴۰۵».
  - `final class TodayEntry { const TodayEntry({required this.taskId, required this.title, required this.done, required this.recurring, this.localStart, this.durationMinutes, this.originalLocalDateTime}); final String taskId; final String title; final bool done; final bool recurring; final DateTime? localStart; /* null = untimed */ final int? durationMinutes; final RecurrenceLocalDateTime? originalLocalDateTime; /* recurring only */ bool get timed => localStart != null; }` with value equality.
  - `final class TodayAgenda { const TodayAgenda({required this.day, required this.timed, required this.untimed}); final DateTime day; /* local midnight */ final List<TodayEntry> timed; final List<TodayEntry> untimed; TodayEntry? nextAfter(DateTime localNow); bool get isEmpty; static final TodayAgenda empty(DateTime day); }`. `nextAfter` = the first timed, not-done entry whose start is at or after `localNow` (minute precision), else null.
  - `final class TodayAgendaBuilder { const TodayAgendaBuilder({TaskOccurrenceProjector projector = const TaskOccurrenceProjector()}); TodayAgenda build({required List<TaskItem> tasks, required List<TaskRecurrenceRule> rules, required List<TaskRecurrenceException> exceptions, required List<TaskOccurrenceCompletion> completions, required DateTime localNow, required String timeZoneId}); }`.

- [ ] **Step 1: Write the failing tests**

`test/core/date_time/persian_date_label_test.dart` (add these cases; keep existing ones):
```dart
import 'package:borj/core/date_time/persian_date_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final wed = DateTime(2026, 11, 4, 14, 30); // ۱۳ آبان ۱۴۰۵, Wednesday

  test('short: weekday + Jalali day + month', () {
    expect(PersianDateLabel.short(wed), 'چهارشنبه ۱۳ آبان');
  });

  test('gregorianShort: Persian weekday, Gregorian day and month name', () {
    expect(PersianDateLabel.gregorianShort(wed), 'چهارشنبه، ۴ نوامبر');
  });

  test('jalaliLong: day month year', () {
    expect(PersianDateLabel.jalaliLong(wed), '۱۳ آبان ۱۴۰۵');
  });
}
```

`test/features/today/today_agenda_builder_test.dart`:
```dart
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

const _tz = 'Asia/Tehran';

TaskItem _task(
  String id, {
  DateTime? startUtc,
  DateTime? dueUtc,
  int? minutes,
  TaskStatus status = TaskStatus.planned,
}) {
  final t = DateTime.utc(2026, 11, 1);
  return TaskItem(
    id: id,
    displayNumber: id.hashCode & 0xffff,
    title: 'task $id',
    priority: 0,
    status: status,
    positionInStatus: 0,
    startAtUtc: startUtc,
    dueAtUtc: dueUtc,
    estimatedDurationMinutes: minutes,
    createdAtUtc: t,
    updatedAtUtc: t,
    completedAtUtc: status == TaskStatus.completed ? t : null,
    canceledAtUtc: status == TaskStatus.canceled ? t : null,
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);
  const builder = TodayAgendaBuilder();
  // 2026-11-04 14:30 Tehran (UTC+3:30) = 11:00 UTC.
  final now = DateTime(2026, 11, 4, 14, 30);

  TodayAgendaBuilderTestHelper agenda(List<TaskItem> tasks) => TodayAgendaBuilderTestHelper(
    builder.build(
      tasks: tasks,
      rules: const [],
      exceptions: const [],
      completions: const [],
      localNow: now,
      timeZoneId: _tz,
    ),
  );

  test('timed entries of the local day, sorted by time', () {
    final a = agenda([
      _task('late', dueUtc: DateTime.utc(2026, 11, 4, 14, 30)), // 18:00 local
      _task('early', startUtc: DateTime.utc(2026, 11, 4, 5, 30), minutes: 60), // 09:00
      _task('tomorrow', dueUtc: DateTime.utc(2026, 11, 4, 21, 0)), // 00:30 next day
      _task('yesterday', dueUtc: DateTime.utc(2026, 11, 3, 19, 0)), // 22:30 previous day
    ]);
    expect(a.timedIds, ['early', 'late']);
    expect(a.value.timed.first.localStart, DateTime(2026, 11, 4, 9, 0));
    expect(a.value.timed.first.durationMinutes, 60);
  });

  test('untimed active one-offs; completed or canceled untimed are left out', () {
    final a = agenda([
      _task('free'),
      _task('freeDone', status: TaskStatus.completed),
      _task('freeCanceled', status: TaskStatus.canceled),
    ]);
    expect(a.untimedIds, ['free']);
  });

  test('a completed one-off today stays, marked done; canceled is dropped', () {
    final a = agenda([
      _task('done', dueUtc: DateTime.utc(2026, 11, 4, 6, 0), status: TaskStatus.completed),
      _task('gone', dueUtc: DateTime.utc(2026, 11, 4, 7, 0), status: TaskStatus.canceled),
    ]);
    expect(a.timedIds, ['done']);
    expect(a.value.timed.single.done, isTrue);
  });

  test('nextAfter: first unfinished timed entry at or after now', () {
    final a = agenda([
      _task('past', dueUtc: DateTime.utc(2026, 11, 4, 8, 0)), // 11:30
      _task('next', dueUtc: DateTime.utc(2026, 11, 4, 11, 30)), // 15:00
      _task('later', dueUtc: DateTime.utc(2026, 11, 4, 14, 30)), // 18:00
    ]);
    expect(a.value.nextAfter(now)?.taskId, 'next');
  });

  test('empty agenda', () {
    final a = agenda(const []);
    expect(a.value.isEmpty, isTrue);
    expect(a.value.day, DateTime(2026, 11, 4));
  });
}

final class TodayAgendaBuilderTestHelper {
  TodayAgendaBuilderTestHelper(this.value);
  final TodayAgenda value;
  List<String> get timedIds => [for (final e in value.timed) e.taskId];
  List<String> get untimedIds => [for (final e in value.untimed) e.taskId];
}
```
Add one recurring case: build a daily `TaskRecurrenceRule` for a task with `startAtUtc` 09:00 local (read `test/features/tasks/application/task_occurrence_projector_test.dart` for how existing tests construct a rule and a completion), add a `TaskOccurrenceCompletion` for today's occurrence, and assert the entry is `recurring: true`, `done: true`, with `originalLocalDateTime` equal to today 09:00. Import paths: confirm `RecurrenceLocalDateTime`'s file under `lib/core/recurrence/` and `TodayAgenda`'s export (the builder file re-exports `today_entry.dart`, or import both).

- [ ] **Step 2: Run** `flutter test test/core/date_time test/features/today`. Expected: FAIL (missing).

- [ ] **Step 3: Implement**

`PersianDateLabel` additions (same file, reuse `_weekdays`, `_months`, `_fa`):
```dart
  static const List<String> _gregorianMonths = <String>[
    'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن',
    'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر',
  ];

  /// «چهارشنبه ۱۳ آبان» (phone Today subtitle).
  static String short(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    final weekday = _weekdays[dateTime.weekday - 1];
    return '$weekday ${_fa(jalali.day)} ${_months[jalali.month - 1]}';
  }

  /// «چهارشنبه، ۴ نوامبر» (desktop date chip subtitle).
  static String gregorianShort(DateTime dateTime) {
    final weekday = _weekdays[dateTime.weekday - 1];
    return '$weekday، ${_fa(dateTime.day)} ${_gregorianMonths[dateTime.month - 1]}';
  }

  /// «۱۳ آبان ۱۴۰۵» (desktop date chip title).
  static String jalaliLong(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${_fa(jalali.day)} ${_months[jalali.month - 1]} ${_fa(jalali.year)}';
  }
```
Format the list with one entry per line if `dart format` requires it.

`lib/features/today/domain/today_entry.dart`:
```dart
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:flutter/foundation.dart';

/// One task on Today: a timed occurrence of the local day, or an untimed
/// active task.
@immutable
final class TodayEntry {
  const TodayEntry({
    required this.taskId,
    required this.title,
    required this.done,
    required this.recurring,
    this.localStart,
    this.durationMinutes,
    this.originalLocalDateTime,
  });

  final String taskId;
  final String title;
  final bool done;
  final bool recurring;

  /// Local start (minute precision); null for untimed tasks.
  final DateTime? localStart;
  final int? durationMinutes;

  /// The occurrence key of a recurring entry (for completion).
  final RecurrenceLocalDateTime? originalLocalDateTime;

  bool get timed => localStart != null;

  @override
  bool operator ==(Object other) =>
      other is TodayEntry &&
      other.taskId == taskId &&
      other.title == title &&
      other.done == done &&
      other.recurring == recurring &&
      other.localStart == localStart &&
      other.durationMinutes == durationMinutes &&
      other.originalLocalDateTime == originalLocalDateTime;

  @override
  int get hashCode => Object.hash(taskId, title, done, recurring, localStart, durationMinutes, originalLocalDateTime);
}

@immutable
final class TodayAgenda {
  const TodayAgenda({required this.day, required this.timed, required this.untimed});

  factory TodayAgenda.empty(DateTime day) =>
      TodayAgenda(day: day, timed: const [], untimed: const []);

  /// Local midnight of the day.
  final DateTime day;
  final List<TodayEntry> timed;
  final List<TodayEntry> untimed;

  bool get isEmpty => timed.isEmpty && untimed.isEmpty;

  TodayEntry? nextAfter(DateTime localNow) {
    final minute = DateTime(localNow.year, localNow.month, localNow.day, localNow.hour, localNow.minute);
    for (final e in timed) {
      if (!e.done && !e.localStart!.isBefore(minute)) return e;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is TodayAgenda && other.day == day && listEquals(other.timed, timed) && listEquals(other.untimed, untimed);

  @override
  int get hashCode => Object.hash(day, Object.hashAll(timed), Object.hashAll(untimed));
}
```
Check that `RecurrenceLocalDateTime` implements `==` (the projector and completion code compare it); if not, compare its fields.

`lib/features/today/application/today_agenda_builder.dart`:
```dart
import 'package:borj/features/tasks/application/task_occurrence_projector.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/domain/today_entry.dart';
import 'package:timezone/timezone.dart' as timezone;

export 'package:borj/features/today/domain/today_entry.dart';

/// Builds Today's agenda (plan Decision 4).
final class TodayAgendaBuilder {
  const TodayAgendaBuilder({this.projector = const TaskOccurrenceProjector()});

  final TaskOccurrenceProjector projector;

  TodayAgenda build({
    required List<TaskItem> tasks,
    required List<TaskRecurrenceRule> rules,
    required List<TaskRecurrenceException> exceptions,
    required List<TaskOccurrenceCompletion> completions,
    required DateTime localNow,
    required String timeZoneId,
  }) {
    final location = timezone.getLocation(timeZoneId);
    final zonedNow = timezone.TZDateTime.from(localNow, location);
    final day = DateTime(zonedNow.year, zonedNow.month, zonedNow.day);
    final startUtc = timezone.TZDateTime(location, day.year, day.month, day.day).toUtc();
    final next = day.add(const Duration(days: 1));
    final endUtc = timezone.TZDateTime(location, next.year, next.month, next.day).toUtc();

    final occurrences = projector.project(
      tasks: tasks,
      rules: rules,
      exceptions: exceptions,
      completions: completions,
      rangeStartUtc: startUtc,
      rangeEndUtc: endUtc,
      floatingTimeZoneId: timeZoneId,
    );

    final timed = <TodayEntry>[
      for (final o in occurrences)
        if (o.status != TaskCalendarOccurrenceStatus.skipped &&
            o.status != TaskCalendarOccurrenceStatus.canceled)
          _entry(o, location),
    ]..sort((a, b) => a.localStart!.compareTo(b.localStart!));

    final ruleTaskIds = {for (final r in rules) r.taskId};
    final untimed = <TodayEntry>[
      for (final t in tasks)
        if (!ruleTaskIds.contains(t.id) &&
            t.startAtUtc == null &&
            t.dueAtUtc == null &&
            (t.status == TaskStatus.planned || t.status == TaskStatus.inProgress))
          TodayEntry(taskId: t.id, title: t.title, done: false, recurring: false),
    ];

    return TodayAgenda(day: day, timed: timed, untimed: untimed);
  }

  TodayEntry _entry(TaskCalendarOccurrence o, timezone.Location location) {
    final local = timezone.TZDateTime.from(o.instantUtc, location);
    return TodayEntry(
      taskId: o.task.id,
      title: o.task.title,
      done: o.isCompleted,
      recurring: o.recurring,
      localStart: DateTime(local.year, local.month, local.day, local.hour, local.minute),
      durationMinutes: o.task.estimatedDurationMinutes,
      originalLocalDateTime: o.recurring ? o.originalLocalDateTime : null,
    );
  }
}
```
`localNow` arrives as a device-local `DateTime`; converting it with `TZDateTime.from` keeps the day in the task calendar zone. Read `task_occurrence_projector.dart` for the sort it already applies, the `isCompleted` getter and the rule's task id field name, and adapt names if they differ.

- [ ] **Step 4: Run** the tests. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): date labels and the today agenda builder`.

---

### Task 2: Today providers and completion

**Files:**
- Create: `lib/features/today/application/today_providers.dart`, `lib/features/today/application/today_completion.dart`
- Test: `test/features/today/today_providers_test.dart`, `test/features/today/today_completion_test.dart`

**Interfaces:**
- Consumes: Task 1; `appClockProvider`, `taskItemsProvider`, `taskRecurrenceRulesProvider`, `taskRecurrenceExceptionsProvider`, `taskOccurrenceCompletionsProvider`, `taskCalendarTimeZoneProvider`, `installmentPlansProvider`, `financeTransactionsProvider`, `debtsProvider`, `taskRepositoryProvider`, `taskRecurrenceServiceProvider` (`lib/core/providers/persistence_providers.dart`).
- Produces:
  - `final minuteTickProvider = StreamProvider<DateTime>(...)` — emits `clock.nowLocal()` immediately, then at every local minute boundary (a `Timer` scheduled to the next minute, then periodic 1 min); cancels on dispose.
  - `final todayAgendaProvider = Provider<AsyncValue<TodayAgenda>>(...)` — combines the four task streams, the time zone and the local day of `minuteTickProvider`; recomputes only when an input changes or the local DATE changes (select the day: `ref.watch(minuteTickProvider.select((v) => v.whenData((t) => DateTime(t.year, t.month, t.day))))`).
  - `final class TodayInstallment { const TodayInstallment({required this.planId, required this.title, required this.nextNumber, required this.count, required this.amount}); final String planId; final String title; final int nextNumber; final int count; final Money amount; double get progress; }` and `final todayInstallmentProvider = Provider<AsyncValue<TodayInstallment?>>(...)` — the first active plan by `createdAtUtc`.
  - `final todayIsNewUserProvider = Provider<AsyncValue<bool>>(...)` — true when tasks, transactions, debts and installment plans are all empty.
  - `final class TodayCompletion { TodayCompletion({required TaskRepository repository, required TaskRecurrenceService recurrence, required AppClock clock}); Future<void> toggle(TodayEntry entry); }` and `final todayCompletionProvider = Provider<TodayCompletion>(...)`.

- [ ] **Step 1: Write the failing tests**

`test/features/today/today_completion_test.dart` — use a real in-memory database (`openTestDatabase()` from `test/support/test_database.dart`) through a `ProviderContainer` with `appDatabaseProvider` and `appClockProvider` (`FixedAppClock`) overridden (read `app_clock.dart` for `FixedAppClock`'s constructor):
```dart
// 1. one-off: create a planned task due today, toggle(entry) → repository status completed; toggle again → planned.
// 2. recurring: create a task + a daily rule (via TaskRecurrenceService.replaceRule), build the agenda for today,
//    toggle(the recurring entry) → the completions stream contains today's originalLocalDateTime; toggle again → removed.
// 3. changedAtUtc comes from the clock: after the one-off toggle, the task's completedAtUtc == clock.nowUtc().
```
Write these three as real `test(...)` bodies with explicit `await` and `expect` calls; use the repositories' `create`, `getById` and the recurrence repository's `watchCompletions().first`.

`test/features/today/today_providers_test.dart`:
```dart
// 1. todayAgendaProvider: with an overridden FixedAppClock (2026-11-04 14:30 local), a task due 15:00 local
//    appears in timed; after the clock moves to 2026-11-05 00:01 (override minuteTickProvider with a
//    StreamController you push into), the agenda's day is 2026-11-05 and the task is gone.
// 2. minuteTickProvider re-emits are filtered: pushing 14:31 on the same day does not recompute the agenda
//    (count builder calls with a counting TodayAgendaBuilder override — expose `todayAgendaBuilderProvider`
//    = Provider((ref) => const TodayAgendaBuilder()) for this).
// 3. todayInstallmentProvider: two active plans → the older one; a fully paid plan is skipped; none → null.
// 4. todayIsNewUserProvider: true on an empty database; false after one task is created; false with only a transaction.
```
Write each as a concrete test. Add `final todayAgendaBuilderProvider = Provider<TodayAgendaBuilder>((ref) => const TodayAgendaBuilder());` to the Produces list and use it in `todayAgendaProvider`. Initialize time zones in `setUpAll` (`tzdata.initializeTimeZones()`) and override `taskCalendarTimeZoneProvider` with `Future.value('Asia/Tehran')`.

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement**

`lib/features/today/application/today_completion.dart`:
```dart
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/features/tasks/application/task_recurrence_service.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/domain/today_entry.dart';

/// Completes or reopens a Today entry: one-off tasks change status;
/// recurring occurrences record or clear their completion.
final class TodayCompletion {
  TodayCompletion({required TaskRepository repository, required TaskRecurrenceService recurrence, required AppClock clock})
    : _repository = repository,
      _recurrence = recurrence,
      _clock = clock;

  final TaskRepository _repository;
  final TaskRecurrenceService _recurrence;
  final AppClock _clock;

  Future<void> toggle(TodayEntry entry) {
    if (entry.recurring) {
      return _recurrence.setCompleted(
        taskId: entry.taskId,
        originalLocalDateTime: entry.originalLocalDateTime!,
        completed: !entry.done,
      );
    }
    return _repository.transition(
      id: entry.taskId,
      status: entry.done ? TaskStatus.planned : TaskStatus.completed,
      targetPosition: 0,
      changedAtUtc: _clock.nowUtc(),
    );
  }
}
```

`lib/features/today/application/today_providers.dart`:
```dart
import 'dart:async';

import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/application/today_completion.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final minuteTickProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(appClockProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  void scheduleNext() {
    final now = clock.nowLocal();
    final next = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    timer = Timer(next.difference(now), () {
      controller.add(clock.nowLocal());
      scheduleNext();
    });
  }

  controller.add(clock.nowLocal());
  scheduleNext();
  ref.onDispose(() {
    timer?.cancel();
    unawaited(controller.close());
  });
  return controller.stream;
});

final todayAgendaBuilderProvider = Provider<TodayAgendaBuilder>((ref) => const TodayAgendaBuilder());

final todayAgendaProvider = Provider<AsyncValue<TodayAgenda>>((ref) {
  final day = ref.watch(minuteTickProvider.select((v) => v.whenData((t) => DateTime(t.year, t.month, t.day))));
  final tasks = ref.watch(taskItemsProvider);
  final rules = ref.watch(taskRecurrenceRulesProvider);
  final exceptions = ref.watch(taskRecurrenceExceptionsProvider);
  final completions = ref.watch(taskOccurrenceCompletionsProvider);
  final zone = ref.watch(taskCalendarTimeZoneProvider);
  for (final v in <AsyncValue<Object?>>[day, tasks, rules, exceptions, completions, zone]) {
    if (v.hasError) return AsyncValue.error(v.error!, v.stackTrace ?? StackTrace.current);
    if (!v.hasValue) return const AsyncValue.loading();
  }
  final clock = ref.read(appClockProvider);
  return AsyncValue.data(
    ref.watch(todayAgendaBuilderProvider).build(
      tasks: tasks.requireValue,
      rules: rules.requireValue,
      exceptions: exceptions.requireValue,
      completions: completions.requireValue,
      localNow: clock.nowLocal(),
      timeZoneId: zone.requireValue,
    ),
  );
});

@immutable
final class TodayInstallment {
  const TodayInstallment({required this.planId, required this.title, required this.nextNumber, required this.count, required this.amount});

  final String planId;
  final String title;
  final int nextNumber;
  final int count;
  final Money amount;

  /// Paid fraction, 0..1.
  double get progress => count == 0 ? 0 : (nextNumber - 1) / count;
}

final todayInstallmentProvider = Provider<AsyncValue<TodayInstallment?>>((ref) {
  return ref.watch(installmentPlansProvider).whenData((plans) {
    final active = [for (final p in plans) if (p.remainingCount > 0) p]
      ..sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
    if (active.isEmpty) return null;
    final p = active.first;
    return TodayInstallment(planId: p.id, title: p.title, nextNumber: p.paidCount + 1, count: p.installmentCount, amount: p.perInstallment);
  });
});

final todayIsNewUserProvider = Provider<AsyncValue<bool>>((ref) {
  final values = <AsyncValue<List<Object?>>>[
    ref.watch(taskItemsProvider),
    ref.watch(financeTransactionsProvider),
    ref.watch(debtsProvider),
    ref.watch(installmentPlansProvider),
  ];
  for (final v in values) {
    if (v.hasError) return AsyncValue.error(v.error!, v.stackTrace ?? StackTrace.current);
    if (!v.hasValue) return const AsyncValue.loading();
  }
  return AsyncValue.data(values.every((v) => v.requireValue.isEmpty));
});

final todayCompletionProvider = Provider<TodayCompletion>(
  (ref) => TodayCompletion(
    repository: ref.watch(taskRepositoryProvider),
    recurrence: ref.watch(taskRecurrenceServiceProvider),
    clock: ref.watch(appClockProvider),
  ),
);
```
Check `AppClock` has `nowUtc()` (it does, `app_clock.dart`). If `taskCalendarTimeZoneProvider` needs platform channels in tests, override it as noted.

- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): today providers and completion`.

---

### Task 3: Card grid and the card shell

**Files:**
- Create: `lib/features/today/presentation/today_grid.dart`, `lib/features/today/presentation/today_card.dart`
- Test: `test/features/today/today_grid_test.dart`, `test/features/today/today_card_test.dart`

**Interfaces:**
- Consumes: `WindowClass`, `AppGlass`, `GlassScope`, `AppRadii`, `AppSpacing`.
- Produces:
  - `enum TodayCardSize { small, wide, large; int get columns; int get rows; }` (small 1×2, wide 2×2, large 2×4).
  - `const double todayRowUnit = 76; const double todayGap = 12; double todayCardHeight(TodayCardSize size)`.
  - `final class TodayGridItem { const TodayGridItem({required this.id, required this.size, required this.child}); }`
  - `final class TodaySlot { const TodaySlot({required this.column, required this.row, required this.columns, required this.rows}); }` and `List<TodaySlot> packTodayGrid(List<TodayCardSize> sizes, {required int columns})` — dense auto-flow: each card in order takes the first (row, column) where it fits without overlap, scanning rows top to bottom and columns from the start (column 0 = the start side, right in RTL). A card wider than `columns` is clamped to `columns`.
  - `int todayColumnsFor(WindowClass windowClass)` → compact 2, otherwise 4.
  - `class TodayGrid extends StatelessWidget { const TodayGrid({required List<TodayGridItem> items, Key? key}); }` — lays items out with `packTodayGrid` in a `Stack` of `PositionedDirectional`, column width `(width − (columns − 1) × gap) / columns`, total height from the lowest slot; RTL via `start`.
  - `class TodayCard extends StatelessWidget { const TodayCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16), String? semanticLabel, Key? key}); }` — `GlassScope(kind: content)` → `AppGlass(role: panel, shape: rounded(AppRadii.cardLarge))` → `Padding` → child; fills its slot.

- [ ] **Step 1: Write the failing tests**

`test/features/today/today_grid_test.dart`:
```dart
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  test('sizes and heights', () {
    expect([TodayCardSize.small.columns, TodayCardSize.small.rows], [1, 2]);
    expect([TodayCardSize.wide.columns, TodayCardSize.wide.rows], [2, 2]);
    expect([TodayCardSize.large.columns, TodayCardSize.large.rows], [2, 4]);
    expect(todayCardHeight(TodayCardSize.small), 164);
    expect(todayCardHeight(TodayCardSize.large), 340);
  });

  test('columns per window class', () {
    expect(todayColumnsFor(WindowClass.compact), 2);
    expect(todayColumnsFor(WindowClass.medium), 4);
    expect(todayColumnsFor(WindowClass.expanded), 4);
  });

  String slots(List<TodayCardSize> sizes, int columns) => [
    for (final s in packTodayGrid(sizes, columns: columns)) '${s.column},${s.row}',
  ].join(' ');

  test('default layout on 2 columns stacks', () {
    expect(slots([TodayCardSize.wide, TodayCardSize.large, TodayCardSize.wide], 2), '0,0 0,2 0,6');
  });

  test('default layout on 4 columns: large beside wide, then wide under the first', () {
    expect(slots([TodayCardSize.wide, TodayCardSize.large, TodayCardSize.wide], 4), '0,0 2,0 0,2');
  });

  test('dense flow pulls a later small card into a gap', () {
    expect(slots([TodayCardSize.small, TodayCardSize.wide, TodayCardSize.small], 2), '0,0 0,2 1,0');
  });

  test('a card wider than the grid is clamped', () {
    final s = packTodayGrid([TodayCardSize.wide], columns: 1).single;
    expect(s.columns, 1);
  });

  testWidgets('TodayGrid places items in RTL from the right with gap 12', (tester) async {
    await tester.pumpWidget(glassTestApp(
      SizedBox(
        width: 412, // 2 × 200 + 12
        child: TodayGrid(items: const [
          TodayGridItem(id: 'a', size: TodayCardSize.small, child: SizedBox.expand(key: ValueKey('a'))),
          TodayGridItem(id: 'b', size: TodayCardSize.small, child: SizedBox.expand(key: ValueKey('b'))),
          TodayGridItem(id: 'c', size: TodayCardSize.wide, child: SizedBox.expand(key: ValueKey('c'))),
        ]),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    final c = tester.getRect(find.byKey(const ValueKey('c')));
    expect(a.width, 200);
    expect(a.height, 164);
    expect(a.left, greaterThan(b.left), reason: 'column 0 is on the right in RTL');
    expect(a.left - b.right, 12);
    expect(c.top - a.bottom, 12);
    expect(c.width, 412);
    expect(tester.getSize(find.byType(TodayGrid)).height, 164 * 2 + 12);
  });
}
```

`test/features/today/today_card_test.dart`:
```dart
// 1. TodayCard builds exactly one GlassScope(kind: content) and one AppGlass(role: panel) with radius 26,
//    and its child under them; no AppGlass inside the child (GlassContext.isOnGlass is true for the child).
// 2. glassTestVariants matrix: renders a TodayCard with an AppText child, no exception.
```
Write them as concrete tests (`find.byWidgetPredicate((w) => w is GlassScope && w.kind == GlassLayerKind.content)`, `findsOneWidget`; for the role and shape read `AppGlass`'s fields).

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement** `lib/features/today/presentation/today_grid.dart`:
```dart
import 'dart:math' as math;

import 'package:borj/app/shell/window_class.dart';
import 'package:flutter/widgets.dart';

/// Card sizes of motion spec §5.1.
enum TodayCardSize {
  small(1, 2),
  wide(2, 2),
  large(2, 4);

  const TodayCardSize(this.columns, this.rows);

  final int columns;
  final int rows;
}

const double todayRowUnit = 76;
const double todayGap = 12;

double todayCardHeight(TodayCardSize size) => size.rows * todayRowUnit + (size.rows - 1) * todayGap;

int todayColumnsFor(WindowClass windowClass) => windowClass == WindowClass.compact ? 2 : 4;

@immutable
final class TodaySlot {
  const TodaySlot({required this.column, required this.row, required this.columns, required this.rows});

  final int column;
  final int row;
  final int columns;
  final int rows;
}

/// Dense auto-flow: each card takes the first place where it fits.
List<TodaySlot> packTodayGrid(List<TodayCardSize> sizes, {required int columns}) {
  final taken = <(int, int)>{};
  final out = <TodaySlot>[];
  for (final size in sizes) {
    final w = math.min(size.columns, columns);
    final h = size.rows;
    for (var row = 0; ; row++) {
      int? found;
      for (var col = 0; col + w <= columns; col++) {
        var free = true;
        for (var r = row; r < row + h && free; r++) {
          for (var c = col; c < col + w && free; c++) {
            if (taken.contains((r, c))) free = false;
          }
        }
        if (free) {
          found = col;
          break;
        }
      }
      if (found != null) {
        for (var r = row; r < row + h; r++) {
          for (var c = found; c < found + w; c++) {
            taken.add((r, c));
          }
        }
        out.add(TodaySlot(column: found, row: row, columns: w, rows: h));
        break;
      }
    }
  }
  return out;
}

@immutable
final class TodayGridItem {
  const TodayGridItem({required this.id, required this.size, required this.child});

  final String id;
  final TodayCardSize size;
  final Widget child;
}

/// Lays Today's cards on the §5.1 grid (start side first, so RTL fills from
/// the right).
class TodayGrid extends StatelessWidget {
  const TodayGrid({required this.items, super.key});

  final List<TodayGridItem> items;

  @override
  Widget build(BuildContext context) {
    final columns = todayColumnsFor(WindowClass.of(context));
    final slots = packTodayGrid([for (final i in items) i.size], columns: columns);
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = (constraints.maxWidth - (columns - 1) * todayGap) / columns;
        var bottom = 0.0;
        final children = <Widget>[];
        for (var i = 0; i < items.length; i++) {
          final s = slots[i];
          final top = s.row * (todayRowUnit + todayGap);
          final height = s.rows * todayRowUnit + (s.rows - 1) * todayGap;
          bottom = math.max(bottom, top + height);
          children.add(PositionedDirectional(
            key: ValueKey('today-slot-${items[i].id}'),
            start: s.column * (colWidth + todayGap),
            top: top,
            width: s.columns * colWidth + (s.columns - 1) * todayGap,
            height: height,
            child: items[i].child,
          ));
        }
        return SizedBox(height: bottom, child: Stack(children: children));
      },
    );
  }
}
```
The grid test pumps at a 412 px host inside an 800 px test window, so `WindowClass.of` reads the window (800 → medium → 4 columns). To keep that test on 2 columns, wrap the host in `MediaQuery(data: MediaQueryData(size: Size(412, 800)), child: …)` — add that to the test.

`lib/features/today/presentation/today_card.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/widgets.dart';

/// The glass panel every Today card sits in: one content scope, one panel.
class TodayCard extends StatelessWidget {
  const TodayCard({required this.child, this.padding = const EdgeInsets.all(16), this.semanticLabel, super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget card = GlassScope(
      kind: GlassLayerKind.content,
      child: AppGlass(
        role: GlassRole.panel,
        shape: const AppleGlassShape.rounded(AppRadii.cardLarge),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (semanticLabel != null) {
      card = Semantics(container: true, label: semanticLabel, child: card);
    }
    return card;
  }
}
```

- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): card grid and card shell`.

---

### Task 4: Timeline card

**Files:**
- Create: `lib/features/today/presentation/timeline_card.dart`
- Test: `test/features/today/timeline_card_test.dart`

**Interfaces:**
- Consumes: `TodayAgenda`, `TodayEntry` (Task 1), `TodayCard` (Task 3), `AppText`, `GlassInner`, `AppTheme`, `formatPersianInteger`, `Money.toPersianDigits`.
- Produces: `class TimelineCard extends StatelessWidget { const TimelineCard({required TodayAgenda agenda, required DateTime now, TodayCardSize size = TodayCardSize.wide, Key? key}); }` plus pure helpers `(int startHour, int endHour) timelineRange(List<TodayEntry> timed)` and `String formatClock(DateTime t)` («۱۴:۳۰»; hours without a leading zero, minutes two digits: «۹:۰۵»).
  Keys: `ValueKey('timeline-block-<taskId>')` per block, `ValueKey('timeline-now')` on the now-line, `ValueKey('timeline-now-pill')`, `ValueKey('timeline-elapsed')`.
  Layout (wide, 164 tall): header row (title «برنامهٔ امروز» 13 pt w800 at the start; «بعدی: <title>» at the end with «بعدی:» `textSecondary`, title `text`), then a 50 pt lane with blocks (42 tall, top 4, `GlassInner` radius 12, padding `5 3`, title 11 pt w700, one line, ellipsis), then the hour labels row (11 pt `textSecondary`). Large (340 tall) uses a 2-lane layout: entries that overlap in time go to the second lane (otherwise identical).
  Positions: the scale runs from `startHour` at the START side (right in RTL) to `endHour` at the END side; `fraction(t) = (minutesSinceStartHour) / ((endHour − startHour) × 60)`, clamped to 0..1; a block's start offset is `fraction(start) × laneWidth`, width `max(fraction(start+duration) − fraction(start), 30 min fraction) × laneWidth`.

- [ ] **Step 1: Write the failing tests** `test/features/today/timeline_card_test.dart`:
```dart
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/presentation/timeline_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

final _day = DateTime(2026, 11, 4);
TodayEntry _e(String id, int h, int m, {int? minutes, bool done = false}) => TodayEntry(
  taskId: id, title: id, done: done, recurring: false,
  localStart: DateTime(2026, 11, 4, h, m), durationMinutes: minutes,
);

Widget _card(TodayAgenda agenda, DateTime now, {Brightness b = Brightness.light, double s = 1.0}) => glassTestApp(
  brightness: b,
  textScale: s,
  SizedBox(width: 358, height: todayCardHeight(TodayCardSize.wide), child: TimelineCard(agenda: agenda, now: now)),
);

void main() {
  final agenda = TodayAgenda(day: _day, timed: [
    _e('deep', 8, 30, minutes: 180, done: true),
    _e('meet', 15, 0, minutes: 90),
    _e('insurance', 18, 0),
  ], untimed: const []);
  final now = DateTime(2026, 11, 4, 14, 30);

  test('range: default 8–20, widened to even hours that cover every block', () {
    expect(timelineRange(const []), (8, 20));
    expect(timelineRange([_e('early', 6, 15)]), (6, 20));
    expect(timelineRange([_e('late', 21, 0, minutes: 60)]), (8, 22));
  });

  test('formatClock', () {
    expect(formatClock(DateTime(2026, 1, 1, 14, 30)), '۱۴:۳۰');
    expect(formatClock(DateTime(2026, 1, 1, 9, 5)), '۹:۰۵');
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(_card(agenda, now, b: v.brightness, s: v.textScale));
      expect(tester.takeException(), isNull);
      expect(find.text('برنامهٔ امروز'), findsOneWidget);
    });
  }

  testWidgets('header names the next unfinished entry', (tester) async {
    await tester.pumpWidget(_card(agenda, now));
    expect(find.textContaining('meet'), findsWidgets);
    expect(find.text('بعدی:'), findsOneWidget);
  });

  testWidgets('RTL: earlier blocks sit to the right; the now-line between them', (tester) async {
    await tester.pumpWidget(_card(agenda, now));
    final deep = tester.getRect(find.byKey(const ValueKey('timeline-block-deep')));
    final meet = tester.getRect(find.byKey(const ValueKey('timeline-block-meet')));
    final line = tester.getRect(find.byKey(const ValueKey('timeline-now')));
    expect(deep.center.dx, greaterThan(meet.center.dx));
    expect(line.center.dx, lessThan(deep.left));
    expect(line.center.dx, greaterThan(meet.right));
    expect(line.width, 2);
    expect(find.descendant(of: find.byKey(const ValueKey('timeline-now-pill')), matching: find.text('۱۴:۳۰')), findsOneWidget);
  });

  testWidgets('a done block shows the check mark; blocks are flat GlassInner', (tester) async {
    await tester.pumpWidget(_card(agenda, now));
    expect(find.textContaining('deep ✓'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('timeline-block-meet')), matching: find.byType(GlassInner)), findsOneWidget);
  });

  testWidgets('elapsed tint spans from the start side to the now-line', (tester) async {
    await tester.pumpWidget(_card(agenda, now));
    final elapsed = tester.getRect(find.byKey(const ValueKey('timeline-elapsed')));
    final line = tester.getRect(find.byKey(const ValueKey('timeline-now')));
    expect((elapsed.left - line.center.dx).abs(), lessThan(1.5));
  });

  testWidgets('now-line moves when now changes; no animation', (tester) async {
    await tester.pumpWidget(_card(agenda, now));
    final before = tester.getRect(find.byKey(const ValueKey('timeline-now'))).center.dx;
    await tester.pumpWidget(_card(agenda, now.add(const Duration(hours: 1))));
    final after = tester.getRect(find.byKey(const ValueKey('timeline-now'))).center.dx;
    expect(after, lessThan(before));
  });

  testWidgets('now outside the range: no now-line', (tester) async {
    await tester.pumpWidget(_card(agenda, DateTime(2026, 11, 4, 23, 0)));
    expect(find.byKey(const ValueKey('timeline-now')), findsNothing);
  });

  testWidgets('empty agenda: a calm message, no blocks', (tester) async {
    await tester.pumpWidget(_card(TodayAgenda.empty(_day), now));
    expect(find.text('برای امروز برنامهٔ زمان‌داری نداری'), findsOneWidget);
  });

  testWidgets('reduce motion: nothing moves', (tester) async {
    await tester.pumpWidget(glassTestApp(reduceMotion: true, SizedBox(width: 358, height: 164, child: TimelineCard(agenda: agenda, now: now))));
    await expectNoMovement(tester, within: find.byType(TimelineCard), trigger: () async => tester.pump());
  });
}
```
Add the empty-state string «برای امروز برنامهٔ زمان‌داری نداری» to the card (flat `AppText`, `textSecondary`, centred in the lane) and to Global Constraints notes in your report.

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement** `lib/features/today/presentation/timeline_card.dart`:
```dart
import 'dart:math' as math;

import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';

String formatClock(DateTime t) =>
    Money.toPersianDigits('${t.hour}:${t.minute.toString().padLeft(2, '0')}');

/// Whole even hours covering 8–20 and every block, clamped to 0–24.
(int, int) timelineRange(List<TodayEntry> timed) {
  var start = 8;
  var end = 20;
  for (final e in timed) {
    final s = e.localStart!;
    final endAt = s.add(Duration(minutes: e.durationMinutes ?? 30));
    final sh = s.hour;
    final eh = endAt.day != s.day ? 24 : (endAt.minute > 0 ? endAt.hour + 1 : endAt.hour);
    start = math.min(start, sh - sh % 2);
    end = math.max(end, eh + eh % 2);
  }
  return (math.max(0, start), math.min(24, end));
}

/// The board's «برنامهٔ امروز» card: blocks on an hour scale with a now-line.
class TimelineCard extends StatelessWidget {
  const TimelineCard({required this.agenda, required this.now, this.size = TodayCardSize.wide, super.key});

  final TodayAgenda agenda;
  final DateTime now;
  final TodayCardSize size;

  @override
  Widget build(BuildContext context) {
    final next = agenda.nextAfter(now);
    return TodayCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      semanticLabel: 'برنامهٔ امروز',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const AppText('برنامهٔ امروز', role: AppTextRole.footnote, weight: FontWeight.w800),
            const Spacer(),
            if (next != null) ...[
              const AppText('بعدی:', role: AppTextRole.footnote, tone: AppTextTone.secondary),
              const SizedBox(width: AppSpacing.s4),
              Flexible(child: AppText(next.title, role: AppTextRole.footnote, weight: FontWeight.w700, maxLines: 1)),
            ],
          ]),
          const SizedBox(height: AppSpacing.s8),
          Expanded(child: _Scale(agenda: agenda, now: now, lanes: size == TodayCardSize.large ? 2 : 1)),
        ],
      ),
    );
  }
}

class _Scale extends StatelessWidget {
  const _Scale({required this.agenda, required this.now, required this.lanes});

  final TodayAgenda agenda;
  final DateTime now;
  final int lanes;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final (startHour, endHour) = timelineRange(agenda.timed);
    final span = (endHour - startHour) * 60.0;
    double fraction(DateTime t) {
      final minutes = (t.difference(DateTime(agenda.day.year, agenda.day.month, agenda.day.day, startHour)).inMinutes).toDouble();
      return (minutes / span).clamp(0.0, 1.0);
    }

    final laneOf = <String, int>{};
    final laneEnds = List<DateTime?>.filled(lanes, null);
    for (final e in agenda.timed) {
      final s = e.localStart!;
      var lane = 0;
      while (lane < lanes - 1 && laneEnds[lane] != null && s.isBefore(laneEnds[lane]!)) {
        lane++;
      }
      laneOf[e.taskId] = lane;
      laneEnds[lane] = s.add(Duration(minutes: e.durationMinutes ?? 30));
    }

    final nowInDay = now.year == agenda.day.year && now.month == agenda.day.month && now.day == agenda.day.day;
    final nowMinutes = now.hour * 60 + now.minute;
    final showNow = nowInDay && nowMinutes >= startHour * 60 && nowMinutes <= endHour * 60;

    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      const laneHeight = 50.0;
      final children = <Widget>[];
      if (agenda.timed.isEmpty) {
        children.add(const Positioned.fill(
          bottom: 18,
          child: Center(child: AppText('برای امروز برنامهٔ زمان‌داری نداری', role: AppTextRole.footnote, tone: AppTextTone.secondary)),
        ));
      }
      if (showNow) {
        children.add(PositionedDirectional(
          key: const ValueKey('timeline-elapsed'),
          start: 0,
          top: 0,
          width: fraction(now) * width,
          height: laneHeight * lanes,
          child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: colors.selection.withValues(alpha: colors.selection.a * 0.5), borderRadius: BorderRadius.circular(AppRadii.small)))),
        ));
      }
      for (final e in agenda.timed) {
        final s = e.localStart!;
        final f0 = fraction(s);
        final f1 = fraction(s.add(Duration(minutes: e.durationMinutes ?? 30)));
        final minW = 30 / span;
        final past = showNow && s.add(Duration(minutes: e.durationMinutes ?? 30)).isBefore(now);
        final lane = laneOf[e.taskId]!;
        children.add(PositionedDirectional(
          key: ValueKey('timeline-block-${e.taskId}'),
          start: f0 * width,
          top: 4 + lane * laneHeight,
          width: math.max(f1 - f0, minW) * width,
          height: 42,
          child: Opacity(
            opacity: past ? 0.55 : 1,
            child: GlassInner(
              shape: const AppleGlassShape.rounded(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                child: AppText(e.done ? '${e.title} ✓' : e.title, role: AppTextRole.caption2, weight: FontWeight.w700, maxLines: 1, textAlign: TextAlign.center),
              ),
            ),
          ),
        ));
      }
      if (showNow) {
        final x = fraction(now) * width;
        children
          ..add(PositionedDirectional(
            key: const ValueKey('timeline-now'),
            start: x - 1,
            top: -4,
            width: 2,
            height: laneHeight * lanes + 8,
            child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: colors.danger, borderRadius: BorderRadius.circular(2)))),
          ));
      }
      final labels = <Widget>[
        for (var h = startHour; h <= endHour; h += 2)
          PositionedDirectional(
            start: fraction(DateTime(agenda.day.year, agenda.day.month, agenda.day.day, h)) * width - 12,
            width: 24,
            top: 0,
            child: AppText(formatPersianInteger(h), role: AppTextRole.caption2, tone: AppTextTone.secondary, textAlign: TextAlign.center),
          ),
        if (showNow)
          PositionedDirectional(
            key: const ValueKey('timeline-now-pill'),
            start: fraction(now) * width - 22,
            width: 44,
            top: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.danger, borderRadius: BorderRadius.circular(AppRadii.capsule)),
              child: AppText(formatClock(now), role: AppTextRole.caption2, tone: AppTextTone.onTint, weight: FontWeight.w800, textAlign: TextAlign.center),
            ),
          ),
      ];
      return Column(children: [
        SizedBox(height: laneHeight * lanes, child: Stack(clipBehavior: Clip.none, children: children)),
        const SizedBox(height: AppSpacing.s4),
        SizedBox(height: 18, child: Stack(clipBehavior: Clip.none, children: labels)),
      ]);
    });
  }
}
```
`Opacity` here sits INSIDE the card's glass over a flat `GlassInner` (not between a `LiquidGlass` and its layer), so it does not bare-fade glass; keep it that way (run `bareFadesAboveGlass` from `test/support/glass_fade_expectations.dart` in one test to prove the card's own glass has no fade above it). `formatPersianInteger` is in `lib/core/formatting/persian_number.dart`; add its import. Check `AppColors` has `selection` and `danger` (it does) and `AppTextTone.onTint`.

- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): timeline card`.

---

### Task 5: Today's tasks card

**Files:**
- Create: `lib/features/today/presentation/today_tasks_card.dart`
- Test: `test/features/today/today_tasks_card_test.dart`

**Interfaces:**
- Consumes: Task 1, `TodayCard`, `TodayCardSize`, `RoundCheck`, `AppText`, `Pressable`, `formatClock` (Task 4), `WindowClass`.
- Produces: `class TodayTasksCard extends StatelessWidget { const TodayTasksCard({required TodayAgenda agenda, required DateTime now, required ValueChanged<TodayEntry> onToggle, required VoidCallback onShowAll, TodayCardSize size = TodayCardSize.large, Key? key}); }`.
  - Row height 54 (board `min-height: 54px`), hairline divider `colors.hairline` 0.5 px between rows (board `Main` hairline rows).
  - Capacity by size: small 2 rows, wide 2 rows, large 5 rows (the card's inner height / 54, minus one row when there is overflow, for the «و <n> کار دیگر» row).
  - Expanded/medium: group headers «صبح», «بعدازظهر», «بی‌زمان» (12 pt w700 `textSecondary`, padding `8 0 4`), headers count toward capacity as 28 pt; compact: no headers (board `Main`).
  - Keys: `ValueKey('today-task-<taskId>')` per row, `ValueKey('today-tasks-more')` on the overflow row.
  - Title in the board's style: done → `AppTextTone.tertiary` + `TextDecoration.lineThrough` (use `AppText`'s style hook; if AppText has no decoration parameter, add `decoration` to `AppText` with a test in `test/app/design/app_text_test.dart`).
  - The row is one `Pressable` over title+time that toggles too (semantics: `RoundCheck` carries the checked state; the row label is the title).

- [ ] **Step 1: Write the failing tests** `test/features/today/today_tasks_card_test.dart`:
```dart
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:borj/features/today/presentation/today_tasks_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

final _day = DateTime(2026, 11, 4);
TodayEntry _t(String id, int h, {bool done = false}) => TodayEntry(taskId: id, title: 'کار $id', done: done, recurring: false, localStart: DateTime(2026, 11, 4, h));
TodayEntry _u(String id) => TodayEntry(taskId: id, title: 'کار $id', done: false, recurring: false);

Widget _card(TodayAgenda a, {TodayCardSize size = TodayCardSize.large, double width = 358, Size window = const Size(390, 844), ValueChanged<TodayEntry>? onToggle, VoidCallback? onShowAll, Brightness b = Brightness.light, double s = 1.0}) =>
    glassTestApp(
      brightness: b,
      textScale: s,
      MediaQuery(
        data: MediaQueryData(size: window),
        child: SizedBox(width: width, height: todayCardHeight(size), child: TodayTasksCard(agenda: a, now: DateTime(2026, 11, 4, 14, 30), size: size, onToggle: onToggle ?? (_) {}, onShowAll: onShowAll ?? () {})),
      ),
    );

void main() {
  final agenda = TodayAgenda(day: _day, timed: [_t('a', 7, done: true), _t('b', 15), _t('c', 18)], untimed: [_u('d')]);

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(_card(agenda, b: v.brightness, s: v.textScale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact: rows in order, no group headers, times in Persian', (tester) async {
    await tester.pumpWidget(_card(agenda));
    final ys = [for (final id in ['a', 'b', 'c', 'd']) tester.getTopLeft(find.byKey(ValueKey('today-task-$id'))).dy];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text('صبح'), findsNothing);
    expect(find.text('۱۵:۰۰'), findsOneWidget);
  });

  testWidgets('expanded: group headers صبح / بعدازظهر / بی‌زمان', (tester) async {
    await tester.pumpWidget(_card(agenda, width: 572, window: const Size(1440, 900)));
    expect(find.text('صبح'), findsOneWidget);
    expect(find.text('بعدازظهر'), findsOneWidget);
    expect(find.text('بی‌زمان'), findsOneWidget);
  });

  testWidgets('tapping the check toggles that entry', (tester) async {
    TodayEntry? toggled;
    await tester.pumpWidget(_card(agenda, onToggle: (e) => toggled = e));
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('today-task-b')), matching: find.byType(RoundCheck)));
    expect(toggled?.taskId, 'b');
  });

  testWidgets('overflow: a small card shows 1 row and «و ۳ کار دیگر»', (tester) async {
    String? opened;
    await tester.pumpWidget(_card(agenda, size: TodayCardSize.small, width: 173, onShowAll: () => opened = 'all'));
    expect(find.byKey(const ValueKey('today-task-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-task-b')), findsNothing);
    expect(find.text('و ۳ کار دیگر'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('today-tasks-more')));
    expect(opened, 'all');
  });

  testWidgets('empty: «امروز کاری نداری»', (tester) async {
    await tester.pumpWidget(_card(TodayAgenda.empty(_day)));
    expect(find.text('امروز کاری نداری'), findsOneWidget);
  });

  testWidgets('semantics: each check is a checkbox with the task title', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_card(agenda));
    expect(find.bySemanticsLabel('کار a'), findsWidgets);
    handle.dispose();
  });
}
```
Small capacity is 2 rows; with overflow one row is replaced by the «و n کار دیگر» row, so a small card shows 1 task + the overflow row (3 hidden of 4). Adjust the count text in the test only if your capacity arithmetic differs from the Interfaces block, and report it.

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement** `lib/features/today/presentation/today_tasks_card.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/presentation/timeline_card.dart' show formatClock;
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';

/// The board's today's-tasks card.
class TodayTasksCard extends StatelessWidget {
  const TodayTasksCard({required this.agenda, required this.now, required this.onToggle, required this.onShowAll, this.size = TodayCardSize.large, super.key});

  final TodayAgenda agenda;
  final DateTime now;
  final ValueChanged<TodayEntry> onToggle;
  final VoidCallback onShowAll;
  final TodayCardSize size;

  static const double _rowHeight = 54;
  static const double _headerHeight = 28;

  @override
  Widget build(BuildContext context) {
    final grouped = WindowClass.of(context) != WindowClass.compact;
    final next = agenda.nextAfter(now);
    final entries = [...agenda.timed, ...agenda.untimed];
    if (entries.isEmpty) {
      return const TodayCard(
        semanticLabel: 'کارهای امروز',
        child: Center(child: AppText('امروز کاری نداری', role: AppTextRole.subheadline, tone: AppTextTone.secondary)),
      );
    }
    return TodayCard(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      semanticLabel: 'کارهای امروز',
      child: LayoutBuilder(builder: (context, c) {
        final rows = <Widget>[];
        var used = 0.0;
        String? group;
        var shown = 0;
        for (final e in entries) {
          final g = !e.timed ? 'بی‌زمان' : (e.localStart!.hour < 12 ? 'صبح' : 'بعدازظهر');
          final needsHeader = grouped && g != group;
          final cost = _rowHeight + (needsHeader ? _headerHeight : 0);
          final remainingAfter = entries.length - shown - 1;
          final reserve = remainingAfter > 0 ? _rowHeight : 0;
          if (used + cost + reserve > c.maxHeight) break;
          if (needsHeader) {
            rows.add(SizedBox(height: _headerHeight, child: Align(alignment: AlignmentDirectional.bottomStart, child: AppText(g, role: AppTextRole.caption, tone: AppTextTone.secondary, weight: FontWeight.w700))));
            group = g;
          }
          rows.add(_Row(entry: e, isNext: identical(e, next) || e == next, onToggle: onToggle, divider: shown > 0 && !needsHeader));
          used += cost;
          shown++;
        }
        final hidden = entries.length - shown;
        if (hidden > 0) {
          rows.add(Pressable(
            key: const ValueKey('today-tasks-more'),
            onPressed: onShowAll,
            semanticLabel: 'و ${formatPersianInteger(hidden)} کار دیگر',
            child: SizedBox(height: _rowHeight, child: Align(alignment: AlignmentDirectional.centerStart, child: AppText('و ${formatPersianInteger(hidden)} کار دیگر', role: AppTextRole.subheadline, tone: AppTextTone.link, weight: FontWeight.w700))),
          ));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
      }),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.isNext, required this.onToggle, required this.divider});

  final TodayEntry entry;
  final bool isNext;
  final ValueChanged<TodayEntry> onToggle;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final time = entry.timed ? formatClock(entry.localStart!) : null;
    return DecoratedBox(
      key: ValueKey('today-task-${entry.taskId}'),
      decoration: BoxDecoration(border: divider ? Border(top: BorderSide(color: colors.hairline, width: 0.5)) : null),
      child: SizedBox(
        height: TodayTasksCard._rowHeight,
        child: Row(children: [
          RoundCheck(checked: entry.done, onChanged: (_) => onToggle(entry), semanticLabel: entry.title),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: AppText(
              entry.title,
              maxLines: 1,
              tone: entry.done ? AppTextTone.tertiary : AppTextTone.primary,
              weight: isNext ? FontWeight.w700 : null,
              decoration: entry.done ? TextDecoration.lineThrough : null,
            ),
          ),
          if (time != null)
            AppText(time, role: AppTextRole.footnote, tabular: true, tone: isNext ? AppTextTone.link : AppTextTone.secondary, weight: isNext ? FontWeight.w800 : null),
        ]),
      ),
    );
  }
}
```
If `AppText` has no `decoration` parameter, add it (`final TextDecoration? decoration;` applied through the resolved `TextStyle.copyWith(decoration: …)`) with one test in `test/app/design/app_text_test.dart`; keep existing behaviour unchanged.

- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): today's tasks card`.

---

### Task 6: Installment card

**Files:**
- Create: `lib/features/today/presentation/installment_card.dart`
- Test: `test/features/today/installment_card_test.dart`

**Interfaces:**
- Consumes: `TodayInstallment` (Task 2), `TodayCard`, `TodayCardSize`, `ProgressTrack`, `AppText`, `Pressable`, `formatPersianInteger`.
- Produces: `class InstallmentCard extends StatelessWidget { const InstallmentCard({required TodayInstallment installment, required VoidCallback onOpen, TodayCardSize size = TodayCardSize.wide, bool animateIn = false, Key? key}); }`.
  - wide: a row — start: title (w700, 1 line) over «قسط ۲۵ از ۶۰» (footnote `textSecondary`); end: amount `installment.amount.formatMajorUnits()` (w900, tabular); under the row a `ProgressTrack(value: installment.progress, animateIn: animateIn, semanticLabel: '<paid> از <count> قسط پرداخت شده')`.
  - small: column — title, «قسط n از m», amount; no track.
  - The whole card is one `Pressable(onPressed: onOpen, semanticLabel: 'قسط <title>')` with `dimsGlass: false` (the Pressable wraps the card's content inside the glass, never the glass).

- [ ] **Step 1: Write the failing tests** `test/features/today/installment_card_test.dart`:
```dart
import 'package:borj/core/money/money.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:borj/features/today/presentation/installment_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_fade_expectations.dart';
import '../../support/glass_test_app.dart';

final _plan = TodayInstallment(planId: 'p', title: 'قسط وام مسکن', nextNumber: 25, count: 60, amount: Money(minorUnits: 4200000, currencyCode: 'IRT', scale: 0));

Widget _card({TodayCardSize size = TodayCardSize.wide, VoidCallback? onOpen, Brightness b = Brightness.light, double s = 1.0}) => glassTestApp(
  brightness: b,
  textScale: s,
  SizedBox(width: size == TodayCardSize.small ? 173 : 358, height: todayCardHeight(size), child: InstallmentCard(installment: _plan, size: size, onOpen: onOpen ?? () {})),
);

void main() {
  for (final v in glassTestVariants) {
    for (final size in [TodayCardSize.small, TodayCardSize.wide]) {
      testWidgets('renders $size (${v.name})', (tester) async {
        await tester.pumpWidget(_card(size: size, b: v.brightness, s: v.textScale));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('wide: title, «قسط ۲۵ از ۶۰», amount, track at 24/60', (tester) async {
    await tester.pumpWidget(_card());
    expect(find.text('قسط وام مسکن'), findsOneWidget);
    expect(find.text('قسط ۲۵ از ۶۰'), findsOneWidget);
    expect(find.text('۴٬۲۰۰٬۰۰۰'), findsOneWidget);
    expect(tester.widget<ProgressTrack>(find.byType(ProgressTrack)).value, closeTo(24 / 60, 1e-9));
  });

  testWidgets('small: no track', (tester) async {
    await tester.pumpWidget(_card(size: TodayCardSize.small));
    expect(find.byType(ProgressTrack), findsNothing);
  });

  testWidgets('tap opens; no fade above the card glass', (tester) async {
    var opened = false;
    await tester.pumpWidget(_card(onOpen: () => opened = true));
    await tester.tap(find.text('قسط وام مسکن'));
    expect(opened, isTrue);
    expect(bareFadesAboveGlass(tester, find.byType(InstallmentCard)), isEmpty);
  });
}
```
Read `bareFadesAboveGlass`'s real signature in `test/support/glass_fade_expectations.dart` and adapt the call; `ProgressTrack`'s import comes from `design.dart`.

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement** `lib/features/today/presentation/installment_card.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';

/// The board's upcoming-installment card (no due date: plan Decision 1).
class InstallmentCard extends StatelessWidget {
  const InstallmentCard({required this.installment, required this.onOpen, this.size = TodayCardSize.wide, this.animateIn = false, super.key});

  final TodayInstallment installment;
  final VoidCallback onOpen;
  final TodayCardSize size;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final i = installment;
    final progressText = 'قسط ${formatPersianInteger(i.nextNumber)} از ${formatPersianInteger(i.count)}';
    final amount = AppText(i.amount.formatMajorUnits(), weight: FontWeight.w900, tabular: true);
    final title = AppText(i.title, weight: FontWeight.w700, maxLines: 1);
    final sub = AppText(progressText, role: AppTextRole.footnote, tone: AppTextTone.secondary);
    final content = size == TodayCardSize.small
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [title, const SizedBox(height: AppSpacing.s4), sub, const SizedBox(height: AppSpacing.s8), amount])
        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: AppSpacing.s4), sub])),
              amount,
            ]),
            const SizedBox(height: AppSpacing.s12),
            ProgressTrack(
              value: i.progress,
              animateIn: animateIn,
              semanticLabel: '${formatPersianInteger(i.nextNumber - 1)} از ${formatPersianInteger(i.count)} قسط پرداخت شده',
            ),
          ]);
    return TodayCard(
      child: Pressable(onPressed: onOpen, semanticLabel: 'قسط ${i.title}', child: SizedBox.expand(child: content)),
    );
  }
}
```

- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): installment card`.

---

### Task 7: Today header and onboarding

**Files:**
- Create: `lib/features/today/presentation/today_header.dart`, `lib/features/today/presentation/today_onboarding.dart`
- Test: `test/features/today/today_header_test.dart`, `test/features/today/today_onboarding_test.dart`

**Interfaces:**
- Consumes: `LargeTitleHeader`, `AppGlass`, `GlassScope`, `AppText`, `GlassInner`, `Pressable`, `TodayCard`, `PersianDateLabel` (Task 1), `WindowClass`.
- Produces:
  - `class TodayHeader extends StatelessWidget { const TodayHeader({required DateTime now, VoidCallback? onTitleLongPress, Key? key}); }` — compact: `LargeTitleHeader(key: ValueKey('today-title'), title: 'امروز', subtitle: PersianDateLabel.short(now), onTitleLongPress: …)`; medium/expanded: the date chip (`ValueKey('today-date-chip')`), padding `22 28 0` around it, aligned to the start, its title text keyed `ValueKey('today-title')` and wrapped in the long-press `GestureDetector`. The chip is `GlassScope(kind: GlassLayerKind.clear)` + `AppGlass(role: GlassRole.clear, shape: AppleGlassShape.rounded(26))`. Check `GlassLayerKind.clear.allows(GlassRole.clear)`.
  - `class TodayOnboarding extends StatelessWidget { const TodayOnboarding({required VoidCallback onAddTask, Key? key}); }` — the welcome card, the one step card with a `GlassInner` «افزودن کار» button (`ValueKey('onboarding-add-task')`, 36 tall, padding `0 14`, 13 pt w800 `link`), and the footer text; each card a `TodayCard`; vertical gap 12.

- [ ] **Step 1: Write the failing tests**

`test/features/today/today_header_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/features/today/presentation/today_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

final _now = DateTime(2026, 11, 4, 14, 30);
Widget _header(Size window, {VoidCallback? onLong, Brightness b = Brightness.light, double s = 1.0}) => glassTestApp(
  brightness: b,
  textScale: s,
  MediaQuery(data: MediaQueryData(size: window), child: SizedBox(width: window.width, child: TodayHeader(now: _now, onTitleLongPress: onLong))),
);

void main() {
  for (final v in glassTestVariants) {
    for (final w in [const Size(390, 844), const Size(1440, 900)]) {
      testWidgets('renders ${w.width} (${v.name})', (tester) async {
        await tester.pumpWidget(_header(w, b: v.brightness, s: v.textScale));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('compact: large title امروز with «چهارشنبه ۱۳ آبان», no glass', (tester) async {
    await tester.pumpWidget(_header(const Size(390, 844)));
    expect(find.text('امروز'), findsOneWidget);
    expect(find.text('چهارشنبه ۱۳ آبان'), findsOneWidget);
    expect(find.byType(AppGlass), findsNothing);
  });

  testWidgets('expanded: clear-glass date chip with Gregorian and Jalali lines', (tester) async {
    await tester.pumpWidget(_header(const Size(1440, 900)));
    expect(find.byKey(const ValueKey('today-date-chip')), findsOneWidget);
    expect(find.text('چهارشنبه، ۴ نوامبر'), findsOneWidget);
    expect(find.text('۱۳ آبان ۱۴۰۵'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is AppGlass && w.role == GlassRole.clear), findsOneWidget);
  });

  for (final w in [const Size(390, 844), const Size(1440, 900)]) {
    testWidgets('long-press the title (${w.width})', (tester) async {
      var pressed = false;
      await tester.pumpWidget(_header(w, onLong: () => pressed = true));
      await tester.longPress(find.byKey(const ValueKey('today-title')));
      expect(pressed, isTrue);
    });
  }
}
```

`test/features/today/today_onboarding_test.dart`:
```dart
// 1. glassTestVariants: renders, no exception.
// 2. shows «روز تازه‌ای است», «اولین کار را بنویس», «افزودن کار», the footer; does NOT show «اولین حساب را بساز» or «یک عادت شروع کن».
// 3. tapping `onboarding-add-task` calls onAddTask.
// 4. the «افزودن کار» button is GlassInner (flat), and there are exactly 2 AppGlass (two cards) — no glass on glass.
```
Write them as concrete tests like the header test.

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement** `lib/features/today/presentation/today_header.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/core/date_time/persian_date_label.dart';
import 'package:flutter/material.dart';

/// Today's header: the phone large title, or the desktop date chip
/// (board `MacToday`).
class TodayHeader extends StatelessWidget {
  const TodayHeader({required this.now, this.onTitleLongPress, super.key});

  final DateTime now;
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    if (WindowClass.of(context) == WindowClass.compact) {
      return LargeTitleHeader(
        key: const ValueKey('today-title'),
        title: 'امروز',
        subtitle: PersianDateLabel.short(now),
        onTitleLongPress: onTitleLongPress,
      );
    }
    Widget title = AppText(PersianDateLabel.jalaliLong(now), role: AppTextRole.largeTitle, weight: FontWeight.w900, tone: AppTextTone.onTint);
    title = KeyedSubtree(
      key: const ValueKey('today-title'),
      child: onTitleLongPress == null ? title : GestureDetector(onLongPress: onTitleLongPress, child: title),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 22, 28, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: GlassScope(
          kind: GlassLayerKind.clear,
          child: AppGlass(
            key: const ValueKey('today-date-chip'),
            role: GlassRole.clear,
            shape: const AppleGlassShape.rounded(26),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 10, 26, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(PersianDateLabel.gregorianShort(now), role: AppTextRole.subheadline, weight: FontWeight.w600, tone: AppTextTone.onTint),
                  title,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```
The board's chip title is 40 pt; `AppTextRole.largeTitle` is 34. If the theme has no 40 pt role, apply `fontSize: 40` through AppText only if it exposes a size override; otherwise keep 34 and report it (do not add a literal size in `lib/features/**`; spec §6).

`lib/features/today/presentation/today_onboarding.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:flutter/material.dart';

/// The board `PhoneEmptyToday`, with only the steps whose feature exists
/// (plan Decision 2).
class TodayOnboarding extends StatelessWidget {
  const TodayOnboarding({required this.onAddTask, super.key});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TodayCard(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            AppText('روز تازه‌ای است', role: AppTextRole.headline, weight: FontWeight.w900),
            SizedBox(height: AppSpacing.s4),
            AppText('چند قدم کوچک، و داشبوردت زنده می‌شود.', role: AppTextRole.footnote, tone: AppTextTone.secondary),
          ]),
        ),
        const SizedBox(height: AppSpacing.s12),
        TodayCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                AppText('اولین کار را بنویس', role: AppTextRole.subheadline, weight: FontWeight.w800),
                SizedBox(height: AppSpacing.s4),
                AppText('مثلاً «ورزش صبح» با ساعت و یادآور.', role: AppTextRole.footnote, tone: AppTextTone.secondary),
              ]),
            ),
            const SizedBox(width: AppSpacing.s12),
            Pressable(
              key: const ValueKey('onboarding-add-task'),
              onPressed: onAddTask,
              semanticLabel: 'افزودن کار',
              child: const GlassInner(
                child: SizedBox(
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Center(child: AppText('افزودن کار', role: AppTextRole.footnote, tone: AppTextTone.link, weight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.s12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s8),
          child: AppText('هر وقت خواستی، با دکمهٔ مثبت بالا چیزی اضافه کن.', role: AppTextRole.footnote, tone: AppTextTone.secondary, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
```
`Pressable` needs a 44 pt hit target: if its child is 36 tall, wrap the `GlassInner` in `ConstrainedBox(constraints: BoxConstraints(minHeight: 44))` with the inner box centred, keeping the visible pill 36 tall; add a hit-target test.

- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): header and onboarding`.

---

### Task 8: TodayPage, entrance and router

**Files:**
- Create: `lib/features/today/presentation/today_page.dart`
- Modify: `lib/app/router/app_router.dart` (`/` builds `TodayPage`), delete `lib/app/shell/today_interim_page.dart`, update tests that reference `TodayInterimPage` (`grep -rn TodayInterimPage lib test integration_test`)
- Test: `test/features/today/today_page_test.dart`, `test/features/today/today_budget_test.dart`

**Interfaces:**
- Consumes: Tasks 1–7; `LegacyImportBanner`; `AppRoutes.glassReview`, `AppRoutes.tasks`; `GlassVisibility`; `AppMotion.quick`, `AppMotion.reduced`, `AppMotion.staggerAt`; `MotionScope`; `WindowClass`.
- Produces:
  - `abstract final class TodayEntrance { static bool get played; static void markPlayed(); @visibleForTesting static void reset(); }` — process-wide cold-start flag.
  - `class TodayPage extends ConsumerStatefulWidget { const TodayPage({super.key}); }` — a `ListView` padded with `MediaQuery.paddingOf(context)` plus `EdgeInsets.symmetric(horizontal: 16)` on compact and `EdgeInsetsDirectional.fromSTEB(28, 0, 28, 28)` on medium/expanded: `TodayHeader(now:, onTitleLongPress: kDebugMode ? () => context.push(AppRoutes.glassReview) : null)`, `LegacyImportBanner()`, then either `TodayOnboarding(onAddTask: () => context.go(AppRoutes.tasks))` when `todayIsNewUserProvider` is true, or a `TodayGrid` of: `timeline` (wide) `TimelineCard`, `tasks` (large) `TodayTasksCard(onToggle: ref.read(todayCompletionProvider).toggle, onShowAll: () => context.go(AppRoutes.tasks))`, and `installment` (wide) `InstallmentCard(onOpen: () => context.go('/finance'))` when `todayInstallmentProvider` has a plan. Loading: an empty `SizedBox` for the grid area (no spinner flash); error: `EmptyState(icon: Icons.error_outline, title: 'امروز بارگذاری نشد')`.
  - Entrance: each grid item and the onboarding cards are wrapped in `_Enter(index:)`: on cold start (`!TodayEntrance.played`, read once in `initState`), a controller per item runs after `AppMotion.staggerAt(index)` for `AppMotion.quick.duration` (`reduced` under Reduce Motion); the child is `Transform.translate(offset: Offset(0, 8 × (1 − t)))` (skipped when reduced) around `GlassVisibility(value: t)`. `TodayEntrance.markPlayed()` is called in the first post-frame callback. Later builds use `t = 1` with no controller. `animateIn` on `InstallmentCard` is true only on cold start.
  - Keys: `ValueKey('today-page')` on the ListView, `ValueKey('today-onboarding')`, `ValueKey('today-grid')`.

- [ ] **Step 1: Write the failing tests**

`test/features/today/today_page_test.dart` — pump the real app with `pumpBorjTestApp` (`test/support/borj_test_app.dart`, with `useWindowSize` for 390×844 and 1440×900) and a `FixedAppClock` override at 2026-11-04 14:30 local plus `taskCalendarTimeZoneProvider` overridden to `'Asia/Tehran'`; call `TodayEntrance.reset()` in `setUp`:
```dart
// 1. empty database → TodayOnboarding shown; tap `onboarding-add-task` → the Tasks branch (TasksPanel) is visible.
// 2. with one planned task due today 15:00 local → `today-grid` shown with timeline + tasks cards, no installment card,
//    the timeline header reads «بعدی:» + the task title, and the tasks card row `today-task-<id>` exists.
// 3. toggling the row's RoundCheck marks the task completed in the repository (read it back); toggling again → planned.
// 4. with an active InstallmentPlan → the installment card appears; tapping it goes to /finance (FinancePanel visible).
// 5. compact header shows «چهارشنبه ۱۳ آبان»; expanded shows the date chip «۱۳ آبان ۱۴۰۵».
// 6. debug long-press on `today-title` pushes the glass review; pop returns to Today.
// 7. entrance: on the first build cards start invisible (GlassVisibility value 0 on the first frame) and reach 1 within
//    300 ms + the last stagger; a second TodayPage build (switch to Tasks and back) has no entrance (value 1 on the first frame).
// 8. reduce motion: the first build moves nothing (expectNoMovement on `today-grid`) and still fades (value < 1 then 1).
// 9. the agenda follows the clock: advance the overridden minuteTickProvider to the next day → the task due today disappears.
```
Write each as a concrete `testWidgets` (create data through the real repositories from the container: `container.read(taskRepositoryProvider).create(...)` then `transition(...)`, `container.read(financeRepositoryProvider)` for an installment plan — read `finance_repository.dart` for the create method).

`test/features/today/today_budget_test.dart`:
```dart
// With the populated Today (task + installment) in BorjApp at 390×844 and 1440×900:
// countCompositedBackdrops == 2 at idle (content group 1 + chrome 1) on both, sampled over 20 frames,
// and during the cold-start entrance (sample the first 30 frames) max == 2; no bare fade above any card glass
// (bareFadesAboveGlass over the today-page) during the entrance.
```
Write it concretely (pattern: `test/app/shell/app_shell_budget_test.dart`).

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement** `lib/features/today/presentation/today_page.dart`:
```dart
import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_banner.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:borj/features/today/presentation/installment_card.dart';
import 'package:borj/features/today/presentation/timeline_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:borj/features/today/presentation/today_header.dart';
import 'package:borj/features/today/presentation/today_onboarding.dart';
import 'package:borj/features/today/presentation/today_tasks_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Today's cold start plays once per process (motion spec §4).
abstract final class TodayEntrance {
  static bool _played = false;
  static bool get played => _played;
  static void markPlayed() => _played = true;
  @visibleForTesting
  static void reset() => _played = false;
}

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  late final bool _coldStart = !TodayEntrance.played;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => TodayEntrance.markPlayed());
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(minuteTickProvider).valueOrNull ?? ref.read(appClockProvider).nowLocal();
    final compact = WindowClass.of(context) == WindowClass.compact;
    final newUser = ref.watch(todayIsNewUserProvider);
    final agenda = ref.watch(todayAgendaProvider);
    final installment = ref.watch(todayInstallmentProvider);

    Widget body;
    if (newUser.hasError || agenda.hasError) {
      body = const EmptyState(icon: Icons.error_outline, title: 'امروز بارگذاری نشد');
    } else if (!newUser.hasValue || !agenda.hasValue || !installment.hasValue) {
      body = const SizedBox.shrink();
    } else if (newUser.requireValue) {
      body = KeyedSubtree(
        key: const ValueKey('today-onboarding'),
        child: _Enter(index: 0, play: _coldStart, child: TodayOnboarding(onAddTask: () => context.go(AppRoutes.tasks))),
      );
    } else {
      final a = agenda.requireValue;
      final plan = installment.requireValue;
      final items = <TodayGridItem>[
        TodayGridItem(id: 'timeline', size: TodayCardSize.wide, child: TimelineCard(agenda: a, now: now)),
        TodayGridItem(
          id: 'tasks',
          size: TodayCardSize.large,
          child: TodayTasksCard(agenda: a, now: now, onToggle: ref.read(todayCompletionProvider).toggle, onShowAll: () => context.go(AppRoutes.tasks)),
        ),
        if (plan != null)
          TodayGridItem(id: 'installment', size: TodayCardSize.wide, child: InstallmentCard(installment: plan, animateIn: _coldStart, onOpen: () => context.go('/finance'))),
      ];
      body = KeyedSubtree(
        key: const ValueKey('today-grid'),
        child: TodayGrid(items: [
          for (var i = 0; i < items.length; i++)
            TodayGridItem(id: items[i].id, size: items[i].size, child: _Enter(index: i, play: _coldStart, child: items[i].child)),
        ]),
      );
    }

    final media = MediaQuery.paddingOf(context);
    final side = compact ? const EdgeInsets.symmetric(horizontal: 16) : const EdgeInsetsDirectional.fromSTEB(28, 0, 28, 28).resolve(Directionality.of(context));
    return ListView(
      key: const ValueKey('today-page'),
      padding: media + side,
      children: [
        TodayHeader(now: now, onTitleLongPress: kDebugMode ? () => context.push(AppRoutes.glassReview) : null),
        const LegacyImportBanner(),
        const SizedBox(height: 20),
        body,
      ],
    );
  }
}

class _Enter extends StatefulWidget {
  const _Enter({required this.index, required this.play, required this.child});

  final int index;
  final bool play;
  final Widget child;

  @override
  State<_Enter> createState() => _EnterState();
}

class _EnterState extends State<_Enter> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Timer? _delay;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.play || _c != null) return;
    _reduced = MotionScope.reducedOf(context);
    final m = _reduced ? AppMotion.reduced : AppMotion.quick;
    final c = _c = AnimationController(vsync: this, duration: m.duration);
    final curved = CurvedAnimation(parent: c, curve: m.curve);
    c.addListener(() => setState(() {}));
    _curved = curved;
    _delay = Timer(AppMotion.staggerAt(widget.index), () {
      if (mounted) unawaited(c.forward());
    });
  }

  CurvedAnimation? _curved;

  @override
  void dispose() {
    _delay?.cancel();
    _curved?.dispose();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _curved?.value ?? 1.0;
    Widget child = GlassVisibility(value: t, child: widget.child);
    if (!_reduced && t < 1) child = Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child);
    return child;
  }
}
```
`GlassVisibility` dims the glass and its children (Phase 1), so the cards' text fades with the glass; the header is not wrapped (static). Timers in widget tests: the stagger uses `Timer`, so tests must `pump` past the last stagger (`AppMotion.staggerAt(2)` + the duration) before ending, or the test framework reports a pending timer — keep that in the tests.

Router: in `lib/app/router/app_router.dart`, the `/` branch root builds `const TodayPage()` (keep `NoTransitionPage`); delete `today_interim_page.dart` and its import; update `test/app/router/app_router_test.dart` and any test that finds `TodayInterimPage` to find `TodayPage` (the «صفحهٔ امروز در حال ساخت است» assertion becomes the onboarding check on an empty database). Keep the `today-title` key working on both classes.

- [ ] **Step 4: Run** `flutter test test/features/today test/app/router test/app/shell`, then the full `flutter test --exclude-tags device`. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): today page with cold-start entrance`.

---

### Task 9: Review samples and the device probe on a populated Today

**Files:**
- Modify: `lib/app/apple_visual/review/design_review_samples.dart`, `integration_test/glass_shell_probe_test.dart`
- Test: the existing review test; the device probe

Steps:
- [ ] **Step 1: Review samples** (follow the existing entries): `TimelineCard` (board `Main`, a fixed agenda with three blocks and now at 14:30), `TodayTasksCard` large (board `Main`), `TodayTasksCard` expanded grouping (board `MacToday`, in a 572 × 340 box with a 1440 MediaQuery), `InstallmentCard` wide and small (board `Main`), `TodayHeader` date chip (board `MacToday`), `TodayOnboarding` (board `PhoneEmptyToday`). Samples use fixed data, never providers.
- [ ] **Step 2: Run** `flutter test test/app/apple_visual`. Expected: PASS.
- [ ] **Step 3: Device probe.** In `integration_test/glass_shell_probe_test.dart`, before sampling Today, create one task due today and one active installment plan through the real repositories (via the container returned by `pumpBorjTestApp`), wait for the grid (`find.byKey(ValueKey('today-grid'))`), then sample. Change the phone and desktop Today assertions to `today ≤ budget` AND `today ≥ 2` (content + chrome now that Today has content glass), and print `today=` as before. Run `flutter test integration_test/glass_shell_probe_test.dart -d linux`, the full `tool/ci.sh --device`, and the profile drive (`flutter drive --profile -d linux --driver=test_driver/integration_test.dart --target=integration_test/glass_shell_probe_test.dart`); report every `LG_` line.
- [ ] **Step 4: Commit** `test(today): review samples and the device probe on a populated Today`.

---

### Task 10 (controller): Part B checkpoint

- [ ] Final whole-branch review (most capable model) and one fix wave.
- [ ] `docs/superpowers/checkpoints/2026-11-XX-redesign-phase-2b-checkpoint.md`, WORKLOG, roadmap; merge into `feat/v2-complete-dashboard`.
- [ ] Tell the owner in Persian what Today now shows and how to try it; owner sign-off still waits for Part C.
