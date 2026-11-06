# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Every reply to the owner in chat is in Persian. No exceptions**, even when
> the previous message, a tool result or a skill is in English. Follow the
> terminal rules in the user's global CLAUDE.md: no markdown tables, no Latin
> words or digits inside a Persian sentence (put them on their own line or in a
> code block), short lines. Files written to the repo (specs, plans, docs, code,
> commit messages) stay in English.

## What this is

Borj (برج): a Persian, Jalali-calendar, offline-first personal dashboard
(finance + tasks today; habits and goals planned). Flutter for Linux (primary),
Android, Windows and macOS. Repository `majidsii/borj`; Dart package `borj`;
app ID `app.borj`. The working name until 2026-11-06 was "Dashboard Shakhsi"
(داشبورد شخصی); historical docs still use it. See
`docs/superpowers/specs/2026-11-06-rename-to-borj-design.md`.

- v1 (Python + HTML webview, still named Dashboard Shakhsi) is published on
  GitHub (`main`, releases v1.0.0–v1.2.0). It stores user data in
  `~/.local/share/dashboard-shakhsi/data.json`
  (Windows `%APPDATA%\dashboard-shakhsi\data.json`). Keep that directory name in
  the importer; it is v1's, not ours.
- v2 is a full Flutter rewrite on `feat/v2-complete-dashboard`, not yet released.
  v2 imports v1 data from Settings (`lib/features/legacy_import/`).

## Where things are written down

Read these before proposing work. Don't redo or redesign anything listed as done
without fresh evidence of a defect.

- `PROJECT_ROADMAP.md`: §0 program order, §7 current task, §14 handoff summary.
  Source of truth for scope and status.
- `docs/WORKLOG.md`: append-only log of what was implemented, reviewed or decided,
  with commits and links. Add an entry whenever a unit of work finishes.
- `docs/superpowers/specs/`: approved designs. `plans/`: task-by-task plans.
  `checkpoints/`: evidence that a task is done. `references/`: research,
  blockers and spike reports. `decisions/`: approved deviations.

Authority when sources disagree: repository state and tests > checkpoint >
spec > roadmap > chat history.

## Commands

The Flutter SDK version is pinned in `.flutter-version` (3.47.5). Use
`/home/shabin/develop/flutter-3.47.5/bin` first on `PATH` (the shared
`~/develop/flutter` is 3.44.6 for other projects; never upgrade it).
Pub uses the `pub.flutter-io.cn` mirror (`PUB_HOSTED_URL`), and `pubspec.lock`
records that host. The `storage.flutter-io.cn` notice in output is expected.

```bash
flutter test                                   # full suite, ~5 min, ~1370 tests
dart run build_runner build --delete-conflicting-outputs  # Drift codegen (app_database.g.dart)
tool/ci.sh                                     # all CI checks (format, codegen, analyze, test, build)
tool/ci.sh --device                            # plus integration_test on Linux
```

Tests that need a GPU or a desktop session go under `integration_test/` and run
on a device: `flutter test integration_test/<file> -d linux`. Shader image
filters and Flutter GPU are on by default with 3.47.5 on Linux once the runner
enables Flutter GPU (Task 2).

## Architecture

**Entry point.** `lib/main.dart` → `ApplicationEntrypoint`
(`lib/app/bootstrap/application_entrypoint.dart`). The same binary has two modes:

- normal app: `bootstrapApp()` builds a `ProviderContainer`, wraps the app in
  `UncontrolledProviderScope` and starts notification bootstrap;
- `--deliver-notification ...`: headless delivery of one Linux notification, then
  exit. systemd user timers invoke this mode.

**Linux notifications** (`lib/core/notifications/linux_systemd_*`). The app
writes systemd user `.timer`/`.service` units whose `ExecStart` re-invokes the
app binary in delivery mode. A JSON registry tracks scheduled units. Process
execution, the file system and unit stores sit behind interfaces with fakes in
`test/support/`. Other platforms use `flutter_local_notifications`. Feature code
talks only to `NotificationCoordinator`, keyed by `NotificationOwner`.

**Layers per feature** (`lib/features/<feature>/{domain,data,application,presentation}`):
domain types and repository interfaces → Drift implementations in `data/` →
services and projectors in `application/` → widgets in `presentation/`.
Dependency wiring is plain Riverpod `Provider`s in
`lib/core/providers/persistence_providers.dart` (no codegen). Tests override them.

**Persistence.** One Drift database (`lib/core/database/app_database.dart`),
schema version 9. Migrations are append-only and must keep existing data
deterministic. Every schema change needs migration and restart tests. Persisted
timestamps are UTC. Local-day logic goes through `AppClock` and
`local_day_boundary.dart`. Never call `DateTime.now()` in domain code.

