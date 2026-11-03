# Money scale 8 and int64 overflow: analysis for the v2 release-readiness spec

Date: 2026-11-04. Research only; no code changed. Companion to `2026-11-04-v1-data-format-and-v2-mapping.md` (section 3 money, section 5 risk 1).

## 1. Summary

- v2 stores IRT as `toman x 10^8` in int64. Max single value: **92,233,720,368 toman** (9.22e10).
- v1 allowed 15-digit toman amounts (up to 999,999,999,999,999). Real data above 92 billion is plausible but rare; products and sums hit the limit earlier than single values.
- **`_checkedMinorUnits` does not protect anything on native Dart.** Dart VM ints wrap silently on `+`, `-`, `*`, so the value is already wrapped (and therefore in range) before the check runs. Verified with `dart run`: `9223372036854775807 + 1 == -9223372036854775808`, and `5000000000000000000 * 2 == -8446744073709551616`. The check only fires for `-minInt64` negation cases that happen to be handled the same way (also wraps). No test covers overflow (`grep RangeError|maxInt64 test` finds nothing).
- Parsing is safe: `int.tryParse` returns null for digit strings above int64, so `tryParseMajorUnits` returns null (`money.dart:94-96`) and an over-limit entry is rejected as "invalid" without a specific message.
- Recommendation: option (b), scale 0 for IRT, plus real overflow checks (section 6). Scale 8 buys nothing: v1 has no decimals, v2 is unreleased, and toman has no practical subunit.

## 2. Why scale 8 was chosen

No rationale for the number 8 itself is written anywhere. It is stated as a requirement, then propagated.

- Introduced in the baseline commit `9f0573d feat: establish Flutter v2 application baseline` (the only commit touching `financeScale`; `git log -S financeScale`).
- `docs/superpowers/specs/2026-07-26-tasks-finance-drift-persistence-design.md:35`: "amounts in the UI have up to 8 decimal digits; stored as int64 minor_units; scale is always 8". Example `123.45678901 toman -> minor_units 12345678901`. Table rows at `:99`, `:112`, `:140`, validation rule `:306`.
- `docs/superpowers/specs/2026-07-26-exact-money-formatting-design.md:5,9,20,31,40`: "up to eight fractional digits"; scale 8 as a fixed-point requirement.
- Plans: `plans/2026-07-26-exact-money-formatting-plan.md:5,27,39`, `plans/2026-07-26-tasks-finance-drift-persistence-plan.md:473,642,973-976,1245,1446` (eight-decimal exact-sum and round-trip tests).
- Nothing in the docs weighs the cost: the int64 ceiling at scale 8 (9.2e10 toman) is never computed in the specs. The v1 mapping doc (`:138`, `:211`) is the first place it is quantified.
- Likely origin (inference): the original brief asked for crypto-style 8-digit precision (satoshi-like); toman amounts never need it.

## 3. Where money is stored, computed, aggregated

Constants: `money.dart:10-11` int64 bounds, `:12` `financeScale = 8`, `:13` `tomanCurrencyCode`. `Money` asserts `scale 0..18` and int64 range (`:6-8`).

### 3.1 Storage (Drift, schema version 8, `app_database.dart:385`)

| Table / column | Type | Scale persisted per row | Lines |
|---|---|---|---|
| `finance_transactions.amount_minor_units` | INTEGER (int64) | yes, `scale` default 8 | `app_database.dart:55,57` |
| `debts.total_minor_units` | INTEGER | yes, `scale` default 8 | `:77,79` |
| `debt_payments.amount_minor_units` | INTEGER | no, inherits from `debts` row | `:95` |
| `installment_plans.per_installment_minor_units` | INTEGER | yes, `scale` default 8 | `:109,112` |
| `installment_payments.amount_minor_units` | INTEGER | no, inherits from plan | `:137` |

`currency_code` is also persisted per row (default `IRT`). The domain validator rejects anything but IRT and scale 8 (`finance_transaction.dart:111-118`, message says "eight decimals"), so the per-row scale is effectively a constant. Repository writes scale explicitly (`drift_finance_repository.dart:105,131,213`) and reads it back (`:40,348,353,387`). Debt remaining and "paid" are not stored; they are derived. SQLite INTEGER is 64-bit signed, so storage itself never exceeds int64.

