# Checkpoint — Redesign Phase 2 Part B (Today), 2026-11-09

Plan: `docs/superpowers/plans/2026-11-09-redesign-phase-2b-today.md` (controller amendments A1–A5, Decisions 1–8). Specs: `2026-11-06-motion-and-today-customization-design.md` §4 Today, §5.1 grid; `2026-11-05-liquid-glass-redesign-design.md`. Boards: `Main`, `MacToday`, `PhoneEmptyToday`.
Ledger (every agent, review, ruling, deferred item): `docs/superpowers/references/2026-11-09-phase-2b-progress-ledger.md`.
Branch `feat/redesign-phase-2b`, base `56b3b91`, head `9ab2cd0` plus docs.

## Delivered

- Application: `TodayAgendaBuilder` (timed occurrences of the task-zone day + untimed active one-offs + untimed completed today; skipped/canceled out; stable order), providers `minuteTickProvider` (UTC-minute aligned), `todayNowProvider` (task-zone wall clock), `todayAgendaProvider` (recomputes on input or zone-date change), `todayInstallmentProvider`, `todayIsNewUserProvider`, `TodayCompletion` (one-off status transition / recurring occurrence completion).
- Presentation: fixed-size card grid (§5.1 sizes; columns follow the grid width: ≥ 720 → 4, else 2), `TodayCard`, timeline card (hour scale, blocks, danger now-line with pill, elapsed tint, past fade, «بعدی:»), today's tasks card (check rows, desktop groups, overflow row), installment card, header (phone large title / desktop clear-glass date chip), onboarding (one step), `TodayPage` with a once-per-process cold-start entrance (rise 8 px + fade through `GlassVisibility`, staggered; Reduce Motion: 200 ms fade only).
- Router `/` → `TodayPage`; interim page removed. Review samples; device probe on a populated Today including the cold start.
- Shared: `PersianDateLabel.short/gregorianShort/jalaliLong`, `AppText.decoration`, `AppTextTone.inverse`, `pumpBorjTestApp(minuteTicks:, seed:, settle:)`.

## Verification (head `9ab2cd0`)

- `flutter analyze`: no issues; format check exit 0.
- `flutter test --exclude-tags device`: 1934 passed, 1 skipped. `TZ=UTC flutter test test/features/today`: 148 passed (Tokyo also checked during review).
- `tool/ci.sh --device`: exit 0.

Real glass (Linux, debug):
```
LG_COMPOSITED scene=phoneShell today=2 todayEntrance=2 tasks=8 finance=16 settingsPush=5 settingsSettled=3 searchPush=3 active_seeded_passes=4
LG_CAPTURES scene=phoneShell path=real max=3
LG_COMPOSITED scene=desktopShell today=2 todayEntrance=2 search=3 active_seeded_passes=6
LG_CAPTURES scene=desktopShell path=real max=3
LG_PERF scene=phoneShell mode=debug raster_p90_ms=2.741
LG_PERF scene=desktopShellLegacyTasks mode=debug raster_p90_ms=2.102
```
Profile (Task 9, `a933ae7`): phone 2.243 ms, desktop (legacy Tasks scroll) 2.132 ms (gate 8 ms).
Phone search push is exactly at the budget (3) now that Today has content glass. Legacy Tasks/Finance/Settings are printed only (Part A Decision 7).

## Decisions

Plan Decisions 1–8: no installment due date; one onboarding step; default installment wide; "today" for tasks; desktop timeline card; date chip text follows the theme (white on clear glass was 1.00:1; the navy chip needs a tinted-dark role, deferred); grid columns follow the grid width (600 px medium and 1024 px expanded get 2 columns); completed untimed tasks stay on Today. Amendments: one time base (task-zone wall clock), no live timers in widget tests, chip contrast check, medium widths, cold-start probe.

## Deferred (triaged by the final review)

- Phase 3: naive `DateTime` wall-clock carrier shifts under a device-zone DST gap when the device zone differs from the task zone (carry as `DateTime.utc` fields); time-zone database init in `bootstrapApp` + `Etc/UTC` fallback for Today; toggle Future ignored / double tap / reopen `inProgress` → `planned`; "rule but no times" documentation test.
- Part C (customization): 4-column pull-into-gap tests, unbounded width, `assert(columns >= 1)`, third overlapping block on a large timeline, `today-title` key shape, 4 pt band tap test.
- Legacy-import UI migration phase: the `OriginalGlass` banner adds a capture on Today's onboarding state.
- Owner visual review: faint elapsed tint in dark mode; the date chip without the board's navy tint.
- Owner sign-off and the A34 profile run: at the end of Phase 2 (after Part C).
