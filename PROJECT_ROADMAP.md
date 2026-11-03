# PROJECT ROADMAP & HANDOFF — Dashboard Shakhsi v2

> **This file is the primary continuity document for this repository.**
>
> In a new ChatGPT/Codex/Claude session, read this file **before proposing or implementing anything**.
> Then read the task-specific spec/checkpoint files linked from the current task.
>
> **Resume instruction for a new chat:**
>
> `Read PROJECT_ROADMAP.md first. Treat it as the source of truth for scope, architecture, completed work, current task, verification gates, and handoff rules. Continue only from CURRENT TASK and do not redesign completed work unless there is verified evidence of a defect.`
>
> **Visual direction (2026-11-02):** Liquid Glass rendering now follows `docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md`. It replaces the Gate C custom renderer and the pixel-golden acceptance rule. Glass is accepted perceptually (side-by-side with real iOS 27 / macOS 27 captures); design tokens stay source-derived. Read that spec before proposing any UI change.

Last updated: **2026-11-04**
Current branch: `feat/v2-complete-dashboard`
Latest fully verified checkpoint commit: `458499dfdb3504034d1d7115bd1515fe20ffc876`
Project stack: Flutter desktop + Riverpod + Drift/SQLite
Current database schema: **9**
Latest completed roadmap task: **Task 2.8 — Quick-Entry Templates**
Current task: **3. v2 release readiness** (Liquid Glass adoption implemented, awaiting owner visual sign-off)
Visual target: **Android/mobile = iOS 27; Windows/Linux desktop = macOS 27 — perceptual match, owner sign-off**

## 0. Program order (decided 2026-11-02)

The owner delegated prioritization. Each item gets its own spec → plan → implementation cycle.

1. **Engineering baseline** — CI (analyze, test, Linux build) restored; v2 deleted the v1 workflow in `9f0573d`. — **DONE** (2026-11-03, checkpoint: docs/superpowers/checkpoints/2026-11-03-ci-baseline-checkpoint.md)
2. **Liquid Glass adoption** — spec `2026-11-02-liquid-glass-renderer-adoption-design.md`. — **DONE** (2026-11-04, awaiting owner visual sign-off; checkpoint: docs/superpowers/checkpoints/2026-11-04-liquid-glass-adoption-checkpoint.md)
3. **v2 release readiness** — import v1 `data.json` (v1 users exist; v2 has no importer today), product name decision (before release: app ID and data paths depend on it), packaging and release automation. Part A (data foundation: whole-toman money, checked arithmetic, v1 importer) — **DONE** (2026-11-04, checkpoint: docs/superpowers/checkpoints/2026-11-04-release-data-foundation-checkpoint.md). Remaining: part B (packaging, release automation, Android signing continuity) and part C (product name).
4. **Habits and Goals** — complete the all-in-one product.
5. **Tasks 2.9–2.11** — Trash/Undo/Audit, dashboard cards, Phase 2 checkpoint. No longer blocked by visual work.

---

## 1. Purpose of this file

This document exists so project work can continue safely across chat/session limits without losing architectural decisions or redoing completed work.

It must contain and continuously maintain:

- the complete Phase 2 roadmap;
- the status of every task;
- links to task-specific specs and checkpoints;
- permanent architectural constraints and invariants;
- the currently approved design for the next task;
- verification requirements;
- commit/checkpoint discipline;
- a concise handoff summary for the next session.

This file is a **living source of truth**.
Every completed task must update this file before its final checkpoint commit.

---

## 2. Authority order

When sources disagree, use this order:

1. **Fresh repository state and tests**
2. **Task-specific checkpoint**
3. **Task-specific approved design/spec**
4. **This `PROJECT_ROADMAP.md`**
5. Older chat history

Do not trust stale chat summaries over the repository.

Completed tasks must not be silently redesigned. If a completed behavior appears wrong, first reproduce the issue and collect evidence.

---

## 3. Permanent development rules

### 3.1 Incremental architecture

Phase 2 extends the existing Drift and notification foundations.

Do not:

- create a parallel normal-operation `tasks_v2` table;
- replace the current task architecture wholesale;
- introduce broad unrelated refactors during a task;
- bundle multiple roadmap tasks into one implementation commit.

### 3.2 Database rules

