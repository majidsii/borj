# Dashboard Shakhsi v2 - IA and design-system architecture research

Date: 2026-11-05 (research done 2026-11-04). Branch feat/v2-complete-dashboard. Research only; no code changed.
Repo paths are relative to the repo root.
"SPEC" = docs/superpowers/specs/2026-07-26-personal-dashboard-rebuild-design.md.
"LG" = docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md.
"RM" = PROJECT_ROADMAP.md.
PKG = ~/.pub-cache/hosted/pub.flutter-io.cn/liquid_glass_renderer-1.0.0-dev.2/lib/src.

---------------------------------------------------------------------
## A. Inventory and current navigation

### A1. Feature inventory (built vs planned)

BUILT = logic and UI present. PARTIAL = one of the two. PLANNED = not in code.

Tasks (user tasks: capture, plan, schedule, track and review work)
- Task CRUD, 4 statuses, display numbers, per-status order: BUILT (lib/features/tasks/domain/task_repository.dart:9-29; RM Tasks 2.1-2.3).
- Priority, description, start/due time, estimate: BUILT (task_details_dialog.dart, task_details_form.dart; RM 2.2).
- List view with filters, sort, progress ring: BUILT (lib/features/dashboard/presentation/widgets/tasks_panel.dart, 1850 lines; _TaskRow :1269).
- Kanban with drag between statuses: BUILT (lib/features/tasks/presentation/task_board/task_kanban_board.dart, 776 lines).
- Calendar view (Jalali, recurring occurrences): BUILT (task_calendar/task_calendar_board.dart, 719 lines).
- Reminder rules and notification projection: BUILT (lib/features/tasks/application/task_reminder_*; task_reminder_rules_field.dart).
- Recurrence, exceptions, per-occurrence completion: BUILT (lib/core/recurrence, task_recurrence_field.dart).
- Timer (start/pause/stop), manual time entry, recovery: BUILT (task_timer/task_timer_panel.dart 513 lines, task_manual_time_entry_dialog.dart).
- Quick-entry templates (picker, manager, editor, save as template): BUILT (task_templates/*; RM 2.8).
- Subtasks, tags, goal/challenge links: PLANNED (SPEC s10). No code found.
- Undo, 30-day Trash, audit history: PLANNED (RM Task 2.9, design not started).
- Dashboard card visibility and order: PLANNED (RM Task 2.10).

Finance (user tasks: record money, see month status, manage debts and installments, report)
- Add income/expense, delete: BUILT (finance_panel.dart: _EntryForm :816, _TransactionRow :1497; finance_repository.dart:13-15).
- Debts and payments: BUILT (finance_repository.dart:17-25; _DebtRow :1155).
- Installment plans and pay-next: BUILT (finance_repository.dart:27-34; _InstallmentRow :1266).
- Summary cards, 6-month trend, 7-day chart, donut by category, report service: BUILT (finance_charts.dart, lib/features/finance/application/finance_report_service.dart).
- "Report and export" button: stub with empty onPressed (finance_panel.dart:159-163).
- Categories: hard-coded list (finance_panel.dart:33-46), not DB-backed. PARTIAL (SPEC s7.9 requires DB categories).
- Accounts, split/refund, monthly planning, budgets and rollover, reconciliation, financial calendar, attachments, category filter, month-over-month, custom ranges, safe-to-spend: PLANNED (SPEC s7.1-7.9, s18).
- Routes /finance, /finance/transactions, /finance/calendar, /finance/debts, /finance/installments are placeholders that render only a title (lib/app/router/app_router.dart:10-14, :32-55).

Time tracking
- Timer and manual entries linked to tasks: BUILT inside Tasks (lib/features/tasks/domain/task_time_entry.dart).
- Standalone module (Work/Useful/Rest/Wasted, custom categories, overlap policy, untracked time, edit past entries): PLANNED (SPEC s12).

Habits, Challenger, Goals: PLANNED (RM s0 item 4; SPEC s13-15). Nothing in lib/features.

Reports (daily/weekly/monthly, cross-module): PLANNED (SPEC s16). Only finance charts exist.

Cross-cutting
- Global search: PLANNED (SPEC s6.1).
- Global quick entry (expense, income, task, timer, manual time, habit): PLANNED (SPEC s5.1). Today quick entry is task templates plus the inline finance form.
- Settings: PARTIAL, one section (legacy import) (lib/features/settings/presentation/settings_screen.dart:25-63).
- v1 importer with preview, report, banner: BUILT (lib/features/legacy_import/presentation/*).
- Backup/restore/export (encrypted, JSON/CSV/MD), PIN and biometrics, notification settings UI, theme settings (only a toggle button), onboarding, module visibility, home widgets, attachments: PLANNED. /backup and /migration are placeholders (app_router.dart:62-71). cryptography and flutter_secure_storage are already in pubspec.yaml.
- Notifications: BUILT as infrastructure (Linux systemd timers, flutter_local_notifications elsewhere); deep-link router binding in lib/app/router/notification_*.
- Debug glass review page: BUILT, kDebugMode only (app_router.dart:72-77).

### A2. Screens, dialogs and entry points today

Routes (app_router.dart:9-20): / (DashboardScreen), /settings (real), /debug/glass-review (debug), 7 placeholders.
Tasks vs Finance is a local state switch (_selectedPanel, dashboard_screen.dart:25) via AnimatedSwitcher (:54-77), not a route.
Dialogs from tasks_panel.dart: task details editor (:408, :661), template picker AlertDialog (:447), template manager Dialog (:479), template editor (:542, :558, :611).
Other: manual time-entry dialog (task_manual_time_entry_dialog.dart:79 uses AppleLiquidGlass), Jalali date/time popup (task_jalali_date_time_field.dart:529), legacy import dialogs (legacy_import_dialogs.dart), import banner on the dashboard.
Finance panel is all inline: form card, lists, small action buttons (_MiniButton :1455).

### A3. Current navigation map

```
MaterialApp.router (fa_IR, Vazirmatn)                app_bootstrap.dart:50-60
 /                DashboardScreen
    TopBar [brand island | Tasks/Finance pill | theme toggle | settings]   dashboard_screen.dart:99-
    LegacyImportBanner
    TasksPanel   (list | kanban | calendar, filters, sort, templates, timer, dialogs)
    FinancePanel (summary, charts, entry form, debts, installments, recent transactions)
 /settings        back arrow + LegacyImportSection only
 /finance*, /backup, /migration   placeholders
 /debug/glass-review              debug only
```

### A4. Problems

1. Narrow column everywhere. Dashboard and Settings clamp content to contentMaxWidth = 780 (lib/app/theme/original_design_tokens.dart:4; dashboard_screen.dart:44-47; settings_screen.dart:27-29). The reference desktop window is 1180x780 (tokens :27-28); more than a third is empty. No sidebar, multi-column or inspector.
2. Kanban clipped. Four fixed-width columns (274 or 300 px, chosen by constraints.maxWidth < 700, task_kanban_board.dart:40) inside a horizontal SingleChildScrollView (:44). 4x300 + 3x12 = 1236 px, inside a 780 px column, so the last columns are cut off and need horizontal scroll. Columns never flex to window width.
3. Navigation is not a system. Module switch is widget state: no deep link, no back stack, no restoration, so notification routing has no panel target. Eight more modules cannot fit in the top bar, which already hides text at <=560 and compacts tabs at <=480 (dashboard_screen.dart, _TopBar LayoutBuilder).
4. The "dashboard" is two module screens behind a tab, with no today summary or cross-module cards (SPEC s6; RM 2.10 pending).
5. Glass misuse and cost. Content cards still use OriginalGlass (blur sigma 28 plus saturation, large shadows: lib/app/widgets/original_glass.dart; 9 OriginalGlass( call sites in 11 files). LG s6 says content must be solid. The adapter always uses LiquidGlass.withOwnLayer (lib/app/apple_visual/widgets/apple_liquid_glass.dart:52), so each glass control is its own backdrop sample. The top bar alone has about 5 (dashboard_screen.dart:180, :262, :387, :419 plus brand). The LG s5 plan (siblings share one layer) is not implemented: no LiquidGlassLayer anywhere in lib (only LiquidGlass.precache at app_bootstrap.dart:16).
6. Two visual systems: OriginalPalette (ThemeExtension, v1 CSS port) and apple_visual (AppleVisualScope InheritedWidget, apple_visual_scope.dart:8). Screens read Original* for colors and Apple* only for glass. The iOS27/macOS27 family is resolved (apple_visual_platform_resolver.dart:5-12) but no screen branches on it.
7. Material remains: MaterialApp, Scaffold, AlertDialog, Dialog, IconButton and Icons.* (settings_screen.dart:39; finance_panel.dart:156), against the RM s7 rule "no Material fallback".
8. RTL fragility: Settings back uses Icons.arrow_forward by hand (settings_screen.dart:39). Needs a directional icon helper.
9. Dialogs for everything on every size: no sheets, no inspector.
10. Accessibility: only reduce-motion is read (lib/app/widgets/aurora_background.dart:45-46). No reduce-transparency, high-contrast or text-scale handling. The motion policy enum is unused by screens (apple_visual_motion.dart:3).
11. Stub UI: export button does nothing (finance_panel.dart:159-163).
12. Fixed pixel widths in toolbars (tasks_panel.dart _DesktopToolbar, 148 px control) instead of breakpoint tokens.

---------------------------------------------------------------------
## B. Target information architecture

### B1. Principles
- Navigate by noun (module), act by verb (global quick entry), find by search (global).
- Glass only on chrome: tab bar, sidebar, toolbar, sheets, popovers, floating buttons. Content is solid (LG s6).
- One router tree for all sizes. The shell changes, the routes do not, so deep links and notifications work everywhere.
- Details: push on compact, inspector on expanded. No centered modal for editing on phones.

### B2. Sitemap

```
Today (Home)       greeting + Jalali date, active timer, today tasks, habits left, month finance glance,
                   goal/challenge progress, quick actions (configurable cards, RM 2.10)
Finance
  Overview         month metrics, safe-to-spend, charts
  Transactions     list, filters, category filter       -> Transaction detail
  Calendar         month | week | agenda                -> Day detail
  Debts and receivables                                 -> Debt detail + payments
  Installments                                          -> Plan detail
  Accounts and budgets (planned)
Plan (SPEC "برنامه")
  Tasks            List | Board | Calendar              -> Task detail (timer, reminders, recurrence)
  Time             timer, today timeline, entries, categories
  Habits           today list, adherence                -> Habit detail
  Challenges       active, history                      -> Challenge detail
  Goals            status groups                        -> Goal detail (milestones, progress explainer)
Reports            daily | weekly | monthly (cross-module)
Search             global, separate
More / Settings
  Settings         appearance, notifications per category, privacy (PIN/biometrics), modules and dashboard cards, currency
  Backup and restore (encrypted, auto backups, JSON/CSV/MD export)
  Import           v1 data.json (exists)
  Trash and history (RM 2.9)
  Templates manager (exists as dialog)
  About
```

### B3. Phone (compact, under 600 dp), iOS 27 pattern

Floating glass tab bar, at most 5 tabs, plus a detached Search item at the trailing end. Proposed (RTL: first tab on the right):
1. امروز (Today)
2. مالی (Finance)
3. برنامه (Plan hub: tasks, time, habits, challenges, goals)
4. گزارش‌ها (Reports), or fold into Plan until habits ship
5. بیشتر (More: settings, backup, trash, import, about)
+ Search.
Recommendation: ship 4 tabs + Search until Habits/Goals exist.
Quick entry is not a tab. A floating glass "+" (or toolbar "+") opens a bottom sheet: expense, income, task, start timer, manual time, habit progress (SPEC s5.1). This replaces SPEC's centre-add tab.
UNVERIFIED: whether iOS 27 keeps the iOS 26 detached search tab; check Apple HIG.
Per-tab stacks: go_router StatefulShellRoute.indexedStack, one Navigator per tab, state kept.
Navigation levels:
- Primary: tab bar.
- Secondary: large-title navigation bar plus segmented control (Tasks: List/Board/Calendar; Finance: Overview/Transactions/Calendar/Debts/Installments as scrollable segments).
- Tertiary: detail pushes and sheets.
Presentation on compact:
- Push (slide, swipe-back mirrored for RTL): task, transaction, debt, plan, habit, goal and challenge detail; settings sub-pages; report drill-down.
- Sheet (medium/large detents with grabber): quick entry, add/edit transaction, add/edit task, template picker, filters, sort, date/time picker, timer controls, calendar day details.
- Full-screen cover: onboarding, PIN lock, restore progress.
- Context menu or popover: row actions (status, priority, delete), toolbar overflow, view switch.
- Alert: destructive confirm only; prefer an Undo toast (SPEC s19).
- Kanban: one status column per page, paged horizontally, with status chips.

### B4. Desktop (expanded), macOS 27 pattern

Floating glass sidebar on the leading edge (physical right in RTL), collapsible. Sections:
- امروز
- مالی (disclosure: نمای کلی، تراکنش‌ها، تقویم مالی، بدهی/طلب، اقساط، حساب‌ها و بودجه)
- برنامه‌ریزی: تسک‌ها، زمان، عادت‌ها، چالش‌ها، اهداف
- گزارش‌ها
- footer: جستجو (Ctrl+K), تنظیمات (Ctrl+,), quick-entry button.
Window toolbar (glass, grouped): [sidebar toggle] [title or view switcher] ... [search field] [+ New menu] [export] [inspector toggle].
Layout: sidebar | content (list, board or calendar) | optional trailing inspector (physical left in RTL), resizable 320-420 dp.
Presentation on expanded:
- Inspector (docked): task, transaction, debt, plan, habit and goal details. Replaces centered edit dialogs.
- Popover: date/time pickers, filters, sort, template picker, row menus, compact quick entry anchored to "+" (Ctrl+N).
- Window-attached sheet: destructive confirms, import preview/report, backup restore, onboarding steps.
- Dialog: blocking only (PIN, fatal errors).
- Search: Ctrl+K overlay, results grouped by module, opens the owning detail (SPEC s6.1).
- Keyboard: Ctrl+N new, Ctrl+F filter, Ctrl+K search, arrows in lists, Delete with Undo, Space toggles done.

### B5. Breakpoints (logical width; MediaQuery.sizeOf in the shell, LayoutBuilder inside panes)

Compact < 600 | Medium 600-1023 | Expanded 1024-1439 | Large >= 1440.
- Compact: tab bar, single column, stack pushes, sheets.
- Medium: collapsed icon sidebar (touch devices keep the tab bar); master/detail for Tasks and Transactions; detail as pushed pane or trailing sheet; kanban shows 2 columns with paging.
- Expanded: full sidebar + content + inspector (inspector overlays when width < 1200 leaves no room).
- Large: sidebar, content and inspector all docked; Today in 3 columns; kanban 4 flexible columns (min 260, max 360); page max width about 1600, not 780.
Content rule: fluid 12-column grid with 16/24/32 gutters; reading-width cap (~640) only for forms; never cap the shell.
Reflow per screen:
- Today: 1 / 2 / 3 columns of cards, right rail with timer and quick actions on large; cards reorderable (RM 2.10).
- Tasks: compact = list, paged board, calendar plus day list; medium = list | detail; expanded = list/board/calendar + inspector. Board columns use Expanded in a Row when width >= 4x260 + gaps, else paged.
- Finance overview: chart grid 1/2/3 columns. Transactions: list + inspector. Calendar: month grid + day panel (side panel on expanded, sheet on compact).
- Reports: stacked cards, then two columns with a sticky range control.
- Settings: compact = grouped inset list with pushes; expanded = macOS-style sub-sidebar + detail.

### B6. RTL, Jalali and Persian rules
- Root locale fa_IR with RTL Directionality (already: app_bootstrap.dart:52). New code uses EdgeInsetsDirectional, AlignmentDirectional, PositionedDirectional, BorderRadiusDirectional only. Ban left/right in review.
- Mirror: back/forward chevrons, back button and swipe-back edge, sidebar and inspector sides, progress fill direction, disclosure chevrons, tab and segmented order, sliders, month prev/next arrows, undo/redo/send arrows, text alignment, kanban column order (first status at the right), timeline time axis (flows right to left).
- Do not flip: play/pause/stop glyphs, checkmark, plus/minus, search magnifier, clock faces and hand rotation, brand marks, calculator digit pad layout (1-2-3 left to right), percent sign, value (y) axis of charts, Latin code. Amounts, phone numbers and times are LTR runs: isolate them (Directionality.ltr or U+2066/U+2069).
- Jalali grid: week starts Saturday (شنبه), ends Friday (جمعه); Friday styled as holiday; first-day offset counted from Saturday; day 1 in the first row at the right. Leap years via shamsi_date (already a dependency). Expose a single weekStart token. The recurrence engine already has Jalali and Gregorian calendars (lib/core/recurrence).
- Digits: display Persian digits (۰-۹) through one formatter. Input accepts Persian, Arabic-Indic and Latin digits and normalizes. Store UTC/ISO. Thousands separator choice (U+060C style vs ",") is an owner decision, UNVERIFIED.
- Type: Vazirmatn variable is bundled (pubspec.yaml fonts). Persian line height 1.5-1.7; no letter-spacing (breaks joining); no synthetic italics; no fixed-height text containers; bidi-isolate Latin words in Persian text.

### B7. Navigation summary
Primary: tab bar (phone) / sidebar (desktop).
Secondary: segmented switchers and large-title bar (phone) / toolbar groups and list pane (desktop).
Tertiary: pushes, sheets, popovers, inspector.
Cross-cutting: Search (detached tab item / Ctrl+K), Quick entry ("+" -> sheet or popover), Undo toast above the tab bar, notification deep links to the same routes.
Router sketch (go_router 17.x): StatefulShellRoute.indexedStack with branches today, finance, plan, reports, more. Child routes such as /plan/tasks/:id and /finance/transactions/:id. View state in a query (?view=board). The inspector is the same URL as the compact push route, with a different presentation.

---------------------------------------------------------------------
## C. Research: Flutter design-system practice (2026)

### C1. liquid_glass_renderer 1.0.0-dev.2 (VERIFIED in the pub cache)
All paths under PKG.
- LiquidGlassLayer: rendering/liquid_glass_layer.dart:86 (class). Fields: settings, defaultAppearance, fake (:118 area, "uses FakeGlass when Impeller shader filters or Flutter GPU are unavailable, e.g. Skia"), useBackdropGroup (:141), backdropKey (:148). Doc comments: nearest ancestor BackdropGroup is used if present, else the layer creates a local group; multiple layers need a common ancestor group or an explicit shared backdropKey; on Impeller each independent backdrop capture reads back the screen; shared members do not see content painted between them, so group only elements over the same content plane (e.g. all root chrome) and never a sheet with the FAB above it; backdropKey takes precedence; default false.
- Constructors on LiquidGlass (liquid_glass.dart): regular (:54, needs a LiquidGlassLayer ancestor; creates a new independent sample when nested inside another glass), LiquidGlass.auto (:79; uses a parent layer if found, else creates its own; also takes useBackdropGroup and backdropKey), LiquidGlass.grouped (:104; needs a LiquidGlassBlendGroup and a LiquidGlassLayer above it), LiquidGlass.withOwnLayer (:124; takes settings, useBackdropGroup, backdropKey). Doc :124-132: "creating many individual layers can be expensive; prefer multiple shapes sharing one LiquidGlassLayer; use withOwnLayer when glass sits on other glass or needs its own settings".
- LiquidGlassCapture: liquid_glass_capture.dart:28 (class), :30 (const ctor with optional bleed), :37 (bleed). Doc :8-26: captures the backdrop once for all glass inside, limited to the region the glass paints or samples; the look is identical; paint content to be refracted below the capture, not inside it; keep captures small (a screen-size capture saves nothing); null bleed is computed from blur, refraction and shadow reach.
- Shape cap: LiquidGlassBlendGroup.maxShapesPerLayer = 16 (liquid_glass_blend_group.dart:38). It counts grouped and standalone shapes; extra shapes are not drawn and debug builds print a warning (rendering/liquid_glass_layer.dart:504-507, 1792).
- Independent-capture accounting in debug: debugRegisterBackdropCapture in rendering/consolidated_fake_glass_layer.dart:355-357 and :486. The exact warning threshold ("more than one independent copy per frame", seen in the pub.dev docs) was not located in source; treat the threshold as UNVERIFIED, the registration hook as verified.
- FakeGlass: fake_glass.dart:34 and :106 expose useBackdropGroup; LiquidGlassRenderScope (liquid_glass_render_scope.dart:6-33) carries useFake, consolidation flags and backdropKey.
- Docs (https://pub.dev/documentation/liquid_glass_renderer/latest/): needs Flutter >= 3.47, Impeller and Flutter GPU (preview); enable with FLTEnableFlutterGPU (iOS/macOS) or the Android EnableFlutterGPU meta-data; tested on iOS, Android, macOS; Web renders FakeGlass. Windows/Linux are not upstream-tested; the repo's own spike says Linux yes, Windows unverified (RM s7). Prerelease API; the repo pins it exactly (pubspec.yaml). The old 0.1.x docs say 64 shapes; ignore, dev.2 is 16.
- Perf advice from docs: keep layers small; avoid animating blend-group geometry every frame; few small shadows; very small blurs can cost more than moderate ones; opaque surface for low-power; FakeGlass costs about the same as full glass; await LiquidGlass.precache() before runApp (done, app_bootstrap.dart:16).
Consequence for this repo: the adapter should wrap each chrome region in one LiquidGlassLayer (or LiquidGlass.auto inside a shared scope) with useBackdropGroup: true across regions that sit over the same content plane, and reserve withOwnLayer for glass-on-glass.

### C2. Adaptive layout
- Flutter docs: pick the UI from the measured window; MediaQuery.sizeOf for the window, LayoutBuilder for local constraints (https://docs.flutter.dev/ui/adaptive-responsive/general).
- Material window size classes (compact/medium/expanded) are the de-facto standard. flutter_adaptive_scaffold is reported discontinued (secondary source, UNVERIFIED); forks adaptive_scaffold_plus and adaptive_shell exist (maintenance UNVERIFIED).
- Recommendation: write a small project-owned AdaptiveShell and WindowClass enum. The sidebar and tab bar must be glass and Apple-shaped, not Material NavigationRail. A macOS sidebar is a sectioned source list with a selection pill, not an icon rail; use the "rail" idea only for the medium collapsed state.

### C3. macos_ui and Cupertino
- macos_ui 2.2.0+1 (Flutter >= 3.35) has MacosWindow, Sidebar, MacosScaffold, ToolBar, endSidebar, toggleSidebar. Works on any platform, best on macOS, others not guaranteed (https://pub.dev/documentation/macos_ui/latest/). Several repos appear (HaltiaAI, macosui, muizidn); the canonical one was not verified.
- It targets the pre-Liquid-Glass macOS look and would add a third visual system. Recommendation: do not adopt; borrow the window-scope and toolbar-item model ideas only.
- Flutter Cupertino is the iOS 13-18 look; no Liquid Glass tab bar or toolbar in the framework as far as known (UNVERIFIED for Flutter 3.47). Reuse behaviours only (CupertinoSliverNavigationBar scroll collapse, CupertinoContextMenu, sheet route physics, page transition with RTL), restyled with our tokens. Native UIKit glass through platform views is out of scope (Android and Linux targets).

### C4. Tokens and ThemeExtension
- Convention (secondary sources): raw palette, then semantic roles in a ThemeExtension, then typography, then ThemeData light/dark; widgets never read raw tokens; ThemeExtension also holds spacing, radii, gradients, shadows (https://www.designsystemscollective.com/building-a-complete-design-system-in-flutter-colors-typography-variable-fonts-theme-extensions-202c28f7e72d, https://theflutterk.it.com/blog/flutter-material3-design-tokens-guide). design_builder generates ThemeExtensions from W3C tokens (https://pub.dev/packages/design_builder); not needed because the repo already generates tokens from the Apple kit via tool/ scripts into lib/app/apple_visual/generated.
- Repo status: OriginalPalette is a ThemeExtension (original_design_tokens.dart:~50); apple_visual uses an InheritedWidget. Recommendation: one semantic ThemeExtension (AppTheme) fed from apple_visual foundation; AppleVisualScope becomes a thin accessor.
- Accessibility: MediaQuery exposes disableAnimations, highContrast, boldText, accessibleNavigation, textScaler (https://api.flutter.dev/flutter/widgets/MediaQueryData/MediaQueryData.html). A Reduce Transparency flag was not found: UNVERIFIED, likely absent. Plan an own AppAccessibility setting (user toggle, plus derive from highContrast) that switches glass roles to opaque surfaces.

### C5. Impeller
Full glass needs Impeller + Flutter GPU; Skia gets FakeGlass automatically. Linux status was decided by the project spike (docs/superpowers/references/2026-11-04-liquid-glass-spike-report.md, GO). Not re-verified here.

### C6. Persian text
- Vazirmatn: SIL OFL 1.1, variable font bundled (https://github.com/rastikerdar/vazirmatn). The Latin glyphs in the default build come from Roboto; a no-Latin build exists.
- SF Arabic: Apple's Arabic-script system font, covers Persian (https://tdc.org/winner/sf-arabic). Redistribution and bundling outside Apple platforms: licence not found, UNVERIFIED. Keep the approved Vazirmatn deviation (RM s7).
- Open questions, UNVERIFIED: tabular digits (tnum) support in Vazirmatn; best Latin fallback (Inter or Roboto via fontFamilyFallback).
- Layout rules: flexible rows and Wrap so text scales to 200%; height >= 1.5.

### C7. Skills and rules found (read only; nothing downloaded or executed)
- Anthropic frontend-design is the canonical starting point; OpenAI has frontend-skill (https://composio.dev/blog/top-design-skills). Codegen's version says to defer to an existing design system and apply the skill only where the system is silent (https://codegen.com/skills/frontend-design/).
- Pattern: SKILL.md holds procedure, DESIGN.md or references/ holds the spec; skills reference files instead of embedding them (https://medium.com/@gravitano/i-built-a-claude-code-skill-that-turns-a-design-system-into-pixel-perfect-ui-heres-how-6d00c90daccd, https://design.sprout.ph/en/guide/claude-skills.html).
- A 7-step design pipeline: requirements, brief, information architecture, tokens, task decomposition, generation, review (Composio link above).
- supercent-io frontend-design-system: component library with consistent tokens, themes, primitives (https://www.vibeindex.ai/skills/supercent-io/skills-template/frontend-design-system).
Rules worth adopting as a repo DESIGN.md (not as an external skill): tokens are the only source of values; screens compose patterns, not primitives; every pattern has a review-page sample; specify IA before generating screens. These are web-oriented; none is Flutter-specific, so direct reuse is UNVERIFIED.

---------------------------------------------------------------------
## D. Recommended component architecture

### D1. Layers (dependencies point downward only)

```
L6 Screens        lib/features/*/presentation: routes, compose patterns, no styling constants
L5 Patterns       AppShell (tab bar / sidebar), GlassSidebar, GlassTabBar, GlassToolbar, AppSheet, AppPopover,
                  AppInspector, AppDialog, ListRow (swipe, context menu), SectionCard, EmptyState, UndoToast,
                  SegmentedSwitcher, form field set, KanbanColumn, Jalali CalendarGrid, Donut/Trend/Week charts,
                  SearchOverlay, QuickEntrySheet
L4 Primitives     AppText, AppIcon (direction-aware), AppButton (prominent/glass/plain), AppSurface (solid roles),
                  AppPressable, AppDivider, AppBadge, ProgressBar/Ring, AppTextField
L3 Materials      AppleLiquidGlass adapter + GlassScope (shared layer/capture) + roles (smallControl, tinted,
                  medium for toolbar/sidebar, large for sheet, overGlass) + opaque fallback + solid materials
L2 Semantic theme AppTheme ThemeExtension: colors, type roles (Persian metrics), spacing, radii, motion,
                  WindowClass, platform family
L1 Raw tokens     lib/app/apple_visual/foundation + generated (keep)
L0 Platform       Impeller/Flutter GPU flags, fonts, locale, AppClock, digit and Jalali formatters (lib/core/date_time)
```
Enforcement: screens must not import liquid_glass_renderer (already true), Material color constants, or fixed widths. Prefer analyzer rules or a unit test; CLAUDE.md forbids new tool/verify_* scripts.

### D2. Reuse vs replace

Keep:
- apple_visual/foundation/** and generated tokens (RM s7); trim the 18k-line metrics file as planned (LG s5).
- The AppleLiquidGlass public shape (role, shape, state) (apple_liquid_glass.dart:10-30) and the role-to-preset map (:34-44).
- Platform family resolver (apple_visual_platform_resolver.dart:5).
- AuroraBackground as wallpaper that glass refracts, optional and static under reduce motion (aurora_background.dart:45). Android raster cost UNVERIFIED.
- OriginalPalette colors and OriginalDesignTokens radii and accents as the content palette until mapped into AppTheme roles.
- Vazirmatn deviation and project vector icons.
Replace:
- OriginalGlass for content cards (original_glass.dart; blur plus 44-50 px shadows per card) -> solid AppSurface (grouped-background fill, hairline, no BackdropFilter). Largest perf and correctness win; 11 files use it.
- OriginalPressable, PrimaryButton, GhostButton, Pills, TextField (original_controls.dart) -> AppButton, AppSegmented, AppTextField on tokens.
- OriginalIcon painter set (original_icon.dart:3) -> project icon set with direction metadata.
- Dashboard top bar and _selectedPanel switch -> AppShell and router branches.
- Settings scaffold -> settings pattern (grouped list or sidebar-detail).
- Dialog editors -> AppSheet on compact and AppInspector on expanded, from one form widget (task_details_form.dart is already separate from the dialog).
- Direct Material widgets in features (AlertDialog, Dialog, IconButton, Icons.*) -> patterns. Scaffold may remain as an invisible host.
Split: tasks_panel.dart (1850 lines) and finance_panel.dart (1623 lines) into screens and widgets by pattern.

### D3. Adapter changes
1. GlassScope: one LiquidGlassLayer (or LiquidGlassCapture) per chrome region, holding that region's controls (<=16 shapes). AppleLiquidGlass inside a scope uses the regular or auto constructor; withOwnLayer only for standalone or glass-on-glass. Use useBackdropGroup: true (or a shared backdropKey) for regions over the same content plane (e.g. tab bar + toolbar); never for a sheet and the controls above it (layer.dart doc, C1).
2. Role to settings table stays; add reduceTransparency -> opaque path and highContrast -> stronger border.
3. Map pressed/hover/focus (AppleControlState) to the package's stretch/glow parameters.
4. Tune macos27 vs ios27 on the review page (LG s10 risk).

### D4. Glass performance budget (proposed targets; validate in profile builds)
- Independent backdrop captures per frame: <= 2 on phone (tab-bar region plus one sheet or toolbar), <= 3 on desktop (sidebar, toolbar, sheet or popover). Share via useBackdropGroup where chrome sits on one plane.
- Shapes per layer: hard cap 16; target <= 8 visible.
- Glass area: <= ~35% of the window on phone, <= ~30% on desktop; scrolling content has none.
- No glass inside scrolling item builders (rows, cards, chart bars); rows use solid or translucent fills.
- No animating glass geometry per frame except spring press feedback; sheets animate by transform.
- Zero extra BackdropFilter blurs in content (remove OriginalGlass blur).
- At most one shadow per glass region.
- Frame target: p90 raster <= 8 ms on the Linux dev machine (LG s4.4); Android mid-range: owner judgment, profile mode on the real Today screen.
- Tests: the review page must show no more than the budgeted independent captures; integration_test/liquid_glass_full_glass_test.dart continues to assert full glass is active.
- Fallbacks: runtime FakeGlass (package) and user Reduce Transparency -> opaque tinted surfaces; Reduce Motion -> no spring or aurora drift.

### D5. Suggested sequence
1. AppTheme unification, WindowClass, AppShell and router branches (no visual change).
2. GlassScope, GlassTabBar, GlassSidebar, GlassToolbar, review-page samples.
3. Replace OriginalGlass cards with solid surfaces; fix kanban with flexible columns by WindowClass.
4. Sheet and Inspector patterns; migrate task editor and finance entry.
5. Global search, quick entry sheet, Settings restructure, backup and import screens.
6. Habits, Goals, Time, Reports built directly on the patterns.

### UNVERIFIED summary
- iOS 27 tab bar and detached search behaviour; macOS 27 toolbar details.
- Exact debug-warning threshold for independent captures (hook exists, threshold not found).
- Windows and Linux behaviour upstream.
- Flutter exposure of iOS Reduce Transparency.
- SF Arabic redistribution licence; Vazirmatn tabular digits; Latin fallback choice; thousands separator choice.
- flutter_adaptive_scaffold discontinuation (secondary source).
- Aurora background raster cost on Android.
- Cupertino/Flutter 3.47 lacking Liquid Glass widgets.

---------------------------------------------------------------------
## Sources
- https://pub.dev/documentation/liquid_glass_renderer/latest/
- https://pub.dev/documentation/liquid_glass_renderer/1.0.0-dev.1/
- https://pub.dev/packages/liquid_glass_renderer
- Local source: ~/.pub-cache/hosted/pub.flutter-io.cn/liquid_glass_renderer-1.0.0-dev.2/lib/src (files cited above)
- https://docs.flutter.dev/ui/adaptive-responsive/general
- https://pub.dev/packages/adaptive_scaffold_plus
- https://pub.dev/packages/adaptive_shell
- https://pub.dev/documentation/macos_ui/latest/
- https://github.com/macosui/macos_ui
- https://api.flutter.dev/flutter/widgets/MediaQueryData/MediaQueryData.html
- https://www.designsystemscollective.com/building-a-complete-design-system-in-flutter-colors-typography-variable-fonts-theme-extensions-202c28f7e72d
- https://theflutterk.it.com/blog/flutter-material3-design-tokens-guide
- https://pub.dev/packages/design_builder
- https://github.com/rastikerdar/vazirmatn
- https://tdc.org/winner/sf-arabic
- https://codegen.com/skills/frontend-design/
- https://composio.dev/blog/top-design-skills
- https://design.sprout.ph/en/guide/claude-skills.html
- https://medium.com/@gravitano/i-built-a-claude-code-skill-that-turns-a-design-system-into-pixel-perfect-ui-heres-how-6d00c90daccd
- https://www.vibeindex.ai/skills/supercent-io/skills-template/frontend-design-system
