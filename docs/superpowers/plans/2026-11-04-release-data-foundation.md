# Release Data Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make IRT money overflow-safe whole-toman (scale 0, schema 8 to 9) and let v2 import v1 data (`data.json` and v1's two JSON exports) through a previewed, idempotent, single-transaction importer reachable from Settings and a first-launch banner.

**Architecture:** `Money` gets real checked arithmetic. One append-only schema step 8 to 9 rescales every scale-8 finance row to scale 0 and adds a `legacy_imports` ledger table. A pure-Dart v1 parser produces a `LegacySnapshot`. A `LegacyImportService` plans (preview) and executes (one Drift transaction) against the same `AppDatabase`, writing task rows directly and finance rows through `DriftFinanceRepository`. A small UI layer (Settings route, preview/report dialogs, dashboard banner, `file_picker`) drives it.

**Tech Stack:** Flutter 3.47.5, Dart, Drift 2.34 (`schemaVersion` 9), Riverpod 2.6 (plain `Provider`s), `cryptography` (hashing), `file_picker ^13.3.2`, go_router.

**Spec:** `docs/superpowers/specs/2026-11-04-release-data-foundation-design.md`
**References:** `docs/superpowers/references/2026-11-04-v1-data-format-and-v2-mapping.md`, `docs/superpowers/references/2026-11-04-money-scale-overflow-analysis.md`

## Global Constraints

- SDK: put `/home/shabin/develop/flutter-3.47.5/bin` first on PATH in EVERY shell command: `export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH`. The default `flutter` on PATH is the shared 3.44 SDK and must not be used or upgraded. `.flutter-version` is `3.47.5`.
- Pub mirror: `PUB_HOSTED_URL=https://pub.flutter-io.cn` is already set in the owner's shell. `pubspec.lock` is committed and CI runs `flutter pub get --enforce-lockfile`.
- Lints that bite: `require_trailing_commas`, `sort_constructors_first`, `directives_ordering` (alphabetical imports; `dart:` first, then `package:`), `prefer_final_locals`, `unawaited_futures`, `avoid_print`, `avoid_dynamic_calls`, `dead_code` is an error. Run `flutter analyze` before claiming a task done.
- Money is integer minor units plus scale. Never `double` for money. IRT is `Money.tomanCurrencyCode` (`'IRT'`) and, after Task 3, `Money.financeScale == 0`.
- Persisted timestamps are UTC. Domain/application code never calls `DateTime.now()`; use the injected `AppClock` (`lib/core/date_time/app_clock.dart`).
- Migrations are append-only. Schema 8 to 9 is ONE step (`if (from < 9)`). Exactly one task (Task 3) edits `lib/core/database/app_database.dart`, `schemaVersion`, and regenerates `lib/core/database/app_database.g.dart` (the `.g.dart` is committed and CI fails if it is stale).
- Every schema change needs migration and restart tests.
- Test fixtures are synthetic JSON under `test/fixtures/legacy_v1/`. Never read, copy, or commit the owner's real v1 data. The importer opens source files read-only and never modifies or deletes them.
- Never use `DriftTaskRepository.create` for import: it ignores supplied `displayNumber` and `positionInStatus`. Import writes task rows directly.
- Task invariants must hold after import: status parsed exactly; `displayNumber` immutable, never reused, UNIQUE; `positionInStatus` contiguous `0..n-1` per status.
- Files written to the repo (code comments, docs, commit messages) are in English. UI strings stay Persian like the rest of the app.
- Git: stage explicit paths only (never `git add -A`). Never force-push. Pushing `feat/v2-complete-dashboard` is pre-approved. Never bare `git stash`.
- Do not add new `tool/verify_*` scripts. Tests, analyzer and CI are the evidence.
- Commit message trailer on every commit: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Do not add `crypto` as a dependency; use `cryptography` (already a dependency; see `lib/core/notifications/linux_notification_request_fingerprint.dart`).
- v1's `data.json` shape: a flat object whose VALUES ARE STRINGS containing JSON (double-encoded) under four keys `tasklist:v1`, `tasklist:prefs:v1`, `finance:v1`, `app:prefs:v1`. v1 has two separate export files (no ids): tasks export `{exportedAt, stats, tasks:[{text, done, priority:"none|low|medium|high", createdAt}]}` and finance export `{exportedAt, summary, transactions:[{type:"income|expense", title, category, amount, at}], debts:[{name, total, paid}], installments:[{name, perInstallment, count, paidCount}]}`.

## Spec decisions this plan resolves or amends (review before executing)

1. **Rounding rule (spec 1: "round half-even").** Kept, but the migration also (a) clamps a positive amount that rounds to 0 up to 1, because `validateExactPositiveMoney` rejects 0, and (b) raises a debt's `total_minor_units` to the sum of its rounded payments when rounding made the payments exceed the total, because `Debt()` throws on `paid > total` and the finance panel would crash. The spec's claim that fractions are "impossible from the UI" is false: the current UI accepts 8 decimals.
2. **"Synthetic payments marked `imported` in their note"** is not implementable: `debt_payments` and `installment_payments` have no note column. Decision: no schema column. The parent debt/installment row is recorded in `legacy_imports`; payments cascade with the parent and are identified through it.
3. **First-launch banner "one-time".** No settings store exists. Decision: the banner shows only while `legacy_imports` is empty and a v1 file was auto-detected, and "later" dismisses it for the current session only. No persisted dismissal flag.
4. **Export files have no ids.** Ids are derived as `v1:<entity>:<sha1 of canonical JSON>` from the normalized record, so importing an export and then `data.json` (or the reverse) duplicates rows, and identical records inside one export collapse. Export debts and installments carry no `created`; the fallback is the export's `exportedAt`, then import time.
5. **v1 `abc` sort** uses JS `localeCompare("fa")`, which Dart cannot reproduce exactly. Fallback: plain Dart `String.compareTo` on the trimmed title.
6. **Unknown v1 transaction type** (anything but `in`/`ex`): v1 counts it as an expense in totals, so it is imported as an expense with a warning.
7. **Re-import never updates existing rows.** A v1 debt that gained payments after the first import is skipped as "already imported".
8. **Logging "the row id" for migration rounding** uses `dart:developer` `log` (no logging facility exists and `avoid_print` is on).
9. **Android** auto-detect is not attempted (spec: manual import only).
10. **macOS** sandbox: the `file_picker` read needs `com.apple.security.files.user-selected.read-only`, added in Task 6. Auto-detect cannot see `~/Library/Application Support/dashboard-shakhsi` from inside the sandbox, so macOS users import manually.
11. The `legacy_imports` table is created in Task 3 together with the money rescale (not as a separate parallel table task) because Drift table registration, companions and the committed `app_database.g.dart` all live behind the single schema owner.

## Worktrees and parallel groups

Each parallel task runs in its own worktree created from the current tip of `feat/v2-complete-dashboard`:

```bash
export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH
cd /home/shabin/projects/personal/dashboard-shakhsi-v2-integration
git worktree add ../dashboard-shakhsi-rdf-t1 -b rdf/t1-money-checked feat/v2-complete-dashboard
git worktree add ../dashboard-shakhsi-rdf-t2 -b rdf/t2-v1-parser feat/v2-complete-dashboard
git worktree add ../dashboard-shakhsi-rdf-t3 -b rdf/t3-schema-9 feat/v2-complete-dashboard
```

Run `flutter pub get` in each new worktree. Integrate by merging each finished branch into `feat/v2-complete-dashboard` from the main worktree with `git merge --no-ff rdf/tN-...`, then re-run the touched tests on the merged head before starting the next group.

| Group | Tasks | Run in parallel | Gate before next group |
|---|---|---|---|
| G1 | T1 money checked arithmetic, T2 v1 parser/fixtures/locator, T3 schema 9 (scale 0 + `legacy_imports`) | yes, 3 worktrees | merge all three; `flutter analyze` and `flutter test test/core test/features/legacy_import test/features/finance` pass on the merged head |
| G2 | T4 overflow-safe consumers (needs T1, T3), T5 importer service (needs T2, T3) | yes, 2 worktrees | merge both; same checks |
| G3 | T6 UI (needs T5; may start as soon as T5 is merged, and may run in parallel with T4 if T4 is not yet merged because the files are disjoint) | n/a | merge |
| G4 | T7 CI, checkpoint, roadmap, worklog, push | no | pushed |

Known benign merge overlap: T1 and T3 both touch `lib/core/money/money.dart` in different hunks (T1: arithmetic and `percentOf`; T3: the `financeScale` constant line only). T3 and T4 both touch `lib/core/money/money_input_formatter.dart` but T4 runs after T3. Only T3 touches `app_database.dart` and `app_database.g.dart`.

## File structure