**Money** (`lib/core/money/money.dart`) is integer minor units plus scale, with
Toman (`IRT`) as the default. IRT uses scale 0 (whole toman). Arithmetic is
checked: overflow throws `MoneyOverflowFailure`, never wraps or truncates.
Never use `double` for money.

**Recurrence** (`lib/core/recurrence/`) is a generic engine with Jalali and
Gregorian calendars. Task-specific exceptions and completion state live in
`lib/features/tasks`, never in the engine.

**Tasks invariants.** These are established by Tasks 2.1–2.8 and must not be broken:
- status is one of `planned | inProgress | completed | canceled`, parsed exactly;
- `displayNumber` is immutable and never reused;
- `positionInStatus` is contiguous `0..n-1` per status, changed only transactionally;
- reminders, recurrence, timers and templates are separate persisted entities,
  not fields on `TaskItem`.

**Visual system.** Content screens use `lib/app/widgets/original_*` (`OriginalGlass`
for cards) and `lib/app/theme/`. Apple-style system in `lib/app/apple_visual/`:
- `foundation/`: source-derived tokens. Keep these.
- `generated/`: tokens generated from the Apple UI kit by `tool/` scripts.
- The Gate C `rendering/` pipeline is gone.

Redesign in progress (owner-approved 2026-11-05): EVERY element is Liquid Glass,
chrome and content alike, but never glass on glass (things drawn on glass use a flat
inner material). Light background white, dark background charcoal with warm light.
The approved boards are `docs/superpowers/references/2026-11-05-glass-mockups/`
(the board wins on layout); the design is
`docs/superpowers/specs/2026-11-05-liquid-glass-redesign-design.md`. New code uses `AppGlass(role: GlassRole..., shape: AppleGlassShape..., child:)` inside a
`GlassScope(kind: GlassLayerKind...)` (one layer, ≤ 16 shapes), with the scopes of one surface under one
`GlassBackdropGroup`. Things drawn on glass use `GlassInner`. The legacy `AppleLiquidGlass` remains only for
screens not yet migrated. The theme comes from
`AppleVisualScope.of(context)` (follows app brightness). Only `apple_liquid_glass.dart`
and `app_bootstrap.dart` import `liquid_glass_renderer`. Acceptance is side-by-side
perceptual, not pixel goldens: debug review page (long-press the brand island, run
with `--dart-define=GLASS_REFERENCE_DIR=...`) and `tool/ci.sh --device` for the Linux
full-glass test. See
`docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md` and
`docs/superpowers/checkpoints/2026-11-04-liquid-glass-adoption-checkpoint.md`.

## Lints that bite

`analysis_options.yaml` turns on `require_trailing_commas`,
`sort_constructors_first`, `directives_ordering`, `prefer_final_locals`,
`unawaited_futures`, `avoid_print` and `avoid_dynamic_calls`. `dead_code` is an
error. Run `flutter analyze` before claiming anything is done.

## How work is run

- **Language.** Talk to the owner in Persian, following the terminal rules in the
  user's global CLAUDE.md. Specs, plans, docs, code comments and commit messages
  are in English.
- **Flow.** For each item in roadmap §0: brainstorm → spec
  (`docs/superpowers/specs/`) → plan (`docs/superpowers/plans/`) → RED/GREEN
  implementation → checkpoint → `docs/WORKLOG.md` entry → roadmap update. The
  owner has delegated prioritization: recommend one option and ask one yes/no.
- **Orchestration.** The main session (the strongest model) plans, dispatches,
  reviews and integrates. Cheaper subagents implement:
  - `sonnet` implements plan tasks by default;
  - `haiku` gets purely mechanical work only (formatting, renames, running a
    command and reporting, applying exact text);
  - one plan task per agent. The prompt carries the task text verbatim, the
    plan's Global Constraints and the relevant file paths;
  - the main session reviews every result itself: it reads the diff against the
    spec and plan and reruns the focused tests and `flutter analyze`. A
    subagent's "done" is not evidence;
  - send problems back to the same agent with `SendMessage` (it keeps its
    context) until fixed, then review again;
  - the main session alone handles trivial one-step operations, git pushes,
    questions to the owner, and roadmap and worklog updates.
- **Git.** Stage explicit paths, never `git add -A`. The owner granted standing
  permission (2026-11-03) to push branches of this repo to GitHub without
  asking. Still ask before force-pushing, pushing to `main`, deleting a branch
  you didn't create, or tagging a release. Don't use bare `git stash`
  (worktrees share the stash).
- **Don't add new `tool/verify_*` scripts.** Tests, the analyzer and CI are the
  evidence.
