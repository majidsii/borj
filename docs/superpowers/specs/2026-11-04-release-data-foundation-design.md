# Release Data Foundation — Design (money scale + v1 import)

**Date:** 2026-11-04
**Status:** DECIDED BY CLAUDE under the owner's standing instruction (2026-11-04: "if a question comes up, find the best practice and execute it"). Owner may override any decision below; each is marked.
**Program order:** item 3 of `PROJECT_ROADMAP.md` §0, part A of three:

- **A. Data foundation:** this spec.
- **B. Packaging and release automation:** separate spec. This includes Android signing continuity with v1.
- **C. Product name:** the owner's decision. Keep the app ID `ir.dashboard.shakhsi` and the data directory names stable whatever the display name becomes.

**Inputs:** `references/2026-11-04-v1-data-format-and-v2-mapping.md`, `references/2026-11-04-money-scale-overflow-analysis.md`.

## 1. Money scale

Decision: IRT money uses **scale 0** (whole toman). Existing rows migrate deterministically in **schema 8 → 9**.

- `Money.financeScale` becomes `0`. Toman has no practical subunit, and v1 never stored fractions.
- Migration: every persisted money column whose rows have scale 8 is divided by 10^8 with exact integer division.
  - A row with a non-zero remainder is impossible from the UI. If one exists, the migration rounds half-even and logs the row id.
  - Migration and restart tests are required, per the roadmap's database rules.
- Real overflow checks: `Money` `+ - *` use checked arithmetic and throw `MoneyOverflowFailure`. Today's `_checkedMinorUnits` is dead code on native, because int64 wraps before the check runs.
  - Reports and aggregations catch the failure and show "out of range" instead of a wrong number.
- The chart legend percent, which breaks above about 922 million toman today, is computed without overflow. Divide first, or use `double` only for the ratio. Money values never become `double`.

## 2. v1 import

### 2.1 Sources
- **Desktop:** auto-detect v1's `data.json` at its platform path (Linux `~/.local/share/dashboard-shakhsi/data.json`, Windows `%APPDATA%\dashboard-shakhsi\data.json`, macOS `~/Library/Application Support/dashboard-shakhsi/data.json`).
- **Manual file:** re-add `file_picker: ^13.3.2`, which supports Flutter 3.47 and Android with built-in Kotlin. Accept v1 `data.json` and v1's JSON export. The plan must confirm the export's shape from `origin/main:src/app.html`, and both shapes must parse.
- **Android:** v2 may not be able to read v1's private files: they're only readable if signing matches (part B). So Android import is manual: export JSON from v1, then pick it in v2.

### 2.2 Entry point
**Decision (owner open question 4):** an explicit "Import from v1" action in Settings. On first launch, if a v1 file is auto-detected and nothing has been imported yet, a one-time banner offers the import.

Flow: parse → **preview** (counts per entity, rows that will be skipped and why) → confirm → import in **one transaction** → report.

### 2.3 Idempotency
**Decision (open question 5):** a persistent `legacy_imports` table in schema 9, which is being bumped anyway. It stores `(source_kind, v1_id, entity_type, v2_id, imported_at_utc, source_sha256)`.

- Re-running the import skips rows whose `v1_id` is already present.
- New v1 records added later are imported.
- The preview says "N already imported".

### 2.4 Mapping decisions
- **Task order (open question 2):** keep v1's visible order. `position_in_status` follows v1's display order per status. `display_number` is assigned by `created` ascending (oldest = 1), continuing after any existing v2 numbers. The display number is identity, not order.
- **Completion time (open question 3):** v1 `done` tasks get `completed_at_utc = created`. Statistics stay honest; the alternative, the import time, would inflate "completed today".
- **Overflow (open question 1):** with scale 0, int64 holds about 9.2×10^18 toman, so overflow isn't reachable from realistic data. Any row that still fails validation is skipped and reported. The rest of the import proceeds; the import is never aborted for one bad row.
- Debts and installments only keep payment counters in v1. They become synthetic payment rows, dated at the record's `created` time and marked `imported` in their note.
- Priority, the legacy `important` flag, and categories follow the mapping table in the v1 reference doc.
- Rows with a missing or duplicate v1 id: duplicates keep the first occurrence. Rows with no id get a deterministic id `v1:<entity>:<sha1 of canonical JSON>`.

## 3. Architecture

- `lib/features/legacy_import/`:
  - `domain/`: v1 models and an import report;
  - `data/`: the v1 JSON parser for both shapes, and the `legacy_imports` Drift table plus repository;
  - `application/`: the importer service, which plans, previews and executes in one transaction through the existing repositories' transactional APIs, plus direct row writes where the repositories append (`DriftTaskRepository.create` ignores supplied positions, so the import writes rows directly inside the transaction and keeps positions contiguous);
  - `presentation/`: the Settings entry, the preview and report dialog, and the first-launch banner.
- Money migration lives in `app_database.dart` (`schemaVersion 9`, append-only `onUpgrade` step).

## 4. Testing

- Money: checked-arithmetic overflow tests; migration 8 → 9 with mixed rows; restart test; report "out of range" test.
- Parser: golden v1 fixtures (v1.0, v1.2, an Android-compact file, an export file, corrupt, empty, and double-encoded values). Fixtures are synthetic; the owner's real data is never committed.
- Importer:
  - preview counts;
  - one transaction, so a failure leaves zero rows written;
  - idempotent re-run;
  - an import into a DB that already has v2 tasks: display numbers continue and positions stay contiguous;
  - done tasks get `completed_at = created`;
  - synthetic payments.
- UI widget tests for the preview and report dialog.

## 5. Out of scope

Packaging, signing and release automation (B); the product name (C); habits and goals; Tasks 2.9+.