New:
- `lib/features/legacy_import/domain/legacy_snapshot.dart` (v1 models, skip/warning types)
- `lib/features/legacy_import/domain/legacy_import_report.dart` (preview and report)
- `lib/features/legacy_import/data/legacy_v1_parser.dart` (both shapes)
- `lib/features/legacy_import/data/legacy_v1_source_locator.dart` (desktop auto-detect)
- `lib/features/legacy_import/data/drift_legacy_import_ledger.dart` (ledger interface and Drift implementation)
- `lib/features/legacy_import/data/file_picker_legacy_file_picker.dart` (only file importing `file_picker`)
- `lib/features/legacy_import/application/legacy_file_picker.dart` (picker interface)
- `lib/features/legacy_import/application/legacy_import_service.dart` (plan, preview, execute)
- `lib/features/legacy_import/presentation/legacy_import_labels.dart`, `legacy_import_providers.dart`, `legacy_import_dialogs.dart`, `legacy_import_flow.dart`, `legacy_import_section.dart`, `legacy_import_banner.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `test/fixtures/legacy_v1/*.json` (synthetic)
- Tests named in each task.

Modified: `lib/core/money/money.dart`, `lib/core/errors/app_failure.dart`, `lib/core/database/app_database.dart` (+ `.g.dart`), `lib/core/money/money_input_formatter.dart`, `lib/features/finance/domain/finance_transaction.dart`, `lib/features/finance/domain/installment_plan.dart`, `lib/features/finance/data/drift_finance_repository.dart`, `lib/features/dashboard/presentation/widgets/finance_charts.dart`, `lib/features/dashboard/presentation/widgets/finance_panel.dart`, `lib/core/providers/persistence_providers.dart`, `lib/app/router/app_router.dart`, `lib/features/dashboard/presentation/dashboard_screen.dart`, `pubspec.yaml`, `pubspec.lock`, `macos/Runner/*.entitlements`, and many existing tests (listed in Task 3).

---

### Task 1: Checked `Money` arithmetic

**Depends on:** none (G1)

**Why:** `Money._checkedMinorUnits` is dead code on native Dart: int64 wraps before the check runs (`5000000000000000000 * 2 == -8446744073709551616`). Fix it so `+ - * unary-` and `absolute` throw `MoneyOverflowFailure`, and add an overflow-free percentage.

**Files:**
- Modify: `lib/core/errors/app_failure.dart` (`AppFailure` is `sealed`, so the subclass must live in this file)
- Modify: `lib/core/money/money.dart`
- Create: `test/core/money/money_overflow_test.dart`

**Interfaces:**
- Produces (used by Tasks 4 and others):
  - `final class MoneyOverflowFailure extends AppFailure { const MoneyOverflowFailure(); }` in `lib/core/errors/app_failure.dart`.
  - `Money.checkedAdd(int left, int right) -> int`, `Money.checkedSubtract(int, int) -> int`, `Money.checkedMultiply(int, int) -> int`, `Money.checkedNegate(int) -> int`; all `static`, all throw `MoneyOverflowFailure`.
  - `int Money.percentOf(Money total)`: `this` as a rounded-half-up integer percent of `total`; `total` must be positive and compatible, else `ArgumentError`.
  - `Money +`, `-`, `*`, unary `-`, `absolute` throw `MoneyOverflowFailure` instead of wrapping.

- [ ] **Step 1: Write the failing tests**

Create `test/core/money/money_overflow_test.dart`:

```dart
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Money toman(int minorUnits, {int scale = 0}) =>
      Money(minorUnits: minorUnits, currencyCode: 'IRT', scale: scale);

  final overflow = throwsA(isA<MoneyOverflowFailure>());

  group('checked arithmetic', () {
    test('addition throws at both int64 edges and allows exact edges', () {
      expect(() => toman(Money.maxInt64) + toman(1), overflow);
      expect(() => toman(Money.minInt64) + toman(-1), overflow);
      expect(toman(Money.maxInt64) + toman(0), toman(Money.maxInt64));
      expect(toman(Money.maxInt64) + toman(Money.minInt64), toman(-1));
    });

    test('subtraction throws at both int64 edges', () {
      expect(() => toman(Money.minInt64) - toman(1), overflow);
      expect(() => toman(Money.maxInt64) - toman(-1), overflow);
      expect(() => toman(0) - toman(Money.minInt64), overflow);
      expect(toman(5) - toman(7), toman(-2));
    });

    test('multiplication throws instead of wrapping', () {
      expect(() => toman(5000000000000000000) * 2, overflow);
      expect(() => toman(Money.minInt64) * -1, overflow);
      expect(() => toman(3037000500) * 3037000500, overflow);
      expect(toman(3037000499) * 3037000499, toman(9223372030926249001));
      expect(toman(Money.minInt64) * 1, toman(Money.minInt64));
    });

    test('negation and absolute value reject minInt64', () {
      expect(() => -toman(Money.minInt64), overflow);
      expect(() => toman(Money.minInt64).absolute, overflow);
      expect(-toman(5), toman(-5));
      expect(toman(-5).absolute, toman(5));
    });

    test('overflow is an AppFailure with a user message', () {
      try {
        toman(Money.maxInt64) + toman(1);
        fail('expected MoneyOverflowFailure');
      } on AppFailure catch (failure) {
        expect(failure, isA<MoneyOverflowFailure>());
        expect(failure.userMessage, isNotEmpty);
      }
    });

    test('static helpers expose the same checks', () {
      expect(() => Money.checkedAdd(Money.maxInt64, 1), overflow);
      expect(() => Money.checkedSubtract(Money.minInt64, 1), overflow);
      expect(() => Money.checkedMultiply(Money.maxInt64, 2), overflow);
      expect(() => Money.checkedNegate(Money.minInt64), overflow);
      expect(Money.checkedAdd(2, 3), 5);
    });
  });

  group('percentOf', () {
    test('rounds half up without overflowing value * 100', () {
      expect(toman(Money.maxInt64).percentOf(toman(Money.maxInt64)), 100);
      expect(toman(1).percentOf(toman(3)), 33);
      expect(toman(2).percentOf(toman(3)), 67);
      // 1e9 toman at the legacy scale 8 is 1e17 minor units; 1e17 * 100
      // overflows int64, which broke the donut legend.
      final half = toman(100000000000000000, scale: 8);
      final whole = toman(200000000000000000, scale: 8);
      expect(half.percentOf(whole), 50);
    });

    test('rejects an incompatible or non-positive total', () {
      expect(() => toman(1).percentOf(toman(0)), throwsArgumentError);
      expect(
        () => toman(1).percentOf(toman(5, scale: 2)),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH
cd /home/shabin/projects/personal/dashboard-shakhsi-rdf-t1   # your T1 worktree
flutter pub get
flutter test test/core/money/money_overflow_test.dart
```

Expected: compile error ("MoneyOverflowFailure" / "percentOf" / "checkedAdd" not defined).

- [ ] **Step 3: Add `MoneyOverflowFailure`**

In `lib/core/errors/app_failure.dart`, append after `BackupFailure`:

```dart
final class MoneyOverflowFailure extends AppFailure {
  const MoneyOverflowFailure() : super('مبلغ از محدوده قابل نمایش بیشتر است.');
}
```

- [ ] **Step 4: Replace the unchecked arithmetic in `lib/core/money/money.dart`**

Add the import at the top of the file (it currently has no imports):

```dart
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
```

Replace the `absolute` getter:

```dart
  Money get absolute =>
      minorUnits < 0 ? copyWith(minorUnits: checkedNegate(minorUnits)) : this;
```

Replace the four operators (`+`, `-`, unary `-`, `*`) with:

```dart
  Money operator +(Money other) {
    _requireCompatible(other);
    return copyWith(minorUnits: checkedAdd(minorUnits, other.minorUnits));
  }

  Money operator -(Money other) {
    _requireCompatible(other);
    return copyWith(minorUnits: checkedSubtract(minorUnits, other.minorUnits));
  }

  Money operator -() => copyWith(minorUnits: checkedNegate(minorUnits));

  Money operator *(int multiplier) =>
      copyWith(minorUnits: checkedMultiply(minorUnits, multiplier));

  /// This value as a rounded-half-up integer percentage of [total].
  ///
  /// Uses [BigInt] so `minorUnits * 100` can never wrap.
  int percentOf(Money total) {
    _requireCompatible(total);
    if (!total.isPositive) {
      throw ArgumentError('The total must be positive.');
    }
    final numerator =
        BigInt.from(minorUnits) * BigInt.from(100) +
        BigInt.from(total.minorUnits) ~/ BigInt.two;
    return (numerator ~/ BigInt.from(total.minorUnits)).toInt();
  }
```

Delete the old private `_checkedMinorUnits` and add these public statics in its place:

```dart
  static final BigInt _minInt64Big = BigInt.from(minInt64);
  static final BigInt _maxInt64Big = BigInt.from(maxInt64);

  static int checkedAdd(int left, int right) {
    final result = left + right;
    if ((left >= 0) == (right >= 0) && (result >= 0) != (left >= 0)) {
      throw const MoneyOverflowFailure();
    }
    return result;
  }

  static int checkedSubtract(int left, int right) {
    final result = left - right;
    if ((left >= 0) != (right >= 0) && (result >= 0) != (left >= 0)) {
      throw const MoneyOverflowFailure();
    }
    return result;
  }

  static int checkedMultiply(int left, int right) {
    final product = BigInt.from(left) * BigInt.from(right);
    if (product < _minInt64Big || product > _maxInt64Big) {
      throw const MoneyOverflowFailure();
    }
    return product.toInt();
  }

  static int checkedNegate(int value) {
    if (value == minInt64) throw const MoneyOverflowFailure();
    return -value;
  }
```

(These snippets were verified with `dart run` against the int64 edge cases before this plan was written: `maxInt64 + 1`, `minInt64 - 1`, `0 - minInt64`, `5e18 * 2`, `minInt64 * -1` and `-minInt64` all throw; `maxInt64 + minInt64` and `minInt64 * 1` do not.) Native Dart ints only; the app does not target web.

- [ ] **Step 5: Run the tests to verify they pass**

```bash
flutter test test/core/money
flutter analyze lib/core/money lib/core/errors test/core/money
dart format lib/core test/core
```

Expected: all PASS, analyzer clean (existing `money_test.dart` cases still pass; none relied on wrapping).

- [ ] **Step 6: Commit**

```bash
git add lib/core/errors/app_failure.dart lib/core/money/money.dart test/core/money/money_overflow_test.dart
git commit -m "feat: checked Money arithmetic with MoneyOverflowFailure" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 2: v1 snapshot models, parser, source locator, fixtures

**Depends on:** none (G1). Pure Dart, no database.

**Files:**
- Create: `lib/features/legacy_import/domain/legacy_snapshot.dart`
- Create: `lib/features/legacy_import/data/legacy_v1_parser.dart`
- Create: `lib/features/legacy_import/data/legacy_v1_source_locator.dart`
- Create: `test/fixtures/legacy_v1/` files (listed in Step 1)
- Test: `test/features/legacy_import/data/legacy_v1_parser_test.dart`
- Test: `test/features/legacy_import/data/legacy_v1_source_locator_test.dart`

**Interfaces:**
- Produces (used by Tasks 5 and 6):
  - `enum LegacyEntityType { task, transaction, debt, installment }` with `String get storageValue` (= `name`).
  - `enum LegacySourceKind { dataJson, export }` with `String get storageValue` (`'data_json'` / `'export'`).
  - `enum LegacyTaskSort { newest, priority, alphabetical }`.
  - `enum LegacySkipReason { notAnObject, emptyTitle, duplicateId, invalidAmount, invalidCount, totalOverflow, failedValidation }`.
  - `enum LegacyWarningCode { tasksUnreadable, financeUnreadable, unknownTransactionType, paidClamped, paidCountClamped }`.
  - `LegacySkippedRow({required LegacyEntityType entityType, required String? v1Id, required LegacySkipReason reason})`.
  - `LegacyWarning({required LegacyWarningCode code, LegacyEntityType? entityType, String? v1Id})`.
  - `LegacyTask({required String v1Id, required String title, required bool done, required int priority, DateTime? createdAtUtc})`.
  - `LegacyTransaction({required String v1Id, required String title, required String category, required bool isIncome, required int amountToman, DateTime? occurredAtUtc})`.
  - `LegacyDebt({required String v1Id, required String title, required int totalToman, required int paidToman, DateTime? createdAtUtc})`.
  - `LegacyInstallment({required String v1Id, required String title, required int perToman, required int count, required int paidCount, DateTime? createdAtUtc})`.
  - `LegacySnapshot({required LegacySourceKind sourceKind, required String sourceSha256, required LegacyTaskSort taskSort, DateTime? exportedAtUtc, required List<LegacyTask> tasks, required List<LegacyTransaction> transactions, required List<LegacyDebt> debts, required List<LegacyInstallment> installments, required List<LegacySkippedRow> skipped, required List<LegacyWarning> warnings})` with `bool get isEmpty`.
  - `LegacyV1Parser`: `const LegacyV1Parser()`; `Future<LegacySnapshot> parseBytes(Uint8List bytes)`. Throws `ImportFailure` for non-UTF-8/non-JSON input, a non-object root, or an unrecognized object shape. `{}` is a valid empty snapshot.
  - `LegacyV1SourceLocator({String? operatingSystem, Map<String, String>? environment})` (both default to `dart:io` `Platform`); `String? candidatePath()`; `Future<File?> detect()`.

- [ ] **Step 1: Create the synthetic fixtures**

Create each file below under `test/fixtures/legacy_v1/` with exactly this content.

`test/fixtures/legacy_v1/data_v1_2_desktop.json`:

```json
{
 "app:prefs:v1": "{\"theme\":\"dark\",\"tab\":\"fin\"}",
 "tasklist:prefs:v1": "{\"sort\":\"new\"}",
 "tasklist:v1": "[{\"id\":\"1730640000123-aaaaa\",\"text\":\"خرید نان\",\"done\":false,\"priority\":3,\"created\":1730640000123},{\"id\":\"1730500000000-bbbbb\",\"text\":\"قبض برق\",\"done\":true,\"priority\":0,\"created\":1730500000000},{\"id\":\"1730400000000-ccccc\",\"text\":\"تماس با بانک\",\"done\":false,\"priority\":1,\"created\":1730400000000},{\"id\":\"1730300000000-ddddd\",\"text\":\"ورزش\",\"done\":true,\"priority\":2,\"created\":1730300000000}]",
 "finance:v1": "{\"tx\":[{\"id\":\"1730641000000-aaaa1\",\"type\":\"ex\",\"title\":\"پرداخت بدهی: قرض از علی\",\"cat\":\"بدهی\",\"amount\":2000000,\"ts\":1730641000000},{\"id\":\"1730600000000-aaaa2\",\"type\":\"in\",\"title\":\"حقوق آبان\",\"cat\":\"حقوق\",\"amount\":25000000,\"ts\":1730600000000}],\"debts\":[{\"id\":\"1730000000001-bbbb1\",\"name\":\"قرض از علی\",\"total\":10000000,\"paid\":2000000,\"created\":1730000000001}],\"insts\":[{\"id\":\"1730000000002-cccc1\",\"name\":\"قسط خودرو\",\"per\":3500000,\"count\":12,\"paidCount\":4,\"created\":1730000000002}]}"
}
```

`test/fixtures/legacy_v1/data_v1_0_legacy.json`:

```json
{
 "tasklist:v1": "[{\"id\":\"1700000000000-old01\",\"text\":\"کار قدیمی مهم\",\"done\":false,\"important\":true,\"created\":1700000000000},{\"text\":\"بدون شناسه\",\"done\":false,\"priority\":2,\"created\":1700000100000},{\"id\":\"1700000200000-old03\",\"text\":\"   \",\"done\":false,\"priority\":1,\"created\":1700000200000}]",
 "tasklist:prefs:v1": "{\"sort\":\"pri\"}"
}
```

`test/fixtures/legacy_v1/data_android_compact.json`:

```json
{"tasklist:v1":"[{\"id\":\"1730640000123-aaaaa\",\"text\":\"خرید نان\",\"done\":false,\"priority\":3,\"created\":1730640000123},{\"id\":\"1730500000000-bbbbb\",\"text\":\"قبض برق\",\"done\":true,\"priority\":0,\"created\":1730500000000}]","tasklist:prefs:v1":"{\"sort\":\"abc\"}","finance:v1":"{\"tx\":[{\"id\":\"1730600000000-aaaa2\",\"type\":\"in\",\"title\":\"حقوق آبان\",\"cat\":\"حقوق\",\"amount\":25000000,\"ts\":1730600000000}],\"debts\":[],\"insts\":[]}","app:prefs:v1":"{\"theme\":null,\"tab\":\"tasks\"}"}
```

`test/fixtures/legacy_v1/data_structured_values.json`:

```json
{
 "tasklist:v1": [
  {
   "id": "1730640000123-aaaaa",
   "text": "خرید نان",
   "done": false,
   "priority": 3,
   "created": 1730640000123
  }
 ],
 "finance:v1": {
  "tx": [
   {
    "id": "1730600000000-aaaa2",
    "type": "in",
    "title": "حقوق آبان",
    "cat": "حقوق",
    "amount": 25000000,
    "ts": 1730600000000
   }
  ],
  "debts": [],
  "insts": []
 }
}
```

`test/fixtures/legacy_v1/data_edge_cases.json`:

```json
{
 "tasklist:v1": "[{\"id\":\"dup-1\",\"text\":\"اولین\",\"done\":false,\"priority\":1,\"created\":1730000000000},{\"id\":\"dup-1\",\"text\":\"تکراری\",\"done\":false,\"priority\":1,\"created\":1730000001000},\"not-an-object\"]",
 "finance:v1": "{\"tx\":[{\"id\":\"tx-unknown\",\"type\":\"zz\",\"title\":\"نوع ناشناخته\",\"cat\":\"سایر\",\"amount\":5000,\"ts\":1730000000000},{\"id\":\"tx-float\",\"type\":\"ex\",\"title\":\"اعشاری\",\"cat\":\"سایر\",\"amount\":1500.5,\"ts\":1730000000000},{\"id\":\"tx-zero\",\"type\":\"ex\",\"title\":\"صفر\",\"cat\":\"سایر\",\"amount\":0,\"ts\":1730000000000},{\"id\":\"tx-text\",\"type\":\"ex\",\"title\":\"متن\",\"cat\":\"سایر\",\"amount\":\"abc\",\"ts\":1730000000000},{\"id\":\"tx-huge\",\"type\":\"in\",\"title\":\"عدد بزرگ\",\"cat\":\"سایر\",\"amount\":999999999999999,\"ts\":1730000000000},{\"id\":\"tx-blank\",\"type\":\"ex\",\"title\":\"\",\"cat\":\"\",\"amount\":100,\"ts\":1730000000000}],\"debts\":[{\"id\":\"debt-over\",\"name\":\"پرداخت بیشتر از کل\",\"total\":1000,\"paid\":5000,\"created\":1730000000000},{\"id\":\"debt-zero\",\"name\":\"کل صفر\",\"total\":0,\"paid\":0,\"created\":1730000000000}],\"insts\":[{\"id\":\"inst-overflow\",\"name\":\"سرریز\",\"per\":1000000000000000,\"count\":10000,\"paidCount\":0,\"created\":1730000000000},{\"id\":\"inst-paid-over\",\"name\":\"پرداخت بیشتر\",\"per\":1000,\"count\":3,\"paidCount\":9,\"created\":1730000000000},{\"id\":\"inst-count-zero\",\"name\":\"تعداد صفر\",\"per\":1000,\"count\":0,\"paidCount\":0,\"created\":1730000000000},{\"name\":\"بدون شناسه\",\"per\":2000,\"count\":2,\"paidCount\":1,\"created\":1730000000000}]}"
}
```

`test/fixtures/legacy_v1/data_finance_unreadable.json`:

```json
{
 "tasklist:v1": "[{\"id\":\"1730640000123-aaaaa\",\"text\":\"خرید نان\",\"done\":false,\"priority\":3,\"created\":1730640000123}]",
 "finance:v1": "{not json"
}
```

`test/fixtures/legacy_v1/export_tasks.json`:

```json
{
  "exportedAt": "2026-11-01T08:30:00.000Z",
  "stats": {
    "total": 2,
    "active": 1,
    "done": 1
  },
  "tasks": [
    {
      "text": "خرید نان",
      "done": false,
      "priority": "high",
      "createdAt": "2024-11-03T13:20:00.123Z"
    },
    {
      "text": "قبض برق",
      "done": true,
      "priority": "none",
      "createdAt": "2024-11-01T22:26:40.000Z"
    }
  ]
}
```

`test/fixtures/legacy_v1/export_finance.json`:

```json
{
  "exportedAt": "2026-11-01T08:30:00.000Z",
  "summary": {
    "balance": 23000000,
    "monthIncome": 25000000,
    "monthExpense": 2000000,
    "debtRemaining": 30400000
  },
  "transactions": [
    {
      "type": "income",
      "title": "حقوق آبان",
      "category": "حقوق",
      "amount": 25000000,
      "at": "2024-11-02T22:40:00.000Z"
    },
    {
      "type": "expense",
      "title": "پرداخت بدهی: قرض از علی",
      "category": "بدهی",
      "amount": 2000000,
      "at": "2024-11-03T14:36:40.000Z"
    }
  ],
  "debts": [
    {
      "name": "قرض از علی",
      "total": 10000000,
      "paid": 2000000
    }
  ],
  "installments": [
    {
      "name": "قسط خودرو",
      "perInstallment": 3500000,
      "count": 12,
      "paidCount": 4
    }
  ]
}
```

`test/fixtures/legacy_v1/empty_object.json`:

```json
{}
```

`test/fixtures/legacy_v1/not_object.json`:

```json
[1,2,3]
```

`test/fixtures/legacy_v1/unsupported_object.json`:

```json
{"hello":"world"}
```

`test/fixtures/legacy_v1/corrupt_truncated.json`:

```json
{"tasklist:v1": "[{\"id\"
```


(`corrupt_truncated.json` is intentionally cut off mid-string and has no trailing newline. `data_android_compact.json` is one compact line with no trailing newline, like v1's Android writer.)

- [ ] **Step 2: Write the failing parser tests**

Create `test/features/legacy_import/data/legacy_v1_parser_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_parser.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> fixture(String name) =>
    File('test/fixtures/legacy_v1/$name').readAsBytes();

Future<LegacySnapshot> parse(String name) async =>
    const LegacyV1Parser().parseBytes(await fixture(name));

DateTime ms(int value) =>
    DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

void main() {
  group('data.json (double-encoded values)', () {
    test('v1.2 desktop file parses every entity exactly', () async {
      final snapshot = await parse('data_v1_2_desktop.json');

      expect(snapshot.sourceKind, LegacySourceKind.dataJson);
      expect(snapshot.taskSort, LegacyTaskSort.newest);
      expect(snapshot.exportedAtUtc, isNull);
      expect(snapshot.skipped, isEmpty);
      expect(snapshot.warnings, isEmpty);

      expect(snapshot.tasks.map((t) => t.v1Id), <String>[
        '1730640000123-aaaaa',
        '1730500000000-bbbbb',
        '1730400000000-ccccc',
        '1730300000000-ddddd',
      ]);
      final first = snapshot.tasks.first;
      expect(first.title, 'خرید نان');
      expect(first.done, isFalse);
      expect(first.priority, 3);
      expect(first.createdAtUtc, ms(1730640000123));
      expect(snapshot.tasks[1].done, isTrue);

      expect(snapshot.transactions, hasLength(2));
      final expense = snapshot.transactions.first;
      expect(expense.v1Id, '1730641000000-aaaa1');
      expect(expense.isIncome, isFalse);
      expect(expense.category, 'بدهی');
      expect(expense.amountToman, 2000000);
      expect(expense.occurredAtUtc, ms(1730641000000));
      expect(snapshot.transactions.last.isIncome, isTrue);
      expect(snapshot.transactions.last.amountToman, 25000000);

      final debt = snapshot.debts.single;
      expect(debt.title, 'قرض از علی');
      expect(debt.totalToman, 10000000);
      expect(debt.paidToman, 2000000);
      expect(debt.createdAtUtc, ms(1730000000001));

      final installment = snapshot.installments.single;
      expect(installment.perToman, 3500000);
      expect(installment.count, 12);
      expect(installment.paidCount, 4);
    });

    test('v1.0 legacy file: important flag, missing id, blank title', () async {
      final snapshot = await parse('data_v1_0_legacy.json');

      expect(snapshot.taskSort, LegacyTaskSort.priority);
      expect(snapshot.tasks, hasLength(2));
      expect(snapshot.tasks.first.v1Id, '1700000000000-old01');
      expect(snapshot.tasks.first.priority, 3);
      expect(snapshot.tasks.last.v1Id, startsWith('v1:task:'));
      expect(snapshot.tasks.last.priority, 2);
      expect(snapshot.skipped, hasLength(1));
      expect(snapshot.skipped.single.reason, LegacySkipReason.emptyTitle);
      expect(snapshot.skipped.single.entityType, LegacyEntityType.task);
      expect(snapshot.transactions, isEmpty);
    });

    test('derived ids are deterministic across parses', () async {
      final first = await parse('data_v1_0_legacy.json');
      final second = await parse('data_v1_0_legacy.json');

      expect(first.tasks.last.v1Id, second.tasks.last.v1Id);
      expect(first.tasks.last.v1Id, matches(RegExp(r'^v1:task:[0-9a-f]{40}$')));
    });

    test('android compact single-line file parses', () async {
      final snapshot = await parse('data_android_compact.json');

      expect(snapshot.taskSort, LegacyTaskSort.alphabetical);
      expect(snapshot.tasks, hasLength(2));
      expect(snapshot.transactions.single.amountToman, 25000000);
      expect(snapshot.debts, isEmpty);
    });

    test('already-structured values parse like string-encoded ones', () async {
      final snapshot = await parse('data_structured_values.json');

      expect(snapshot.tasks.single.title, 'خرید نان');
      expect(snapshot.transactions.single.isIncome, isTrue);
    });

    test('edge cases skip bad rows and never abort', () async {
      final snapshot = await parse('data_edge_cases.json');

      expect(snapshot.tasks.map((t) => t.v1Id), <String>['dup-1']);
      expect(
        snapshot.transactions.map((t) => t.v1Id),
        <String>['tx-unknown', 'tx-huge', 'tx-blank'],
      );
      final unknown = snapshot.transactions.first;
      expect(unknown.isIncome, isFalse);
      final huge = snapshot.transactions[1];
      expect(huge.amountToman, 999999999999999);
      final blank = snapshot.transactions.last;
      expect(blank.title, 'بدون عنوان');
      expect(blank.category, 'سایر');

      final debt = snapshot.debts.single;
      expect(debt.v1Id, 'debt-over');
      expect(debt.paidToman, 1000);

      expect(snapshot.installments, hasLength(2));
      expect(snapshot.installments.first.v1Id, 'inst-paid-over');
      expect(snapshot.installments.first.paidCount, 3);
      expect(snapshot.installments.last.v1Id, startsWith('v1:installment:'));

      Map<LegacySkipReason, int> reasons(LegacyEntityType type) {
        final result = <LegacySkipReason, int>{};
        for (final row in snapshot.skipped.where((r) => r.entityType == type)) {
          result[row.reason] = (result[row.reason] ?? 0) + 1;
        }
        return result;
      }

      expect(reasons(LegacyEntityType.task), <LegacySkipReason, int>{
        LegacySkipReason.duplicateId: 1,
        LegacySkipReason.notAnObject: 1,
      });
      expect(reasons(LegacyEntityType.transaction), <LegacySkipReason, int>{
        LegacySkipReason.invalidAmount: 3,
      });
      expect(reasons(LegacyEntityType.debt), <LegacySkipReason, int>{
        LegacySkipReason.invalidAmount: 1,
      });
      expect(reasons(LegacyEntityType.installment), <LegacySkipReason, int>{
        LegacySkipReason.totalOverflow: 1,
        LegacySkipReason.invalidCount: 1,
      });
      expect(snapshot.skipped, hasLength(8));

      expect(
        snapshot.warnings.map((w) => w.code).toSet(),
        <LegacyWarningCode>{
          LegacyWarningCode.unknownTransactionType,
          LegacyWarningCode.paidClamped,
          LegacyWarningCode.paidCountClamped,
        },
      );
      expect(snapshot.warnings, hasLength(3));
    });

    test('unreadable finance string keeps tasks and warns', () async {
      final snapshot = await parse('data_finance_unreadable.json');

      expect(snapshot.tasks, hasLength(1));
      expect(snapshot.transactions, isEmpty);
      expect(snapshot.warnings.single.code, LegacyWarningCode.financeUnreadable);
    });

    test('an empty object is a valid empty snapshot', () async {
      final snapshot = await parse('empty_object.json');

      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.skipped, isEmpty);
    });

    test('the source hash is the sha256 of the file bytes', () async {
      final bytes = await fixture('data_v1_2_desktop.json');
      final expected = await Sha256().hash(bytes);
      final hex = expected.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      final snapshot = await const LegacyV1Parser().parseBytes(bytes);

      expect(snapshot.sourceSha256, hex);
      expect(snapshot.sourceSha256, hasLength(64));
    });
  });

  group('v1 export files', () {
    test('tasks export maps names, dates and priorities', () async {
      final snapshot = await parse('export_tasks.json');

      expect(snapshot.sourceKind, LegacySourceKind.export);
      expect(snapshot.exportedAtUtc, DateTime.utc(2026, 11, 1, 8, 30));
      expect(snapshot.tasks, hasLength(2));
      final first = snapshot.tasks.first;
      expect(first.title, 'خرید نان');
      expect(first.priority, 3);
      expect(first.done, isFalse);
      expect(first.createdAtUtc, DateTime.utc(2024, 11, 3, 13, 20, 0, 123));
      expect(first.v1Id, startsWith('v1:task:'));
      expect(snapshot.tasks.last.done, isTrue);
      expect(snapshot.tasks.last.priority, 0);
      expect(snapshot.tasks.last.createdAtUtc, ms(1730500000000));
    });

    test('finance export maps transactions, debts and installments', () async {
      final snapshot = await parse('export_finance.json');

      expect(snapshot.sourceKind, LegacySourceKind.export);
      expect(snapshot.transactions, hasLength(2));
      expect(snapshot.transactions.first.isIncome, isTrue);
      expect(snapshot.transactions.first.category, 'حقوق');
      expect(
        snapshot.transactions.first.occurredAtUtc,
        DateTime.utc(2024, 11, 2, 22, 40),
      );
      expect(snapshot.transactions.last.isIncome, isFalse);
      expect(snapshot.debts.single.totalToman, 10000000);
      expect(snapshot.debts.single.paidToman, 2000000);
      expect(snapshot.debts.single.createdAtUtc, isNull);
      expect(snapshot.installments.single.perToman, 3500000);
      expect(snapshot.installments.single.count, 12);
      expect(snapshot.installments.single.paidCount, 4);
      expect(snapshot.installments.single.createdAtUtc, isNull);
    });
  });

  group('unusable input', () {
    test('truncated JSON throws ImportFailure', () async {
      expect(
        () => parse('corrupt_truncated.json'),
        throwsA(isA<ImportFailure>()),
      );
    });

    test('a JSON array root throws ImportFailure', () async {
      expect(() => parse('not_object.json'), throwsA(isA<ImportFailure>()));
    });

    test('an unrecognized object throws ImportFailure', () async {
      expect(
        () => parse('unsupported_object.json'),
        throwsA(isA<ImportFailure>()),
      );
    });

    test('non UTF-8 bytes throw ImportFailure', () async {
      expect(
        () => const LegacyV1Parser().parseBytes(
          Uint8List.fromList(<int>[0xff, 0xfe, 0xfd]),
        ),
        throwsA(isA<ImportFailure>()),
      );
    });
  });
}
```

Create `test/features/legacy_import/data/legacy_v1_source_locator_test.dart`:

```dart
import 'dart:io';

import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('linux honors XDG_DATA_HOME first, then ~/.local/share', () {
    const withXdg = LegacyV1SourceLocator(
      operatingSystem: 'linux',
      environment: <String, String>{
        'XDG_DATA_HOME': '/data/xdg',
        'HOME': '/home/u',
      },
    );
    const withoutXdg = LegacyV1SourceLocator(
      operatingSystem: 'linux',
      environment: <String, String>{'HOME': '/home/u'},
    );

    expect(withXdg.candidatePath(), '/data/xdg/dashboard-shakhsi/data.json');
    expect(
      withoutXdg.candidatePath(),
      '/home/u/.local/share/dashboard-shakhsi/data.json',
    );
  });

  test('windows uses APPDATA, falling back to the home directory', () {
    const withAppData = LegacyV1SourceLocator(
      operatingSystem: 'windows',
      environment: <String, String>{
        'APPDATA': r'C:\Users\u\AppData\Roaming',
        'USERPROFILE': r'C:\Users\u',
      },
    );
    const homeOnly = LegacyV1SourceLocator(
      operatingSystem: 'windows',
      environment: <String, String>{'USERPROFILE': r'C:\Users\u'},
    );

    expect(
      withAppData.candidatePath(),
      r'C:\Users\u\AppData\Roaming\dashboard-shakhsi\data.json',
    );
    expect(
      homeOnly.candidatePath(),
      r'C:\Users\u\dashboard-shakhsi\data.json',
    );
  });

  test('macos uses Library/Application Support', () {
    const locator = LegacyV1SourceLocator(
      operatingSystem: 'macos',
      environment: <String, String>{'HOME': '/Users/u'},
    );

    expect(
      locator.candidatePath(),
      '/Users/u/Library/Application Support/dashboard-shakhsi/data.json',
    );
  });

  test('android and unknown platforms have no auto-detect path', () {
    const android = LegacyV1SourceLocator(
      operatingSystem: 'android',
      environment: <String, String>{'HOME': '/data'},
    );
    const noHome = LegacyV1SourceLocator(
      operatingSystem: 'linux',
      environment: <String, String>{},
    );

    expect(android.candidatePath(), isNull);
    expect(noHome.candidatePath(), isNull);
  });

  test('detect returns the file only when it exists', () async {
    final directory = await Directory.systemTemp.createTemp('v1-locator-');
    try {
      final locator = LegacyV1SourceLocator(
        operatingSystem: 'linux',
        environment: <String, String>{'XDG_DATA_HOME': directory.path},
      );
      expect(await locator.detect(), isNull);

      final file = File('${directory.path}/dashboard-shakhsi/data.json');
      await file.create(recursive: true);
      await file.writeAsString('{}');

      final detected = await locator.detect();
      expect(detected?.path, file.path);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

```bash
export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH
cd /home/shabin/projects/personal/dashboard-shakhsi-rdf-t2   # your T2 worktree
flutter pub get
flutter test test/features/legacy_import
```

Expected: compile errors (the library files do not exist yet).

- [ ] **Step 4: Write the snapshot models**

Create `lib/features/legacy_import/domain/legacy_snapshot.dart`:

```dart
enum LegacyEntityType {
  task,
  transaction,
  debt,
  installment;

  String get storageValue => name;
}

enum LegacySourceKind {
  dataJson('data_json'),
  export('export');

  const LegacySourceKind(this.storageValue);

  final String storageValue;
}

/// v1's visible task order preference (`tasklist:prefs:v1`.sort).
enum LegacyTaskSort { newest, priority, alphabetical }

enum LegacySkipReason {
  notAnObject,
  emptyTitle,
  duplicateId,
  invalidAmount,
  invalidCount,
  totalOverflow,
  failedValidation,
}

enum LegacyWarningCode {
  tasksUnreadable,
  financeUnreadable,
  unknownTransactionType,
  paidClamped,
  paidCountClamped,
}

final class LegacySkippedRow {
  const LegacySkippedRow({
    required this.entityType,
    required this.v1Id,
    required this.reason,
  });

  final LegacyEntityType entityType;
  final String? v1Id;
  final LegacySkipReason reason;
}

final class LegacyWarning {
  const LegacyWarning({required this.code, this.entityType, this.v1Id});

  final LegacyWarningCode code;
  final LegacyEntityType? entityType;
  final String? v1Id;
}

final class LegacyTask {
  const LegacyTask({
    required this.v1Id,
    required this.title,
    required this.done,
    required this.priority,
    this.createdAtUtc,
  });

  final String v1Id;
  final String title;
  final bool done;
  final int priority;
  final DateTime? createdAtUtc;
}

final class LegacyTransaction {
  const LegacyTransaction({
    required this.v1Id,
    required this.title,
    required this.category,
    required this.isIncome,
    required this.amountToman,
    this.occurredAtUtc,
  });

  final String v1Id;
  final String title;
  final String category;
  final bool isIncome;
  final int amountToman;
  final DateTime? occurredAtUtc;
}

final class LegacyDebt {
  const LegacyDebt({
    required this.v1Id,
    required this.title,
    required this.totalToman,
    required this.paidToman,
    this.createdAtUtc,
  });

  final String v1Id;
  final String title;
  final int totalToman;
  final int paidToman;
  final DateTime? createdAtUtc;
}

final class LegacyInstallment {
  const LegacyInstallment({
    required this.v1Id,
    required this.title,
    required this.perToman,
    required this.count,
    required this.paidCount,
    this.createdAtUtc,
  });

  final String v1Id;
  final String title;
  final int perToman;
  final int count;
  final int paidCount;
  final DateTime? createdAtUtc;
}

final class LegacySnapshot {
  const LegacySnapshot({
    required this.sourceKind,
    required this.sourceSha256,
    required this.taskSort,
    required this.tasks,
    required this.transactions,
    required this.debts,
    required this.installments,
    required this.skipped,
    required this.warnings,
    this.exportedAtUtc,
  });

  final LegacySourceKind sourceKind;
  final String sourceSha256;
  final LegacyTaskSort taskSort;
  final DateTime? exportedAtUtc;
  final List<LegacyTask> tasks;
  final List<LegacyTransaction> transactions;
  final List<LegacyDebt> debts;
  final List<LegacyInstallment> installments;
  final List<LegacySkippedRow> skipped;
  final List<LegacyWarning> warnings;

  bool get isEmpty =>
      tasks.isEmpty &&
      transactions.isEmpty &&
      debts.isEmpty &&
      installments.isEmpty;
}
```

- [ ] **Step 5: Write the parser**

Create `lib/features/legacy_import/data/legacy_v1_parser.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';

/// Parses v1's `data.json` (string-encoded values, or already-structured
/// values) and v1's two JSON export files into a [LegacySnapshot].
///
/// Row-level problems never abort parsing: the row is recorded in
/// [LegacySnapshot.skipped] or [LegacySnapshot.warnings].
final class LegacyV1Parser {
  const LegacyV1Parser();

  static const Set<String> _storageKeys = <String>{
    'tasklist:v1',
    'tasklist:prefs:v1',
    'finance:v1',
    'app:prefs:v1',
  };
  static const int _maxInt64 = 9223372036854775807;
  static const int _maxJsEpochMs = 8640000000000000;

  Future<LegacySnapshot> parseBytes(Uint8List bytes) async {
    final sha256 = await _hex(Sha256(), bytes);

    final Object? root;
    try {
      var text = utf8.decode(bytes);
      if (text.startsWith('\uFEFF')) text = text.substring(1);
      root = jsonDecode(text);
    } on FormatException {
      throw const ImportFailure('فایل انتخاب‌شده JSON معتبر نیست.');
    }
    if (root is! Map<String, Object?>) {
      throw const ImportFailure('ساختار فایل انتخاب‌شده قابل شناسایی نیست.');
    }

    final sink = _Sink();
    if (root.isEmpty || _storageKeys.any(root.containsKey)) {
      return _parseDataJson(root, sha256, sink);
    }
    if (root['tasks'] is List ||
        root['transactions'] is List ||
        root['debts'] is List ||
        root['installments'] is List) {
      return _parseExport(root, sha256, sink);
    }
    throw const ImportFailure('ساختار فایل انتخاب‌شده قابل شناسایی نیست.');
  }

  Future<LegacySnapshot> _parseDataJson(
    Map<String, Object?> root,
    String sha256,
    _Sink sink,
  ) async {
    final tasksValue = _decode(root['tasklist:v1']);
    if (tasksValue.unreadable ||
        (tasksValue.value != null && tasksValue.value is! List)) {
      sink.warn(LegacyWarningCode.tasksUnreadable);
    }
    final financeValue = _decode(root['finance:v1']);
    final finance = financeValue.value;
    if (financeValue.unreadable ||
        (finance != null && finance is! Map<String, Object?>)) {
      sink.warn(LegacyWarningCode.financeUnreadable);
    }
    final financeMap = finance is Map<String, Object?>
        ? finance
        : const <String, Object?>{};
    final prefs = _decode(root['tasklist:prefs:v1']).value;
    final sort = prefs is Map<String, Object?> ? prefs['sort'] : null;

    return LegacySnapshot(
      sourceKind: LegacySourceKind.dataJson,
      sourceSha256: sha256,
      taskSort: switch (sort) {
        'pri' => LegacyTaskSort.priority,
        'abc' => LegacyTaskSort.alphabetical,
        _ => LegacyTaskSort.newest,
      },
      tasks: await _tasks(tasksValue.value, sink),
      transactions: await _transactions(financeMap['tx'], sink),
      debts: await _debts(financeMap['debts'], sink),
      installments: await _installments(financeMap['insts'], sink),
      skipped: sink.skipped,
      warnings: sink.warnings,
    );
  }

  Future<LegacySnapshot> _parseExport(
    Map<String, Object?> root,
    String sha256,
    _Sink sink,
  ) async {
    final exportedAt = root['exportedAt'];
    return LegacySnapshot(
      sourceKind: LegacySourceKind.export,
      sourceSha256: sha256,
      taskSort: LegacyTaskSort.newest,
      exportedAtUtc: exportedAt is String
          ? DateTime.tryParse(exportedAt)?.toUtc()
          : null,
      tasks: await _tasks(_normalize(root['tasks'], _exportTask), sink),
      transactions: await _transactions(
        _normalize(root['transactions'], _exportTransaction),
        sink,
      ),
      debts: await _debts(_normalize(root['debts'], _exportDebt), sink),
      installments: await _installments(
        _normalize(root['installments'], _exportInstallment),
        sink,
      ),
      skipped: sink.skipped,
      warnings: sink.warnings,
    );
  }

  // ---- export normalization: rewrite export records into data.json shape ----

  static Object? _normalize(
    Object? raw,
    Map<String, Object?> Function(Map<String, Object?>) convert,
  ) {
    if (raw is! List) return null;
    return raw
        .map((item) => item is Map<String, Object?> ? convert(item) : item)
        .toList();
  }

  static Map<String, Object?> _exportTask(Map<String, Object?> item) {
    return <String, Object?>{
      'text': item['text'],
      'done': item['done'],
      'priority': switch (item['priority']) {
        'low' => 1,
        'medium' => 2,
        'high' => 3,
        _ => 0,
      },
      'created': _isoToEpochMs(item['createdAt']),
    };
  }

  static Map<String, Object?> _exportTransaction(Map<String, Object?> item) {
    return <String, Object?>{
      'type': switch (item['type']) {
        'income' => 'in',
        'expense' => 'ex',
        final other => other,
      },
      'title': item['title'],
      'cat': item['category'],
      'amount': item['amount'],
      'ts': _isoToEpochMs(item['at']),
    };
  }

  static Map<String, Object?> _exportDebt(Map<String, Object?> item) {
    return <String, Object?>{
      'name': item['name'],
      'total': item['total'],
      'paid': item['paid'],
    };
  }

  static Map<String, Object?> _exportInstallment(Map<String, Object?> item) {
    return <String, Object?>{
      'name': item['name'],
      'per': item['perInstallment'],
      'count': item['count'],
      'paidCount': item['paidCount'],
    };
  }

  static int? _isoToEpochMs(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.millisecondsSinceEpoch;
  }

  // ---- entities ----

  Future<List<LegacyTask>> _tasks(Object? raw, _Sink sink) async {
    final result = <LegacyTask>[];
    if (raw is! List) return result;
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        sink.skip(LegacyEntityType.task, null, LegacySkipReason.notAnObject);
        continue;
      }
      final id = await _idFor(LegacyEntityType.task, item);
      final title = _text(item['text']) ?? '';
      if (title.isEmpty) {
        sink.skip(LegacyEntityType.task, id, LegacySkipReason.emptyTitle);
        continue;
      }
      if (!seen.add(id)) {
        sink.skip(LegacyEntityType.task, id, LegacySkipReason.duplicateId);
        continue;
      }
      final priority = _wholeNumber(item['priority']);
      result.add(
        LegacyTask(
          v1Id: id,
          title: title,
          done: _truthy(item['done']),
          priority: priority != null && priority >= 0 && priority <= 3
              ? priority
              : (_truthy(item['important']) ? 3 : 0),
          createdAtUtc: _epochMs(item['created']),
        ),
      );
    }
    return result;
  }

  Future<List<LegacyTransaction>> _transactions(
    Object? raw,
    _Sink sink,
  ) async {
    final result = <LegacyTransaction>[];
    if (raw is! List) return result;
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        sink.skip(
          LegacyEntityType.transaction,
          null,
          LegacySkipReason.notAnObject,
        );
        continue;
      }
      final id = await _idFor(LegacyEntityType.transaction, item);
      final amount = _positiveInt(item['amount']);
      if (amount == null) {
        sink.skip(
          LegacyEntityType.transaction,
          id,
          LegacySkipReason.invalidAmount,
        );
        continue;
      }
      if (!seen.add(id)) {
        sink.skip(
          LegacyEntityType.transaction,
          id,
          LegacySkipReason.duplicateId,
        );
        continue;
      }
      final type = item['type'];
      if (type != 'in' && type != 'ex') {
        sink.warn(
          LegacyWarningCode.unknownTransactionType,
          LegacyEntityType.transaction,
          id,
        );
      }
      result.add(
        LegacyTransaction(
          v1Id: id,
          title: _nonEmpty(item['title'], 'بدون عنوان'),
          category: _nonEmpty(item['cat'], 'سایر'),
          isIncome: type == 'in',
          amountToman: amount,
          occurredAtUtc: _epochMs(item['ts']),
        ),
      );
    }
    return result;
  }

  Future<List<LegacyDebt>> _debts(Object? raw, _Sink sink) async {
    final result = <LegacyDebt>[];
    if (raw is! List) return result;
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        sink.skip(LegacyEntityType.debt, null, LegacySkipReason.notAnObject);
        continue;
      }
      final id = await _idFor(LegacyEntityType.debt, item);
      final total = _positiveInt(item['total']);
      if (total == null) {
        sink.skip(LegacyEntityType.debt, id, LegacySkipReason.invalidAmount);
        continue;
      }
      if (!seen.add(id)) {
        sink.skip(LegacyEntityType.debt, id, LegacySkipReason.duplicateId);
        continue;
      }
      final paidRaw = _wholeNumber(item['paid']) ?? 0;
      final paid = paidRaw < 0 ? 0 : (paidRaw > total ? total : paidRaw);
      if (paid != paidRaw) {
        sink.warn(LegacyWarningCode.paidClamped, LegacyEntityType.debt, id);
      }
      result.add(
        LegacyDebt(
          v1Id: id,
          title: _nonEmpty(item['name'], 'بدون عنوان'),
          totalToman: total,
          paidToman: paid,
          createdAtUtc: _epochMs(item['created']),
        ),
      );
    }
    return result;
  }

  Future<List<LegacyInstallment>> _installments(
    Object? raw,
    _Sink sink,
  ) async {
    final result = <LegacyInstallment>[];
    if (raw is! List) return result;
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        sink.skip(
          LegacyEntityType.installment,
          null,
          LegacySkipReason.notAnObject,
        );
        continue;
      }
      final id = await _idFor(LegacyEntityType.installment, item);
      final per = _positiveInt(item['per']);
      if (per == null) {
        sink.skip(
          LegacyEntityType.installment,
          id,
          LegacySkipReason.invalidAmount,
        );
        continue;
      }
      final count = _positiveInt(item['count']);
      if (count == null) {
        sink.skip(
          LegacyEntityType.installment,
          id,
          LegacySkipReason.invalidCount,
        );
        continue;
      }
      if (BigInt.from(per) * BigInt.from(count) > BigInt.from(_maxInt64)) {
        sink.skip(
          LegacyEntityType.installment,
          id,
          LegacySkipReason.totalOverflow,
        );
        continue;
      }
      if (!seen.add(id)) {
        sink.skip(
          LegacyEntityType.installment,
          id,
          LegacySkipReason.duplicateId,
        );
        continue;
      }
      final paidRaw = _wholeNumber(item['paidCount']) ?? 0;
      final paid = paidRaw < 0 ? 0 : (paidRaw > count ? count : paidRaw);
      if (paid != paidRaw) {
        sink.warn(
          LegacyWarningCode.paidCountClamped,
          LegacyEntityType.installment,
          id,
        );
      }
      result.add(
        LegacyInstallment(
          v1Id: id,
          title: _nonEmpty(item['name'], 'بدون عنوان'),
          perToman: per,
          count: count,
          paidCount: paid,
          createdAtUtc: _epochMs(item['created']),
        ),
      );
    }
    return result;
  }

  // ---- helpers ----

  static _Decoded _decode(Object? raw) {
    if (raw == null) return const _Decoded(null, unreadable: false);
    if (raw is String) {
      try {
        return _Decoded(jsonDecode(raw), unreadable: false);
      } on FormatException {
        return const _Decoded(null, unreadable: true);
      }
    }
    return _Decoded(raw, unreadable: false);
  }

  static Future<String> _idFor(
    LegacyEntityType type,
    Map<String, Object?> item,
  ) async {
    final raw = item['id'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is int) return '$raw';
    final canonical = jsonEncode(_canonical(item));
    final digest = await _hex(Sha1(), utf8.encode(canonical));
    return 'v1:${type.storageValue}:$digest';
  }

  /// Rebuilds [value] with map keys sorted so equal records hash equally.
  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => '$key').toList()..sort();
      return <String, Object?>{for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList();
    return value;
  }

  static Future<String> _hex(HashAlgorithm algorithm, List<int> data) async {
    final hash = await algorithm.hash(data);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String? _text(Object? value) => value is String ? value.trim() : null;

  static String _nonEmpty(Object? value, String fallback) {
    final text = _text(value);
    return text == null || text.isEmpty ? fallback : text;
  }

  static bool _truthy(Object? value) =>
      value == true ||
      (value is num && value != 0) ||
      (value is String && value.isNotEmpty);

  static int? _wholeNumber(Object? value) {
    if (value is int) return value;
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble() &&
        value.abs() < 9007199254740992) {
      return value.toInt();
    }
    return null;
  }

  static int? _positiveInt(Object? value) {
    final number = _wholeNumber(value);
    return number != null && number > 0 ? number : null;
  }

  static DateTime? _epochMs(Object? value) {
    final number = _wholeNumber(value);
    if (number == null || number <= 0 || number > _maxJsEpochMs) return null;
    return DateTime.fromMillisecondsSinceEpoch(number, isUtc: true);
  }
}

final class _Decoded {
  const _Decoded(this.value, {required this.unreadable});

  final Object? value;
  final bool unreadable;
}

final class _Sink {
  final List<LegacySkippedRow> skipped = <LegacySkippedRow>[];
  final List<LegacyWarning> warnings = <LegacyWarning>[];

  void skip(LegacyEntityType type, String? v1Id, LegacySkipReason reason) {
    skipped.add(
      LegacySkippedRow(entityType: type, v1Id: v1Id, reason: reason),
    );
  }

  void warn(LegacyWarningCode code, [LegacyEntityType? type, String? v1Id]) {
    warnings.add(LegacyWarning(code: code, entityType: type, v1Id: v1Id));
  }
}
```

- [ ] **Step 6: Write the source locator**

Create `lib/features/legacy_import/data/legacy_v1_source_locator.dart`:

```dart
import 'dart:io';

/// Finds v1's `data.json` on desktop. Android is manual-import only (v2 may
/// not be able to read v1's private files). The file is only ever read.
final class LegacyV1SourceLocator {
  const LegacyV1SourceLocator({this.operatingSystem, this.environment});

  static const String appDirectoryName = 'dashboard-shakhsi';
  static const String fileName = 'data.json';

  final String? operatingSystem;
  final Map<String, String>? environment;

  String? candidatePath() {
    final os = operatingSystem ?? Platform.operatingSystem;
    final env = environment ?? Platform.environment;
    final home = _nonEmpty(env['HOME']) ?? _nonEmpty(env['USERPROFILE']);

    switch (os) {
      case 'linux':
        final xdg = _nonEmpty(env['XDG_DATA_HOME']);
        final root = xdg ?? (home == null ? null : '$home/.local/share');
        return root == null ? null : '$root/$appDirectoryName/$fileName';
      case 'macos':
        return home == null
            ? null
            : '$home/Library/Application Support/$appDirectoryName/$fileName';
      case 'windows':
        final root = _nonEmpty(env['APPDATA']) ?? home;
        return root == null ? null : '$root\\$appDirectoryName\\$fileName';
      default:
        return null;
    }
  }

  Future<File?> detect() async {
    final path = candidatePath();
    if (path == null) return null;
    try {
      final file = File(path);
      return await file.exists() ? file : null;
    } on FileSystemException {
      return null;
    }
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;
}
```

- [ ] **Step 7: Run tests, analyze, format**

```bash
flutter test test/features/legacy_import
dart format lib/features/legacy_import test/features/legacy_import
flutter analyze lib/features/legacy_import test/features/legacy_import
```

Expected: all PASS; analyzer clean. If the `Sha1()` or `Sha256()` constructors are flagged, copy the exact usage from `lib/core/notifications/linux_notification_request_fingerprint.dart:47` (`await Sha256().hash(utf8.encode(...))`).

- [ ] **Step 8: Commit**

```bash
git add lib/features/legacy_import/domain/legacy_snapshot.dart lib/features/legacy_import/data/legacy_v1_parser.dart lib/features/legacy_import/data/legacy_v1_source_locator.dart test/fixtures/legacy_v1 test/features/legacy_import
git commit -m "feat: parse v1 data.json and exports into a legacy snapshot" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---
### Task 3: Schema 9 - whole-toman money, `legacy_imports`, and the scale-0 test conversion

**Depends on:** none (G1). Sole owner of `app_database.dart`, `schemaVersion` and the generated `app_database.g.dart`.

**Files:**
- Modify: `lib/core/money/money.dart` (ONLY the `financeScale` constant line)
- Modify: `lib/core/database/app_database.dart`
- Regenerate: `lib/core/database/app_database.g.dart`
- Modify: `lib/features/finance/domain/finance_transaction.dart` (validator message)
- Modify: `lib/core/money/money_input_formatter.dart` (reject a decimal separator when `maxFractionDigits == 0`)
- Create: `test/core/database/finance_scale_migration_test.dart`
- Modify: `test/core/money/money_input_formatter_test.dart`, `test/features/finance/domain/finance_domain_test.dart`
- Modify (schema-version expectations 8 to 9): `test/core/database/app_database_test.dart`, `database_restart_test.dart`, `notification_schedule_migration_test.dart`, `task_planning_migration_test.dart`, `task_recurrence_restart_test.dart`, `task_recurrence_schema_migration_test.dart`, `task_reminder_schema_migration_test.dart`, `task_status_migration_test.dart`, `task_template_schema_test.dart`, `task_time_restart_test.dart`, `task_time_schema_migration_test.dart`
- Modify (decimal-string tests converted to whole toman): `test/features/finance/application/finance_report_service_test.dart`, `test/features/dashboard/finance_preview_math_test.dart`, `test/core/providers/persistence_providers_test.dart`, `test/core/database/database_restart_test.dart`, `test/features/dashboard/finance_panel_test.dart`, `test/features/dashboard/finance_panel_persistence_test.dart`

**Interfaces:**
- Produces (used by Tasks 4, 5, 6):
  - `Money.financeScale == 0`, so `Money.zeroIRT` has scale 0 and validators require scale 0.
  - Drift table `LegacyImportRows` (`tableName` `'legacy_imports'`), data class `LegacyImportRow`, companion `LegacyImportRowsCompanion`, accessor `AppDatabase.legacyImportRows`. Columns (SQL name: Dart getter): `source_kind: sourceKind`, `entity_type: entityType` (`'task'|'transaction'|'debt'|'installment'`), `v1_id: v1Id`, `v2_id: v2Id`, `imported_at_utc: importedAtUtc`, `source_sha256: sourceSha256`. Primary key `(entity_type, v1_id)` only (source kind and hash are not part of the key, so a changed file still skips already-imported rows).
  - `AppDatabase.schemaVersion == 9`.
  - Whole-toman rows for all three money tables; `scale` DDL default for freshly created DBs is 0 (migrated DBs keep the inert DDL default 8; the repository always writes `scale` explicitly).

- [ ] **Step 1: Write the failing migration test**

Create `test/core/database/finance_scale_migration_test.dart`:

```dart
import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/data/drift_finance_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

const String _seedSql = '''
INSERT INTO finance_transactions (id, type, title, category, amount_minor_units, currency_code, scale, occurred_at_utc, created_at_utc, updated_at_utc) VALUES
  ('tx-whole', 'income', 'A', 'c', 1500000000000, 'IRT', 8, 1780000000, 1780000000, 1780000000),
  ('tx-half-down', 'expense', 'B', 'c', 250000000, 'IRT', 8, 1780000000, 1780000000, 1780000000),
  ('tx-half-up', 'expense', 'C', 'c', 350000000, 'IRT', 8, 1780000000, 1780000000, 1780000000),
  ('tx-tiny', 'expense', 'D', 'c', 40000000, 'IRT', 8, 1780000000, 1780000000, 1780000000),
  ('tx-already-whole', 'expense', 'E', 'c', 777, 'IRT', 0, 1780000000, 1780000000, 1780000000);
INSERT INTO debts (id, title, total_minor_units, currency_code, scale, created_at_utc, updated_at_utc) VALUES
  ('debt-exact', 'D1', 1000000000000, 'IRT', 8, 1780000000, 1780000000),
  ('debt-rounding', 'D2', 250000000, 'IRT', 8, 1780000000, 1780000000);
INSERT INTO debt_payments (id, debt_id, amount_minor_units, paid_at_utc, created_at_utc) VALUES
  ('p1', 'debt-exact', 400000000000, 1780000000, 1780000000),
  ('p2', 'debt-exact', 600000000000, 1780000100, 1780000100),
  ('p3', 'debt-rounding', 150000000, 1780000000, 1780000000),
  ('p4', 'debt-rounding', 100000000, 1780000100, 1780000100);
INSERT INTO installment_plans (id, title, per_installment_minor_units, installment_count, currency_code, scale, created_at_utc, updated_at_utc) VALUES
  ('plan-1', 'P', 300000000000, 12, 'IRT', 8, 1780000000, 1780000000);
INSERT INTO installment_payments (id, plan_id, installment_number, amount_minor_units, paid_at_utc, created_at_utc) VALUES
  ('ip1', 'plan-1', 1, 300000000000, 1780000000, 1780000000),
  ('ip2', 'plan-1', 2, 300000000000, 1780000100, 1780000100);
''';

Future<File> _seedSchema8(Directory directory) async {
  final file = File('${directory.path}/dashboard.sqlite');
  final created = AppDatabase(NativeDatabase(file));
  await created.customSelect('SELECT 1').get();
  await created.close();

  final raw = sqlite3.open(file.path);
  try {
    raw.execute('DROP TABLE legacy_imports');
    raw.execute('PRAGMA user_version = 8');
    raw.execute(_seedSql);
  } finally {
    raw.close();
  }
  return file;
}

Future<void> _expectMigratedValues(AppDatabase database) async {
  final finance = DriftFinanceRepository(
    database,
    idGenerator: SequenceIdGenerator(prefix: 'check'),
  );

  final transactions = {
    for (final tx in await finance.watchTransactions().first) tx.id: tx,
  };
  expect(transactions['tx-whole']!.amount.minorUnits, 15000);
  expect(transactions['tx-half-down']!.amount.minorUnits, 2); // 2.5 -> even
  expect(transactions['tx-half-up']!.amount.minorUnits, 4); // 3.5 -> even
  expect(transactions['tx-tiny']!.amount.minorUnits, 1); // 0.4 clamped to 1
  expect(transactions['tx-already-whole']!.amount.minorUnits, 777);
  for (final tx in transactions.values) {
    expect(tx.amount.scale, Money.financeScale);
  }

  final debts = {for (final d in await finance.watchDebts().first) d.id: d};
  expect(debts['debt-exact']!.total.minorUnits, 10000);
  expect(debts['debt-exact']!.paid.minorUnits, 10000);
  expect(debts['debt-exact']!.settled, isTrue);
  // total 2.5 -> 2, payments 1.5 -> 2 and 1.0 -> 1 sum to 3: the total is
  // raised to 3 so Debt() stays valid.
  expect(debts['debt-rounding']!.total.minorUnits, 3);
  expect(debts['debt-rounding']!.paid.minorUnits, 3);

  final plans = await finance.watchInstallmentPlans().first;
  expect(plans.single.perInstallment.minorUnits, 3000);
  expect(plans.single.installmentCount, 12);
  expect(plans.single.paidCount, 2);
  expect(plans.single.perInstallment.scale, Money.financeScale);

  final leftovers = await database
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM finance_transactions WHERE scale != 0) + '
        '(SELECT COUNT(*) FROM debts WHERE scale != 0) + '
        '(SELECT COUNT(*) FROM installment_plans WHERE scale != 0) AS bad',
      )
      .getSingle();
  expect(leftovers.read<int>('bad'), 0);
}

void main() {
  test('finance scale is whole toman', () {
    expect(Money.financeScale, 0);
    expect(Money.zeroIRT.scale, 0);
  });

  test('a fresh database is schema 9 and has the legacy_imports table', () async {
    final database = AppDatabase(NativeDatabase.memory());
    try {
      expect(database.schemaVersion, 9);
      final rows = await database
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name = 'legacy_imports'",
          )
          .get();
      expect(rows, hasLength(1));
    } finally {
      await database.close();
    }
  });

  test('legacy_imports is unique on (entity_type, v1_id) only', () async {
    final database = AppDatabase(NativeDatabase.memory());
    try {
      final now = DateTime.utc(2026, 11, 4);
      Future<void> insert(String hash, String sourceKind) => database
          .into(database.legacyImportRows)
          .insert(
            LegacyImportRowsCompanion.insert(
              sourceKind: sourceKind,
              entityType: 'task',
              v1Id: 'v1-id',
              v2Id: 'v2-$hash',
              importedAtUtc: now,
              sourceSha256: hash,
            ),
          );

      await insert('hash-a', 'data_json');
      await expectLater(insert('hash-b', 'export'), throwsA(anything));
    } finally {
      await database.close();
    }
  });

  test('schema 8 to 9 rescales rows deterministically', () async {
    final directory = await Directory.systemTemp.createTemp('rdf-scale-');
    try {
      final file = await _seedSchema8(directory);

      final upgraded = AppDatabase(NativeDatabase(file));
      try {
        await _expectMigratedValues(upgraded);
        final version = await upgraded.customSelect('PRAGMA user_version').get();
        expect(version.single.read<int>('user_version'), 9);
        final tables = await upgraded
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type = 'table' AND name = 'legacy_imports'",
            )
            .get();
        expect(tables, hasLength(1));
      } finally {
        await upgraded.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('migrated data survives a restart and is not rescaled twice', () async {
    final directory = await Directory.systemTemp.createTemp('rdf-restart-');
    try {
      final file = await _seedSchema8(directory);

      final first = AppDatabase(NativeDatabase(file));
      await _expectMigratedValues(first);
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      try {
        await _expectMigratedValues(second);
        final version = await second.customSelect('PRAGMA user_version').get();
        expect(version.single.read<int>('user_version'), 9);
      } finally {
        await second.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
```

- [ ] **Step 2: Write the other failing tests**

Append to `test/core/money/money_input_formatter_test.dart` (inside `main()`, after the last test):

```dart
  test('the whole-toman formatter rejects a decimal separator', () {
    const wholeFormatter = MoneyInputFormatter();
    const previous = TextEditingValue(
      text: '۱۲',
      selection: TextSelection.collapsed(offset: 2),
    );

    for (final typed in <String>['12.', '12٫', '12.5']) {
      final result = wholeFormatter.formatEditUpdate(
        previous,
        TextEditingValue(
          text: typed,
          selection: TextSelection.collapsed(offset: typed.length),
        ),
      );
      expect(result, previous, reason: 'typed "$typed" must be refused');
    }
  });

  test('the whole-toman formatter still groups digits', () {
    const wholeFormatter = MoneyInputFormatter();
    final result = wholeFormatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1234567',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );

    expect(result.text, '۱٬۲۳۴٬۵۶۷');
  });
```

Append to `test/features/finance/domain/finance_domain_test.dart` inside `main()`:

```dart
  test('transaction rejects a legacy scale-8 amount', () {
    const legacy = Money(
      minorUnits: 100000000,
      currencyCode: Money.tomanCurrencyCode,
      scale: 8,
    );

    expect(
      () => FinanceTransaction.create(
        id: 'tx-legacy',
        type: FinanceTransactionType.expense,
        title: 'خرید',
        category: 'خوراک',
        amount: legacy,
        occurredAtUtc: createdAt,
        createdAtUtc: createdAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
```

- [ ] **Step 3: Run to verify the failures**

```bash
export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH
cd /home/shabin/projects/personal/dashboard-shakhsi-rdf-t3   # your T3 worktree
flutter pub get
flutter test test/core/database/finance_scale_migration_test.dart test/core/money/money_input_formatter_test.dart test/features/finance/domain/finance_domain_test.dart
```

Expected: FAIL (financeScale is 8, `legacyImportRows` undefined, formatter keeps the digits after `.`).

- [ ] **Step 4: Change the money constant and validator text**

In `lib/core/money/money.dart` change ONLY this line:

```dart
  static const int financeScale = 0;
```

In `lib/features/finance/domain/finance_transaction.dart` replace the `validateExactMoneyDefinition` message:

```dart
    throw const ValidationFailure(
      'مبلغ باید با واحد تومان و به‌صورت عدد صحیح ثبت شود.',
    );
```

- [ ] **Step 5: Fix the formatter bug at scale 0**

In `lib/core/money/money_input_formatter.dart`, `_sanitize`, replace the block

```dart
      if ((character == '.' || character == '٫') &&
          !hasDecimal &&
          maxFractionDigits > 0) {
        hasDecimal = true;
        continue;
      }
```

with

```dart
      if (character == '.' || character == '٫') {
        // A whole-unit currency refuses the separator. Without this, the
        // fraction digits that follow would be appended to the integer part
        // ("12.5" would become 125).
        if (maxFractionDigits == 0) return null;
        hasDecimal = true;
        continue;
      }
```

(A second decimal separator is still ignored: `hasDecimal` stays true and the loop continues.)

- [ ] **Step 6: Add the table and the migration in `lib/core/database/app_database.dart`**

Add at the top of the imports (alphabetical; `dart:` first):

```dart
import 'dart:developer' as developer;

import 'package:dashboard_shakhsi/core/database/database_connection.dart';
import 'package:drift/drift.dart';
```

Change the three `scale` defaults (in `FinanceTransactionRows`, `DebtRows`, `InstallmentPlanRows`) from `Constant(8)` to `Constant(0)`:

```dart
  IntColumn get scale => integer().withDefault(const Constant(0))();
```

Add the table class after `NotificationScheduleRows`:

```dart
class LegacyImportRows extends Table {
  @override
  String get tableName => 'legacy_imports';

  TextColumn get sourceKind => text().named('source_kind')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get v1Id => text().named('v1_id')();
  TextColumn get v2Id => text().named('v2_id')();
  DateTimeColumn get importedAtUtc => dateTime()();
  TextColumn get sourceSha256 => text().named('source_sha256')();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (entity_type IN ('task', 'transaction', 'debt', 'installment'))",
    "CHECK (source_kind IN ('data_json', 'export'))",
    'CHECK (length(trim(v1_id)) > 0)',
    'CHECK (length(trim(v2_id)) > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{entityType, v1Id};
}
```

Register it in `@DriftDatabase(tables: ...)` (append `LegacyImportRows,` after `NotificationScheduleRows,`), set `int get schemaVersion => 9;`, and append the new step at the end of `onUpgrade`, after the `if (from < 8)` block:

```dart
      if (from < 9) {
        await _migrateToWholeTomanAndLegacyImports(migrator);
      }
```

Add these members to `AppDatabase` (below `migration`):

```dart
  static const String _legacyUnit = '100000000';
  static const String _legacyHalf = '50000000';

  /// Integer-only round-half-even of `column / 1e8`, clamping a positive
  /// value that would round to 0 up to 1 (the domain rejects 0 amounts).
  static String _roundToWholeUnits(String column) {
    final whole = '($column / $_legacyUnit)';
    final remainder = '($column % $_legacyUnit)';
    final rounded =
        '($whole + CASE WHEN $remainder > $_legacyHalf '
        'OR ($remainder = $_legacyHalf AND $whole % 2 = 1) '
        'THEN 1 ELSE 0 END)';
    return 'CASE WHEN $column > 0 THEN MAX(1, $rounded) ELSE 0 END';
  }

  Future<bool> _tableExists(String name) async {
    final rows = await customSelect(
      "SELECT 1 AS present FROM sqlite_master "
      "WHERE type = 'table' AND name = ?",
      variables: <Variable<Object>>[Variable<String>(name)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _logRoundedRows(
    String table,
    String column,
    String where,
  ) async {
    final rows = await customSelect(
      'SELECT id FROM $table WHERE $where AND $column % $_legacyUnit != 0',
    ).get();
    for (final row in rows) {
      developer.log(
        'schema 9 rounded $table row ${row.read<String>('id')} to whole toman',
        name: 'dashboard_shakhsi.migration',
      );
    }
  }

  /// Schema 8 -> 9, one step: rescale every scale-8 money row to scale 0 and
  /// create `legacy_imports`. Tables are checked for existence because older
  /// test fixtures seed partial schemas.
  Future<void> _migrateToWholeTomanAndLegacyImports(Migrator migrator) async {
    if (await _tableExists('finance_transactions')) {
      await _logRoundedRows(
        'finance_transactions',
        'amount_minor_units',
        'scale = 8',
      );
      await customStatement(
        'UPDATE finance_transactions SET '
        'amount_minor_units = ${_roundToWholeUnits('amount_minor_units')}, '
        'scale = 0 WHERE scale = 8',
      );
    }

    final hasDebts = await _tableExists('debts');
    final hasDebtPayments = await _tableExists('debt_payments');
    if (hasDebts && hasDebtPayments) {
      // Children first: they are selected through the parent's scale.
      await _logRoundedRows(
        'debt_payments',
        'amount_minor_units',
        'debt_id IN (SELECT id FROM debts WHERE scale = 8)',
      );
      await customStatement(
        'UPDATE debt_payments SET '
        'amount_minor_units = ${_roundToWholeUnits('amount_minor_units')} '
        'WHERE debt_id IN (SELECT id FROM debts WHERE scale = 8)',
      );
    }
    if (hasDebts) {
      await _logRoundedRows('debts', 'total_minor_units', 'scale = 8');
      await customStatement(
        'UPDATE debts SET '
        'total_minor_units = ${_roundToWholeUnits('total_minor_units')}, '
        'scale = 0 WHERE scale = 8',
      );
    }
    if (hasDebts && hasDebtPayments) {
      // Rounding payments and totals separately can leave paid > total.
      // Raise the total to the payment sum so Debt() never throws.
      await customStatement('''
        UPDATE debts SET total_minor_units = (
          SELECT COALESCE(SUM(p.amount_minor_units), 0)
          FROM debt_payments p WHERE p.debt_id = debts.id
        )
        WHERE (
          SELECT COALESCE(SUM(p.amount_minor_units), 0)
          FROM debt_payments p WHERE p.debt_id = debts.id
        ) > total_minor_units
      ''');
    }

    final hasPlans = await _tableExists('installment_plans');
    if (hasPlans && await _tableExists('installment_payments')) {
      await _logRoundedRows(
        'installment_payments',
        'amount_minor_units',
        'plan_id IN (SELECT id FROM installment_plans WHERE scale = 8)',
      );
      await customStatement(
        'UPDATE installment_payments SET '
        'amount_minor_units = ${_roundToWholeUnits('amount_minor_units')} '
        'WHERE plan_id IN '
        '(SELECT id FROM installment_plans WHERE scale = 8)',
      );
    }
    if (hasPlans) {
      await _logRoundedRows(
        'installment_plans',
        'per_installment_minor_units',
        'scale = 8',
      );
      await customStatement(
        'UPDATE installment_plans SET per_installment_minor_units = '
        '${_roundToWholeUnits('per_installment_minor_units')}, '
        'scale = 0 WHERE scale = 8',
      );
    }

    await migrator.createTable(legacyImportRows);
  }
```

(The `_roundToWholeUnits` SQL was verified with sqlite3 before this plan was written: `0 -> 0`, `1 -> 1`, `40000000 -> 1`, `50000000 -> 1`, `150000000 -> 2`, `250000000 -> 2`, `350000000 -> 4`, `1500000000000 -> 15000`, `9223372036854775807 -> 92233720369`. An installment plan's payments get the same rounding as its per-installment amount, so they stay equal.)

- [ ] **Step 7: Regenerate the Drift code**

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --stat -- lib/core/database/app_database.g.dart
```

Expected: `app_database.g.dart` changed (new `LegacyImportRows`, `LegacyImportRow`, `LegacyImportRowsCompanion`, `legacyImportRows`, scale defaults `0`).

- [ ] **Step 8: Bump every schema-version expectation from 8 to 9**

```bash
grep -rlE "schemaVersion, 8|'user_version'\), 8" test | xargs sed -i -E "s/schemaVersion, 8\)/schemaVersion, 9)/; s/'user_version'\), 8\)/'user_version'), 9)/"
grep -rnE "schemaVersion, 8|'user_version'\), 8" test
```

Expected: the final grep prints nothing. Also rename the cosmetic test names that say "schema version eight" only if you wish; they are not asserted. In `test/core/database/app_database_test.dart` update the test title to `'schema version nine creates all persistence tables'` and add `'legacy_imports'` to the `containsAll` set.

- [ ] **Step 9: Convert the decimal-string tests to whole toman**

Tests that build `Money(minorUnits: N, scale: Money.financeScale)` stay valid (just larger toman). Only tests that PARSE decimal strings or type decimals must change. Apply exactly these edits.

`test/features/finance/application/finance_report_service_test.dart`:
- Test `summary preserves exact eight-decimal values` becomes `summary sums whole-toman values exactly`. Amounts: `'0.10000001'` to `'10'`, `'0.20000002'` to `'20'`, `'0.00000003'` to `'3'`; debt `total: _money('20.50000001')` to `_money('2050')`, `paid: _money('0.50000001')` to `_money('50')`; installment `perInstallment: _money('2.5')` to `_money('250')`. Expectations: `balance` `_money('27')`, `monthIncome` `_money('30')`, `monthExpense` `_money('3')`, `debtRemaining` `_money('2750')` (2000 debt remaining + 3 x 250 installments).
- Trend test: `'11.00000001'` to `'1100'`, `'4.00000001'` to `'400'`; expectations `points.last.income` `_money('1100')`, `points.last.expense` `_money('400')`.
- Categories test: `'1.25'` to `'1'` and `'2.75'` to `'3'` (the sum stays 4, expectations `_money('7')` first and `_money('4')` last are unchanged).
- Week test: `'1.00000001'` to `'101'`, `'2.00000002'` to `'202'`; expectations `points.last.value` `_money('101')`, `points[4].value` `_money('202')`.

`test/features/dashboard/finance_preview_math_test.dart`: rename to `finance totals sum whole-toman values exactly`; `amount('1000.12345678')` to `amount('1000')`; `amount('0.00000001')` to `amount('1')`; debt `total: amount('20.50000001')` to `amount('21')`, `paid: amount('0.50000001')` to `amount('1')`. Expectations: `balance` `'۹۹۹'`, `monthIncome` `'۱٬۰۰۰'`, `monthExpense` `'۱'`, `debtRemaining` `'۲۰'`.

`test/core/providers/persistence_providers_test.dart`: `_money('12.50000001')` (lines ~145 and ~152) to `_money('1250')`; `_money('2.5')` (lines ~186 and ~195) to `_money('250')`.

`test/core/database/database_restart_test.dart`: `_money('1234567.12345678')` to `_money('1234567')`; debt `paid: _money('2500000.00000001')` to `_money('2500001')`; payment `_money('1000000.00000001')` to `_money('1000001')`; plan `_money('3000000.12345678')` to `_money('3000000')`. Expectations: transaction `minorUnits` `1234567`; debt `total.minorUnits` `10000000`, `paid.minorUnits` `3500002`, `remaining.minorUnits` `6499998`; plan `perInstallment.minorUnits` `3000000`. (The `expect(first.schemaVersion, ...)` and `user_version` lines were already bumped in Step 8.)

`test/features/dashboard/finance_panel_test.dart`: the test `formats decimal money live and preserves all eight digits` becomes `formats whole-toman money live`: type `'1234567'`; expect the controller text `'۱٬۲۳۴٬۵۶۷'`; after submit expect `find.text('۱٬۲۳۴٬۵۶۷')` `findsWidgets` and `find.text('+۱٬۲۳۴٬۵۶۷')` `findsOneWidget`.

`test/features/dashboard/finance_panel_persistence_test.dart`:
- Seed `_money('1234567.12345678')` (line ~101) to `_money('1234567')`; the expectations at lines ~135-136 to `'+۱٬۲۳۴٬۵۶۷'` and `'۱٬۲۳۴٬۵۶۷'`.
- Form test: `'1234567.12345678'` to `'1234567'` and expect `minorUnits` `1234567`; debt total `'10000000.00000001'` to `'10000001'` (expect `total.minorUnits` `10000001`); debt paid `'2500000.00000001'` to `'2500001'` (expect `paid.minorUnits` `2500001`); installment `'3000000.12345678'` to `'3000001'` (expect `perInstallment.minorUnits` `3000001`).
- Payment test: `'1000000.00000001'` (line ~245) to `'1000000'`; the seeded debt already has `2500000` paid, so expect `repository.debts.single.paid.minorUnits` `3500000`.

Then confirm no decimal-string money remains and that no UI text still advertises decimals:

```bash
grep -rnE "'[0-9]+\.[0-9]+'" test --include=*.dart | grep -v "apple_visual\|test/core/money/money_test\|money_input_formatter_test\|notifications"
grep -rn "اعشار" lib
```

Expected: both print nothing. (`money_test.dart` and the formatter test use explicit `scale: 8` / `maxFractionDigits: 8` and exercise the generic `Money` class, so they stay valid.)

- [ ] **Step 10: Run the whole affected suite**

```bash
dart format lib test
flutter analyze
flutter test test/core test/features/finance test/features/dashboard test/features/tasks/data
```

Expected: PASS and `No issues found`. Existing partial-schema migration tests (`task_status_migration_test.dart` etc.) also prove the `_tableExists` guards: they migrate DBs that have no finance tables.

- [ ] **Step 11: Commit**

```bash
git add lib/core/money/money.dart lib/core/money/money_input_formatter.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart lib/features/finance/domain/finance_transaction.dart test/core test/features/finance test/features/dashboard
git commit -m "feat: schema 9 whole-toman money and legacy_imports ledger" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---
### Task 4: Overflow-safe consumers (reports, chart legend, repository sums, input cap)

**Depends on:** Task 1 (checked `Money`, `MoneyOverflowFailure`, `percentOf`) and Task 3 (scale 0, formatter). Runs in G2, in parallel with Task 5 (disjoint files).

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/finance_charts.dart` (legend percent, line ~92)
- Modify: `lib/features/dashboard/presentation/widgets/finance_panel.dart` (`build`, ~lines 76-97)
- Modify: `lib/features/finance/data/drift_finance_repository.dart` (`recordDebtPayment` sums ~170-176; `_mapDebtJoinRows` ~336)
- Modify: `lib/features/finance/domain/installment_plan.dart` (constructor total check)
- Modify: `lib/core/money/money_input_formatter.dart` (integer-digit cap)
- Create: `test/features/dashboard/finance_donut_percent_test.dart`
- Create: `test/features/dashboard/finance_panel_overflow_test.dart`
- Modify: `test/features/finance/data/drift_finance_repository_test.dart` (one test)
- Modify: `test/features/finance/domain/finance_domain_test.dart` (one test)
- Modify: `test/core/money/money_input_formatter_test.dart` (one test)

**Interfaces:**
- Consumes: `MoneyOverflowFailure`, `Money.checkedAdd`, `Money.checkedSubtract`, `Money.percentOf` (Task 1); `Money.financeScale == 0` (Task 3).
- Produces: `MoneyInputFormatter({int maxFractionDigits = Money.financeScale, int maxIntegerDigits = 15})`; `InstallmentPlan` constructor throws `ValidationFailure` when `perInstallment * installmentCount` overflows int64; `FinancePanel` renders a widget keyed `finance-out-of-range` instead of crashing when a report sum overflows.

- [ ] **Step 1: Write the failing tests**

Create `test/features/dashboard/finance_donut_percent_test.dart`:

```dart
import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/finance_charts.dart';
import 'package:dashboard_shakhsi/features/finance/application/finance_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Money toman(int value) => Money(
    minorUnits: value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );

  testWidgets('legend percentages do not overflow on huge categories', (
    tester,
  ) async {
    // 9.5e16 * 100 exceeds int64, which used to show a wrong percentage.
    await tester.pumpWidget(
      MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: FinanceDonutChart(
                currentMonthOnly: true,
                points: <FinanceCategoryPoint>[
                  FinanceCategoryPoint(
                    label: 'بزرگ',
                    value: toman(95000000000000000),
                  ),
                  FinanceCategoryPoint(
                    label: 'کوچک',
                    value: toman(5000000000000000),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('٪۹۵'), findsOneWidget);
    expect(find.text('٪۵'), findsOneWidget);
  });
}
```

Create `test/features/dashboard/finance_panel_overflow_test.dart`:

```dart
import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/finance_panel.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_finance_repository.dart';

void main() {
  testWidgets('a report sum above int64 shows an out-of-range notice', (
    tester,
  ) async {
    final repository = MemoryFinanceRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        financeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });

    final now = DateTime.now().toUtc();
    const huge = Money(
      minorUnits: 6000000000000000000,
      currencyCode: Money.tomanCurrencyCode,
      scale: Money.financeScale,
    );
    repository.seed(
      transactions: <FinanceTransaction>[
        for (final id in <String>['a', 'b'])
          FinanceTransaction.create(
            id: id,
            type: FinanceTransactionType.income,
            title: 'درآمد $id',
            category: 'حقوق',
            amount: huge,
            occurredAtUtc: now,
            createdAtUtc: now,
          ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: const Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                child: SizedBox(width: 780, child: FinancePanel()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey<String>('finance-out-of-range')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
```

Append inside `main()` of `test/features/finance/data/drift_finance_repository_test.dart` (it already has `database`, `repository`, `setUp`/`tearDown`; add `import 'package:dashboard_shakhsi/core/errors/app_failure.dart';` and `import 'package:drift/drift.dart' show Value;` only if not already imported):

```dart
  test('recordDebtPayment refuses a payment sum above int64', () async {
    final now = DateTime.utc(2026, 11, 4);
    await database
        .into(database.debtRows)
        .insert(
          DebtRowsCompanion.insert(
            id: 'debt-huge',
            title: 'بزرگ',
            totalMinorUnits: 9000000000000000000,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
    for (final entry in <(String, int)>[
      ('pay-a', 5000000000000000000),
      ('pay-b', 4900000000000000000),
    ]) {
      await database
          .into(database.debtPaymentRows)
          .insert(
            DebtPaymentRowsCompanion.insert(
              id: entry.$1,
              debtId: 'debt-huge',
              amountMinorUnits: entry.$2,
              paidAtUtc: now,
              createdAtUtc: now,
            ),
          );
    }

    await expectLater(
      repository.recordDebtPayment(
        debtId: 'debt-huge',
        amount: _money(1),
        paidAt: now,
      ),
      throwsA(isA<MoneyOverflowFailure>()),
    );
  });
```

(`_money(int)` is the file's existing helper taking minor units; `MoneyOverflowFailure` comes from `lib/core/errors/app_failure.dart`.)

Append inside `main()` of `test/features/finance/domain/finance_domain_test.dart`:

```dart
  test('installment plan rejects a total above int64', () {
    expect(
      () => InstallmentPlan(
        id: 'plan-huge',
        title: 'بزرگ',
        perInstallment: const Money(
          minorUnits: 1000000000000000,
          currencyCode: Money.tomanCurrencyCode,
          scale: Money.financeScale,
        ),
        installmentCount: 10000,
        paidCount: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
```

Append inside `main()` of `test/core/money/money_input_formatter_test.dart`:

```dart
  test('caps the integer part at fifteen digits like v1', () {
    const wholeFormatter = MoneyInputFormatter();
    final result = wholeFormatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '12345678901234567890',
        selection: TextSelection.collapsed(offset: 20),
      ),
    );

    expect(result.text, '۱۲۳٬۴۵۶٬۷۸۹٬۰۱۲٬۳۴۵');
  });
```

- [ ] **Step 2: Run to verify they fail**

```bash
export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH
cd /home/shabin/projects/personal/dashboard-shakhsi-rdf-t4   # your T4 worktree (created from the merged G1 head)
flutter pub get
flutter test test/features/dashboard/finance_donut_percent_test.dart test/features/dashboard/finance_panel_overflow_test.dart test/features/finance test/core/money
```

Expected: the five new tests FAIL (wrong percentage / uncaught `MoneyOverflowFailure` in build / wrapped sum / no cap).

- [ ] **Step 3: Fix the legend percentage**

In `lib/features/dashboard/presentation/widgets/finance_charts.dart` replace

```dart
            final percentage = total.isZero
                ? 0
                : ((entry.$2.value.minorUnits * 100 + total.minorUnits ~/ 2) ~/
                      total.minorUnits);
```

with

```dart
            final percentage = total.isPositive
                ? entry.$2.value.percentOf(total)
                : 0;
```

- [ ] **Step 4: Guard the finance panel**

In `lib/features/dashboard/presentation/widgets/finance_panel.dart` add the import (alphabetical, before the `core/ids` import): `import 'package:dashboard_shakhsi/core/errors/app_failure.dart';`. Replace the block in `build` that assigns `totals`, `trend`, `categories`, `week` with:

```dart
    final reports = ref.watch(financeReportServiceProvider);
    final FinanceSummary totals;
    final List<FinanceMonthPoint> trend;
    final List<FinanceCategoryPoint> categories;
    final List<FinanceDayPoint> week;
    try {
      totals = reports.summary(
        transactions: transactions,
        debts: debts,
        installments: installments,
      );
      trend = reports.trend(transactions: transactions);
      categories = reports.categories(
        transactions: transactions,
        currentMonthOnly: _donutScope == 0,
      );
      week = reports.week(transactions: transactions);
    } on MoneyOverflowFailure {
      return const _OutOfRangeNotice();
    }
```

(`reports` was already read just above; keep a single `final reports = ...` line.) Add this private widget at the end of the file:

```dart
final class _OutOfRangeNotice extends StatelessWidget {
  const _OutOfRangeNotice();

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Padding(
      key: const ValueKey<String>('finance-out-of-range'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'مجموع مبالغ از محدوده قابل نمایش بیشتر است.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
```

Known limitation (documented in the checkpoint): while a sum is out of range the panel shows only this notice. At scale 0 that needs more than 9.2e18 toman, so it is a safety net, not a realistic state.

- [ ] **Step 5: Use checked sums in the repository**

In `lib/features/finance/data/drift_finance_repository.dart`, `recordDebtPayment`, replace the two statements computing `paidMinorUnits` and `remainingMinorUnits` with:

```dart
      final paidMinorUnits = paymentRows.fold<int>(
        0,
        (sum, row) => Money.checkedAdd(sum, row.amountMinorUnits),
      );
      final remainingMinorUnits = Money.checkedSubtract(
        debtRow.totalMinorUnits,
        paidMinorUnits,
      );
```

In `_mapDebtJoinRows` replace `aggregate.paidMinorUnits += paymentRow.amountMinorUnits;` with:

```dart
        aggregate.paidMinorUnits = Money.checkedAdd(
          aggregate.paidMinorUnits,
          paymentRow.amountMinorUnits,
        );
```

- [ ] **Step 6: Reject overflowing installment totals at construction**

In `lib/features/finance/domain/installment_plan.dart` add the import `import 'package:dashboard_shakhsi/core/errors/app_failure.dart';` (already present) and, inside the constructor body right after `validateExactPositiveMoney(perInstallment);` and the `installmentCount < 1` check, add:

```dart
    try {
      perInstallment * installmentCount;
    } on MoneyOverflowFailure {
      throw const ValidationFailure('مجموع اقساط از حد مجاز بیشتر است.');
    }
```

(The `total`, `paid` and `remaining` getters then can never overflow for a valid plan, since `paidCount` and `remainingCount` are at most `installmentCount`.)

- [ ] **Step 7: Cap the integer digits in the formatter**

In `lib/core/money/money_input_formatter.dart` replace the constructor and field block with:

```dart
  const MoneyInputFormatter({
    this.maxFractionDigits = Money.financeScale,
    this.maxIntegerDigits = 15,
  }) : assert(maxFractionDigits >= 0 && maxFractionDigits <= 18),
       assert(maxIntegerDigits > 0);

  final int maxFractionDigits;

  /// v1 kept at most 15 digits (`parseAmount`); the same cap keeps typed
  /// amounts far below the int64 limit.
  final int maxIntegerDigits;
```

and in `_sanitize` replace `integer.write(character);` (the integer branch, the `else` of `if (hasDecimal)`) with:

```dart
          if (integer.length < maxIntegerDigits) integer.write(character);
```

- [ ] **Step 8: Run tests, analyze, format**

```bash
dart format lib test
flutter analyze
flutter test test/features/dashboard test/features/finance test/core/money test/core/database
```

Expected: PASS, `No issues found`.

- [ ] **Step 9: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/finance_charts.dart lib/features/dashboard/presentation/widgets/finance_panel.dart lib/features/finance/data/drift_finance_repository.dart lib/features/finance/domain/installment_plan.dart lib/core/money/money_input_formatter.dart test/features/dashboard/finance_donut_percent_test.dart test/features/dashboard/finance_panel_overflow_test.dart test/features/finance test/core/money
git commit -m "fix: overflow-safe finance reports, legend percent and amount input" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Legacy import service (plan, preview, one-transaction execute)

**Depends on:** Task 2 (snapshot models, parser) and Task 3 (`legacy_imports`, scale 0). Runs in G2, in parallel with Task 4.

**Files:**
- Create: `lib/features/legacy_import/domain/legacy_import_report.dart`
- Create: `lib/features/legacy_import/data/drift_legacy_import_ledger.dart`
- Create: `lib/features/legacy_import/application/legacy_import_service.dart`
- Modify: `lib/core/providers/persistence_providers.dart` (new providers appended)
- Test: `test/features/legacy_import/application/legacy_import_service_test.dart`

**Interfaces:**
- Consumes: everything from Task 2 (`LegacySnapshot` and models, `LegacyV1Parser`, `LegacyV1SourceLocator`); `LegacyImportRows` / `LegacyImportRowsCompanion` / `AppDatabase.legacyImportRows` and `Money.financeScale == 0` from Task 3; existing `DriftFinanceRepository(AppDatabase, {IdGenerator idGenerator})` with `addTransaction`, `addDebt`, `addInstallmentPlan`; `AppClock`, `IdGenerator`, `FinanceTransaction.create`, `Debt`, `InstallmentPlan`, `TaskItem`, `TaskStatus`.
- Produces (used by Task 6):
  - `LegacyImportPreview({required Map<LegacyEntityType,int> toImport, required Map<LegacyEntityType,int> alreadyImported, required List<LegacySkippedRow> skipped, required List<LegacyWarning> warnings})` with `int get totalToImport`.
  - `LegacyImportReport({required Map<LegacyEntityType,int> imported, required Map<LegacyEntityType,int> alreadyImported, required List<LegacySkippedRow> skipped, required List<LegacyWarning> warnings})` with `int get totalImported`.
  - `abstract interface class LegacyImportLedger { Future<Set<String>> importedIds(LegacyEntityType type); Future<void> record({required LegacyEntityType type, required LegacySourceKind sourceKind, required String v1Id, required String v2Id, required DateTime importedAtUtc, required String sourceSha256}); Future<bool> hasAnyRecords(); }` and `DriftLegacyImportLedger(AppDatabase)`.
  - `LegacyImportService({required AppDatabase database, required LegacyImportLedger ledger, required AppClock clock, required IdGenerator idGenerator})` with `Future<LegacyImportPreview> preview(LegacySnapshot)` (no writes) and `Future<LegacyImportReport> execute(LegacySnapshot)` (one transaction; throws `ImportFailure` and writes nothing on any failure).
  - Providers in `persistence_providers.dart`: `legacyV1ParserProvider` (`Provider<LegacyV1Parser>`), `legacyV1SourceLocatorProvider` (`Provider<LegacyV1SourceLocator>`), `legacyImportLedgerProvider` (`Provider<LegacyImportLedger>`), `legacyImportServiceProvider` (`Provider<LegacyImportService>`).

Design notes the implementer must keep:
- Task rows are written directly (`DriftTaskRepository.create` ignores positions). Finance rows go through `DriftFinanceRepository` built on the SAME `AppDatabase`: its nested `transaction()` calls join the outer one, `addDebt` inserts the synthetic payment of `debt.paid` dated `debt.updatedAtUtc`, and `addInstallmentPlan` inserts payments `1..paidCount` dated `plan.updatedAtUtc`. The importer sets `updatedAtUtc = createdAtUtc` so synthetic payments are dated at the record's `created`. Nothing here creates a `finance_transactions` row from a counter (v1's payment transactions are already ordinary `tx` items).
- Display numbers: oldest `created` gets the next free number (`MAX(display_number)+1` onward), ties by v1 id. Positions: per status, continue after the existing row count, in v1's visible order (`LegacyTaskSort`), position 0 = top.
- Done tasks: `status completed`, `completedAtUtc = createdAtUtc`, `updatedAtUtc = createdAtUtc`.
- A row that fails domain validation (`ValidationFailure`) is skipped and reported; positions and numbers are assigned only among valid rows, so there are no gaps.

- [ ] **Step 1: Write the failing tests**

Create `test/features/legacy_import/application/legacy_import_service_test.dart`:

```dart
import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
import 'package:dashboard_shakhsi/features/finance/data/drift_finance_repository.dart';
import 'package:dashboard_shakhsi/features/legacy_import/application/legacy_import_service.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/drift_legacy_import_ledger.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_parser.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

final class _FailingLedger implements LegacyImportLedger {
  _FailingLedger(this.inner, {required this.failOnCall});

  final LegacyImportLedger inner;
  final int failOnCall;
  int calls = 0;

  @override
  Future<Set<String>> importedIds(LegacyEntityType type) =>
      inner.importedIds(type);

  @override
  Future<bool> hasAnyRecords() => inner.hasAnyRecords();

  @override
  Future<void> record({
    required LegacyEntityType type,
    required LegacySourceKind sourceKind,
    required String v1Id,
    required String v2Id,
    required DateTime importedAtUtc,
    required String sourceSha256,
  }) {
    calls += 1;
    if (calls == failOnCall) throw StateError('injected ledger failure');
    return inner.record(
      type: type,
      sourceKind: sourceKind,
      v1Id: v1Id,
      v2Id: v2Id,
      importedAtUtc: importedAtUtc,
      sourceSha256: sourceSha256,
    );
  }
}

Future<LegacySnapshot> _parse(String name) async => const LegacyV1Parser()
    .parseBytes(await File('test/fixtures/legacy_v1/$name').readAsBytes());

void main() {
  final now = DateTime.utc(2026, 11, 4, 10);
  late AppDatabase database;
  late LegacySnapshot snapshot;

  setUpAll(() async {
    snapshot = await _parse('data_v1_2_desktop.json');
  });

  setUp(() {
    database = openTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  LegacyImportService buildService({LegacyImportLedger? ledger}) {
    return LegacyImportService(
      database: database,
      ledger: ledger ?? DriftLegacyImportLedger(database),
      clock: FixedAppClock(utcValue: now, localValue: now),
      idGenerator: SequenceIdGenerator(prefix: 'v2'),
    );
  }

  Future<int> count(String table) async {
    final row = await database
        .customSelect('SELECT COUNT(*) AS total FROM $table')
        .getSingle();
    return row.read<int>('total');
  }

  Future<Map<String, TaskRow>> tasksByTitle() async {
    final rows = await database.select(database.taskRows).get();
    return {for (final row in rows) row.title: row};
  }

  Future<void> expectContiguousPositions() async {
    final rows = await database.select(database.taskRows).get();
    final byStatus = <String, List<int>>{};
    for (final row in rows) {
      byStatus.putIfAbsent(row.status, () => <int>[]).add(row.positionInStatus);
    }
    for (final entry in byStatus.entries) {
      final positions = entry.value..sort();
      expect(
        positions,
        List<int>.generate(positions.length, (i) => i),
        reason: 'positions for ${entry.key} must be contiguous 0..n-1',
      );
    }
    final numbers = rows.map((r) => r.displayNumber).toSet();
    expect(numbers, hasLength(rows.length));
  }

  test('preview counts rows and writes nothing', () async {
    final service = buildService();

    final preview = await service.preview(snapshot);

    expect(preview.toImport, <LegacyEntityType, int>{
      LegacyEntityType.task: 4,
      LegacyEntityType.transaction: 2,
      LegacyEntityType.debt: 1,
      LegacyEntityType.installment: 1,
    });
    expect(preview.totalToImport, 8);
    expect(preview.alreadyImported.values.every((n) => n == 0), isTrue);
    expect(preview.skipped, isEmpty);
    expect(await count('tasks'), 0);
    expect(await count('legacy_imports'), 0);
  });

  test('execute imports everything with v1 order, numbers and dates', () async {
    final service = buildService();

    final report = await service.execute(snapshot);

    expect(report.imported, <LegacyEntityType, int>{
      LegacyEntityType.task: 4,
      LegacyEntityType.transaction: 2,
      LegacyEntityType.debt: 1,
      LegacyEntityType.installment: 1,
    });
    expect(report.totalImported, 8);

    final tasks = await tasksByTitle();
    // display_number: oldest created first.
    expect(tasks['ورزش']!.displayNumber, 1);
    expect(tasks['تماس با بانک']!.displayNumber, 2);
    expect(tasks['قبض برق']!.displayNumber, 3);
    expect(tasks['خرید نان']!.displayNumber, 4);
    // positions follow v1's visible order (sort "new" = created desc).
    expect(tasks['خرید نان']!.status, 'planned');
    expect(tasks['خرید نان']!.positionInStatus, 0);
    expect(tasks['تماس با بانک']!.positionInStatus, 1);
    expect(tasks['قبض برق']!.status, 'completed');
    expect(tasks['قبض برق']!.positionInStatus, 0);
    expect(tasks['ورزش']!.positionInStatus, 1);
    // done tasks complete at their created time.
    expect(tasks['قبض برق']!.completedAtUtc, tasks['قبض برق']!.createdAtUtc);
    expect(tasks['ورزش']!.completedAtUtc, tasks['ورزش']!.createdAtUtc);
    expect(tasks['خرید نان']!.completedAtUtc, isNull);
    expect(tasks['خرید نان']!.priority, 3);
    expect(
      tasks['خرید نان']!.createdAtUtc.millisecondsSinceEpoch ~/ 1000,
      1730640000,
    );
    await expectContiguousPositions();

    final finance = DriftFinanceRepository(database);
    final transactions = await finance.watchTransactions().first;
    expect(transactions, hasLength(2));
    expect(
      transactions.map((t) => t.amount.minorUnits).toSet(),
      <int>{2000000, 25000000},
    );
    expect(transactions.every((t) => t.amount.scale == 0), isTrue);
    // payments are NOT mirrored into finance_transactions.
    expect(await count('finance_transactions'), 2);

    final debt = (await finance.watchDebts().first).single;
    expect(debt.total.minorUnits, 10000000);
    expect(debt.paid.minorUnits, 2000000);
    expect(debt.createdAtUtc.millisecondsSinceEpoch ~/ 1000, 1730000000);
    expect(await count('debt_payments'), 1);

    final plan = (await finance.watchInstallmentPlans().first).single;
    expect(plan.perInstallment.minorUnits, 3500000);
    expect(plan.installmentCount, 12);
    expect(plan.paidCount, 4);
    expect(await count('installment_payments'), 4);

    expect(await count('legacy_imports'), 8);
    final hashes = await database
        .customSelect('SELECT DISTINCT source_sha256 AS h FROM legacy_imports')
        .get();
    expect(hashes.single.read<String>('h'), snapshot.sourceSha256);
  });

  test('re-running is idempotent and imports only new v1 records', () async {
    final service = buildService();
    await service.execute(snapshot);

    final again = await service.execute(snapshot);
    expect(again.totalImported, 0);
    expect(again.alreadyImported[LegacyEntityType.task], 4);
    expect(again.alreadyImported[LegacyEntityType.transaction], 2);
    expect(await count('tasks'), 4);
    expect(await count('finance_transactions'), 2);
    expect(await count('legacy_imports'), 8);

    final extended = LegacySnapshot(
      sourceKind: snapshot.sourceKind,
      sourceSha256: 'changed-file-hash',
      taskSort: snapshot.taskSort,
      tasks: <LegacyTask>[
        ...snapshot.tasks,
        LegacyTask(
          v1Id: 'added-later',
          title: 'کار جدید',
          done: false,
          priority: 1,
          createdAtUtc: DateTime.utc(2024, 12, 1),
        ),
      ],
      transactions: snapshot.transactions,
      debts: snapshot.debts,
      installments: snapshot.installments,
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );
    final preview = await service.preview(extended);
    expect(preview.toImport[LegacyEntityType.task], 1);
    expect(preview.alreadyImported[LegacyEntityType.task], 4);

    final third = await service.execute(extended);
    expect(third.imported[LegacyEntityType.task], 1);
    final tasks = await tasksByTitle();
    expect(tasks['کار جدید']!.displayNumber, 5);
    expect(tasks['کار جدید']!.positionInStatus, 2);
    await expectContiguousPositions();
  });

  test('importing into a database that already has v2 tasks', () async {
    final tasks = DriftTaskRepository(database);
    for (final id in <String>['existing-1', 'existing-2']) {
      await tasks.create(
        TaskItem(
          id: id,
          displayNumber: 99,
          title: 'موجود $id',
          priority: 0,
          status: TaskStatus.planned,
          positionInStatus: 99,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      );
    }

    await buildService().execute(snapshot);

    final byTitle = await tasksByTitle();
    expect(byTitle['موجود existing-1']!.displayNumber, 1);
    expect(byTitle['موجود existing-2']!.displayNumber, 2);
    expect(byTitle['ورزش']!.displayNumber, 3);
    expect(byTitle['تماس با بانک']!.displayNumber, 4);
    expect(byTitle['قبض برق']!.displayNumber, 5);
    expect(byTitle['خرید نان']!.displayNumber, 6);
    // planned: 2 existing rows keep 0 and 1; imported rows follow.
    expect(byTitle['موجود existing-1']!.positionInStatus, 0);
    expect(byTitle['خرید نان']!.positionInStatus, 2);
    expect(byTitle['تماس با بانک']!.positionInStatus, 3);
    expect(byTitle['قبض برق']!.positionInStatus, 0);
    expect(byTitle['ورزش']!.positionInStatus, 1);
    await expectContiguousPositions();
  });

  test('one failure rolls back every row', () async {
    final service = buildService(
      ledger: _FailingLedger(
        DriftLegacyImportLedger(database),
        failOnCall: 5,
      ),
    );

    await expectLater(
      service.execute(snapshot),
      throwsA(isA<ImportFailure>()),
    );

    for (final table in <String>[
      'tasks',
      'finance_transactions',
      'debts',
      'debt_payments',
      'installment_plans',
      'installment_payments',
      'legacy_imports',
    ]) {
      expect(await count(table), 0, reason: '$table must be rolled back');
    }
  });

  test('a row that fails domain validation is skipped, not fatal', () async {
    final bad = LegacySnapshot(
      sourceKind: LegacySourceKind.dataJson,
      sourceSha256: 'hash',
      taskSort: LegacyTaskSort.newest,
      tasks: const <LegacyTask>[],
      transactions: <LegacyTransaction>[
        LegacyTransaction(
          v1Id: 'tx-bad',
          title: '   ',
          category: 'سایر',
          isIncome: false,
          amountToman: 5,
          occurredAtUtc: now,
        ),
        LegacyTransaction(
          v1Id: 'tx-ok',
          title: 'خوب',
          category: 'سایر',
          isIncome: true,
          amountToman: 7,
          occurredAtUtc: now,
        ),
      ],
      debts: const <LegacyDebt>[],
      installments: const <LegacyInstallment>[],
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );
    final service = buildService();

    final preview = await service.preview(bad);
    expect(preview.toImport[LegacyEntityType.transaction], 1);
    expect(preview.skipped.single.reason, LegacySkipReason.failedValidation);

    final report = await service.execute(bad);
    expect(report.imported[LegacyEntityType.transaction], 1);
    expect(report.skipped.single.v1Id, 'tx-bad');
    expect(await count('finance_transactions'), 1);
  });

  test('the edge-case file imports without aborting', () async {
    final edge = await _parse('data_edge_cases.json');

    final report = await buildService().execute(edge);

    expect(report.imported[LegacyEntityType.task], 1);
    expect(report.imported[LegacyEntityType.transaction], 3);
    expect(report.imported[LegacyEntityType.debt], 1);
    expect(report.imported[LegacyEntityType.installment], 2);
    expect(report.skipped, hasLength(8));
    expect(await count('debt_payments'), 1);
    expect(await count('installment_payments'), 4);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH
cd /home/shabin/projects/personal/dashboard-shakhsi-rdf-t5   # your T5 worktree (from the merged G1 head)
flutter pub get
flutter test test/features/legacy_import/application/legacy_import_service_test.dart
```

Expected: compile errors (service, ledger and report do not exist).

- [ ] **Step 3: Write the preview and report models**

Create `lib/features/legacy_import/domain/legacy_import_report.dart`:

```dart
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';

final class LegacyImportPreview {
  const LegacyImportPreview({
    required this.toImport,
    required this.alreadyImported,
    required this.skipped,
    required this.warnings,
  });

  final Map<LegacyEntityType, int> toImport;
  final Map<LegacyEntityType, int> alreadyImported;
  final List<LegacySkippedRow> skipped;
  final List<LegacyWarning> warnings;

  int get totalToImport => toImport.values.fold(0, (sum, n) => sum + n);
}

final class LegacyImportReport {
  const LegacyImportReport({
    required this.imported,
    required this.alreadyImported,
    required this.skipped,
    required this.warnings,
  });

  final Map<LegacyEntityType, int> imported;
  final Map<LegacyEntityType, int> alreadyImported;
  final List<LegacySkippedRow> skipped;
  final List<LegacyWarning> warnings;

  int get totalImported => imported.values.fold(0, (sum, n) => sum + n);
}
```

- [ ] **Step 4: Write the ledger**

Create `lib/features/legacy_import/data/drift_legacy_import_ledger.dart`:

```dart
import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';

abstract interface class LegacyImportLedger {
  Future<Set<String>> importedIds(LegacyEntityType type);

  Future<void> record({
    required LegacyEntityType type,
    required LegacySourceKind sourceKind,
    required String v1Id,
    required String v2Id,
    required DateTime importedAtUtc,
    required String sourceSha256,
  });

  Future<bool> hasAnyRecords();
}

final class DriftLegacyImportLedger implements LegacyImportLedger {
  const DriftLegacyImportLedger(this._database);

  final AppDatabase _database;

  @override
  Future<Set<String>> importedIds(LegacyEntityType type) async {
    final rows = await (_database.select(
      _database.legacyImportRows,
    )..where((row) => row.entityType.equals(type.storageValue))).get();
    return <String>{for (final row in rows) row.v1Id};
  }

  @override
  Future<void> record({
    required LegacyEntityType type,
    required LegacySourceKind sourceKind,
    required String v1Id,
    required String v2Id,
    required DateTime importedAtUtc,
    required String sourceSha256,
  }) async {
    await _database
        .into(_database.legacyImportRows)
        .insert(
          LegacyImportRowsCompanion.insert(
            sourceKind: sourceKind.storageValue,
            entityType: type.storageValue,
            v1Id: v1Id,
            v2Id: v2Id,
            importedAtUtc: importedAtUtc,
            sourceSha256: sourceSha256,
          ),
        );
  }

  @override
  Future<bool> hasAnyRecords() async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM legacy_imports',
          readsFrom: {_database.legacyImportRows},
        )
        .getSingle();
    return row.read<int>('total') > 0;
  }
}
```

- [ ] **Step 5: Write the service**

Create `lib/features/legacy_import/application/legacy_import_service.dart`:

```dart
import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/data/drift_finance_repository.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/drift_legacy_import_ledger.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_import_report.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/drift.dart';

/// Plans, previews and executes a v1 import against one [AppDatabase].
///
/// [execute] runs inside a single database transaction: any failure rolls
/// back every row (tasks, finance rows and ledger rows alike).
final class LegacyImportService {
  LegacyImportService({
    required AppDatabase database,
    required LegacyImportLedger ledger,
    required AppClock clock,
    required IdGenerator idGenerator,
  }) : _database = database,
       _ledger = ledger,
       _clock = clock,
       _ids = idGenerator,
       _finance = DriftFinanceRepository(database, idGenerator: idGenerator);

  final AppDatabase _database;
  final LegacyImportLedger _ledger;
  final AppClock _clock;
  final IdGenerator _ids;
  final DriftFinanceRepository _finance;

  Future<LegacyImportPreview> preview(LegacySnapshot snapshot) async {
    final plan = await _plan(snapshot, newId: (v1Id) => v1Id);
    return LegacyImportPreview(
      toImport: plan.counts,
      alreadyImported: plan.alreadyImported,
      skipped: <LegacySkippedRow>[...snapshot.skipped, ...plan.skipped],
      warnings: snapshot.warnings,
    );
  }

  Future<LegacyImportReport> execute(LegacySnapshot snapshot) async {
    final importedAt = _clock.nowUtc();
    try {
      return await _database.transaction(() async {
        final plan = await _plan(snapshot, newId: (_) => _ids.next());

        for (final entry in plan.tasks) {
          await _insertTask(entry.item);
          await _record(
            LegacyEntityType.task,
            entry.v1Id,
            entry.item.id,
            snapshot,
            importedAt,
          );
        }
        for (final entry in plan.transactions) {
          await _finance.addTransaction(entry.item);
          await _record(
            LegacyEntityType.transaction,
            entry.v1Id,
            entry.item.id,
            snapshot,
            importedAt,
          );
        }
        for (final entry in plan.debts) {
          await _finance.addDebt(entry.item);
          await _record(
            LegacyEntityType.debt,
            entry.v1Id,
            entry.item.id,
            snapshot,
            importedAt,
          );
        }
        for (final entry in plan.installments) {
          await _finance.addInstallmentPlan(entry.item);
          await _record(
            LegacyEntityType.installment,
            entry.v1Id,
            entry.item.id,
            snapshot,
            importedAt,
          );
        }

        return LegacyImportReport(
          imported: plan.counts,
          alreadyImported: plan.alreadyImported,
          skipped: <LegacySkippedRow>[...snapshot.skipped, ...plan.skipped],
          warnings: snapshot.warnings,
        );
      });
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw ImportFailure(
        'ورود اطلاعات انجام نشد و هیچ تغییری ذخیره نشد.',
        cause: error,
      );
    }
  }

  Future<void> _record(
    LegacyEntityType type,
    String v1Id,
    String v2Id,
    LegacySnapshot snapshot,
    DateTime importedAt,
  ) {
    return _ledger.record(
      type: type,
      sourceKind: snapshot.sourceKind,
      v1Id: v1Id,
      v2Id: v2Id,
      importedAtUtc: importedAt,
      sourceSha256: snapshot.sourceSha256,
    );
  }

  /// Writes a task row directly. `DriftTaskRepository.create` would ignore
  /// the display number and position chosen by the planner.
  Future<void> _insertTask(TaskItem task) async {
    await _database
        .into(_database.taskRows)
        .insert(
          TaskRowsCompanion.insert(
            id: task.id,
            displayNumber: task.displayNumber,
            title: task.title,
            priority: task.priority,
            status: task.status.storageValue,
            positionInStatus: task.positionInStatus,
            createdAtUtc: task.createdAtUtc,
            updatedAtUtc: task.updatedAtUtc,
            completedAtUtc: Value<DateTime?>(task.completedAtUtc),
          ),
        );
  }

  // ---- planning (shared by preview and execute) ----

  Future<_ImportPlan> _plan(
    LegacySnapshot snapshot, {
    required String Function(String v1Id) newId,
  }) async {
    final plan = _ImportPlan();
    final fallback = snapshot.exportedAtUtc ?? _clock.nowUtc();

    await _planTasks(snapshot, plan, fallback, newId);

    final importedTransactions = await _ledger.importedIds(
      LegacyEntityType.transaction,
    );
    for (final tx in snapshot.transactions) {
      if (importedTransactions.contains(tx.v1Id)) {
        plan.markAlready(LegacyEntityType.transaction);
        continue;
      }
      try {
        final occurred = tx.occurredAtUtc ?? fallback;
        plan.transactions.add((
          v1Id: tx.v1Id,
          item: FinanceTransaction.create(
            id: newId(tx.v1Id),
            type: tx.isIncome
                ? FinanceTransactionType.income
                : FinanceTransactionType.expense,
            title: tx.title,
            category: tx.category,
            amount: _toman(tx.amountToman),
            occurredAtUtc: occurred,
            createdAtUtc: occurred,
          ),
        ));
      } on ValidationFailure {
        plan.fail(LegacyEntityType.transaction, tx.v1Id);
      }
    }

    final importedDebts = await _ledger.importedIds(LegacyEntityType.debt);
    for (final debt in snapshot.debts) {
      if (importedDebts.contains(debt.v1Id)) {
        plan.markAlready(LegacyEntityType.debt);
        continue;
      }
      try {
        final created = debt.createdAtUtc ?? fallback;
        plan.debts.add((
          v1Id: debt.v1Id,
          item: Debt(
            id: newId(debt.v1Id),
            title: debt.title,
            total: _toman(debt.totalToman),
            paid: _toman(debt.paidToman),
            createdAtUtc: created,
            updatedAtUtc: created,
          ),
        ));
      } on ValidationFailure {
        plan.fail(LegacyEntityType.debt, debt.v1Id);
      }
    }

    final importedInstallments = await _ledger.importedIds(
      LegacyEntityType.installment,
    );
    for (final installment in snapshot.installments) {
      if (importedInstallments.contains(installment.v1Id)) {
        plan.markAlready(LegacyEntityType.installment);
        continue;
      }
      try {
        final created = installment.createdAtUtc ?? fallback;
        plan.installments.add((
          v1Id: installment.v1Id,
          item: InstallmentPlan(
            id: newId(installment.v1Id),
            title: installment.title,
            perInstallment: _toman(installment.perToman),
            installmentCount: installment.count,
            paidCount: installment.paidCount,
            createdAtUtc: created,
            updatedAtUtc: created,
          ),
        ));
      } on ValidationFailure {
        plan.fail(LegacyEntityType.installment, installment.v1Id);
      }
    }

    return plan;
  }

  Future<void> _planTasks(
    LegacySnapshot snapshot,
    _ImportPlan plan,
    DateTime fallback,
    String Function(String v1Id) newId,
  ) async {
    final imported = await _ledger.importedIds(LegacyEntityType.task);
    final valid = <LegacyTask>[];
    for (final task in snapshot.tasks) {
      if (imported.contains(task.v1Id)) {
        plan.markAlready(LegacyEntityType.task);
        continue;
      }
      try {
        _buildTask(task, task.v1Id, 1, 0, fallback); // validation only
        valid.add(task);
      } on ValidationFailure {
        plan.fail(LegacyEntityType.task, task.v1Id);
      }
    }
    if (valid.isEmpty) return;

    DateTime createdOf(LegacyTask task) => task.createdAtUtc ?? fallback;

    // Display numbers: oldest first, continuing after the highest used one.
    final byAge = <LegacyTask>[...valid]
      ..sort((a, b) {
        final byDate = createdOf(a).compareTo(createdOf(b));
        return byDate != 0 ? byDate : a.v1Id.compareTo(b.v1Id);
      });
    final maxRow = await _database
        .customSelect(
          'SELECT COALESCE(MAX(display_number), 0) AS max_number FROM tasks',
          readsFrom: {_database.taskRows},
        )
        .getSingle();
    var nextNumber = maxRow.read<int>('max_number');
    final numbers = <String, int>{
      for (final task in byAge) task.v1Id: ++nextNumber,
    };

    // Positions: per status, after existing rows, in v1's visible order.
    final countRows = await _database
        .customSelect(
          'SELECT status, COUNT(*) AS total FROM tasks GROUP BY status',
          readsFrom: {_database.taskRows},
        )
        .get();
    final existing = <String, int>{
      for (final row in countRows)
        row.read<String>('status'): row.read<int>('total'),
    };

    for (final done in <bool>[false, true]) {
      final status = done ? TaskStatus.completed : TaskStatus.planned;
      final group = valid.where((task) => task.done == done).toList()
        ..sort((a, b) => _compareVisible(a, b, snapshot.taskSort, createdOf));
      var position = existing[status.storageValue] ?? 0;
      for (final task in group) {
        plan.tasks.add((
          v1Id: task.v1Id,
          item: _buildTask(
            task,
            newId(task.v1Id),
            numbers[task.v1Id]!,
            position++,
            fallback,
          ),
        ));
      }
    }
  }

  TaskItem _buildTask(
    LegacyTask task,
    String id,
    int displayNumber,
    int position,
    DateTime fallback,
  ) {
    final created = task.createdAtUtc ?? fallback;
    return TaskItem(
      id: id,
      displayNumber: displayNumber,
      title: task.title,
      priority: task.priority,
      status: task.done ? TaskStatus.completed : TaskStatus.planned,
      positionInStatus: position,
      createdAtUtc: created,
      updatedAtUtc: created,
      completedAtUtc: task.done ? created : null,
    );
  }

  /// v1's visible order inside one status. `alphabetical` falls back to a
  /// plain `String.compareTo` (v1 used JS `localeCompare("fa")`).
  int _compareVisible(
    LegacyTask a,
    LegacyTask b,
    LegacyTaskSort sort,
    DateTime Function(LegacyTask) createdOf,
  ) {
    int newest() {
      final byDate = createdOf(b).compareTo(createdOf(a));
      return byDate != 0 ? byDate : a.v1Id.compareTo(b.v1Id);
    }

    switch (sort) {
      case LegacyTaskSort.newest:
        return newest();
      case LegacyTaskSort.priority:
        final byPriority = b.priority.compareTo(a.priority);
        return byPriority != 0 ? byPriority : newest();
      case LegacyTaskSort.alphabetical:
        final byTitle = a.title.compareTo(b.title);
        return byTitle != 0 ? byTitle : newest();
    }
  }

  Money _toman(int value) => Money(
    minorUnits: value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );
}

final class _ImportPlan {
  final List<({String v1Id, TaskItem item})> tasks =
      <({String v1Id, TaskItem item})>[];
  final List<({String v1Id, FinanceTransaction item})> transactions =
      <({String v1Id, FinanceTransaction item})>[];
  final List<({String v1Id, Debt item})> debts = <({String v1Id, Debt item})>[];
  final List<({String v1Id, InstallmentPlan item})> installments =
      <({String v1Id, InstallmentPlan item})>[];
  final List<LegacySkippedRow> skipped = <LegacySkippedRow>[];
  final Map<LegacyEntityType, int> alreadyImported = <LegacyEntityType, int>{
    for (final type in LegacyEntityType.values) type: 0,
  };

  Map<LegacyEntityType, int> get counts => <LegacyEntityType, int>{
    LegacyEntityType.task: tasks.length,
    LegacyEntityType.transaction: transactions.length,
    LegacyEntityType.debt: debts.length,
    LegacyEntityType.installment: installments.length,
  };

  void markAlready(LegacyEntityType type) {
    alreadyImported[type] = (alreadyImported[type] ?? 0) + 1;
  }

  void fail(LegacyEntityType type, String v1Id) {
    skipped.add(
      LegacySkippedRow(
        entityType: type,
        v1Id: v1Id,
        reason: LegacySkipReason.failedValidation,
      ),
    );
  }
}
```

- [ ] **Step 6: Add the providers**

In `lib/core/providers/persistence_providers.dart` add these imports in alphabetical position among the `package:dashboard_shakhsi/...` imports:

```dart
import 'package:dashboard_shakhsi/features/legacy_import/application/legacy_import_service.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/drift_legacy_import_ledger.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_parser.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
```

and append at the end of the file:

```dart
final legacyV1ParserProvider = Provider<LegacyV1Parser>((ref) {
  return const LegacyV1Parser();
});

final legacyV1SourceLocatorProvider = Provider<LegacyV1SourceLocator>((ref) {
  return const LegacyV1SourceLocator();
});

final legacyImportLedgerProvider = Provider<LegacyImportLedger>((ref) {
  return DriftLegacyImportLedger(ref.watch(appDatabaseProvider));
});

final legacyImportServiceProvider = Provider<LegacyImportService>((ref) {
  return LegacyImportService(
    database: ref.watch(appDatabaseProvider),
    ledger: ref.watch(legacyImportLedgerProvider),
    clock: ref.watch(appClockProvider),
    idGenerator: const UuidV7IdGenerator(),
  );
});
```

- [ ] **Step 7: Run tests, analyze, format**

```bash
dart format lib test
flutter analyze
flutter test test/features/legacy_import test/core/providers
```

Expected: PASS, `No issues found`. If `nested transaction` inside `addDebt` misbehaves (it must not: Drift joins nested `transaction()` calls), the `one failure rolls back every row` test is the one that exposes it; do not work around it by removing the outer transaction.

- [ ] **Step 8: Commit**

```bash
git add lib/features/legacy_import/domain/legacy_import_report.dart lib/features/legacy_import/data/drift_legacy_import_ledger.dart lib/features/legacy_import/application/legacy_import_service.dart lib/core/providers/persistence_providers.dart test/features/legacy_import/application
git commit -m "feat: transactional idempotent v1 import service" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---
### Task 6: Import UI (Settings entry, preview and report dialogs, banner, file picker)

**Depends on:** Task 5 (service, providers). Files are disjoint from Task 4, so it may run in parallel with Task 4 if Task 4 is not merged yet.

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock` (re-add `file_picker: ^13.3.2`)
- Modify: `macos/Runner/DebugProfile.entitlements`, `macos/Runner/Release.entitlements`
- Create: `lib/features/legacy_import/application/legacy_file_picker.dart`
- Create: `lib/features/legacy_import/data/file_picker_legacy_file_picker.dart`
- Create: `lib/features/legacy_import/presentation/legacy_import_labels.dart`
- Create: `lib/features/legacy_import/presentation/legacy_import_providers.dart`
- Create: `lib/features/legacy_import/presentation/legacy_import_dialogs.dart`
- Create: `lib/features/legacy_import/presentation/legacy_import_flow.dart`
- Create: `lib/features/legacy_import/presentation/legacy_import_section.dart`
- Create: `lib/features/legacy_import/presentation/legacy_import_banner.dart`
- Create: `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/app/router/app_router.dart` (the `/settings` route)
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart` (settings island, banner)
- Test: `test/features/legacy_import/presentation/legacy_import_dialogs_test.dart`
- Test: `test/features/legacy_import/presentation/legacy_import_flow_test.dart`
- Test: `test/features/legacy_import/presentation/legacy_import_banner_test.dart`
- Modify: `test/features/dashboard/original_dashboard_screen_test.dart`, `test/features/dashboard/dashboard_chrome_glass_test.dart`

**Interfaces:**
- Consumes (Task 5): `legacyV1ParserProvider`, `legacyV1SourceLocatorProvider`, `legacyImportLedgerProvider`, `legacyImportServiceProvider`, `LegacyImportPreview`, `LegacyImportReport`, `LegacyImportLedger.hasAnyRecords()`. (Task 2): `LegacyV1SourceLocator`, `LegacyEntityType`, `LegacySkipReason`, `LegacyWarningCode`. Existing: `appDatabaseProvider`, `appClockProvider`, `OriginalGlass`, `OriginalPrimaryButton`, `OriginalGhostButton`, `OriginalPressable`, `OriginalPalette`, `AuroraBackground`, `AppleLiquidGlass`.
- Produces:
  - `abstract interface class LegacyFilePicker { Future<Uint8List?> pickJsonBytes(); }` and `legacyFilePickerProvider` (`Provider<LegacyFilePicker>`, default `FilePickerLegacyFilePicker`).
  - `legacyDetectedFileProvider` (`FutureProvider<File?>`), `legacyBannerFileProvider` (`FutureProvider<File?>`: the detected file only while `legacy_imports` is empty), `legacyBannerDismissedProvider` (`StateProvider<bool>`, session only).
  - `Future<void> runLegacyImportFlow({required BuildContext context, required WidgetRef ref, required Future<Uint8List?> Function() loadBytes})`.
  - Widgets `LegacyImportPreviewDialog({required LegacyImportPreview preview})` (pops `true` on confirm, `false` on cancel), `LegacyImportReportDialog({required LegacyImportReport report})`, `LegacyImportSection`, `LegacyImportBanner`, `SettingsScreen({required VoidCallback onBack})`.
  - Widget keys used by tests: `legacy-import-pick-file`, `legacy-import-use-detected`, `legacy-import-confirm`, `legacy-import-cancel`, `legacy-import-close`, `legacy-nothing-new`, `legacy-issues`, `legacy-count-<entity>`, `legacy-count-already-<entity>`, `legacy-report-count-<entity>`, `legacy-banner-import`, `legacy-banner-dismiss`, `dashboard-settings-button`, `settings-back`.

- [ ] **Step 1: Re-add `file_picker` and the macOS entitlement**

```bash
export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH
cd /home/shabin/projects/personal/dashboard-shakhsi-rdf-t6   # your T6 worktree (from the merged head with Task 5)
flutter pub add file_picker:^13.3.2
git diff --stat -- pubspec.yaml pubspec.lock
flutter pub get --enforce-lockfile
```

Expected: `pubspec.yaml` gains `file_picker: ^13.3.2`; `pubspec.lock` adds `file_picker 13.3.2`, `file_picker_darwin`, `file_picker_linux`, `file_picker_platform_interface`, `file_picker_web`, `android_file_picker`, `windows_file_picker`, `cross_file`, `ffi_leak_tracker`, and moves `win32` 5.15.0 to 6.4.0 and `flutter_secure_storage_windows` 4.1.0 to 4.2.2 (a dry run before this plan showed exactly these 11 changes). The last command must succeed (CI uses `--enforce-lockfile`). The v13 API is `FilePicker.pickFile(...)` returning `PlatformFile?` with `readAsBytes()` (static; there is no `FilePicker.platform`). Linux needs `zenity` or `kdialog` at runtime for the dialog.

In BOTH `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`, replace

```xml
	<key>com.apple.security.app-sandbox</key>
	<true/>
```

with

```xml
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-only</key>
	<true/>
```

(`DebugProfile.entitlements` has other keys after the sandbox one; keep them.)

- [ ] **Step 2: Write the failing dialog tests**

Create `test/features/legacy_import/presentation/legacy_import_dialogs_test.dart`:

```dart
import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_import_report.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<LegacyEntityType, int> _counts({
  int task = 0,
  int transaction = 0,
  int debt = 0,
  int installment = 0,
}) => <LegacyEntityType, int>{
  LegacyEntityType.task: task,
  LegacyEntityType.transaction: transaction,
  LegacyEntityType.debt: debt,
  LegacyEntityType.installment: installment,
};

Widget _host(void Function(BuildContext) onOpen) {
  return MaterialApp(
    theme: OriginalTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey<String>('open'),
              onPressed: () => onOpen(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('open')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;

void main() {
  testWidgets('preview shows counts, already-imported and skipped rows', (
    tester,
  ) async {
    bool? confirmed;
    final preview = LegacyImportPreview(
      toImport: _counts(task: 4, transaction: 2, debt: 1, installment: 1),
      alreadyImported: _counts(task: 3),
      skipped: const <LegacySkippedRow>[
        LegacySkippedRow(
          entityType: LegacyEntityType.task,
          v1Id: 'x',
          reason: LegacySkipReason.emptyTitle,
        ),
      ],
      warnings: const <LegacyWarning>[
        LegacyWarning(code: LegacyWarningCode.financeUnreadable),
      ],
    );

    await tester.pumpWidget(
      _host((context) async {
        confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => LegacyImportPreviewDialog(preview: preview),
        );
      }),
    );
    await _pumpDialog(tester);

    expect(_text(tester, 'legacy-count-task'), '۴');
    expect(_text(tester, 'legacy-count-transaction'), '۲');
    expect(_text(tester, 'legacy-count-debt'), '۱');
    expect(_text(tester, 'legacy-count-installment'), '۱');
    expect(_text(tester, 'legacy-count-already-task'), contains('۳'));
    expect(find.text('کار: عنوان خالی (۱)'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('legacy-issues')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(confirmed, isTrue);
  });

  testWidgets('cancel returns false', (tester) async {
    bool? confirmed;
    final preview = LegacyImportPreview(
      toImport: _counts(task: 1),
      alreadyImported: _counts(),
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );

    await tester.pumpWidget(
      _host((context) async {
        confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => LegacyImportPreviewDialog(preview: preview),
        );
      }),
    );
    await _pumpDialog(tester);
    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(confirmed, isFalse);
  });

  testWidgets('nothing new hides the confirm button', (tester) async {
    final preview = LegacyImportPreview(
      toImport: _counts(),
      alreadyImported: _counts(task: 4),
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );

    await tester.pumpWidget(
      _host((context) {
        showDialog<bool>(
          context: context,
          builder: (_) => LegacyImportPreviewDialog(preview: preview),
        );
      }),
    );
    await _pumpDialog(tester);

    expect(
      find.byKey(const ValueKey<String>('legacy-nothing-new')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('legacy-import-confirm')),
      findsNothing,
    );
  });

  testWidgets('report shows what was imported', (tester) async {
    final report = LegacyImportReport(
      imported: _counts(task: 4, transaction: 2),
      alreadyImported: _counts(),
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );

    await tester.pumpWidget(
      _host((context) {
        showDialog<void>(
          context: context,
          builder: (_) => LegacyImportReportDialog(report: report),
        );
      }),
    );
    await _pumpDialog(tester);

    expect(_text(tester, 'legacy-report-count-task'), '۴');
    expect(_text(tester, 'legacy-report-count-transaction'), '۲');
    expect(
      find.byKey(const ValueKey<String>('legacy-import-close')),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 3: Write the failing flow and banner tests**

Create `test/features/legacy_import/presentation/legacy_import_flow_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/legacy_import/application/legacy_file_picker.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:dashboard_shakhsi/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

final class _FakePicker implements LegacyFilePicker {
  _FakePicker(this.bytes);

  final Uint8List? bytes;

  @override
  Future<Uint8List?> pickJsonBytes() async => bytes;
}

void main() {
  late Uint8List fixtureBytes;

  setUpAll(() async {
    fixtureBytes = await File(
      'test/fixtures/legacy_v1/data_v1_2_desktop.json',
    ).readAsBytes();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<AppDatabase> pumpSettings(
    WidgetTester tester, {
    required LegacyFilePicker picker,
  }) async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 11, 4, 10);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          appClockProvider.overrideWithValue(
            FixedAppClock(utcValue: now, localValue: now),
          ),
          legacyFilePickerProvider.overrideWithValue(picker),
          legacyV1SourceLocatorProvider.overrideWithValue(
            const LegacyV1SourceLocator(
              operatingSystem: 'android',
              environment: <String, String>{},
            ),
          ),
        ],
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SettingsScreen(onBack: () {}),
          ),
        ),
      ),
    );
    await settle(tester);
    return database;
  }

  testWidgets('pick, preview, confirm and report import the file', (
    tester,
  ) async {
    final database = await pumpSettings(
      tester,
      picker: _FakePicker(fixtureBytes),
    );

    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-pick-file')));
    await settle(tester);

    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('legacy-count-task'))).data,
      '۴',
    );

    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-confirm')));
    await settle(tester);

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('legacy-report-count-task')),
          )
          .data,
      '۴',
    );
    final tasks = await database.select(database.taskRows).get();
    expect(tasks, hasLength(4));

    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-close')));
    await settle(tester);
  });

  testWidgets('cancelling the preview writes nothing', (tester) async {
    final database = await pumpSettings(
      tester,
      picker: _FakePicker(fixtureBytes),
    );

    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-pick-file')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-cancel')));
    await settle(tester);

    expect(await database.select(database.taskRows).get(), isEmpty);
    expect(await database.select(database.legacyImportRows).get(), isEmpty);
  });

  testWidgets('an unreadable file shows a message and writes nothing', (
    tester,
  ) async {
    final database = await pumpSettings(
      tester,
      picker: _FakePicker(Uint8List.fromList(<int>[0x7b, 0x22])),
    );

    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-pick-file')));
    await settle(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(await database.select(database.taskRows).get(), isEmpty);
  });

  testWidgets('a cancelled picker does nothing', (tester) async {
    final database = await pumpSettings(tester, picker: _FakePicker(null));

    await tester.tap(find.byKey(const ValueKey<String>('legacy-import-pick-file')));
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(await database.select(database.taskRows).get(), isEmpty);
  });
}
```

Create `test/features/legacy_import/presentation/legacy_import_banner_test.dart`:

```dart
import 'dart:io';

import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_banner.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rdf-banner-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<ProviderContainer> pumpBanner(
    WidgetTester tester, {
    required bool fileExists,
    bool alreadyImported = false,
  }) async {
    if (fileExists) {
      final file = File('${directory.path}/dashboard-shakhsi/data.json');
      await tester.runAsync(() async {
        await file.create(recursive: true);
        await file.writeAsString('{}');
      });
    }
    final database = openTestDatabase();
    addTearDown(database.close);
    if (alreadyImported) {
      await database
          .into(database.legacyImportRows)
          .insert(
            LegacyImportRowsCompanion.insert(
              sourceKind: LegacySourceKind.dataJson.storageValue,
              entityType: 'task',
              v1Id: 'seen',
              v2Id: 'v2-seen',
              importedAtUtc: DateTime.utc(2026, 11, 4),
              sourceSha256: 'hash',
            ),
          );
    }

    final container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        legacyV1SourceLocatorProvider.overrideWithValue(
          LegacyV1SourceLocator(
            operatingSystem: 'linux',
            environment: <String, String>{'XDG_DATA_HOME': directory.path},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Real file IO must complete outside the fake-async zone.
    await tester.runAsync(() => container.read(legacyBannerFileProvider.future));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: LegacyImportBanner()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    return container;
  }

  testWidgets('shows when a v1 file exists and nothing was imported', (
    tester,
  ) async {
    await pumpBanner(tester, fileExists: true);

    expect(
      find.byKey(const ValueKey<String>('legacy-banner-import')),
      findsOneWidget,
    );
  });

  testWidgets('hidden when no v1 file is found', (tester) async {
    await pumpBanner(tester, fileExists: false);

    expect(
      find.byKey(const ValueKey<String>('legacy-banner-import')),
      findsNothing,
    );
  });

  testWidgets('hidden once something was imported', (tester) async {
    await pumpBanner(tester, fileExists: true, alreadyImported: true);

    expect(
      find.byKey(const ValueKey<String>('legacy-banner-import')),
      findsNothing,
    );
  });

  testWidgets('later hides it for the session', (tester) async {
    final container = await pumpBanner(tester, fileExists: true);

    await tester.tap(find.byKey(const ValueKey<String>('legacy-banner-dismiss')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(container.read(legacyBannerDismissedProvider), isTrue);
    expect(
      find.byKey(const ValueKey<String>('legacy-banner-import')),
      findsNothing,
    );
  });
}
```


- [ ] **Step 4: Run to verify they fail**

```bash
flutter test test/features/legacy_import/presentation
```

Expected: compile errors (the presentation files do not exist).

- [ ] **Step 5: Picker interface and adapter**

Create `lib/features/legacy_import/application/legacy_file_picker.dart`:

```dart
import 'dart:typed_data';

abstract interface class LegacyFilePicker {
  /// Lets the user pick a v1 `.json` file and returns its bytes, or `null`
  /// when the dialog was cancelled.
  Future<Uint8List?> pickJsonBytes();
}
```

Create `lib/features/legacy_import/data/file_picker_legacy_file_picker.dart` (the only file that imports `file_picker`):

```dart
import 'dart:typed_data';

import 'package:dashboard_shakhsi/features/legacy_import/application/legacy_file_picker.dart';
import 'package:file_picker/file_picker.dart';

final class FilePickerLegacyFilePicker implements LegacyFilePicker {
  const FilePickerLegacyFilePicker();

  @override
  Future<Uint8List?> pickJsonBytes() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'انتخاب فایل داده نسخه ۱',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
```

- [ ] **Step 6: Labels and providers**

Create `lib/features/legacy_import/presentation/legacy_import_labels.dart`:

```dart
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';

String legacyDigits(int value) => Money.toPersianDigits('$value');

String legacyEntityLabel(LegacyEntityType type) => switch (type) {
  LegacyEntityType.task => 'کار',
  LegacyEntityType.transaction => 'تراکنش',
  LegacyEntityType.debt => 'بدهی',
  LegacyEntityType.installment => 'قسط',
};

String legacySkipReasonLabel(LegacySkipReason reason) => switch (reason) {
  LegacySkipReason.notAnObject => 'ساختار رکورد نامعتبر',
  LegacySkipReason.emptyTitle => 'عنوان خالی',
  LegacySkipReason.duplicateId => 'شناسه تکراری',
  LegacySkipReason.invalidAmount => 'مبلغ نامعتبر',
  LegacySkipReason.invalidCount => 'تعداد نامعتبر',
  LegacySkipReason.totalOverflow => 'مجموع اقساط بیش از حد مجاز',
  LegacySkipReason.failedValidation => 'رد شده در اعتبارسنجی',
};

String legacyWarningLabel(LegacyWarningCode code) => switch (code) {
  LegacyWarningCode.tasksUnreadable => 'فهرست کارها خوانده نشد',
  LegacyWarningCode.financeUnreadable => 'داده‌های مالی خوانده نشد',
  LegacyWarningCode.unknownTransactionType =>
    'نوع تراکنش ناشناخته بود و به‌عنوان هزینه وارد شد',
  LegacyWarningCode.paidClamped => 'مبلغ پرداخت‌شده به کل بدهی محدود شد',
  LegacyWarningCode.paidCountClamped => 'تعداد اقساط پرداخت‌شده محدود شد',
};
```

Create `lib/features/legacy_import/presentation/legacy_import_providers.dart`:

```dart
import 'dart:io';

import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/legacy_import/application/legacy_file_picker.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/file_picker_legacy_file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final legacyFilePickerProvider = Provider<LegacyFilePicker>((ref) {
  return const FilePickerLegacyFilePicker();
});

/// v1's `data.json` on this desktop, if it exists.
final legacyDetectedFileProvider = FutureProvider<File?>((ref) {
  return ref.watch(legacyV1SourceLocatorProvider).detect();
});

/// The detected file, but only while nothing has been imported yet.
final legacyBannerFileProvider = FutureProvider<File?>((ref) async {
  final file = await ref.watch(legacyDetectedFileProvider.future);
  if (file == null) return null;
  final imported = await ref.watch(legacyImportLedgerProvider).hasAnyRecords();
  return imported ? null : file;
});

/// "Later" on the banner. Session only: no settings store exists yet.
final legacyBannerDismissedProvider = StateProvider<bool>((ref) => false);
```

- [ ] **Step 7: Dialogs**

Create `lib/features/legacy_import/presentation/legacy_import_dialogs.dart`:

```dart
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_import_report.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_labels.dart';
import 'package:flutter/material.dart';

final class LegacyImportPreviewDialog extends StatelessWidget {
  const LegacyImportPreviewDialog({required this.preview, super.key});

  final LegacyImportPreview preview;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('پیش‌نمایش ورود اطلاعات'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final type in LegacyEntityType.values)
                _CountRow(
                  keyPrefix: 'legacy-count',
                  type: type,
                  count: preview.toImport[type] ?? 0,
                  already: preview.alreadyImported[type] ?? 0,
                ),
              if (preview.totalToImport == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'چیز جدیدی برای ورود وجود ندارد.',
                    key: ValueKey<String>('legacy-nothing-new'),
                  ),
                ),
              _IssueList(skipped: preview.skipped, warnings: preview.warnings),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('legacy-import-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('انصراف'),
        ),
        if (preview.totalToImport > 0)
          FilledButton(
            key: const ValueKey<String>('legacy-import-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ورود اطلاعات'),
          ),
      ],
    );
  }
}

final class LegacyImportReportDialog extends StatelessWidget {
  const LegacyImportReportDialog({required this.report, super.key});

  final LegacyImportReport report;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('نتیجه ورود اطلاعات'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final type in LegacyEntityType.values)
                _CountRow(
                  keyPrefix: 'legacy-report-count',
                  type: type,
                  count: report.imported[type] ?? 0,
                  already: report.alreadyImported[type] ?? 0,
                ),
              _IssueList(skipped: report.skipped, warnings: report.warnings),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        FilledButton(
          key: const ValueKey<String>('legacy-import-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('بستن'),
        ),
      ],
    );
  }
}

final class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.keyPrefix,
    required this.type,
    required this.count,
    required this.already,
  });

  final String keyPrefix;
  final LegacyEntityType type;
  final int count;
  final int already;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(legacyEntityLabel(type))),
          Text(
            legacyDigits(count),
            key: ValueKey<String>('$keyPrefix-${type.name}'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (already > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Text(
                '(${legacyDigits(already)} قبلاً وارد شده)',
                key: ValueKey<String>('$keyPrefix-already-${type.name}'),
              ),
            ),
        ],
      ),
    );
  }
}

final class _IssueList extends StatelessWidget {
  const _IssueList({required this.skipped, required this.warnings});

  final List<LegacySkippedRow> skipped;
  final List<LegacyWarning> warnings;

  @override
  Widget build(BuildContext context) {
    if (skipped.isEmpty && warnings.isEmpty) return const SizedBox.shrink();

    final skippedCounts = <(LegacyEntityType, LegacySkipReason), int>{};
    for (final row in skipped) {
      final key = (row.entityType, row.reason);
      skippedCounts[key] = (skippedCounts[key] ?? 0) + 1;
    }
    final warningCounts = <LegacyWarningCode, int>{};
    for (final warning in warnings) {
      warningCounts[warning.code] = (warningCounts[warning.code] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        key: const ValueKey<String>('legacy-issues'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'ردیف‌های ردشده و هشدارها',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          for (final entry in skippedCounts.entries)
            Text(
              '${legacyEntityLabel(entry.key.$1)}: '
              '${legacySkipReasonLabel(entry.key.$2)} '
              '(${legacyDigits(entry.value)})',
            ),
          for (final entry in warningCounts.entries)
            Text('${legacyWarningLabel(entry.key)} (${legacyDigits(entry.value)})'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: The flow, the Settings section, the banner, the Settings screen**

Create `lib/features/legacy_import/presentation/legacy_import_flow.dart`:

```dart
import 'dart:typed_data';

import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_dialogs.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Load bytes, parse, preview, confirm, import in one transaction, report.
/// Failures show a snackbar; nothing is written unless the user confirms.
Future<void> runLegacyImportFlow({
  required BuildContext context,
  required WidgetRef ref,
  required Future<Uint8List?> Function() loadBytes,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final bytes = await loadBytes();
    if (bytes == null) return;

    final snapshot = await ref.read(legacyV1ParserProvider).parseBytes(bytes);
    final service = ref.read(legacyImportServiceProvider);
    final preview = await service.preview(snapshot);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => LegacyImportPreviewDialog(preview: preview),
    );
    if (confirmed != true) return;

    final report = await service.execute(snapshot);
    ref.invalidate(legacyBannerFileProvider);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => LegacyImportReportDialog(report: report),
    );
  } on AppFailure catch (failure) {
    messenger?.showSnackBar(SnackBar(content: Text(failure.userMessage)));
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('خواندن یا ورود فایل انجام نشد.')),
    );
  }
}
```

Create `lib/features/legacy_import/presentation/legacy_import_section.dart`:

```dart
import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/original_controls.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_flow.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class LegacyImportSection extends ConsumerWidget {
  const LegacyImportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = OriginalPalette.of(context);
    final detected = ref.watch(legacyDetectedFileProvider).asData?.value;
    final picker = ref.watch(legacyFilePickerProvider);

    return OriginalGlass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ورود اطلاعات از نسخه ۱',
            style: TextStyle(
              color: palette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'فایل data.json نسخه ۱ یا فایل خروجی JSON آن را انتخاب کنید. '
            'پیش از ورود، پیش‌نمایش را می‌بینید و فایل شما تغییر نمی‌کند.',
            style: TextStyle(color: palette.muted, fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              if (detected != null)
                OriginalPrimaryButton(
                  key: const ValueKey<String>('legacy-import-use-detected'),
                  label: 'بررسی فایل پیدا‌شده',
                  onPressed: () => runLegacyImportFlow(
                    context: context,
                    ref: ref,
                    loadBytes: detected.readAsBytes,
                  ),
                ),
              OriginalGhostButton(
                key: const ValueKey<String>('legacy-import-pick-file'),
                label: 'انتخاب فایل داده',
                icon: Icons.folder_open_outlined,
                onPressed: () => runLegacyImportFlow(
                  context: context,
                  ref: ref,
                  loadBytes: picker.pickJsonBytes,
                ),
              ),
            ],
          ),
          if (detected != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              detected.path,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: palette.faint, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
```

Create `lib/features/legacy_import/presentation/legacy_import_banner.dart`:

```dart
import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_flow.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Offers the import once: only while a v1 file was auto-detected and the
/// ledger is empty. "Later" hides it for the current session.
final class LegacyImportBanner extends ConsumerWidget {
  const LegacyImportBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(legacyBannerDismissedProvider)) {
      return const SizedBox.shrink();
    }
    final file = ref.watch(legacyBannerFileProvider).asData?.value;
    if (file == null) return const SizedBox.shrink();

    final palette = OriginalPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OriginalGlass(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(Icons.download_outlined, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'فایل داده‌های نسخه ۱ روی این دستگاه پیدا شد. وارد شود؟',
                style: TextStyle(color: palette.ink, fontSize: 13.5),
              ),
            ),
            TextButton(
              key: const ValueKey<String>('legacy-banner-dismiss'),
              onPressed: () =>
                  ref.read(legacyBannerDismissedProvider.notifier).state = true,
              child: const Text('بعداً'),
            ),
            FilledButton(
              key: const ValueKey<String>('legacy-banner-import'),
              onPressed: () => runLegacyImportFlow(
                context: context,
                ref: ref,
                loadBytes: file.readAsBytes,
              ),
              child: const Text('ورود'),
            ),
          ],
        ),
      ),
    );
  }
}
```

Create `lib/features/settings/presentation/settings_screen.dart`:

```dart
import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/aurora_background.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_section.dart';
import 'package:flutter/material.dart';

final class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              OriginalDesignTokens.pageHorizontalPadding,
              OriginalDesignTokens.pageTopPadding,
              OriginalDesignTokens.pageHorizontalPadding,
              OriginalDesignTokens.pageBottomPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: OriginalDesignTokens.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          key: const ValueKey<String>('settings-back'),
                          tooltip: 'بازگشت',
                          onPressed: onBack,
                          icon: Icon(Icons.arrow_forward, color: palette.ink),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تنظیمات',
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const LegacyImportSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

(`OriginalPalette` lives in `original_design_tokens.dart`; `OriginalDesignTokens.pageHorizontalPadding`, `pageTopPadding`, `pageBottomPadding`, `contentMaxWidth` are the constants `dashboard_screen.dart` already uses.)

- [ ] **Step 9: Wire the route and the dashboard**

In `lib/app/router/app_router.dart` add `import 'package:dashboard_shakhsi/features/settings/presentation/settings_screen.dart';` (alphabetical) and replace the settings route:

```dart
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => SettingsScreen(
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
```

(`/migration` stays a placeholder; the import lives in Settings per the spec.)

In `lib/features/dashboard/presentation/dashboard_screen.dart`:
1. Add `import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_banner.dart';` (alphabetical).
2. In `_DashboardScreenState.build`, pass the new callback to `_TopBar` and insert the banner right after it:

```dart
                    _TopBar(
                      selectedPanel: _selectedPanel,
                      onPanelSelected: (value) {
                        setState(() => _selectedPanel = value);
                      },
                      onThemePressed: () => _toggleTheme(context),
                      onSettingsPressed: () =>
                          GoRouter.maybeOf(context)?.push('/settings'),
                    ),
                    const LegacyImportBanner(),
```

(`'/settings'` is a literal like the existing `'/debug/glass-review'`; importing `AppRoutes` would be circular.)
3. In `_TopBar` add the field and constructor parameter `required this.onSettingsPressed` (`final VoidCallback onSettingsPressed;`), and replace `final theme = _ThemeIsland(onPressed: onThemePressed);` with:

```dart
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: <Widget>[
              _SettingsIsland(onPressed: onSettingsPressed),
              const SizedBox(width: 8),
              _ThemeIsland(onPressed: onThemePressed),
            ],
          );
```

then use `actions` instead of `theme` in BOTH `children: <Widget>[brand, tabs, theme]` lists.
4. Add the island widget after `_ThemeIsland`:

```dart
final class _SettingsIsland extends StatelessWidget {
  const _SettingsIsland({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return AppleLiquidGlass(
      role: AppleGlassRole.smallControl,
      shape: const AppleGlassShape.circle(),
      child: OriginalPressable(
        key: const ValueKey<String>('dashboard-settings-button'),
        onPressed: onPressed,
        pressedScale: .92,
        borderRadius: BorderRadius.circular(OriginalDesignTokens.pillRadius),
        semanticLabel: 'تنظیمات',
        child: SizedBox.square(
          dimension: 42,
          child: Center(
            child: Icon(Icons.settings_outlined, color: palette.ink, size: 20),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 10: Keep the existing dashboard tests deterministic**

The banner reads the real home directory by default, so every test that pumps `DashboardScreen` must override the locator. In `test/features/dashboard/original_dashboard_screen_test.dart` and `test/features/dashboard/dashboard_chrome_glass_test.dart` change the overrides to

```dart
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          legacyV1SourceLocatorProvider.overrideWithValue(
            const LegacyV1SourceLocator(
              operatingSystem: 'android',
              environment: <String, String>{},
            ),
          ),
        ],
```

adding `import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';`. In `dashboard_chrome_glass_test.dart` the top bar now has a fourth glass island: change `findsNWidgets(3)` to `findsNWidgets(4)`. Add this test to `original_dashboard_screen_test.dart` (inside `main()`):

```dart
  testWidgets('the top bar has a settings button', (tester) async {
    final database = openTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          legacyV1SourceLocatorProvider.overrideWithValue(
            const LegacyV1SourceLocator(
              operatingSystem: 'android',
              environment: <String, String>{},
            ),
          ),
        ],
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: DashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey<String>('dashboard-settings-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
```

- [ ] **Step 11: Run tests, analyze, format**

```bash
dart format lib test
flutter analyze
flutter test test/features/legacy_import test/features/dashboard test/app
```

Expected: PASS, `No issues found`. If the flow test hangs on a database call inside the fake-async zone, wrap the awaited service call in the test with `tester.runAsync`; do not change production code for that. Run the app once to see the screen: `flutter run -d linux`, tap the gear in the top bar, pick `test/fixtures/legacy_v1/data_v1_2_desktop.json`, confirm the preview counts (4 / 2 / 1 / 1), import, and re-run to see "already imported".

- [ ] **Step 12: Commit**

```bash
git add pubspec.yaml pubspec.lock macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements lib/features/legacy_import lib/features/settings lib/app/router/app_router.dart lib/features/dashboard/presentation/dashboard_screen.dart test/features/legacy_import/presentation test/features/dashboard
git commit -m "feat: import v1 data from Settings with preview, report and banner" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Full verification, checkpoint, roadmap, worklog, push

**Depends on:** Tasks 1 to 6 all merged into `feat/v2-complete-dashboard` (G4).

**Files:**
- Create: `docs/superpowers/checkpoints/2026-11-04-release-data-foundation-checkpoint.md`
- Modify: `PROJECT_ROADMAP.md` (header, section 0 item 3, section 3.2, section 14)
- Modify: `docs/WORKLOG.md`

- [ ] **Step 1: Run the full CI locally on the merged head**

```bash
export PATH=/home/shabin/develop/flutter-3.47.5/bin:$PATH
cd /home/shabin/projects/personal/dashboard-shakhsi-v2-integration
git status --short
tool/ci.sh
```

Expected: `==> all checks passed` (pub get with enforced lockfile, format, generated code current, analyze, full test suite, `flutter build linux --release`). Note the test count printed by `flutter test` (at least 1310 plus the new tests). If anything fails, fix it on the branch with a focused commit before continuing; do not edit docs until CI is green.

- [ ] **Step 2: Real-device sanity check of the Linux build**

```bash
flutter run -d linux
```

Verify by hand: the gear opens Settings; picking `test/fixtures/legacy_v1/export_tasks.json` and `export_finance.json` previews and imports; the finance panel shows whole-toman amounts with no decimal point in the input; re-importing the same file reports "already imported". Close the app. (Do not use any real v1 data.)

- [ ] **Step 3: Write the checkpoint**

Create `docs/superpowers/checkpoints/2026-11-04-release-data-foundation-checkpoint.md` with this structure, filling every value from real command output (no guesses):

```markdown
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
<paste `git log --oneline <base>..HEAD` for the feature commits, where <base> is the commit before Task 1 (`658e744`)>

## Evidence
- `tool/ci.sh` on the merged head: <paste the final lines, including the test count>.
- GitHub Actions run for the pushed head: <URL and conclusion, filled in after Step 6>.
- Migration and restart tests: `test/core/database/finance_scale_migration_test.dart` (schema 8 to 9, restart, uniqueness of `legacy_imports`), plus every older migration test bumped to schema 9.
- Importer tests: `test/features/legacy_import/` (parser fixtures, preview, idempotency, existing-v2-data numbering, rollback on failure, skipped rows).

## Decisions that differ from the spec
<copy the "Spec decisions this plan resolves or amends" list from the plan, items 1-11>

## Known limitations
- Importing an export file and `data.json` of the same data duplicates rows (exports have no ids).
- Re-import never updates existing rows.
- The out-of-range notice replaces the whole finance panel while a sum overflows (needs more than 9.2e18 toman).
- The Linux file dialog needs `zenity` or `kdialog`; auto-detect works without it.
- Android has no auto-detect; macOS sandbox hides v1's folder, so both import manually.
- Banner dismissal is per session.

## Not done (out of scope per spec)
Packaging, signing and release automation (part B); product name (part C); habits and goals; Tasks 2.9+.
```

- [ ] **Step 4: Update the roadmap**

In `PROJECT_ROADMAP.md`:
1. Header: change `Current database schema: **8**` to `Current database schema: **9**`; update `Last updated` if it is not 2026-11-04.
2. Section 0, item 3: keep the item and append ` Part A (data foundation: whole-toman money, checked arithmetic, v1 importer) — **DONE** (2026-11-04, checkpoint: docs/superpowers/checkpoints/2026-11-04-release-data-foundation-checkpoint.md). Remaining: part B (packaging, release automation, Android signing continuity) and part C (product name).`
3. Section 3.2: change `- Current schema version is **8**.` to `- Current schema version is **9**.` and add the bullet `- Release data foundation moved schema append-only from **8** to **9** (IRT rescaled to whole toman, \`legacy_imports\` added).`
4. Section 14: change `- Repository schema is **8**.` to `- Repository schema is **9**.`, and replace the bullet `- v1 (published on GitHub, v1.2.0) stores data in \`data.json\`; v2 has no importer yet. This blocks the v2 release.` with `- v1 data import is implemented (2026-11-04): Settings, then "Import from v1" (preview, one transaction, idempotent via \`legacy_imports\`). Release still needs part B (packaging) and part C (product name).` Add one bullet: `- IRT money is whole toman (scale 0, schema 9); \`Money\` arithmetic is overflow-checked.`

- [ ] **Step 5: Add the worklog entry**

In `docs/WORKLOG.md`, insert directly above the line `## 2026-11-04 — Liquid Glass adoption implemented` (newest first):

```markdown
## 2026-11-04 — Release data foundation implemented
- **Type:** implemented
- **What:** checked `Money` arithmetic; schema 9 (IRT scale 0, `legacy_imports`); v1 `data.json` and export importer with preview, one transaction and idempotency; Settings entry, banner, `file_picker`.
- **Evidence / links:** checkpoint `docs/superpowers/checkpoints/2026-11-04-release-data-foundation-checkpoint.md`; spec `docs/superpowers/specs/2026-11-04-release-data-foundation-design.md`; plan `docs/superpowers/plans/2026-11-04-release-data-foundation.md`; commits <short SHAs from the checkpoint>; CI run <URL>.
- **Follow-ups:** part B (packaging, release automation, Android signing continuity) and part C (product name).
```

- [ ] **Step 6: Commit and push**

```bash
git add docs/superpowers/checkpoints/2026-11-04-release-data-foundation-checkpoint.md PROJECT_ROADMAP.md docs/WORKLOG.md
git commit -m "docs: checkpoint release data foundation" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git push origin feat/v2-complete-dashboard
gh run list --branch feat/v2-complete-dashboard --limit 1
```

Expected: push succeeds (never force). When the GitHub Actions run for the pushed head finishes green, replace the `<URL and conclusion...>` and `CI run <URL>` placeholders in the checkpoint and worklog with the real run URL, then:

```bash
git add docs/superpowers/checkpoints/2026-11-04-release-data-foundation-checkpoint.md docs/WORKLOG.md
git commit -m "docs: record CI run for release data foundation" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git push origin feat/v2-complete-dashboard
```

- [ ] **Step 7: Clean up the worktrees**

```bash
git worktree remove ../dashboard-shakhsi-rdf-t1
git worktree remove ../dashboard-shakhsi-rdf-t2
git worktree remove ../dashboard-shakhsi-rdf-t3
git worktree remove ../dashboard-shakhsi-rdf-t4
git worktree remove ../dashboard-shakhsi-rdf-t5
git worktree remove ../dashboard-shakhsi-rdf-t6
```

(Delete the merged `rdf/*` branches only if you created them; they are local to this work.)

---

## Self-review

**Spec coverage (spec section to task):**
- 1 Money scale 0 and the 8-to-9 migration with half-even and logging: Task 3 (rule amended and justified in decision 1; logging via `dart:developer`, decision 8). Migration and restart tests: Task 3.
- 1 Real overflow checks; reports show "out of range": Task 1 (arithmetic) and Task 4 (panel notice, repository sums, installment total guard).
- 1 Legend percent without overflow: Task 1 (`percentOf`) and Task 4 (chart).
- 2.1 Sources: desktop auto-detect Task 2 (locator, Linux honors `XDG_DATA_HOME`); manual file and `file_picker ^13.3.2` Task 6; both export shapes confirmed from `origin/main:src/app.html` (`buildTaskJSON`, `buildFinJSON`) and parsed in Task 2; Android manual-only noted (decision 9).
- 2.2 Entry point: Settings action and banner Task 6 (banner dismissal amended, decision 3); flow parse, preview, confirm, one transaction, report: Tasks 2, 5, 6.
- 2.3 Idempotency via `legacy_imports`: table Task 3, ledger and skip logic Task 5. The spec's tuple is stored; the key is `(entity_type, v1_id)`.
- 2.4 Mapping: task order and display numbers, done tasks `completed_at = created` (Task 5); overflow skip-and-report (Task 2 parser plus Task 5 failed-validation skips); debts and installments as synthetic payments (Task 5 through `addDebt`/`addInstallmentPlan`; note marker replaced, decision 2); priority/`important`/category defaults (Task 2); missing/duplicate ids with `v1:<entity>:<sha1>` (Task 2).
- 3 Architecture: layers under `lib/features/legacy_import/`; migration in `app_database.dart` (Task 3).
- 4 Testing: money (T1, T3, T4), parser fixtures including v1.0, v1.2, Android compact, export, corrupt, empty, double-encoded and structured (T2), importer preview/rollback/idempotent/existing-data/done-time/payments (T5), UI dialogs and flow (T6). Each task ends with focused tests, `flutter analyze`, and a commit; Task 7 runs `tool/ci.sh`, writes the checkpoint, updates roadmap section 0 item 3 and section 14, adds the worklog entry, and pushes.
- 5 Out of scope respected.

**Placeholder scan:** the only fill-in-at-execution values are the checkpoint and worklog evidence fields (commit SHAs, test count, CI URL), which cannot exist before execution; each says exactly which command output supplies them. No TBD/TODO steps remain; every code step shows code.

**Type consistency:** `LegacyEntityType.storageValue` (T2) is used by the ledger (T5) and matches the table CHECK values `task|transaction|debt|installment` (T3). `LegacySourceKind.storageValue` is `data_json`/`export`, matching the CHECK. `LegacySnapshot` fields (T2) match their use in T5 and T6 (`sourceKind`, `sourceSha256`, `taskSort`, `exportedAtUtc`, `tasks`, `transactions`, `debts`, `installments`, `skipped`, `warnings`). `LegacyImportLedger.record(...)` named parameters are identical in the interface, the Drift implementation, the test fake and the service. `LegacyImportRowsCompanion.insert(sourceKind, entityType, v1Id, v2Id, importedAtUtc, sourceSha256)` (T3 columns) matches T5 and the T6 banner test. `Money.checkedAdd/checkedSubtract/percentOf` (T1) are the names used in T4. `legacyV1SourceLocatorProvider`, `legacyImportLedgerProvider`, `legacyImportServiceProvider`, `legacyV1ParserProvider` are defined in T5 and consumed in T6. `MoneyInputFormatter` gains `maxIntegerDigits` only in T4, after T3 fixed the zero-fraction case.
