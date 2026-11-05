# Liquid Glass Redesign — Design

**Date:** 2026-11-05
**Status:** APPROVED by the owner (2026-11-05: «همین طرح‌هایی که روی ارتیفکت هست رو میخوام اسپکش رو درست کنی»).
**Program order:** this replaces the visual layer of roadmap item 2 (Liquid Glass adoption, which kept glass on chrome only) and runs before release item 3B.
**Supersedes:** the "glass on chrome only" rule in `2026-11-02-liquid-glass-renderer-adoption-design.md` §§3–5 and in `CLAUDE.md` (Visual system). Everything else in that spec stays: the `liquid_glass_renderer 1.0.0-dev.2` dependency, the runner flags, the `AppleLiquidGlass` adapter boundary, perceptual acceptance.

## 1. Source of truth

The approved design is the canvas https://claude.ai/artifact/BbMdoABnw1aVHo1sVE3MYv, snapshotted in the repo at
`docs/superpowers/references/2026-11-05-glass-mockups/`:

- `*.dc.html` — 39 screens × light/dark = 78 boards (phone 390×844, Mac 1440×900 or 1440×1250).
- `source/` — the generator (`build.py`), the CSS glass kit (`kit2.css`, `kit2.svg.html`) and one template per screen (`screens/*.html`). Colour tokens in the kit are the reference palette for this spec.

Where a board and this spec disagree on layout or content, the board wins. Where a board shows a feature that does not exist yet (habits, goals, budgets, accounts, search, quick-entry parsing, trash, dashboard cards, backup, onboarding), the board is the visual target for that feature's own future spec; this spec builds only the shell and the screens of features that exist (§7).

Research inputs: `references/2026-11-05-apple-first-party-app-patterns.md`, `references/2026-11-05-design-skills-synthesis.md`, `references/2026-11-05-ia-and-design-system-architecture.md` (IA §B and component layers §D are adopted except where §3 below overrides them).

## 2. Owner decisions (fixed)

1. **Every element is Liquid Glass**: chrome (tab bar, sidebar, toolbar, sheets, buttons) AND content (cards, list rows, chips, tiles, panels). Apple's "glass only on chrome" rule is overridden by the owner.
2. **No glass on glass.** Anything drawn on top of a glass shape (checkmarks, inner rows of a grouped card, segmented thumbs, chart marks, progress fills, the "now" lens over a timeline card) is a flat inner material (`lg-in` in the kit), not a second glass layer. The single exception is a deliberate lens on its own sibling layer.
3. **Backgrounds:** light mode = pure white `#FFFFFF`; dark mode = charcoal `#1B1C20` with a warm radial light from the top leading corner (exact gradient in `kit2.css`). Mac: the window sits on the charcoal desk in both modes; window content is white (light) or `#24262B` (dark).
4. **Appearance setting:** روشن / تیره / خودکار (follow the system), plus a glass-intensity slider (iOS 27 "Liquid Glass" slider equivalent: more clear ↔ more tinted). Default خودکار, intensity middle.
5. **Platforms:** phone layouts follow iOS 27 (Android target), desktop layouts follow macOS 27 (Linux, Windows). RTL, Jalali, Persian digits, Vazirmatn.

## 3. Glass material system

### 3.1 Roles
One adapter, `AppleLiquidGlass(role:, shape:, child:)`, extended with content roles. Roles map to `LiquidGlassSettings` presets per brightness and intensity:

- `chrome` — tab bar, sidebar, toolbar capsules, floating circular buttons.
- `tinted` — the single primary action per screen (accent fill; blue `#2F6FDB` light / `#5B8CFF` dark).
- `panel` — content cards and grouped sections (the kit's `.lg` panels).
- `row` — standalone glass rows/capsules (task rows on Today, settings rows, chips).
- `sheet` — bottom sheets / inspectors / popovers (thicker, more frost).
- `clear` — over strong colour (account cards, the date chip).
- `inner` — flat material for things inside glass (not a renderer layer; a painted fill + hairline).

Shapes: capsule, circle, rounded(radius) with concentric radii (inner = outer − padding).

### 3.2 Look (perceptual targets from the boards)
- crisp hairline edge; bright curved specular rim on the top-leading edge (top-right in RTL), darker rim bottom-trailing;
- visible thickness (refraction at the rim; renderer `thickness`/`refractiveIndex`), small contact shadow + soft ambient shadow;
- light: cool, very light tint so glass reads on white; dark: smoky glass with an inner glow;
- text on glass: `#1B2236` / `#38425E` (light), `#F1F2F7` / `#A9AFC4`-class (dark), contrast ≥ 4.5:1 against the worst case.

### 3.3 Layering and budget
Content glass is the expensive part, so it is grouped:
- `GlassScope` widget = one `LiquidGlassLayer` holding up to 16 shapes (renderer cap `maxShapesPerLayer = 16`). A screen section (e.g. "today's tasks" card + its rows) is one scope.
- All content scopes of one scroll view share one backdrop (`useBackdropGroup: true` under one `BackdropGroup`), so content costs **one** capture; chrome is a second group; a sheet/popover is a third.
- Scrolling lists longer than one screen (transactions, all tasks): rows are glass shapes inside per-section scopes that are built lazily (one scope per visible section/page of ≤ 16 rows).
- Budget per frame: ≤ 3 independent captures on phone, ≤ 4 on desktop; p90 raster ≤ 8 ms on the Linux dev machine and ≤ 16 ms on the owner's Samsung A34 (profile build, Today and Transactions while scrolling).
- **Degrade path:** if the budget fails on a device, or the user turns on Reduce Transparency, content roles (`panel`, `row`) switch to the renderer's FakeGlass / frosted fallback while chrome stays real glass. Reduce Motion disables spring/stretch animations.

## 4. Theme and tokens

- One semantic `AppTheme` `ThemeExtension` (light + dark) fed from `apple_visual/foundation`, holding: background, text roles, glass tints per role, accents (blue, turquoise `#0F9C90`, saffron `#C77E00`, pomegranate `#C8324B`, violet), semantic money colours (income teal, expense ink, over-budget pomegranate), spacing (4/8 scale), radii, motion, type roles (Persian line height 1.5–1.7, no letter-spacing).
- `OriginalPalette`/`OriginalGlass`/`original_controls` are retired; screens read only `AppTheme`.
- `AppleVisualScope` becomes a thin accessor over `AppTheme` + window class + platform family.

## 5. App shell and navigation (IA)

Adopted from `ia-and-design-system-architecture.md` §B with the boards' labels:

- **Phone (< 600):** floating glass tab bar امروز / کارها / مالی / عادت‌ها + a search circle (the boards' layout). Large titles, glass circular toolbar buttons, sheets inset from the edges, kanban one column per page.
- **Desktop (≥ 1024):** macOS-27 window: glass sidebar on the RIGHT (sections برنامه / پول / زندگی, as on the boards), glass toolbar capsules at top, content, optional inspector on the LEFT. No 780 px cap; kanban columns flex to fit (min 260).
- **Medium (600–1023):** collapsed sidebar + content; detail as a pushed pane.
- Routing: go_router `StatefulShellRoute.indexedStack`, one branch per tab/section; detail routes are the same URL on every size (push on phone, inspector on desktop); view state in the query (`?view=board`). The dashboard's widget-state panel switch is removed.
- Search: search tab/circle on phone, Ctrl+K overlay on desktop (visual shell now; search engine is its own spec).

## 6. Components (layers L0–L6 of the architecture reference)

L3 materials: `AppleLiquidGlass` (roles §3.1), `GlassScope`, `GlassInner`, opaque/fake fallback.
L4 primitives: `AppText`, `AppIcon` (direction-aware), `GlassButton` (chrome/tinted/plain), `GlassChip`, `GlassToggle`, `GlassSegmented`, `GlassTextField`, `ProgressTrack`, `RoundCheck`.
L5 patterns: `AppShell`, `GlassTabBar`, `GlassSidebar`, `GlassToolbar`, `GlassSheet`, `GlassInspector`, `GlassPanel` (section card with inner rows), `GlassRow`, `LargeTitleHeader`, `JalaliMonthGrid`, `DayTimeline` (+ now lens), `KanbanBoard` (paged/flex), `BarChart`, `CategoryTracks`, `UndoToast`, `EmptyState`.
L6 screens compose patterns only; no colours, sizes or `liquid_glass_renderer` imports in `lib/features/**`.

Every pattern gets a sample on the debug review page (existing `/debug/glass-review`), shown next to the matching mockup PNG for perceptual comparison.

## 7. Scope and phases

Each phase gets its own plan; each ends with CI green, a checkpoint and owner sign-off on the review page / device.

1. **Foundation:** `AppTheme` light/dark + appearance setting (روشن/تیره/خودکار, glass intensity), glass roles + `GlassScope` + fallback, primitives, review page with mockup comparison, performance probe (captures/frame, raster p90) wired into `tool/ci.sh --device`.
2. **Shell:** router branches, `AppShell` (tab bar / sidebar / toolbar / sheet / inspector), window classes, removal of the 780 px cap and the panel switch. Today screen rebuilt to the `Main` / `MacToday` boards (light + dark).
3. **Tasks:** Tasks list, kanban (paged/flex), task detail sheet/inspector, calendar month, day timeline, timer, templates manager/editor, reminder & recurrence editor — to their boards.
4. **Finance:** money overview, transactions + inspector, add-transaction sheet, debts & installments, reports — to their boards.
5. **Settings & data:** settings (phone list / Mac sidebar), v1 import flow (phone + Mac), appearance settings.

Out of scope here (visual targets only, each needs its own spec): habits, goals, budgets, accounts, global search engine, natural-language quick entry, trash/undo (roadmap 2.9), dashboard cards (2.10), backup/restore, onboarding, notifications settings.

## 8. Testing and acceptance

- Widget tests per pattern and screen under FakeGlass (existing harness), including RTL, light/dark, text scale 1.3, Reduce Motion/Transparency paths.
- Unit tests: `AppTheme` contrast pairs ≥ 4.5:1 for text roles in both modes; role → settings mapping.
- Device tests (`integration_test`, Linux): full-glass active, captures per frame within budget, raster p90 within budget on Today and Transactions while scrolling.
- Android: profile build on the owner's A34 for Today/Transactions; owner judges smoothness.
- Perceptual acceptance: owner compares each rebuilt screen with its board (review page shows both); no pixel goldens.
- `flutter analyze` clean; `tool/ci.sh` green; existing invariants (tasks, money, recurrence, notifications) untouched — this is a presentation-layer change.

## 9. Risks

- **Performance of content glass** on Android mid-range — mitigated by grouped scopes, the capture budget and the degrade path (§3.3); measured in phase 1 before screens migrate.
- **Renderer is a prerelease (`1.0.0-dev.2`)** — kept behind the adapter; only `apple_liquid_glass.dart` and `app_bootstrap.dart` import it.
- **Real glass vs CSS mockups** — the boards approximate glass in CSS; acceptance is perceptual and the renderer settings are tuned on the review page, not copied from CSS.
- **Windows** remains unverified (spike); FakeGlass fallback applies automatically if Impeller/Flutter GPU is unavailable.
