# Rename v2 to Borj (برج) — design

Date: 2026-11-06. Status: approved by the owner (decisions in chat, 2026-11-06).
Name decision: `docs/superpowers/references/2026-11-06-product-name-borj.md`.

## Goal

Every live use of the working name "Dashboard Shakhsi" / "داشبورد شخصی" in v2
becomes Borj / برج: code, platform runners, user-visible strings, living docs,
the GitHub repository and the local folders.

## Owner decisions

1. Android application ID changes to `app.borj`. v2 no longer upgrades over the
   v1 APK (`ir.dashboard.shakhsi`); it installs as a separate app and v1 data is
   moved with the existing Settings import.
2. Only living docs change (`CLAUDE.md`, `PROJECT_ROADMAP.md` title and status,
   current specs). Historical records (worklog entries, old plans, checkpoints,
   references, decisions) stay as written: they describe the state at the time.
3. GitHub repository: `majidsii/dashboard-shakhsi` → `majidsii/borj`.
4. Local folders move under `~/projects/personal/borj/`.

## Identifier map

| Where | Old | New |
|---|---|---|
| Dart package (`pubspec.yaml`, all imports) | `dashboard_shakhsi` | `borj` |
| Root widget | `DashboardShakhsiApp` | `BorjApp` |
| App title, brand text, notification title | `داشبورد شخصی` | `برج` |
| Notification permission body | `اعلان‌های داشبورد شخصی فعال هستند.` | `اعلان‌های برج فعال هستند.` |
| Logger names | `dashboard_shakhsi.*` | `borj.*` |
| Windows notification AUMID | `Majidsii.DashboardShakhsi` | `Majidsii.Borj` |
| Drift database name / file | `dashboard_shakhsi` / `dashboard_shakhsi.sqlite` | `borj` / `borj.sqlite` |
| systemd unit base name | `dashboard-shakhsi-notification-<16 hex>` | `borj-notification-<16 hex>` |
| systemd registry file | `dashboard-shakhsi-notification-registry.json` (+ hidden temp files) | `borj-notification-registry.json` |
| systemd unit Description | `Dashboard Shakhsi scheduled notification …` | `Borj scheduled notification …` |
| Android namespace, applicationId | `ir.dashboard.shakhsi` | `app.borj` (`.dev` suffix for debug stays) |
| Android `MainActivity` package dir | `java/ir/dashboard/shakhsi/` | `java/app/borj/` |
| Android label | `dashboard_shakhsi` | `برج` |
| Linux `BINARY_NAME` / `APPLICATION_ID` | `dashboard_shakhsi` / `ir.dashboard.dashboard_shakhsi` | `borj` / `app.borj` |
| Linux GTK header and window title | `dashboard_shakhsi` | `برج` |
| Windows CMake project, `BINARY_NAME` | `dashboard_shakhsi` | `borj` |
| Windows `Runner.rc` | `ir.dashboard`, `dashboard_shakhsi(.exe)` | CompanyName `Majidsii`, FileDescription/ProductName `Borj`, InternalName `borj`, OriginalFilename `borj.exe`, copyright `Copyright (C) 2026 Majidsii.` |
| Windows window title (`main.cpp`) | `L"dashboard_shakhsi"` | `L"برج"` (برج, escaped for MSVC) |
| macOS `PRODUCT_NAME`, bundle ID, pbxproj and scheme refs | `dashboard_shakhsi(.app)`, `ir.dashboard.shakhsi` | `borj(.app)`, `app.borj` |
| Test fixtures (temp dir prefixes, `/opt/...` paths, unit names, titles) | old name | new name |

## Must NOT change

- `LegacyV1SourceLocator.appDirectoryName = 'dashboard-shakhsi'` and any test
  fixture that models the v1 data directory: v1 stores `data.json` in
  `~/.local/share/dashboard-shakhsi/` (Windows `%APPDATA%\dashboard-shakhsi\`),
  and the importer must keep finding it.
- The v1 code on `main`, and the v1 releases.
- Historical docs (decision 2), `APPLY.md` and `tool/apply_phase1_task7_wiring.py`
  (dead one-off artifacts of past tasks).

## Existing v2 database

The owner already has a v2 database at `~/dashboard_shakhsi.sqlite` (Linux
`getApplicationDocumentsDirectory()` resolves to `$HOME` on this machine).
On open, before Drift opens `borj.sqlite`, the app moves the legacy files in the
same directory:

- Only when `borj.sqlite` does not exist and `dashboard_shakhsi.sqlite` does.
- Moves `dashboard_shakhsi.sqlite` and, when present, its `-wal`, `-shm` and
  `-journal` siblings to the matching `borj.sqlite*` names (rename, not copy).
- When both main files exist, nothing is moved and nothing is deleted.
- Done through `DriftNativeOptions(databaseDirectory: ...)` so the directory is
  the same one Drift used before. No schema change; schema stays 9.

No systemd units with the old prefix exist on the owner's machine (checked
2026-11-06), so no unit cleanup is needed. v2 is unreleased, so no other user has
v2 units or a v2 database.

## Environment steps (main session, after code is green)

1. `gh repo rename borj` on `majidsii/dashboard-shakhsi`; update `origin` in the
   main repo and the separate v1 clone to `git@github.com:majidsii/borj.git`.
2. Move folders (all Claude sessions in them closed first):
   - `~/projects/personal/dashboard-shakhsi` (v1 clone) → `borj/v1`
   - `~/projects/personal/dashboard-shakhsi-phase-1-checkpoint/phase-1-finance` (main worktree) → `borj/main`
   - each linked worktree `dashboard-shakhsi-<x>` → `borj/<x>`
   - `dashboard-shakhsi-reference-captures`, `dashboard-shakhsi-gate-c-wip-backup-2026-11-04` → `borj/<rest>`
   - then `git worktree repair` with every new path; delete moved `build/` dirs (CMake caches hold absolute paths).
3. Copy the Claude project memory to the new main path's project key.

## Acceptance

- `git grep -i -E "dashboard[-_ ]?shakhsi|DashboardShakhsi|داشبورد شخصی"` outside
  historical docs returns only the v1-path exceptions above.
- `dart run build_runner build`, `flutter analyze` and the full `flutter test`
  pass; `flutter build linux` produces `build/linux/x64/release/bundle/borj`.
- New unit tests cover the database file move (moved, not moved when target
  exists, siblings moved, no legacy file).
- GitHub shows `majidsii/borj`; `git fetch` works in every moved folder;
  `git worktree list` shows the new paths.
