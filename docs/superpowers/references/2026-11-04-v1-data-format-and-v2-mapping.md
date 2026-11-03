# v1 data format and v2 mapping (importer reference)

Date: 2026-11-04. Inputs to the "v2 release readiness" spec.
Sources: `origin/main` (tags v1.0.0, v1.1.0, v1.2.0) and branch `feat/v2-complete-dashboard` at schema 8.
Line numbers for v1 refer to `origin/main:src/app.html` (v1.2.0, 2043 lines) unless noted.
"Inferred" means derived from code behaviour, not from a spec or a real data file. No real v1 data file was inspected.

## 1. v1 storage, per platform

v1 is a key/value store. The page (`app.html`) keeps four string keys; the native wrapper persists the whole map to one JSON file.

| Platform | Path | Writer |
|---|---|---|
| Linux (deb/rpm, GTK app) | `$XDG_DATA_HOME` or `~/.local/share` (via `GLib.get_user_data_dir()`) + `/dashboard-shakhsi/data.json` | `origin/main:src/main.py:28-32`, save at `:155-170` |
| Linux (pywebview build) | `$XDG_DATA_HOME` or `~/.local/share` + `/dashboard-shakhsi/data.json` | `origin/main:src/desktop.py:41-47` |
| Windows | `%APPDATA%\dashboard-shakhsi\data.json` (falls back to `~`) | `origin/main:src/desktop.py:34-36` |
| macOS | `~/Library/Application Support/dashboard-shakhsi/data.json` | `origin/main:src/desktop.py:37-40` |
| Android | `<app files dir>/data.json` = `/data/data/ir.dashboard.shakhsi/files/data.json` (internal, private) | `origin/main:android/app/src/main/java/ir/dashboard/shakhsi/MainActivity.java:43`, save `:113-132` |

Notes:
- Android does NOT use localStorage as the primary store. It injects `window.__NATIVE_DATA__` from `files/data.json` and writes back through `AndroidBridge.saveData` (`MainActivity.java:94-95`, `app.html:813-814`). The WebView is created with DOM storage enabled and base URL `https://localhost/` (`:47`, `:52`), and `store.set` also mirrors every write to `localStorage` (`app.html:139`). That copy is only a fallback read when a key is missing from the native map (`app.html:130`). It is not needed for import.
- Android `applicationId` is `ir.dashboard.shakhsi` in v1 (`origin/main:android/app/build.gradle:15`) and in v2 (`android/app/build.gradle:21`). A v2 APK installed over v1 keeps the same private data directory, so `files/data.json` is reachable by path (inferred; the Flutter-side path would be `getApplicationSupportDirectory()`, which maps to `files/` on Android; verify on a device). `allowBackup="true"` (`origin/main:android/app/src/main/AndroidManifest.xml:8`), so the file may also be restored by Android Auto Backup.
- GTK Linux app also keeps WebKit data under `<data dir>/webkit` (`main.py:33`), which may hold a stale `localStorage` copy. Not authoritative.
- File format: UTF-8 JSON object, pretty-printed with `indent=1`, `ensure_ascii=False` on desktop (`main.py:166-168`, `desktop.py:101-103`). Android writes the payload as sent by the page (compact `JSON.stringify`, no indent) (`MainActivity.java:119`).
- Shape: a flat object whose keys are storage keys and whose VALUES ARE STRINGS containing JSON (double-encoded). The loader coerces everything: `{str(k): str(v) ...}` (`main.py:46`, `desktop.py:55`). Android loader only validates that the file parses as a `JSONObject` and passes the text through (`MainActivity.java:82`).
- Atomic write: desktop writes `data.json.tmp`, `flush`, `fsync`, `os.replace` (`main.py:58-65`, `desktop.py:67-74`). Android writes `data.json.tmp` then `renameTo`; if rename fails it overwrites directly and deletes tmp (`MainActivity.java:116-129`). No fsync on Android.
- Backups: none. On desktop, a file that fails to parse (or any load exception except missing file) is renamed to `data.json.corrupt-YYYYmmdd-HHMMSS` and the app starts empty (`main.py:49-55`, `desktop.py:58-64`). A parseable file that is not a JSON object returns empty WITHOUT renaming (`main.py:45-55`: the `isinstance` check just falls through to `return {}`) and will be overwritten on the next save. Android returns `"{}"` on any error and does not quarantine (`MainActivity.java:84-86`). A leftover `data.json.tmp` may exist after a crash.
- Version field: none in the file. The only versioning is the key suffixes (`:v1`). The file layout and the four keys are identical in v1.0.0, v1.1.0, v1.2.0 (verified by `git show <tag>:src/app.html`: same `K_*` constants, same `{id,text,done,priority,created}` task shape, same `fin={tx,debts,insts}`). v1.0.0 already wrote `data.json` (`v1.0.0:src/main.py:6,32,65`). Differences between releases are only the wrapper (v1.1.0 adds `desktop.py`, v1.2.0 adds Android).
- Page-side persistence: `store.set` mutates `window.__NATIVE_DATA__[k]` and pushes the entire map on every change (`app.html:134-141`, `:798-822`). Keys are defined at `app.html:794`.
- Exports (`tasks-*.json`, finance export) go to Downloads and are a different, lossy format (`app.html:1277-1287`, `:1946-1956`). They are not an import source.

