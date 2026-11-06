# Rename v2 to Borj — plan

Spec: `docs/superpowers/specs/2026-11-06-rename-to-borj-design.md` (identifier map,
exceptions, acceptance). Branch `feat/v2-complete-dashboard`.

## Global Constraints

- Flutter 3.47.5: put `/home/shabin/develop/flutter-3.47.5/bin` first on `PATH`.
- Lints: `require_trailing_commas`, `sort_constructors_first`, `directives_ordering`
  (renaming the package can reorder imports: run `dart format` and fix ordering),
  `prefer_final_locals`, `unawaited_futures`. `flutter analyze` must be clean.
- Do NOT change the v1 data directory name `dashboard-shakhsi` in
  `lib/features/legacy_import/` or the tests that model the v1 path.
- Do NOT edit historical docs, `APPLY.md`, `tool/apply_phase1_task7_wiring.py`.
- Never call `DateTime.now()` in domain code. No schema change (stays 9).
- Stage explicit paths; never `git add -A`. Do not push. Commit message ends with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Report: files changed, commands run with their real results.

## Task 1 — Dart package, code identifiers, strings, database file move

1. `pubspec.yaml`: `name: borj`. Replace `package:dashboard_shakhsi/` with
   `package:borj/` in `lib/`, `test/`, `integration_test/`, `tool/` (except the
   excluded script). Run `flutter pub get`.
2. Apply the spec's identifier map for: root widget class, app title / brand text /
   notification title and permission body, logger names, Windows AUMID, systemd
   unit base name, regexes, registry file and temp names, unit Description, and the
   Drift database name `borj`. Update test expectations and fixtures to match
   (temp dir prefixes, `/opt/...` fixture paths, unit names, titles) except v1-path
   fixtures.
3. RED first: add tests for a new helper (e.g. `lib/core/database/legacy_database_file_migration.dart`)
   that, given a directory, renames `dashboard_shakhsi.sqlite` and its existing
   `-wal`/`-shm`/`-journal` siblings to `borj.sqlite*` only when `borj.sqlite` does
   not exist. Cases: legacy only → moved with siblings; both exist → nothing
   moved or deleted; neither → no-op; target only → no-op. Use real temp dirs.
   Then implement and wire it into `database_connection.dart` through
   `DriftNativeOptions(databaseDirectory: ...)` resolving
   `getApplicationDocumentsDirectory()` (same directory Drift used by default),
   running the move before returning it.
4. `dart run build_runner build --delete-conflicting-outputs`, `dart format .`,
   `flutter analyze`, full `flutter test`.
5. Check: `git grep -n -i -E "dashboard[-_ ]?shakhsi|DashboardShakhsi|داشبورد شخصی" -- lib test integration_test tool pubspec.yaml`
   shows only v1-path exceptions and the excluded script.
6. Commit: `refactor: rename Dart package and app identifiers to Borj`.

## Task 2 — Platform runners

1. Android: `namespace` and `applicationId` `app.borj` in
   `android/app/build.gradle.kts`; `git mv` `MainActivity.java` to
   `android/app/src/main/java/app/borj/` and fix its `package`; manifest label `برج`.
   Leave `GeneratedPluginRegistrant.java` to the tool.
2. Linux: `linux/CMakeLists.txt` `BINARY_NAME "borj"`, `APPLICATION_ID "app.borj"`;
   `linux/runner/my_application.cc` header bar and window title `"برج"`.
3. Windows: `windows/CMakeLists.txt` project and `BINARY_NAME`; `windows/runner/Runner.rc`
   fields per spec; `windows/runner/main.cpp` title `L"برج"`.
4. macOS: `macos/Runner/Configs/AppInfo.xcconfig` `PRODUCT_NAME = borj`,
   `PRODUCT_BUNDLE_IDENTIFIER = app.borj`; pbxproj and `Runner.xcscheme` refs
   `borj.app` / `borj`; pbxproj bundle IDs `app.borj` (keep any `.RunnerTests` suffix).
5. Check `git grep` over `android linux windows macos` shows no old name.
   Run `flutter build linux --release` and confirm `build/linux/x64/release/bundle/borj`
   exists; `flutter analyze`. Android build only if the SDK is available (report either way).
6. Commit: `build: rename platform runners and app IDs to Borj`.

## Task 3 — Docs and environment (main session)

Living docs (`CLAUDE.md`, roadmap title/status), worklog entry, GitHub rename,
remotes, folder move, worktree repair, memory copy, per spec "Environment steps".