- Distributed migrations are append-only.
- Existing user data must remain deterministic across migrations.
- Persisted timestamps are UTC.
- Restart behavior must be tested for persisted features.
- Every schema change requires migration and restart tests.
- Current schema version is **9**.
- Task 2.8 moved schema append-only from **7** to **8**.
- Release data foundation moved schema append-only from **8** to **9** (IRT rescaled to whole toman, `legacy_imports` added).

### 3.3 Implementation discipline

Every roadmap task follows:

1. Understand existing code and previous checkpoint.
2. Freeze task scope in an approved design.
3. Write a detailed implementation plan.
4. Start with RED tests.
5. Implement the smallest coherent GREEN slice.
6. Run focused verification.
7. Run `tool/ci.sh` locally until green.
8. Commit implementation.
9. Push; the CI run on the pushed commit must be green.
10. Create/update task checkpoint citing the green CI run URL and commit SHA.
11. Update this file and `docs/WORKLOG.md`.
12. Commit and push checkpoint + docs.

Never mark a task complete from partial verification.

### 3.4 Flutter/tooling guardrail

Do **not** run `flutter upgrade` as part of roadmap implementation or debugging.

Exception (2026-11-02): the Liquid Glass adoption moves the project to Flutter 3.47.x. That happens through a separate SDK checkout during the spike and a `.flutter-version` change on merge. The shared SDK at `~/develop/flutter` is never upgraded in place.

The repository currently emits the accepted Flutter asset-source notice for:

`https://storage.flutter-io.cn`

That notice alone is not a task failure.

### 3.5 Debugging rule

For a failing test/build/analyzer:

- identify the root cause before patching;
- reproduce the failure;
- compare with a working pattern in the same codebase;
- make the smallest fix;
- rerun the failing target first;
- only then rerun the wider suite.

Do not stack speculative fixes.

---

## 4. Phase 2 objective

Evolve the persisted Tasks feature into a durable planning system with:

- four canonical statuses;
- stable display numbering;
- independent per-status ordering;
- List, Kanban, and Calendar views;
- planning fields;
- reminder rules and notification projection;
- shared recurrence;
- recurring task exceptions and occurrence completion;
- recoverable timers and manual time entries;
- quick-entry templates;
- reversible destructive operations with Trash and audit history;
- configurable dashboard cards;
- one final integrated Phase 2 checkpoint.

---

## 5. Canonical task invariants already established

### 5.1 Status

Canonical values:

- `planned`
- `inProgress`
- `completed`
- `canceled`

Persisted parsing is exact. Unknown values must not silently default.

### 5.2 Identity

A Task has:

- immutable internal `id`;
- immutable positive user-facing `displayNumber`.

Deleted display numbers are not reused.

### 5.3 Status-local ordering

`positionInStatus` is zero-based and scoped to one status.

For every status:

`0, 1, 2, ..., itemCount - 1`

Moving/reordering must preserve contiguous positions transactionally.

### 5.4 Terminal timestamps

- `completed` requires `completedAtUtc`;
- `canceled` requires `canceledAtUtc`;
- non-terminal states clear terminal timestamps.

### 5.5 Reminder architecture

Reminder rules are separate persisted entities rather than nullable fields on `TaskItem`.

Task notification owner remains task-scoped and reminder projection reprojects the complete expected schedule set.

### 5.6 Recurrence architecture

Shared recurrence infrastructure is separated from task-specific occurrence state.

Task-specific skip/reschedule/cancel/completion behavior must not leak into the generic recurrence engine.

### 5.7 Timer architecture

Timer persistence is separate from `TaskItem` and `TaskRepository`.

Elapsed time is recoverable from persisted UTC timestamps, not an in-memory stopwatch.

---

# 6. PHASE 2 ROADMAP

## Task 2.1 — Task Status, Display Number, and Per-Status Position

**Status: IMPLEMENTED**

Checkpoint:

`docs/superpowers/checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md`

Delivered foundation:

- canonical four-state `TaskStatus`;
- immutable display numbers;
- status-local contiguous positions;
- deterministic schema migration foundation;
- status-aware repository operations;
- atomic transition/reorder behavior;
- compatibility with the pre-existing Tasks panel.

Do not reopen this task unless fresh evidence demonstrates a regression.

---