## 2. v1 JSON schema

### 2.1 Top-level keys (all values are JSON strings)

| Key | Parsed value | Read at | Written at |
|---|---|---|---|
| `tasklist:v1` | array of Task | `:2000-2012` | `:1061` |
| `tasklist:prefs:v1` | `{sort}` | `:2013-2021` | `:1062` |
| `finance:v1` | `{tx:[], debts:[], insts:[]}` | `:2024-2034` | `:1374` |
| `app:prefs:v1` | `{theme, tab}` | `:1992-1993` | `:993` |

No other keys exist. There are no settings beyond theme/tab/sort, no categories list (categories are hard-coded, `:1351-1352`), no notes, habits or goals. Unknown extra keys in the map would be preserved by the wrapper but ignored by the page.

### 2.2 Task (`tasklist:v1` array element)

Creation: `{id:genId(), text, done:false, priority:addPri, created:Date.now()}` (`:1066`). Loader normalisation (`:2005-2009`) is the authoritative tolerance spec.

| Field | Type | Meaning / default |
|---|---|---|
| `id` | string | `genId()` = `Date.now() + "-" + 5 base36 chars` (`:149`), e.g. `1730000000000-k3j9a`. Loader fills `genId()` if falsy, so ids are not stable across loads for id-less records (and the fill is not persisted until next save). |
| `text` | string | Task title, trimmed on add/edit. Loader drops items with empty/falsy text (`:2009`). No length limit. No description field. |
| `done` | boolean | Loader coerces with `!!`. |
| `priority` | integer 0..3 | 0 none, 1 low, 2 medium, 3 high (`:1046-1052`). Loader: valid number in 0..3 kept; otherwise `t.important ? 3 : 0`. `important` is a legacy boolean from a pre-v1.0 build (inferred; never written by any tagged version). |
| `created` | integer, epoch milliseconds | `Date.now()`; loader defaults to now if falsy. |

No due date, no status other than done/not done, no order field. The array order is newest first (`unshift`), but the UI re-sorts by `tasklist:prefs:v1.sort` (`:1098-1103`).

### 2.3 Task prefs (`tasklist:prefs:v1`)

`{"sort":"new"|"pri"|"abc"}`; other values ignored (`:2017`).

### 2.4 App prefs (`app:prefs:v1`)

`{"theme":"dark"|"light"|null, "tab":"tasks"|"fin"}`; `Object.assign` over defaults `{theme:null, tab:"tasks"}` (`:1993`, `:293`).

### 2.5 Finance (`finance:v1`)

Loader accepts any object and takes `tx`, `debts`, `insts` as arrays or `[]` (`:2028-2032`). Elements are NOT normalised or validated on load (unlike tasks).

Money everywhere: JavaScript number holding a whole number of TOMAN (UI unit label is "تومان", `:1458`, `:166`). Entered through `parseAmount` which strips non-digits and keeps at most 15 digits (`:153-159`), so values are non-negative integers up to 999,999,999,999,999 (< 2^53). No decimals can be entered. Hand-edited or imported data could contain floats (inferred).

Transaction `tx[]` (`:1417`, `:1420`, `:1811`, `:1840`):

| Field | Type | Notes |
|---|---|---|
| `id` | string | `genId()` format. Not normalised on load. |
| `type` | `"ex"` or `"in"` | Anything other than `"in"` is treated as expense by the totals (`:1444-1447`) but filtered out of both list filters (`:1867-1870`). |
| `title` | string | Default `"بدون عنوان"` when empty (`:1413`). |
| `cat` | string | Expense: one of خوراک, حمل‌ونقل, خرید, قبوض, مسکن, سلامت, تفریح, آموزش, بدهی, قسط, سایر. Income: حقوق, کسب‌وکار, هدیه, سود سرمایه, سایر (`:1351-1352`). `بدهی` and `قسط` are only produced by payments, not selectable (`:1379`). Free string in storage. |
| `amount` | integer toman > 0 | Form rejects <= 0 (`:1415`). |
| `ts` | integer epoch ms | `Date.now()` at creation. The user cannot choose a date; the transaction date is always entry time. |

