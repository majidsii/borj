# Checkpoint — Redesign Phase 2 Part A (app shell and navigation), 2026-11-09

Plan: `docs/superpowers/plans/2026-11-08-redesign-phase-2a-shell.md`. Spec: `docs/superpowers/specs/2026-11-05-liquid-glass-redesign-design.md` §5, §7 item 2; `2026-11-06-motion-and-today-customization-design.md` §3, §9.
Decision: `docs/superpowers/decisions/2026-11-08-shell-settings-entry-and-unbuilt-sections.md`.
Ledger (every agent, review, ruling, deferred minor with triage): `docs/superpowers/references/2026-11-08-phase-2a-progress-ledger.md`.
Branch `feat/redesign-phase-2a`, base `c413149`, head at this checkpoint `1292151` plus this commit.

Phase 2 is split: Part A (this) shell; Part B Today rebuilt to the boards; Part C Today customization (schema 10). Owner sign-off and the A34 profile run come at the end of Part C.

## Delivered

- Window classes (compact < 600, medium 600–1023, expanded ≥ 1024) and shell destinations; habits, goals and budgets hidden behind `ShellFeatures` (owner: required scope, built later).
- Patterns: `SlidingLens` + `GlassTabBar` (62 pt capsule, 62 pt search circle, lens slides `snappy`, ≤ 12 % stretch, jumps under Reduce Motion), `GlassSidebar` (236 pt, 36 pt rows) and 72 pt rail (44 pt rows), `ShellToolbar`, `LargeTitleHeader`, `EmptyState`, `GlassPushPage` (Cupertino push and back swipe, RTL-aware, scrim behind the page, parallax over any page, instant on medium/expanded and under Reduce Motion, page backdrop group only outside a group), `GlassInspector`.
- `AppShell`: content under one `GlassBackdropGroup`, all chrome of a window class in one chrome `GlassScope` painted after the content; safe areas; keyboard resize (`viewInsets`) with a reveal above the tab bar; Ctrl+, and Ctrl+K (⌘ on macOS); branch state survives window-class changes.
- Router: `StatefulShellRoute.indexedStack` (NoTransitionPage) with Today (interim page), Tasks (`TasksPanel`) and Finance (`FinancePanel`) branches; pending pages for unbuilt detail screens; error page; every `NotificationRouteLocationMapper` location resolves; no `builder:` routes (Material page fades would bare-fade glass); old dashboard deleted.
- Search shell: phone `/search` page, desktop Ctrl+K / toolbar-capsule overlay with no animation.
- Review page samples for the shell patterns; device probe on the real shell; platform app icons (Windows, macOS, Android, Linux window icon).

## Verification (head `1292151`)

- `dart format --output=none --set-exit-if-changed lib test integration_test`: exit 0.
- `flutter analyze`: no issues.
- `flutter test --exclude-tags device`: 1780 passed, 1 skipped.
- `tool/ci.sh --device`: exit 0.

Real glass (Linux, debug):
```
LG_COMPOSITED scene=phoneShell today=1 tasks=7 finance=16 settingsPush=4 settingsSettled=3 searchPush=2 active_seeded_passes=2
LG_CAPTURES scene=phoneShell path=real max=2
LG_COMPOSITED scene=desktopShell today=1 search=2 active_seeded_passes=2
LG_CAPTURES scene=desktopShell path=real max=2
LG_PERF scene=phoneShell mode=debug raster_p90_ms=1.97
LG_PERF scene=desktopShellLegacyTasks mode=debug raster_p90_ms=1.462
```
Profile (`flutter drive --profile … glass_shell_probe_test.dart`):
```
LG_PERF scene=phoneShell mode=profile raster_p90_ms=1.289
LG_PERF scene=desktopShellLegacyTasks mode=profile raster_p90_ms=1.657
```
Phase 1 probe in the same run: phone 2 / desktop 3; phone + sheet + toast 3; desktop + toast 4.
FakeGlass shell budget tests: idle 2, during selection 2, with a sheet open 3, on compact, medium and expanded.
Legacy screens (printed, not asserted; Decision 7 extended): Tasks 7, Finance 16, Settings push 4 / settled 3.

## Decisions and rulings

Plan decisions 1–7, plus controller rulings recorded in the ledger:
- desktop toolbar buttons are 44 pt (GlassButton minimum = 44 pt target; board 36);
- expanded sidebar rows 36 pt (board, pointer), medium rail rows 44 pt (touch tablets);
- Decision 7 extended to Settings (its legacy import section uses OriginalGlass); the phone push budget is asserted on `/search`;
- a page-hosted inspector joins the content group and cannot refract content → Phase 3 adds a shell-level inspector slot with its own budget test;
- no `builder:` routes; the shell route is a NoTransitionPage;
- pushed pages get one page-level backdrop group, only when no glass group is above them;
- until Phase 4 rebuilds finance, the desktop «پول» rows open the legacy FinancePanel (`/finance`, `/finance?section=debts`); sidebar rows always `go` to their exact location; selection falls back to the section's first row.

## Deferred (triaged by the final review; see the ledger)

- Phase 3: shell inspector slot and adaptive detail (push/sheet on compact, inspector on expanded, same URL, resize tests); push/overlay test gaps (scrim alpha, mid-push asserts, positive page assert after a notification, capsule geometry, the 52 magic number, overlay left open when shrinking to compact, Escape focus); `design/` importing `app/shell`; `SidebarItem` duplicating `ShellDestination`; stale `tool/verify_*` scripts that read the deleted dashboard.
- Phase 3/4: the keyboard reveal jumps per animation frame and measures the EditableText box (legacy panels); `/finance/debts/:id` selects «تراکنش‌ها».
- Part B/C: lens relayout/reduce-motion-toggle edge cases; EmptyState duration and assert; Today compact toolbar is at the 5-shape chrome cap (Part B cannot add a Today action without a ruling).
- Habits phase (or Phase 5 for Settings): a notification to a root location (`/settings`, `/habits/:id`, …) drops the shell and Android back exits; fix in the adapter (`go('/')` then `push`), the mapper stays unchanged.
- Brand kit: `borj.ico` uses the master mark at 16/32 px.
- Environment: the sqlite3 native-asset download failed in the agent sandbox (a verified `libsqlite3.so` was copied into `.dart_tool`); check a clean clone with network.