## Task 2.2 — Description, Start/Due Time, and Estimated Duration

**Status: IMPLEMENTED**

Checkpoint:

`docs/superpowers/checkpoints/2026-08-04-task-2-2-planning-fields-checkpoint.md`

Delivered planning layer:

- Task description;
- start date/time;
- due date/time;
- estimated duration;
- persisted planning fields;
- shared Task Details draft validation and planning controls.

---

## Task 2.3 — Atomic Board Operations, List, and Kanban Views

**Status: IMPLEMENTED**

Checkpoint:

`docs/superpowers/checkpoints/2026-08-04-task-2-3-board-list-kanban-checkpoint.md`

Delivered:

- atomic board operations;
- List view;
- Kanban view;
- status-aware transitions and ordering;
- Tasks panel view integration.

List remains the default view unless a later approved requirement explicitly changes that.

---

## Task 2.4 — Task Reminder Rules and Notification Projection

**Status: IMPLEMENTED**

Checkpoint:

`docs/superpowers/checkpoints/2026-08-04-task-2-4-reminders-checkpoint.md`

Delivered:

- task reminder rule domain;
- Drift persistence;
- reminder draft/editor UI;
- notification projection;
- integration with the existing notification coordinator;
- reminder schedule reconciliation tied to task lifecycle.

Reminder rules remain separate from `TaskItem`.

---

## Task 2.5 — Shared Recurrence Domain and Occurrence Engine

**Status: IMPLEMENTED**

Checkpoint:

`docs/superpowers/checkpoints/2026-08-05-task-2-5-recurrence-checkpoint.md`

Delivered:

- shared recurrence domain;
- recurrence frequency/end/rule infrastructure;
- deterministic occurrence engine;
- recurrence boundary intended for reuse beyond Tasks;
- recurrence test coverage for date/time edge cases.

Shared recurrence must remain generic.

---

## Task 2.6 — Recurring Tasks, Exceptions, and Calendar View

**Status: IMPLEMENTED**

Implementation commit:

`55f8e72 feat: add recurring tasks and calendar`

Checkpoint commit:

`387e046 docs: checkpoint recurring tasks and calendar`

Checkpoint:

`docs/superpowers/checkpoints/2026-08-06-task-2-6-recurring-calendar-checkpoint.md`

Delivered:

- task recurrence persistence;
- task occurrence projection;
- exception/completion state;
- recurring reminder projection;
- Calendar view;
- recurring Task integration with the existing planning model.

---

## Task 2.7 — Timer Lifecycle and Recoverable Time Entries

**Status: IMPLEMENTED AND FRESHLY VERIFIED**

Implementation commit:

`99dc7182c03545c102b730f52985a6ae32b3349a`

Checkpoint commit:

`b556ea11fb04f253fb464c6f0f6abd458726b90a`

Checkpoint:

`docs/superpowers/checkpoints/2026-08-06-task-2-7-timer-checkpoint.md`

Delivered:

- Drift schema **7**;
- cascading `task_time_entries`;
- database-enforced single global running/paused timer slot;
- running, paused, stopped lifecycle;
- UTC-derived elapsed-time recovery;
- pause/resume/stop and process restart recovery;
- manual time entry creation/edit/delete;
- overlap validation;
- task-scoped and global Riverpod streams;
- timer controls/history in edit-mode Task Details;
- active timer visibility in Tasks panel;
- per-task total time badges;
- schema-6 → schema-7 migration/restart verification.

Fresh Task 2.7 evidence:

- focused tests: **72 passed**
- full suite: **1188 passed**
- `flutter analyze`: **No issues found**
- Linux debug build: **passed**
- `git diff --check`: **clean**
- Task 2.5 verifier: **passed**
- Task 2.6 verifier: **passed**
- Task 2.7 semantic verifier: **passed**

Compatibility invariants:

- timer fields are not added to `TaskItem`;
- `TaskRepository` signatures remain unchanged;
- task deletion cascades task time entries;
- reminder and recurrence repositories remain independently persisted;
- paused timer does not accumulate offline time;
- running timer does.

---

## Task 2.8 — Quick-Entry Templates

**Status: IMPLEMENTED AND FRESHLY VERIFIED**

Implementation commit:

`0972d8feba1566c0a876d8d5e3969f95281e2e6e`