Debt `debts[]` (`:1424`):

| Field | Type | Notes |
|---|---|---|
| `id` | string | genId. |
| `name` | string | Title (`"بدون عنوان"` default). |
| `total` | integer toman > 0 | |
| `paid` | integer toman | `min(initialPaid, total)` at creation; `+= amt` on payment where `amt <= remaining` (`:1423`, `:1809-1810`). Invariant `0 <= paid <= total` holds for app-written data. |
| `created` | integer epoch ms | |

No payment history is kept for debts. Each payment also appends an independent `tx` with `cat:"بدهی"`, `type:"ex"`, `title:"پرداخت بدهی: <name>"`, no link back (`:1811`). The initial "paid so far" does NOT create a transaction (`:1423-1424`).

Installment `insts[]` (`:1431`):

| Field | Type | Notes |
|---|---|---|
| `id` | string | genId. |
| `name` | string | |
| `per` | integer toman > 0 | Amount of each installment. |
| `count` | integer >= 1 | Total installments. |
| `paidCount` | integer 0..count | Initial value `min(input, count)`; `++` on payment. |
| `created` | integer epoch ms | |

Each payment appends a `tx` `{type:"ex", cat:"قسط", title:"قسط: <name> (<fa paidCount> از <fa count>)", amount:per}` (`:1840`). Initial `paidCount` creates no transactions. Titles use Persian digits (`fa()`), so they are not parseable by regex without digit normalisation.

### 2.6 Dates and timezone

All stored timestamps are epoch milliseconds (UTC instant, from `Date.now()`). Jalali is used ONLY for display and exports (`toJalali`, `:185-198`; `jalaliShort`, `:204`); no Jalali string is ever persisted. So no Jalali-to-Gregorian conversion is needed on import. Local-day semantics (the month bucket in `finTotals`, `monthKey`, `:208`, `:1443-1446`) use the device's local timezone at render time; the stored value carries no timezone and the original timezone is unknown.

### 2.7 Realistic sample

On disk (desktop form; note string-encoded values). Shown pretty-printed inside a single outer object:

```json
{
 "app:prefs:v1": "{\"theme\":\"dark\",\"tab\":\"fin\"}",
 "tasklist:prefs:v1": "{\"sort\":\"pri\"}",
 "tasklist:v1": "[{\"id\":\"1730640000123-k3j9a\",\"text\":\"خرید نان\",\"done\":false,\"priority\":3,\"created\":1730640000123},{\"id\":\"1730500000000-x1q7z\",\"text\":\"قبض برق\",\"done\":true,\"priority\":0,\"created\":1730500000000}]",
 "finance:v1": "{\"tx\":[{\"id\":\"1730641000000-a1b2c\",\"type\":\"ex\",\"title\":\"پرداخت بدهی: قرض از علی\",\"cat\":\"بدهی\",\"amount\":2000000,\"ts\":1730641000000},{\"id\":\"1730600000000-d4e5f\",\"type\":\"in\",\"title\":\"حقوق آبان\",\"cat\":\"حقوق\",\"amount\":25000000,\"ts\":1730600000000}],\"debts\":[{\"id\":\"1730000000001-g6h7i\",\"name\":\"قرض از علی\",\"total\":10000000,\"paid\":2000000,\"created\":1730000000001}],\"insts\":[{\"id\":\"1730000000002-j8k9l\",\"name\":\"قسط خودرو\",\"per\":3500000,\"count\":12,\"paidCount\":4,\"created\":1730000000002}]}"
}
```

## 3. v2 target model

Database: one Drift DB, schema version 8 (`lib/core/database/app_database.dart:385`), file `dashboard_shakhsi.sqlite` in the app documents folder (`lib/core/database/database_connection.dart:4-9`). Migrations are append-only (`:388-`). `PRAGMA foreign_keys = ON` (`:493-495`).

