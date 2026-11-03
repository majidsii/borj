# Release Data Foundation — Checkpoint

**Date:** 2026-11-04
**Status:** implemented (item 3, part A of the program order)
**Spec:** `docs/superpowers/specs/2026-11-04-release-data-foundation-design.md`
**Plan:** `docs/superpowers/plans/2026-11-04-release-data-foundation.md`

## What shipped
- Checked `Money` arithmetic (`MoneyOverflowFailure`), overflow-free `percentOf`, checked repository sums, installment total guard, 15-digit input cap.
- Schema 9: IRT is whole toman (`Money.financeScale == 0`); one migration step rescales scale-8 rows (half-even, positive amounts clamped to at least 1, debt totals raised to the payment sum when rounding exceeded them); `legacy_imports` ledger keyed by `(entity_type, v1_id)`.
- v1 import: parser for `data.json` (string-encoded or structured) and both v1 export files; desktop auto-detect (Linux honors `XDG_DATA_HOME`); preview, one-transaction import, report; Settings entry (`/settings`), first-launch banner, `file_picker ^13.3.2`.

## Commits on `feat/v2-complete-dashboard`
- `cab3907` checked Money arithmetic (`MoneyOverflowFailure`)
- `37a4482` parse v1 `data.json` and exports into a legacy snapshot
- `fdfdd5d` schema 9: whole-toman money and `legacy_imports` ledger
- `d0db623` overflow-safe finance reports, legend percent and amount input
- `1758c5d` transactional idempotent v1 import service
- `42b2226` import v1 data from Settings with preview, report and banner

Planning commits before them: `1027c80` (plan), `c9af84f` (amendments adopted into the spec).

## Evidence
- CI on the pushed head (`42b2226`): https://github.com/majidsii/dashboard-shakhsi/actions/runs/41723578666, success, 1371 tests passed.
- Migration and restart tests: `test/core/database/finance_scale_migration_test.dart` (schema 8 to 9, restart, uniqueness of `legacy_imports`), plus every older migration test bumped to schema 9.
- Importer tests: `test/features/legacy_import/` (parser fixtures, preview, idempotency, existing-v2-data numbering, rollback on failure, skipped rows).
- Not yet verified: the Android and macOS builds with `file_picker` 13.3.2; a manual import run on Linux with the real UI.

## Decisions that differ from the spec
1. **Rounding rule (spec 1: "round half-even").** Kept, but the migration also (a) clamps a positive amount that rounds to 0 up to 1, because `validateExactPositiveMoney` rejects 0, and (b) raises a debt's `total_minor_units` to the sum of its rounded payments when rounding made the payments exceed the total, because `Debt()` throws on `paid > total` and the finance panel would crash. The spec's claim that fractions are "impossible from the UI" is false: the current UI accepts 8 decimals.
2. **"Synthetic payments marked `imported` in their note"** is not implementable: `debt_payments` and `installment_payments` have no note column. Decision: no schema column. The parent debt/installment row is recorded in `legacy_imports`; payments cascade with the parent and are identified through it.
3. **First-launch banner "one-time".** No settings store exists. Decision: the banner shows only while `legacy_imports` is empty and a v1 file was auto-detected, and "later" dismisses it for the current session only. No persisted dismissal flag.
4. **Export files have no ids.** Ids are derived as `v1:<entity>:<sha1 of canonical JSON>` from the normalized record, so importing an export and then `data.json` (or the reverse) duplicates rows, and identical records inside one export collapse. Export debts and installments carry no `created`; the fallback is the export's `exportedAt`, then import time.
5. **v1 `abc` sort** uses JS `localeCompare("fa")`, which Dart cannot reproduce exactly. Fallback: plain Dart `String.compareTo` on the trimmed title.
6. **Unknown v1 transaction type** (anything but `in`/`ex`): v1 counts it as an expense in totals, so it is imported as an expense with a warning.
7. **Re-import never updates existing rows.** A v1 debt that gained payments after the first import is skipped as "already imported".
8. **Logging for migration rounding** uses `dart:developer` `log` (no logging facility exists and `avoid_print` is on).
9. **Android** auto-detect is not attempted (spec: manual import only).
10. **macOS** sandbox: the `file_picker` read needs `com.apple.security.files.user-selected.read-only`, added in Task 6. Auto-detect cannot see `~/Library/Application Support/dashboard-shakhsi` from inside the sandbox, so macOS users import manually.
11. The `legacy_imports` table is created together with the money rescale in one schema step (not as a parallel table task), because Drift table registration, companions and the committed `app_database.g.dart` all live behind the single schema owner.

## Known limitations
- Importing an export file and `data.json` of the same data duplicates rows (exports have no ids).
- Re-import never updates existing rows.
- The out-of-range notice replaces the whole finance panel while a sum overflows (needs more than 9.2e18 toman).
- The Linux file dialog needs `zenity` or `kdialog`; auto-detect works without it.
- Android has no auto-detect; macOS sandbox hides v1's folder, so both import manually.
- Banner dismissal is per session.
- The import has not yet been run by hand on Linux; the owner has not imported real v1 data.

## Not done (out of scope per spec)
Packaging, signing and release automation (part B: includes Android signing continuity and an Android CI build, since the Android build with `file_picker` 13.3.2 is unverified); product name (part C, owner's decision); habits and goals; Tasks 2.9+.