Checkpoint commit:

`458499dfdb3504034d1d7115bd1515fe20ffc876`

Checkpoint:

`docs/superpowers/checkpoints/2026-08-07-task-2-8-quick-entry-templates-checkpoint.md`

Fresh Task 2.8 evidence:

- focused tests: **57 passed**
- full suite: **1245 passed**
- `flutter analyze`: **No issues found**
- Linux debug build: **passed**
- `git diff --check`: **clean**
- Task 2.5 verifier: **passed**
- Task 2.6 verifier: **passed**
- Task 2.7 verifier: **passed**
- Task 2.8 complete verifier: **passed**

This is the only normal roadmap task that should be implemented next.

## 7.1 Product goal

Allow users to create Tasks quickly from reusable templates while retaining the full Task Details review/edit flow before saving.

Templates are not Tasks. They are reusable configuration snapshots.

---

## 7.2 Chosen product model

Use a **hybrid template system**:

- built-in system templates;
- unlimited user-created templates.

Initial system template catalog contains seven entries:

1. جلسه
2. پیگیری
3. کار عمیق
4. کار روزانه
5. موعد پرداخت
6. تماس / پیام
7. خرید / کار شخصی

Exact default field values should be finalized in the Task 2.8 implementation plan/tests rather than improvised during UI coding.

---

## 7.3 System template behavior

System templates:

- cannot be edited in place;
- cannot be permanently deleted;
- can be hidden by the user;
- can be restored;
- can be reordered for the user's picker;
- can be duplicated.

Duplicating a system template creates an independent **custom template**.

This preserves a known built-in baseline while allowing users to remove unwanted defaults from normal view.

A management action must exist to restore hidden/default system templates.

---

## 7.4 Custom template behavior

Users can create unlimited custom templates.

Custom templates support:

- create;
- edit;
- delete;
- hide/show;
- duplicate;
- reorder.

Custom templates are fully user-owned.

---

## 7.5 Template name vs Task title

These are separate fields.

Example:

- template name: `جلسه کاری`
- prefilled Task title: `جلسه با …`

`templateName` identifies the reusable template in template management.

The Task title is just the initial value applied to a new Task draft.

---

## 7.6 Fields stored by a template

A template stores reusable Task intent:

- template name;
- initial Task title;
- description;
- priority;
- estimated duration;
- reminder defaults;
- recurrence defaults.

A template does **not** store fixed Task scheduling dates.

Specifically, do not copy/store as fixed Task values:

- start date/time;
- due date/time;
- Task ID;
- display number;
- status;
- board position;
- created/updated/completed/canceled timestamps;
- timer state;
- time entries;
- occurrence completion history;
- recurrence exception history.

---

## 7.7 Template → Task flow

Selecting a template must **not immediately create a Task**.

Flow:

1. user opens the template picker;
2. selects a template;
3. application creates a new `TaskDetailsDraft`;
4. reusable template values are applied;
5. start/due dates remain empty;
6. full Task Details form opens;
7. user reviews/changes values and chooses scheduling dates;
8. normal Task validation/save flow persists the Task.

This preserves the existing Task creation boundary.

---

## 7.8 Quick-entry UI

The existing “new Task” entry becomes a split action:

- primary action: open an empty new Task form;
- adjacent arrow: open Template Picker.

The picker shows active templates and provides access to template management.

Picker organization:

- system templates;
- custom templates;
- management action at the end.

Picker metadata may show:

- template name;
- initial Task title;
- priority;
- estimated duration;
- reminder presence;
- recurrence presence.

Hidden templates are excluded from the normal picker.

---

## 7.9 Template management UI

“مدیریت قالب‌ها” is accessed from the template picker.

Management UI must support:

- create custom template;
- edit custom template;
- delete custom template with confirmation;
- duplicate system/custom template;
- hide template;
- restore hidden template;
- drag/reorder;
- restore system defaults/visibility.

System templates must visually distinguish themselves from user templates.

---

## 7.10 Template editor

Use a dedicated template draft/domain boundary rather than forcing `TaskDetailsDraft` to represent a template.

Proposed UI draft:

`TaskTemplateDraft`

Template editor fields:

- template name;
- initial Task title;
- description;
- priority;
- estimated duration;
- reminder defaults;
- recurrence defaults.