| v2 table | Lines | Domain type | Relevant constraints |
|---|---|---|---|
| `tasks` | `app_database.dart:6-45` | `TaskItem` (`lib/features/tasks/domain/task_item.dart:4-73`) | PK `id` (text, non-empty); `display_number` UNIQUE, `> 0`; `priority BETWEEN 0 AND 3`; `status IN ('planned','inProgress','completed','canceled')`; `position_in_status >= 0`; completed row needs `completed_at_utc` and no `canceled_at_utc`, canceled the reverse, active both null (`:35-40`); `due >= start`; title trimmed, non-empty. |
| `finance_transactions` | `:47-69` | `FinanceTransaction` (`lib/features/finance/domain/finance_transaction.dart:6-30`) | `type IN ('income','expense')`; `amount_minor_units`, `currency_code` default `IRT`, `scale` default 8; `occurred_at_utc`, `created_at_utc`, `updated_at_utc`; title and category trimmed, non-empty; amount must be > 0, IRT, scale 8 (`:111-127`); all times must be UTC (`:103-109`). |
| `debts` + `debt_payments` | `:71-101` | `Debt` (`lib/features/finance/domain/debt.dart:5-31`) | Debt total > 0, `0 <= paid <= total`; `paid` is DERIVED from payment rows. Payment rows cascade on debt delete. `archived_at_utc` nullable (hidden from watch queries, `drift_finance_repository.dart:60`). |
| `installment_plans` + `installment_payments` | `:103-148` | `InstallmentPlan` (`.../installment_plan.dart:5-28`) | `installment_count > 0`; `paidCount` is DERIVED from payment rows; payments UNIQUE `(plan_id, installment_number)`. |
| Not mapped from v1 | | | `task_reminder_rules`, `task_recurrence_*`, `task_occurrence_completions`, `task_time_entries`, `task_templates`, `notification_schedules`. v1 has no equivalent. |

Money (`lib/core/money/money.dart`): integer minor units plus currency and scale; `financeScale = 8`, `tomanCurrencyCode = 'IRT'` (`:12-13`). Finance validators force IRT + scale 8 (`finance_transaction.dart:111-118`). So 1 toman = 100,000,000 minor units, and the int64 ceiling (`money.dart:10-11`) limits a single amount to 92,233,720,368 toman (about 9.2e10).

Repository behaviour that constrains an importer:
- `DriftTaskRepository.create` IGNORES the `displayNumber` and `positionInStatus` of the passed `TaskItem`: it allocates `MAX(display_number)+1` and `COUNT(status)` inside a transaction (`lib/features/tasks/data/drift_task_repository.dart:47-81`). Importing through `create` gives displayNumber in insertion order and appends to the END of each status list. Preserving a chosen order requires either inserting in the desired order or writing rows directly.
- `addDebt` inserts one synthetic payment of `debt.paid` dated `debt.updatedAtUtc` when paid is positive (`drift_finance_repository.dart:137-143`). `addInstallmentPlan` inserts `paidCount` synthetic payments numbered 1..n at `plan.updatedAtUtc` (`:219-230`). These already model "initial paid so far" without creating transactions.
- `recordDebtPayment` and `payNextInstallment` do NOT create a `finance_transactions` row (`:147-190`, `:234-278`). The importer must not call anything that would. The v1 payment transactions are already present as ordinary `tx` items.
- Ids: generator is UUIDv7 (`lib/core/ids/id_generator.dart:7-14`) but the domain accepts any non-empty string.
- The v2 migration from legacy schema 2 is the precedent for deterministic task numbering: `display_number = ROW_NUMBER() OVER (ORDER BY created_at_utc, id)`, `position_in_status` contiguous per status by legacy order, `completed_at_utc = COALESCE(completed, updated)` (`app_database.dart:398-439`).
- Local-day logic must go through `AppClock` and `local_day_boundary.dart` (CLAUDE.md); domain code never calls `DateTime.now()`. Importer should take an injected clock.
- v2 has no persisted settings: theme is an in-memory `ThemeMode.system` provider (`lib/app/theme/theme_mode_controller.dart:5`).

## 4. Field-by-field mapping

### 4.1 Tasks (`tasklist:v1[]` -> `tasks`)