### 3.2 Arithmetic and aggregation

Dart VM semantic: wraps silently. "Safe max" is the largest toman value before wrapping; "throws?" says whether `_checkedMinorUnits` (`money.dart:196-201`) can ever fire (answer: no, on native).

| Operation | Location | Safe max (toman) | Throws or wraps |
|---|---|---|---|
| `Money +`, `-`, unary `-`, `absolute` | `money.dart:140-155` | 92.2e9 result | wraps; check is dead code |
| `Money * int` | `money.dart:156-157` | 92.2e9 result | wraps |
| Installment `total`/`paid`/`remaining` = per x count | `installment_plan.dart:39-41` | per x count <= 92.2e9. Example: per 3e9 x 36 months = 108e9 overflows | wraps, yields negative or garbage total |
| Debt `remaining = total - paid` | `debt.dart:36` | operands each <= 92.2e9; difference always fits when both non-negative | n/a |
| Summary: balance, month totals, all-time totals | `finance_report_service.dart:45-72` (`+=` loops over all transactions) | running sum <= 92.2e9. All-time income over years is the most exposed | wraps |
| `debtRemaining` sums debts + installments | `finance_report_service.dart:67-72` | sum <= 92.2e9 | wraps |
| 6-month trend (income/expense per month) | `finance_report_service.dart:104-118` | per-month sum <= 92.2e9 | wraps |
| Category totals / expense by category | `finance_report_service.dart:139`, `:185-194` | per-category sum <= 92.2e9 | wraps |
| Debt payment guard: `paidMinorUnits` fold, `remaining = total - paid`, `amount > remaining` | `drift_finance_repository.dart:170-176` (raw `int` arithmetic, bypasses `Money`) | sum of payments <= 92.2e9 | wraps; the guard could be bypassed |
| Aggregate paid per debt (list load) | `drift_finance_repository.dart:336,403` (`int +=`) | same | wraps |
| UI preview models (dashboard) | `finance_preview_models.dart:42-44,69,118-140,172-173,232` (same `Money +` and `*`) | same | wraps |
| Chart legend percentage `value*100/total` | `finance_charts.dart:92-94` | **value x 100 must fit: single category/slice <= 922,337,203 toman (~922 million)** | wraps; wrong percentage shown above ~922M. This is the lowest real limit in the app |
| Chart axis, bars, donut angles | `finance_charts.dart:209,237-258,343-365,424-450` | converts to `double`; exact up to 2^53 minor units = 90.07 million toman; beyond that is only visual rounding | no overflow, visual only (allowed by CLAUDE.md for charts) |
| Progress ratios | `finance_preview_models.dart:49`, `installment_plan.dart:46` | double | visual only |
| `majorUnitsForChart` | `money.dart:29` | double | visual only |

### 3.3 Parsing and formatting

| Piece | Location | Behaviour |
|---|---|---|
| `tryParseMajorUnits` | `money.dart:42-100` | concatenates whole + fraction padded to `scale`, `int.tryParse`, then range check. Over-limit returns null (safe, no wrap). Max accepted at scale 8: 92,233,720,368.54775807 |
| `parseMajorUnits` | `:30-40` | throws `FormatException('Invalid exact money value')` on null |
| Dashboard entry | `finance_preview_models.dart:256-262` | `Money.tryParseMajorUnits(... scale: financeScale)`; over-limit is indistinguishable from malformed input |
| `MoneyInputFormatter` | `money_input_formatter.dart:10,38-80` | No cap on integer digits (only fraction capped at `maxFractionDigits = financeScale`, `:10,51`). A user can type 30 digits; submission then fails with the generic invalid-amount path |
| `formatMajorUnits` | `money.dart:102-130` | string based on `minorUnits.abs().toString()`; correct for the whole int64 range except `minInt64` (`.abs()` wraps; unreachable via validators) |

### 3.4 Not affected

Task tables and all non-money code do not use `Money`. `notification_schedules` and the tasks module are unrelated.

## 4. Real-world headroom (2026 Iran, orders of magnitude; estimates, not sourced figures)