There are no Start/Due date controls in the template editor.

The editor may reuse existing sub-controls where their semantics are compatible, but must not weaken existing Task validation rules.

---

## 7.11 Reminder template behavior

Template reminder definitions are reusable defaults, not persisted Task reminder rows.

When a template is applied:

- do not reuse reminder row IDs;
- create new reminder draft identities;
- Task reminder persistence occurs only when the new Task is actually saved.

If a reminder requires a Due/Start anchor that the user has not yet selected, the Task form retains the configured intent and existing validation explains what scheduling input is still required.

Do not create live notification schedules directly from a template.

---

## 7.12 Recurrence template behavior

Template recurrence is reusable configuration, not an existing Task recurrence row.

When applied:

- do not reuse recurrence IDs;
- do not carry an old occurrence anchor;
- do not carry exception/completion history.

### Relative recurrence end

A template must not preserve a fixed absolute “repeat until” date from the source Task.

Supported reusable end forms:

- no end;
- after N occurrences;
- **N days after the recurrence anchor**.

Example:

`30 days after anchor`

When the new Task receives its real recurrence anchor, its absolute end date is derived.

If the Task anchor later changes while the end is still linked relatively, recompute the end.

If the user manually overrides the absolute end in Task Details, the relative link is broken and the explicit user value wins.

---

## 7.13 Save existing Task as template

Edit-mode Task Details must offer:

**ذخیره به‌عنوان قالب**

This produces a new custom template.

Copied:

- title → initial Task title;
- description;
- priority;
- estimated duration;
- reminder configuration;
- recurrence configuration.

Not copied:

- Task identity;
- display number;
- status;
- board position;
- fixed scheduling dates;
- lifecycle timestamps;
- timer/time entries;
- occurrence completion state;
- recurrence exceptions.

If the source Task recurrence ends on a fixed date, convert the source recurrence end to a relative number of days from its recurrence anchor before storing it in the template.

---

## 7.14 Task 2.8 persistence architecture

**Approved approach: one unified template repository/table for system and custom template state.**

Reasons:

- one picker query;
- one ordering model;
- consistent hide/show behavior;
- simple custom/system management UI;
- easy addition of future built-in catalog entries.

Proposed template identity fields include:

- template internal ID;
- kind (`system` / `custom`);
- stable system key for built-ins;
- template name;
- initial Task title;
- reusable Task values;
- hidden state;
- display order;
- created/updated timestamps.

System catalog content is canonical application-owned data.

User-controlled state such as visibility/order must survive application updates.

The implementation plan must choose a deterministic synchronization rule so newly introduced system templates can appear without overwriting user visibility/order choices for existing system templates.

---

## 7.15 Task 2.8 schema

Proposed migration:

**schema 7 → schema 8**

The exact Drift table/column representation must be frozen by tests before implementation.

Required migration guarantees:

- existing Tasks, reminders, recurrence, occurrence state, and time entries remain untouched;
- upgrade is deterministic;
- restart after migration preserves template state;
- system template synchronization is idempotent;
- no duplicate built-in template identities;
- custom templates survive restarts.

---

## 7.16 Task 2.8 repository/application boundaries

Expected new bounded units:

- `TaskTemplate` domain entity;
- `TaskTemplateDraft` presentation/editor state;
- `TaskTemplateRepository`;
- Drift implementation;
- system-template catalog/synchronizer;
- template-to-task draft mapper;
- Task-to-template mapper;
- template picker;
- template manager/editor.

Keep responsibilities separate:

- repository persists template state;
- catalog defines built-in defaults;
- synchronizer reconciles built-ins with persisted system state;
- mapper converts reusable configuration;
- Task save flow remains responsible for creating Tasks/reminders/recurrence.

Do not make the picker persist Tasks.

---

## 7.17 Task 2.8 error and validation behavior

At minimum test and define:

- blank template name;
- blank/invalid initial title policy;
- invalid priority/duration;
- invalid reminder configuration;
- invalid recurrence configuration;
- impossible relative recurrence-end values;
- custom delete;
- system delete rejection;
- system edit rejection;
- duplicate behavior;
- duplicate system synchronization;
- reorder with incomplete/duplicate/foreign IDs;
- hidden template picker exclusion;
- restore behavior;
- restart persistence;
- Task conversion with new IDs;
- Task conversion with no fixed start/due carry-over.