| v1 | v2 column | Conversion | Notes / loss |
|---|---|---|---|
| `id` | `id` | keep as-is if non-empty; else derive deterministic id (see 5) | Keeping v1 ids gives free idempotency (PK conflict). v1 id loader generated a random id for id-less records, so those have no stable identity. |
| (array index / `created`) | `display_number` | assign 1..n ordered by `(created asc, id asc)` | Same rule as the v3 migration (`app_database.dart:~420`). v1 has no number. Must be contiguous per the "never reused" intent; if the DB already has tasks, continue from `MAX+1` (the repo does this). |
| `text` | `title` | trim; drop if empty (v1 drops too) | v1 has no length limit; v2 none seen. |
| (none) | `description` | NULL | |
| `priority` 0..3 | `priority` 0..3 | identity; non-integer/out of range -> 0, or 3 if legacy `important` true | Same four levels. |
| `done` false | `status` `planned`, no timestamps | | v1 has no in-progress; none inferred. |
| `done` true | `status` `completed`, `completed_at_utc` required | no completion time exists in v1; use `created` (recommended) or import time | LOSSY. DB CHECK requires non-null. |
| (none) | `canceled` / `inProgress` | never produced | |
| array order + tSort | `position_in_status` | contiguous 0..n-1 per status | v1 visible order within a status = `created desc` for default sort `new`, other sorts differ; v1 array order is newest first. v2 appends new tasks at the END, so the old "newest on top" convention is inverted. See open question 2. |
| `created` (ms) | `created_at_utc` | `DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)`; missing -> import time | No Jalali conversion needed. |
| (none) | `updated_at_utc` | = `created_at_utc` (or completed time) | LOSSY: real edit time unknown. |
| (none) | `start/due/estimated` | NULL | |
| `tasklist:prefs:v1.sort` | none | drop | v2 has no persisted sort preference mapped here (inferred). |

### 4.2 Transactions (`finance.tx[]` -> `finance_transactions`)

| v1 | v2 | Conversion | Notes / loss |
|---|---|---|---|
| `id` | `id` | as-is, or derived if missing | |
| `type` `"in"` | `type` `income` | | |
| `type` `"ex"` | `type` `expense` | | Other values: v1 counts as expense in totals; recommend expense plus warning, or skip. |
| `title` | `title` | trim; empty -> `"بدون عنوان"` | v2 rejects empty. |
| `cat` | `category` | trim; empty -> `"سایر"` | Free string in v2 too; v1 categories `بدهی` and `قسط` retained. |
| `amount` (toman int) | `amount_minor_units`, `currency_code='IRT'`, `scale=8` | `amount * 100_000_000` using integer math; must be > 0 | OVERFLOW above 92,233,720,368 toman (v1 allows up to 999,999,999,999,999). Floats/NaN/negative/zero: reject or skip with report. |
| `ts` (ms) | `occurred_at_utc`, `created_at_utc`, `updated_at_utc` | all three from `ts` as UTC | v1 has only entry time. Month bucketing in v2 depends on the device timezone at read time, same as v1 (no stored timezone). |

### 4.3 Debts (`finance.debts[]` -> `debts` + `debt_payments`)

| v1 | v2 | Conversion | Notes / loss |
|---|---|---|---|
| `id`, `name` | `id`, `title` | as above | |
| `total` | `total_minor_units` | `* 1e8`, must be > 0 | same overflow rule |
| `paid` | one `debt_payments` row (amount = paid) | skip if 0; clamp to total if above | LOSSY: real payment history is not in v1; individual payments exist only as separate `tx` rows with `cat:"بدهی"` and no link. Do not create additional transactions. |
| `created` | `created_at_utc`; `updated_at_utc` = created; payment `paid_at_utc`/`created_at_utc` = created | | Payment date is a guess (v1 has none). `addDebt` uses `updatedAtUtc` for it. |
| (none) | `archived_at_utc` | NULL | |

### 4.4 Installments (`finance.insts[]` -> `installment_plans` + `installment_payments`)

| v1 | v2 | Conversion | Notes / loss |
|---|---|---|---|
| `id`, `name` | `id`, `title` | | |
| `per` | `per_installment_minor_units` | `* 1e8`, > 0 | overflow applies to `per`; `total = per*count` is also computed in `Money` and can overflow even when `per` fits (check `per * count`, not just `per`). |
| `count` | `installment_count` | integer >= 1 | float/zero -> skip with report |
| `paidCount` | `installment_payments` rows numbered 1..paidCount, amount = per | clamp to 0..count | LOSSY: payment dates unknown. |
| `created` | `created_at_utc`, `updated_at_utc`, payments' times | | |

### 4.5 Preferences

| v1 | v2 | |
|---|---|---|
| `app:prefs:v1.theme` | none persisted (in-memory `ThemeMode.system`) | drop or defer |
| `app:prefs:v1.tab` | none | drop |
| `tasklist:prefs:v1.sort` | none | drop |

## 5. Edge cases and risks