Limit under test: 92.2 billion toman per single value or per running sum.

| Flow | Typical size (toman) | Exceeds 92.2e9? |
|---|---|---|
| Salary, monthly expenses, groceries | 1e7 .. 1e9 | no |
| Car purchase | ~1e9 .. 1e10 (luxury/imported up to ~1e11) | rarely; imported or luxury cars can |
| Apartment, mid-size city | ~1e10 .. 1e11 | often borderline |
| Apartment, Tehran | ~5e10 .. several e11 | yes, frequently |
| Mortgage/loan total | 1e9 .. 1e11 | borderline |
| Installment product, per x count | per 1e8..5e9 x 12..60 -> 1e9 .. 3e11 | yes for high-end loans (e.g. 3e9 x 36 = 1.08e11) |
| Business income, all-time or yearly aggregate (small business/freelancer) | 1e10 .. 1e12 | yes, as a running sum |
| All-time balance over several years with inflation | 1e10 .. 1e12 | likely for a user who logs a business |
| Chart legend percentage per category | breaks at 9.2e8 | **a single 1-billion-toman expense category breaks the legend today** |

Conclusions:
- The product's target (personal dashboard) mostly stays below 9.2e10 per single value, but property, vehicle, installment totals and multi-year aggregates will exceed it for a real fraction of users, and currency devaluation shifts all of this upward over time.
- The sharpest practical defect is the chart percentage at about 922 million toman, which is reachable by ordinary users (one large category).
- No ordinary use reaches 1e15 (v1's input cap). A realistic ceiling is about 1e13..1e14 toman for any user. Scale 0 gives 9.2e18, scale 2 gives 9.2e16, scale 4 gives 9.2e14.

## 5. Options

Test impact measured: `grep -rn "financeScale\|scale: 8" test | wc -l` = **17 lines** across **8 files**; 12 test files total involve money amounts with large literals or minor units (finance_report_service_test, drift_finance_repository_test, money_test, database_restart_test, finance_domain_test, finance_panel_test, money_input_formatter_test, task_planning_migration_test, finance_preview_math_test, finance_panel_persistence_test, app_database_test, persistence_providers_test). Files with `financeScale` or `scale: 8`: `finance_report_service_test.dart:283`, `finance_domain_test.dart:12,38,63`, `finance_panel_persistence_test.dart:290`, `finance_preview_math_test.dart:9`, `persistence_providers_test.dart:237`, `drift_finance_repository_test.dart:34,307`, `database_restart_test.dart:175,233`, `money_test.dart` (many `scale: 8` at `:42-98`). Plus the 7 eight-decimal assertions in `money_test.dart`/formatter tests. Most tests build amounts via helpers and `Money.financeScale`, so the constant-based ones change automatically if only the constant moves; tests with literal minor units (e.g. `12345678901`) must be rewritten.

### (a) Keep scale 8, add explicit overflow handling and a UI limit

- Change: make `_checkedMinorUnits` real (pre-check with `BigInt`, or detect wrap by sign/`mulHigh`-style test); add `Money.tryAdd`/checked multiply; guard `drift_finance_repository.dart:170-176,336`; fix chart percentage with `~/` on reduced values or `BigInt`; add integer-digit cap to `MoneyInputFormatter` (max 11 integer digits) and a specific "amount too large" message; importer skips records above the limit.
- Migration: none (schema stays 8).
- Tests: 17 lines unchanged; add overflow tests (add, mul, installment total, repository guard, chart percent, formatter cap).
- Risk: product ceiling stays 92.2e9 toman, below real property and installment totals. Needs a user-visible limit, which is a poor experience for the main currency. Running aggregates (all-time balance) still can exceed the limit and need a defined behaviour (saturate? hide? error?). Keeps 8 useless decimals in UI and DB.

### (b) Reduce IRT scale (0 recommended; 2 acceptable)

- Change: `Money.financeScale = 0` (or a per-currency constant); validators and message (`finance_transaction.dart:111-118`, "eight decimals" text); `MoneyInputFormatter` default `maxFractionDigits` follows constant (0 disables the decimal point already, `money_input_formatter.dart:59`); importer maps v1 toman with factor 1 (no `* 1e8`); also add the real overflow checks from (a) so wrap is impossible (limit now 9.2e18 toman, products like per x count still need checks but become practically unreachable).
- Migration 8 to 9 (append-only, `if (from < 9)` in `app_database.dart` `onUpgrade` after `:489`): for the three tables carrying `scale` (`finance_transactions`, `debts`, `installment_plans`), plus the child tables `debt_payments` and `installment_payments` (no scale column; scale comes from parent), run `UPDATE ... SET minor_units = <rounded division by 10^8>` and `scale = 0`. Determinism rule: use integer arithmetic with round-half-away-from-zero (`(x + 50000000) / 100000000` for non-negative, sign-aware for negative); all amounts are non-negative so this is `(x + 5e7) / 1e8` in SQL, no floating point. Parent and child must be done in one transaction so the rule is applied uniformly. Column defaults `withDefault(Constant(8))` cannot be altered in SQLite without a table rebuild; leave the SQL default (the repository always writes scale explicitly, `drift_finance_repository.dart:105,131,213`) or update the Dart default and accept that the DDL default only matters for raw inserts. Sub-toman fractions stored by dev builds are rounded away (information loss, only dev DBs; v2 is unreleased, v1 never had decimals).
- Because v2 is unreleased, the only rows needing migration are developer databases. A cheaper variant: do not migrate; ship a clean schema-8 equivalent as the first public version and wipe dev DBs (not recommended: breaks the "append-only migrations" rule in `CLAUDE.md`). Keep the migration.
- Tests: change the scale constant (most tests follow via `Money.financeScale`); rewrite literal-minor-unit tests (`money_test.dart` eight-decimal cases, formatter eight-fraction cases, `finance_preview_math_test` "preserves exact eight-decimal"), persistence tests "all eight decimal digits" round-trip become scale-0 round-trips; add migration 8 to 9 test with scale-8 fixture rows (rounding, child rows, restart test per `CLAUDE.md`).
- Risk: lowest long-term; one-time rounding of dev data; decimals in UI go away (acceptable: v1 had none; toman has no practical subunit; rial entry is a possible future request, solvable with scale 1 later via the same mechanism). Percent/ratio maths stays integer. If scale 2 is chosen instead: ceiling 9.2e16 toman, keeps `.xx` entry, migration divides by 10^6.

### (c) BigInt / decimal arithmetic in memory, string or two-column storage

- Change: `Money` holds `BigInt`; DB stores TEXT decimal string, or `hi`/`lo` int64 pair; every SQL aggregate must move to Dart (no `SUM`); repository, tests, charts, importer all touch it.
- Migration 8 to 9: rebuild five tables (type change INTEGER to TEXT requires create-new/copy/drop/rename, data copy of every row, ordering and index preservation); in sqlite `CAST` is fine for deterministic conversion. Larger blast radius than (b).
- Tests: all 12 money test files plus fixtures; `database_restart_test` and migration tests need fixtures rebuilt; `.g.dart` regenerated.
- Risk: highest. Slower hot loops, more code, no real-world need beyond 9.2e18 toman. Only justified if multi-currency with 18-decimal assets is ever planned (the generic `Money` allows scale up to 18, which at 18 only holds 9.2 whole units, so that capability is already nominal).

### Comparison

| | (a) keep 8 + guards | (b) scale 0 (or 2) + guards | (c) BigInt/text |
|---|---|---|---|
| Schema change | none | 8 to 9 data rewrite, 5 tables, no DDL change required | 8 to 9, 5 tables rebuilt |
| Max single IRT value | 92.2e9 | 9.2e18 (scale 0) / 9.2e16 (scale 2) | unbounded |
| Test lines changed | ~0 plus new tests | ~17 `scale` lines (most via constant) plus literal-value tests plus new migration tests | all money tests |
| Wrap bug fixed | yes if guards done | yes if guards done (needed anyway) | by construction |
| Real-user fit | poor for property/installments | good | overkill |
| Effort | small | medium | large |

## 6. Recommendation

Option (b) with scale 0 for IRT, plus mandatory real overflow checks (these are needed under any option, because the current check is dead code on native Dart).

Do not choose scale 2 unless the owner wants sub-toman entry; the v1 data has none and CLAUDE.md names IRT as the default currency.

Decisions to put in the spec:
1. Scale 0 vs 2 (recommend 0).
2. Rounding rule for migrating dev rows (recommend half-away-from-zero, integer SQL; any value below 0.5 toman becomes 0, which would violate `validateExactPositiveMoney`: positive amounts rounded to zero must be set to 1 or the migration must abort and report; recommend clamp to a minimum of 1 for rows that were positive).
3. Overflow behaviour for sums above int64 (9.2e18; effectively unreachable): throw a typed `MoneyOverflowException` and have report services show "-" instead of crashing.
4. Input cap: keep a digit cap in `MoneyInputFormatter` (e.g. 15 integer digits = v1's cap) with a specific error message.
5. Importer: v1 toman maps with factor 1; 15-digit v1 values (up to 1e15) fit in scale 0 (9.2e18 limit). Per-record overflow in products (per x count above 9.2e18) is only possible for count above 9,223 at per = 1e15; keep the skip-and-report rule for that corner.

### Files that would change (option b)

Source:
- `lib/core/money/money.dart` (constant, real checked add/sub/mul, optional `tryAdd`; fix `abs`/negation of minInt64)
- `lib/core/money/money_input_formatter.dart` (integer digit cap, default fraction digits follow constant)
- `lib/core/database/app_database.dart` (`schemaVersion` 9, `from < 9` rewrite step; optionally the `withDefault(Constant(8))` defaults at `:57,79,112`)
- `lib/features/finance/domain/finance_transaction.dart` (`:111-118` validator text and check)
- `lib/features/finance/domain/installment_plan.dart` (checked total/paid/remaining)
- `lib/features/finance/data/drift_finance_repository.dart` (`:170-176`, `:336`, `:403` raw int arithmetic)
- `lib/features/finance/application/finance_report_service.dart` (overflow handling in loops `:45-72,104-118,139,185-194`)
- `lib/features/dashboard/presentation/widgets/finance_charts.dart` (`:92-94` percent without `*100` overflow; `:240`)
- `lib/features/dashboard/presentation/widgets/finance_preview_models.dart` (`:260` parse scale, `:42-44,69,118-140` sums)
- Importer (new, per the v1 mapping doc): factor 1.

Tests (rewrite or extend):
- `test/core/money/money_test.dart` (scale 8 literals `:42-98`, add overflow cases)
- `test/core/money/money_input_formatter_test.dart` (eight-fraction cases, digit cap)
- `test/features/finance/domain/finance_domain_test.dart` (`:12,38,63`, validator message)
- `test/features/finance/data/drift_finance_repository_test.dart` (`:34,307`, eight-decimal round trips, debt payment guard)
- `test/features/finance/application/finance_report_service_test.dart` (`:283`)
- `test/features/dashboard/finance_preview_math_test.dart` (`:9`, "exact eight-decimal" sum)
- `test/features/dashboard/finance_panel_persistence_test.dart` (`:290`)
- `test/features/dashboard/finance_panel_test.dart` (large literals)
- `test/core/providers/persistence_providers_test.dart` (`:237`)
- `test/core/database/database_restart_test.dart` (`:175,233`)
- `test/core/database/app_database_test.dart` and `test/core/database/task_planning_migration_test.dart` (schema version expectations; new `finance_scale_migration_test.dart` for 8 to 9, plus restart test)

Count of affected tests: 17 hardcoded `financeScale`/`scale: 8` lines in 8 files; 12 money-related test files in total are expected to be touched.

## 7. Immediate defect list (independent of the option)

1. `Money._checkedMinorUnits` never fires on native Dart (wrap happens first). Fix by pre-checking operands.
2. `finance_charts.dart:92-94` percentage `minorUnits * 100` overflows above ~922 million toman at scale 8 (reachable today).
3. `drift_finance_repository.dart:170-176,336` do raw int sums outside `Money`.
4. `MoneyInputFormatter` has no integer-digit cap and the over-limit error is the generic "invalid" path.
5. No test covers any overflow path.