Mutation failures must not partially write order/visibility/template content.

---

## 7.18 Task 2.8 testing plan

Task 2.8 must add focused coverage across:

### Domain
- `TaskTemplate` invariants;
- relative recurrence-end representation;
- system/custom behavior.

### Data
- schema 7 → 8 migration;
- restart;
- CRUD;
- hide/restore;
- reorder;
- duplicate;
- built-in synchronization.

### Mapping/application
- template → Task draft;
- Task → custom template;
- new reminder/recurrence identities;
- excluded scheduling/lifecycle/time fields.

### Presentation
- split New Task action;
- picker;
- system/custom sections;
- management entry;
- create/edit/delete custom template;
- system hide/restore/duplicate;
- drag reorder;
- save Task as template;
- template opens full Task form rather than creating immediately.

### Regression
Retain green coverage for:

- Task Details;
- List;
- Kanban;
- Calendar;
- reminders;
- recurrence;
- timers;
- persistence providers;
- schema restart chain.

---

## 7.19 Task 2.8 exit criteria

Task 2.8 is complete only when all of the following are fresh:

- Task 2.8 focused tests pass;
- prior Task 2.5/2.6/2.7 verifiers pass;
- `flutter analyze` is clean;
- full project test suite passes;
- Linux debug build passes;
- `git diff --check` is clean;
- implementation commit is pushed;
- Task 2.8 checkpoint records exact implementation commit and evidence;
- Task 2.8 semantic verifier passes;
- checkpoint commit is pushed;
- this `PROJECT_ROADMAP.md` marks Task 2.8 IMPLEMENTED and advances CURRENT TASK to 2.9.

---

# 7. CURRENT TASK — Visual Foundation 2.A — Liquid Glass Renderer Adoption

**Status: LIQUID GLASS ADOPTION IMPLEMENTED (2026-11-04) — awaiting owner visual sign-off — checkpoint: docs/superpowers/checkpoints/2026-11-04-liquid-glass-adoption-checkpoint.md**

Spike verdict was GO: docs/superpowers/references/2026-11-04-liquid-glass-spike-report.md

Spike result: Linux YES, Android YES (visual), hooks YES, perf PASS, Windows unverified. Adoption is done; deferred items are listed in the checkpoint. History: `docs/WORKLOG.md` entry "2026-11-04 — Liquid Glass spike: GO".

Spec: `docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md`

Gate history:

- Gate A — Reproducible Source Extraction: **COMPLETE**
- Gate B — Platform Family, Source Tokens, Typography and Metrics: **COMPLETE** (`docs/superpowers/checkpoints/2026-08-15-visual-foundation-2a-gate-b-complete-checkpoint.md`)
- Gate C — custom shader renderer: **SUPERSEDED** on 2026-11-02. Its shader was still a passthrough, no screen used it, and its pixel-golden gate against the design tool's renderer could not pass (61.33 % diff).
- Typography deviation (Vazirmatn) and symbol deviation (project vectors): **still approved**.

Rules that still hold:

- Android/mobile targets iOS 27; Windows/Linux desktop targets macOS 27;
- no Material, Fluent or native desktop visual fallback;
- source-derived tokens (color, typography, metrics, radii) replace magic numbers;
- Liquid Glass is a centralized material system behind `AppleLiquidGlass`;
- glass is for the navigation/control layer, not content cards;
- light/dark and interactive states need evidence on the side-by-side review page.

Rules superseded on 2026-11-02 (see spec §3):

- `flutter upgrade` ban → Flutter 3.47.x via separate SDK checkout, `.flutter-version` changed on merge;
- pixel-golden acceptance → perceptual side-by-side acceptance, owner sign-off;
- no silent fallback → runtime `FakeGlass` fallback allowed, but integration tests fail if full glass is not active on a supported platform.

Next action: owner visual sign-off on the review page; then program item 3 (v2 release readiness).

---

# 8. UPCOMING ROADMAP

## Task 2.9 — Undo, 30-Day Trash, and Audit History

**Status: PENDING — DESIGN NOT STARTED (no longer blocked by visual work; see §0 program order)**

Planned generic infrastructure:

- operation command;
- inverse/undo payload;
- soft-delete timestamp;
- purge-after timestamp;
- audit event;
- Trash retention of 30 days;
- deterministic restart-safe purge.

Required behavior already agreed in the Phase 2 design:

A Task in Trash must not produce:

- reminders;
- active recurrence occurrences;
- dashboard counts.

Detailed design must be created immediately before implementation.

Create and approve Task 2.9's detailed functional design and implementation plan when it comes up in the §0 program order, then proceed RED → GREEN.

---

# 8. UPCOMING ROADMAP

## Task 2.10 — Dashboard Card Visibility and Ordering

**Status: PENDING**

Planned persistence:

- module visibility;
- card visibility;
- card order;
- per-device layout preferences where required.

Task domain data must remain independent of dashboard layout state.

Detailed design is still required.

---

## Task 2.11 — Phase 2 Integrated Checkpoint

**Status: PENDING**

Purpose:

- integrated regression verification of Tasks Phase 2;
- ensure migrations work from supported older schema paths;
- confirm notifications/recurrence/timers/templates/trash/dashboard configuration coexist;
- close Phase 2 with fresh full-suite, analyze, build, restart, and semantic-verifier evidence.

No new unrelated feature work should be added under Task 2.11.

---

# 9. Current repository map for Tasks

At the Task 2.8 checkpoint, the Tasks feature includes these major boundaries:

### Application

- task occurrence projector;
- recurrence service;
- reminder projection/projector/rules services;
- timer service;
- Task-template mapper.

### Data

- Drift Task repository;
- Drift reminder repository;
- Drift Task-template repository;
- system Task-template catalog/synchronizer/codec;
- Drift recurrence repository;
- Drift time repository;
- reminder-aware Task repository;
- recurrence codec.

### Domain

- Task item/status/repository;
- reminder rule/trigger/repository;
- recurrence rule/bundle/exception/repository;
- occurrence completion/calendar occurrence;
- time entry/repository;
- Task template/repository/relative recurrence defaults.

### Presentation

- List/Kanban board operations and views;
- Calendar board;
- Task Details dialog/form/drafts;
- duration/date-time/reminder/recurrence fields;
- timer panel/manual time-entry dialog;
- Task-template picker/manager/editor and dedicated presentation drafts.

Task 2.9 should extend these boundaries rather than collapse them into one large file.

---

# 10. Verification baseline

Latest fully recorded checkpoint baseline after Task 2.8:

- focused Task 2.8: **57**
- full project tests: **1245**
- analyzer: **clean**
- Linux debug build: **green**
- database schema: **8**

These numbers are historical evidence, **not permanent minimum contracts**.

After adding a new task, record the actual new counts rather than assuming a target count.

---

# 11. Commit and checkpoint convention

Use small, focused commits.

Established recent pattern:

- implementation commit:
  - `feat: ...`
- checkpoint commit:
  - `docs: checkpoint ...`

Examples already in history:

- `55f8e72 feat: add recurring tasks and calendar`
- `387e046 docs: checkpoint recurring tasks and calendar`
- `99dc718 feat: add recoverable task timer`
- `b556ea1 docs: checkpoint recoverable task timer`

Do not create a checkpoint that claims evidence from an unpushed or different implementation commit.

A checkpoint should record the exact implementation commit hash.

---

# 12. Mandatory update protocol for this file

At the **start** of a task:

1. change `CURRENT TASK`;
2. mark task `DESIGN IN PROGRESS` or `DESIGN APPROVED`;
3. record approved design decisions;
4. link the task-specific spec when written.

During implementation:

- update this file only for scope/decision changes that were explicitly approved;
- do not mark implementation complete early.

At task completion:

1. mark task `IMPLEMENTED AND FRESHLY VERIFIED`;
2. add implementation commit hash;
3. add checkpoint commit hash after checkpoint;
4. add checkpoint path;
5. record focused/full/analyze/build evidence;
6. record schema version if changed;
7. record important compatibility invariants;
8. set the next roadmap task as `CURRENT TASK`;
9. commit this update as part of the checkpoint/documentation boundary.
10. append an entry to `docs/WORKLOG.md`.

---

# 13. Handoff checklist for a new session

A new assistant/session must do this before editing code:

1. Read `CLAUDE.md`, then `PROJECT_ROADMAP.md`, then the latest entries of `docs/WORKLOG.md`.
2. Run:
   - `git status -sb`
   - `git log -8 --oneline --decorate`
3. Confirm local HEAD vs upstream.
4. Read the CURRENT TASK section here.
5. Read its task-specific spec/checkpoint files.
6. Read only the relevant implementation files/tests.
7. Do not repeat already approved product questions unless the repository contradicts this file.
8. Do not modify completed tasks without evidence.
9. Continue from the first unfinished gate of CURRENT TASK.
10. Keep this file updated before final checkpoint.

Suggested new-chat prompt:

> Read `PROJECT_ROADMAP.md` from the repository first, then inspect git status and the CURRENT TASK references. Treat completed tasks and approved decisions as fixed unless repository evidence proves otherwise. Continue from the first unfinished gate, use RED → GREEN, and do not mark anything complete without focused tests, analyzer, full tests, Linux build, diff check, pushed implementation commit, checkpoint verifier, and pushed checkpoint.

---

# 14. Current handoff summary

As of this document:

- Phase 2 Tasks **2.1 through 2.8 are implemented**.
- Task 2.8 is the latest fully verified checkpoint.
- Repository schema is **9**.
- Task 2.8 is implemented, checkpointed, and semantically verified.
- Program order is in §0 (decided 2026-11-02; owner delegated prioritization).
- CURRENT TASK is **3. v2 release readiness** (§0). Liquid Glass adoption is implemented (2026-11-04), awaiting owner visual sign-off; checkpoint `docs/superpowers/checkpoints/2026-11-04-liquid-glass-adoption-checkpoint.md`. Inputs for item 3: `docs/superpowers/references/2026-11-04-v1-data-format-and-v2-mapping.md` and `docs/superpowers/references/2026-11-04-money-scale-overflow-analysis.md`. See the latest `docs/WORKLOG.md` entry.
- CI baseline is DONE (2026-11-03): every push runs `tool/ci.sh` on GitHub Actions.
- The Gate C custom renderer is removed (`c2d76dc`); glass goes through `AppleLiquidGlass`.
- Shader filters work on Linux desktop only with Impeller enabled (`flutter test integration_test/... -d linux --enable-impeller` → supported; without the flag → unsupported).
- v1 data import is implemented (2026-11-04): Settings, then "Import from v1" (preview, one transaction, idempotent via `legacy_imports`). Release still needs part B (packaging) and part C (product name).
- IRT money is whole toman (scale 0, schema 9); `Money` arithmetic is overflow-checked.
- Next step: part B: packaging + Android signing + Android CI build.
- Tasks 2.10–2.11 remain pending and must be designed individually before implementation.

---

## 15. Related canonical documents

Primary Phase 2 design:

`docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md`

Latest checkpoint:

`docs/superpowers/checkpoints/2026-08-07-task-2-8-quick-entry-templates-checkpoint.md`

Latest semantic verifier:

`tool/verify_phase2_task2_8_complete.py`

Current Apple UI source manifest:

`docs/superpowers/references/2026-08-09-apple-ui-kit-source-manifest.md`

Current frozen visual fidelity contract:

`docs/superpowers/specs/2026-08-09-apple-liquid-glass-fidelity-contract.md`

Current visual-system design:

`docs/superpowers/specs/2026-08-09-apple-liquid-glass-visual-system-design.md`

This file should point to newer equivalents as the project advances.

<!-- VISUAL_FOUNDATION_2A_GATE_B_CHECKPOINT_2026_08_15 -->
### Visual Foundation 2.A — Gate B checkpoint (2026-08-15)

- Gate B source-token foundation is complete and verified.
- Completed: B.1 platform family, B.2 token/theme boundary, B.3 source reference,
  B.4 semantic colors, B.5 typography including resolved token-group repair,
  B.6A materials, B.6B variant-aware metrics, and B.6C motion.
- Motion source is the approved official SwiftUI runtime reference.
- Exact internal Liquid Glass motion is **not** claimed.
- Reduce Motion policy remains required.
- No guessed motion or typography values were introduced.
- Task 2.9 remains blocked until the entire Visual Foundation 2.A is complete.
- Next implementation gate: **Gate C — Liquid Glass primitives**.