1. Money overflow (HIGH). v1 allows 15-digit toman amounts; v2 stores toman x 10^8 in int64, capping at 92,233,720,368 toman per value, and sums/products (`per*count`, debt remaining, running totals) can overflow earlier. One bad record must not abort the whole import; report and skip, or reduce scale (not allowed by `validateExactMoneyDefinition`). Spec decision needed.
2. Wrong-source / wrong-shape input (HIGH). Values are double-encoded strings: a naive parser that expects `tasklist:v1` to be an array fails. Android may hold compact JSON with no indent; desktop `.corrupt-*` and `.tmp` leftovers exist beside the file. The wrapper tolerates non-string values by `str()`-ing them (a nested array would become a Python repr, not JSON, on desktop; inferred, unlikely in practice). The importer should accept both string-encoded and already-structured values.
3. Data loss on re-import or on a non-empty v2 DB (HIGH). v1 ids are `ms-random5`; no checksum or marker is recorded. Running twice, or importing after the user created v2 data, can duplicate rows unless the importer is idempotent by v1 id and its ledger is persisted. Task `display_number` and `position_in_status` must stay unique/contiguous across mixed old and new rows: recompute contiguity per status inside one transaction, continue display numbers from `MAX+1`, never renumber existing v2 tasks.
4. Lossy conversions (MEDIUM, documented in section 4): completion time of done tasks, updated times, debt payment dates, installment payment dates, task sort preference, theme.
5. Missing or duplicate ids. Finance records are not normalised by v1 on load, so id-less or duplicate-id records can exist (v1 could not delete them reliably). Task loader assigns random ids to id-less tasks only in memory until the next save. Rule suggestion: if id is missing/empty/duplicated within the file, derive `v1-<sha1(kind|index|created|title|amount)>` so a re-import yields the same id; document that identical records collapse.
6. Corrupt or partial file: desktop quarantines unparseable files to `data.json.corrupt-*` (importer should NOT read these automatically but may offer them); a truncated tmp is never promoted (atomic replace), so a partial `data.json` is only possible on Android's non-atomic fallback or a hand-edited file. A `finance:v1` that fails `JSON.parse` is silently treated as empty by v1 (`:2033`), so "fin parse error" should map to "no finance data" plus a warning, not abort tasks.
7. Empty file / `{}` / missing keys: valid, equals a fresh v1 install; the importer should report "nothing to import" and not mark migration done in a way that blocks a later import.
8. v1.0 vs v1.2: same schema, same keys (section 1). Only legacy field is `important` (boolean) on tasks. No migration code by version is needed beyond tolerant parsing.
9. Timezone: instants are exact, but "which day/month is this?" depends on the importing device's timezone. A user who changed timezone sees shifted month boundaries; this matches v1 behaviour. Not fixable.
10. Large numbers of tasks: v2 `create` is O(n) per call for allocation, so bulk import should run in one transaction and compute numbers/positions up front, not 1000 repository calls.
11. Linked history: payment transactions (`cat` بدهی/قسط) and the debt/installment counters are redundant in v1 (the same payment lives in both). Import both as stored; do not synthesize transactions from counters and do not drop the payment transactions as "duplicates".
12. Android: file path access after install-over relies on the same `applicationId` (same in v1 and v2). Android Auto Backup (`allowBackup=true`) may restore `files/data.json` after a reinstall; the importer should be re-runnable and not assume first launch.
13. A leftover v1 install on desktop is a different process and directory; v2 does not write to the v1 path. Importer must open the file read-only and never modify or delete it.

## 6. Open questions for the owner

1. Money overflow: for amounts above about 92 billion toman (or a product that overflows), should the importer skip the record and report, or abort the entire import?
2. Task order: should the imported order preserve what v1 showed (newest at the top, so position 0 = newest) or follow v2's convention (new items appended at the end, so position 0 = oldest)? This also decides whether `display_number` (oldest = 1) and visible order disagree.
3. Completion time for tasks that v1 marked done (v1 stores none): use the task's `created` time (my recommendation; keeps statistics honest) or the time of import?
4. Entry point and idempotency: should import be an explicit button (Settings, "Import from v1", with file picker plus auto-detected default path) that can be re-run safely by v1 id, or a one-shot automatic import on first launch? I recommend the explicit button with a preview and a count report.
5. Should the importer persist a marker (new table or key, needing schema 9 with migration and restart tests) recording imported v1 ids and file hash, or rely only on id-based primary-key skipping? The marker allows "already imported" messaging and import of only new v1 records later; PK-skip needs no schema change.
