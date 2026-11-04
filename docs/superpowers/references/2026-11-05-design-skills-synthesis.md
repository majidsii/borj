# Design-skills synthesis: rules for a native-feeling (iOS/macOS 27, Liquid Glass) Persian RTL dashboard

Date: 2026-11-04 (research), rewritten 2026-11-05. Read-only study of public design skills; no downloaded script was executed.
Context: Dashboard Shakhsi v2 (finance + tasks, Jalali, offline, Flutter). The last mockup round failed because all candidates looked alike
(rounded cards on a gradient, same font, same layout). This file is the toolkit to prevent that.
Note: the original clones lived under a scratchpad that was wiped; this file was rewritten from the notes taken while reading them.
Stars were read with `gh api` on 2026-11-04.

---------------------------------------------------------------------------------------------------

## 1. Skill profiles

| Skill | Source / size | Good at | Weak for us |
|---|---|---|---|
| Impeccable v4.8 (pbakaus) | github.com/pbakaus/impeccable, ~101k stars, active 2026 | Best process: modes (Persuade/Operate/Read/Experience), discovery interview, seeded "direction roll" to force variety, critique scoring (Nielsen 40-pt + P0-P3), craft floor with bans, native iOS/Android references, RTL/Persian notes in harden.md | Heavy tooling (launcher binary, browser overlay) unusable here; Operate mode deliberately pushes toward familiar patterns |
| Taste Skill v2 (Leonxlnx) | github.com/Leonxlnx/taste-skill, ~109k stars, updated Oct 2026 | Anti-slop for pages; `references/app-screens.md` (85 KB) distilled from 23 real product screens with measured numbers (KPI size, colour share, charts, states, phone); "tells of generated dashboards" table; look-and-fix loop (max 3 rounds) | Its dashboard styles are flat/quiet and hostile to glass; scripts (draw.mjs) need Node + Chrome, so use the rules, not the dealer |
| UI/UX Pro Max (nextlevelbuilder) | github.com/nextlevelbuilder/ui-ux-pro-max-skill, ~145k stars | Searchable CSVs: 192 product types, 79 styles (with `rtl_level`), 25 chart types, 119 UX rules, pro-rules pre-delivery checklist, design dials (variance/motion/density) | Category lookups are generic (Claymorphism for habit trackers, dark glass for finance): a source of sameness, not the cure |
| Anthropic frontend-design (official plugin) | claude-plugins-official/plugins/frontend-design | Short and sharp: ground in subject, two-pass "plan then review plan against defaults", named list of AI-default clusters, "spend boldness in one place" | Web-hero oriented; nothing on native chrome |
| Interface Design (Dammyjay93) | github.com/Dammyjay93/interface-design, ~5.9k stars | Product-UI craft: domain exploration (5 concepts, 5 colours, 1 signature, 3 defaults), product-name-removed test, hierarchy math (weight+colour before size), density as a decision, design-deslop squint pass | Linear/Vercel/Stripe taste; not native |
| Apple skills bundle | HIG corpus (fact lookup), ios-liquid-glass (API + 3 principles), disabled ios-design-consultant (glass-vs-content framework, anti-pattern table), ios-ui-craft (bold direction + screenshot loop) | Authoritative platform facts; clear layer model | HIG skill says visual design is the model's own taste; ios-ui-craft's gradients/"bouncy everywhere" advice is partly itself slop |
| Axiom liquid-glass (charleswiltgen) | ~1.2k stars | Design principles + review checklist; regular-vs-clear decision rule; notes that building with the 27 SDK ends the UIDesignRequiresCompatibility opt-out | iOS API focus |
| ECC liquid-glass-design (affaan-m) | parent repo ~296k stars | Concise SwiftUI/UIKit/WidgetKit patterns; best-practice list (contrast on glass) | Thin on design judgment |
| haider-nawaz/liquid-glass-skill | ~75 stars (Feb 2026) | Clean API summary; never glass on content, containers mandatory | Low adoption; nothing the others lack |
| alirezarezvani apple-hig-expert | repo ~29k stars; skill v1.1.0 (June 2026) | Contrast and tap-target checker and 100-point scorecard (-10 per violation) | Only two measurable checks (do not execute; use the formulas by hand) |

---------------------------------------------------------------------------------------------------

## 2. The process the skills recommend (redesign of an existing product UI)

### 2.1 Common spine (Impeccable + Anthropic + Taste + Interface Design agree)

1. Decide what is already true (Impeccable new-work section 1). Redesign = keep product truth, content, function, native affordances, constraints;
   treat the old look as evidence and ANTI-reference. "Never split the difference into polish on the discarded look."
2. Discovery (Impeccable shape.md): 2-3 questions per round, one round by default. Purpose, who and in what state of mind, the one primary task and
   success, what is uniquely true here, real data ranges (min/typical/max), states that matter, what must stay untouched, what would make a polished
   result still feel wrong. Operate-mode questions: the task, information, important states, frequency, constraints.
3. Name the screen's ONE question (Taste app-screens 2.2), e.g. "How much of this month is left to spend?" It decides what is biggest, what is read
   first and what is left out. The largest figure on screen must answer the title row's question.
4. Inventory the domain (Interface Design; Taste 2.1): >=5 concepts from the product's world, >=5 natural colours of that world, realistic
   objects/magnitudes/people/jobs, the product's own words. Write the data first (totals computed from rows; small numbers stay small).
5. Name the defaults you will refuse (Interface Design): 3 obvious choices for this interface type, visual AND structural.
6. Direction contract before code (Impeccable section 5): THESIS (idea + the category-default arrangement refused), OWN-WORLD (palette and component
   language recognisable with content removed), STORY, FIRST VIEWPORT (exact composition), FORM (+ seed reference), FINISH.
7. Two-pass plan (Anthropic): (a) compact token plan: 4-6 named hex colours, type roles, layout in prose + ASCII wireframes, principles;
   (b) review the plan against "would I produce this for any similar prompt?"; revise and say what changed; only then build.
8. Build (code-led for Operate: "working screens come out better built than pictured"), then LOOK at the render at the sizes it ships, batch checks,
   fix, look again (Taste: max 3 rounds; Apple ios-ui-craft: screenshot loop).
9. Critique (section 4) -> polish -> record decisions (DESIGN.md / system.md / worklog).

### 2.2 How they force VARIETY between candidates (the fix for "all mockups looked alike")

Mechanisms, strongest first:

A. Randomised assignment, not self-choice (Impeccable `concept-seed`; Taste `draw.mjs`). A script deals the direction (three of N researched
   directions) because "asked to invent a look a model picks the category default every time". We cannot run their scripts, so emulate: build a deck of
   8-10 candidate directions (section 8), deal 3 by dice (e.g. last digits of the timestamp), and require each candidate agent to build the one dealt.

B. Directions come from the audience's cultural world, NOT the product's obvious artifact (Impeccable new-work section 3): list 7 concrete visual
   systems/artifacts/places/rituals the audience knows by heart, each with ground + main colours, type voices and ONE signature; they must span >=3
   material families; drop the rut (the category default and its predictable opposite). For an Operate surface the world may lend ONLY four things:
   type, palette, density, one signature move. It must NOT supply layout, navigation model or controls (otherwise it is a costume).

C. Candidates must differ in ORGANISATION, not paint (Impeccable mode-operate "Comps"): comps 2 and 3 vary the navigation model (side rail / top bar /
   command-first), how work areas divide the screen, which data leads, density, and where the signature move sits. "Each must be recognisably different
   from the first at thumbnail size; a variant only its prompt can tell apart adds no choice." Adding world material/texture goes the wrong way.

D. Variants vary on a different PRIMARY AXIS each (Impeccable live.md): hierarchy (which element commands the eye), layout topology (stacked /
   side-by-side / grid / asymmetric / overlay), typographic system, colour strategy (Restrained / Committed / Full palette / Drenched), plus density and
   rhythm. "Three 'tighter density' variants is failure." Departure mode: each variant gets a concrete, differently labelled "family"; shared or
   interchangeable labels = fail.

E. Sameness test (Taste critique pass 9): write ONE word per section/candidate layout (split, list, full-bleed, grid, statement, index...). The same
   word twice in a row, or three times on a page, is the template showing. Across candidates: if two share the layout word AND the type voice, merge or kill one.

F. Competitor / cover-the-logo test: put the nearest real competitor (or neighbouring app) in the sentence; if the idea still works, it belongs to the
   category (Taste 4). Interface Design: read the proposal with the product name removed; can someone say what it is for?

G. Calibration lists of AI clusters to refuse unless the brief pins them (Anthropic + Impeccable): (1) warm cream background + high-contrast serif +
   terracotta accent; (2) near-black + one acid accent + glow; (3) broadsheet hairlines / zero radius / dense columns; (4) the SaaS-card kit: identical
   rounded cards, one radius everywhere, the same soft grey shadow, gradient washes; (5) template chrome: tracked ALL-CAPS eyebrow above every heading,
   middle-dot meta strings, "WORD - fragment" labels, tinted near-black, mono small labels, arrows on links. Also from Taste/Apple: purple/indigo
   gradients, glow, glass on everything. If the final pick is one of these, "the self-check failed".

H. "Standing exit": offer exactly one quiet candidate = the category standard played straight at full fidelity (the pure iOS-native default look) as the
   user's door; never recommended by us. Useful as our baseline column.

I. Spend boldness in one place (Anthropic): one memorable element, everything else disciplined. The "signature move" (Impeccable) must be named
   concretely (e.g. "service health drawn as a transit map", "a schedule set in a timetable's column rhythm"). Taste: "one element only this product has",
   "one chart hue on the main data element", "words of the trade" in labels.

J. Re-roll rules: eliminate directions already shown; after two re-rolls ask what quality is missing; re-roll on factual grounds only (the direction
   cannot carry the product's truth), never taste.

### 2.3 Suggested concrete variety protocol for the next round

- Constants for all candidates (Operate, native iOS 27 / macOS 27 chrome): standard tab bar/sidebar, system materials, SF-style controls, RTL, Jalali.
- Variables per candidate: (a) navigation/topology archetype, (b) lead data object + the screen's one question, (c) density tier, (d) type/figure voice,
  (e) colour strategy, (f) ONE named signature move from a Persian/Iranian cultural reference that is NOT a finance tool.
- Dice-deal 3 from the deck in section 8; add one "standing exit" = pure iOS-native.
- Reject any pair that shares layout word AND type voice. Build real screens (not boxes) at 3 widths, light + dark + RTL, then critique (section 4).

---------------------------------------------------------------------------------------------------

## 3. Rules for an Operate-mode app that must feel like iOS 27 / macOS 27 with Liquid Glass

### 3.1 Mode contract (Impeccable)
- Operate: "scanability, consistency, native expectations and the real usage scene outrank expression. Brand lives in precise details." HIG governs
  structure, navigation and interaction; brand expresses only in the layer the platform leaves open: tint, type, motion, content.
- Product slop test: "Would a fluent iPhone user trust this app, or pause at off-spec controls?" The tell is "ported from a website": reinvented
  navigation bars, custom back gestures, web-shaped buttons, hover-dependent affordances. The failure mode of product UI is strangeness without purpose.
- Familiarity is a feature; delight is saved for moments (first use, completion, recovery, mastery), not pages.

### 3.2 Layers and Liquid Glass (Apple ios-liquid-glass, ios-design-consultant, Axiom, ECC, haider, UUPM "Liquid Glass" row)
- Two layers: glass layer = navigation + controls (tab bar, toolbar, sidebar, sheet chrome, floating buttons); content layer = everything read (cards,
  lists, charts, tables, text). NEVER glass on content cards (matches our CLAUDE.md). Glass frames content, never obscures it.
- Never stack glass on glass; nearby glass elements share one container (GlassEffectContainer) so they sample the same backdrop and can morph.
- Variants: `.regular` for ~95% (bars, controls); `.clear` ONLY when all three hold: over media-rich content, a dimming layer is acceptable, bold bright
  content above. Tint the primary action only; keep glass otherwise monochrome; brand colour lives in the CONTENT layer.
- No solid backgrounds under glass (defeats it); avoid content intersecting glass in steady states; scroll-edge blur for legibility.
- Concentric corners: inner radius = outer radius - padding; controls match device/window corner curvature (Harmony). Capsules for floating controls.
- Floating tab bar collapses on scroll; toolbar groups; sheets with detents (.medium/.large) and zoom/morph transitions from the source button.
- Anti-pattern table (ios-design-consultant): glass on content cards; colour throughout glass; solid backgrounds under glass; tab bar with 7+ items;
  primary action top-leading; destructive next to confirm; sheet for the primary flow; purple/indigo gradients; three floating glass buttons at once.
- "Is it too much glass?" -> can any be consolidated into a toolbar, are all needed at once, can one be primary (glass) and the rest in content?
- Accessibility adaptation (design for it, don't just inherit): Reduce Transparency -> more frosting/opaque fallback; Increase Contrast -> stark
  borders; Reduce Motion -> tone down animation. Text on glass must keep >=4.5:1 over the WORST-case background (use vibrant system label colours, not
  systemGray3 on material). In Flutter we implement these fallbacks ourselves (MediaQuery.disableAnimations, highContrast, platform transparency flag;
  supply an opaque/frosted fallback token).
- UUPM Liquid Glass row: "Best for: Apple-platform navigation, controls, system-aligned app chrome. Do not use for: content layers, dense reading
  surfaces, custom effects without accessibility fallbacks. a11y risk conditional (contrast 4.5, keyboard, visible focus, reduced motion)."
- Axiom: building with the 27 SDK ends the UIDesignRequiresCompatibility opt-out, i.e. Liquid Glass chrome becomes non-optional for iOS 27 apps (taken
  from its docs; not verified against Apple).

### 3.3 Layout, structure, hierarchy
- Safe areas respected; system navigation: tab bar for 2-5 top-level SECTIONS (never actions), navigation stack for hierarchy, sheet for self-contained
  tasks; large titles on top-level screens collapsing on scroll; edge-swipe back stays alive (in RTL it is the right edge); grouped/inset lists for
  settings-shaped content; no bespoke card stacks (Impeccable ios.md). Sidebar on iPad/macOS (restructure, don't stretch; size classes, not models).
- One focal point per view; name it aloud, then make it win via size/contrast/isolation (Interface Design). The squint test must show primary,
  secondary and groups.
- Weight + colour do more hierarchy work than size: 3 tiers at one size via weight (600/500/400) + a 4-step label colour ramp; use all 3 levers.
- Spacing: documented 4/8-based scale; rhythm = tight within groups, generous between, MORE space above a heading than below; breathe unevenly (dense
  control zones, open content). Monotone card grids = "no one decided". Cards are "the lazy container; nested cards are always wrong".
- Group by proximity before adding containers; tonal steps before borders; hairlines only where separation truly needs a line.
- Proportions speak (a 280 sidebar serves content; 360 reads as peers).
- Modals are laziness: exhaust inline/progressive options first (Impeccable operate). Sheets only for focused dismissible sub-tasks.
- Density is decided and named in numbers (tool-panel padding 12-16 vs brochure 24). UUPM `--density` dial: dashboards = 8-32px spacing scale.
- 60/30/10: dominant neutral, secondary tone, ~10% accent. Taste measured: median real app screen has ~3% coloured pixels, 12 of 23 have no filled
  primary button, 17 of 23 have no card shadow (1px line or one tone step).

### 3.4 Typography (incl. non-Latin / RTL)
- Native: SF carries UI on Apple; Dynamic Type via text styles (Large Title..Caption), no hard-coded point sizes; 17pt body; 11pt floor. Labels on glass
  use vibrant colours. In Flutter: use textScaler, never fixed sizes; test at the largest accessibility size.
- One family is often right for product UI; fixed scale not fluid; ratio 1.125-1.2 (Impeccable) or 1.2-1.25 (Interface Design); body 14-16, line-height
  ~1.5. Light-on-dark: slightly more leading, tracking and one step more weight.
- Numerals: tabular figures, trailing-aligned, fixed decimals, units as smaller grey suffix; bold for money only (Taste 7.4, 5). KPI values 24-30px
  (median 26), label 12-16px, value ~1.7x label; the answer figure leads at 30-36px and >=1.3x its siblings; nothing at 48+.
- Persian/Arabic-script specifics (Impeccable harden.md): use logical properties (Flutter: EdgeInsetsDirectional, AlignmentDirectional, Directionality);
  preserve ZWNJ U+200C and never strip it; keep Persian ye U+06CC and kaf U+06A9 in storage and treat the Arabic forms as equivalent for search;
  locale-aware digits (fa-IR gives Persian digits) via Intl; Jalali (Solar Hijri) calendar expected; mirror directional icons (arrows, chevrons, back)
  but NOT media/timeline controls, logos or numerals; test with RTL text and very long values. UUPM `rtl_level`: Liquid Glass, Glassmorphism, Swiss,
  Soft UI, Flat Mobile, Material 3 Expressive = full; Editorial Grid, Zero Interface, Kinetic = caveats. Charts, carousels and motion paths are the
  usual partial-RTL traps: time axes run right-to-left in a Persian UI; progress bars fill from the right.
- The skills contain NO Persian typeface guidance (UUPM only lists Noto Naskh/Sans Arabic). Avoid Impeccable's "training default" faces as a reflex
  (Inter-as-display, DM Sans, Plus Jakarta, Space Grotesk, IBM Plex, Outfit, Fraunces...). For Persian choose deliberately (system Persian face on
  Apple, or Vazirmatn / Estedad / Shabnam-style options) and make figure style (Persian digits, tabular) part of the type voice. Latin inside Persian
  runs needs baseline/size matching; verify visually.
- Type avoid-list (Anthropic): accenting a single word of a headline in colour/italic, ALL-CAPS labels, unnecessary eyebrow labels, section numbers
  unless a true sequence (ALL CAPS is moot in Persian, but the eyebrow tell still applies).

### 3.5 Colour
- Operate default = Restrained; one surface may be Committed (30-60% of surface one colour). Colour does real jobs: committed shell palette, state
  colours, data series, selection, signature move. "A grey screen with one accent colour is the category default without the category's polish."
- Semantic system colours (label/secondaryLabel/systemBackground/separator/tint) adaptive to Dark + Increased Contrast; one tint drives interactive
  elements; raw hex breaks adaptivity. Map our tokens to semantic roles with light/dark/high-contrast variants; second neutral layer for sidebars/toolbars.
- Accent = primary actions, selection, state, not decoration. Derive secondary text on coloured surfaces from the surface hue, never generic grey.
- Dark mode is first-class (design it, don't invert); state-contrast parity in both themes; dividers visible in both.
- Colour on data, not chrome (Taste): colour on a change says good/bad, not up/down; red is a signal not a texture (one red mark per object); pale tints
  with dark text for status chips; one hue per chart, <=4 hues per screen; people/objects get stable pale identity tints kept out of chart legends.
  UUPM: avoid red/green-only pairs (add sign/icon/text). Finance polarity should be quiet.
- Contrast: body & placeholder >=4.5:1, large >=3:1, non-text/icons/borders >=3:1; text on glass measured against the composed worst case.
- Avoid: gradient text; glow halos; hard offset shadows outside neobrutalism; zero-offset coloured halos; purple/indigo AI gradient.

### 3.6 Motion
- 100-150 ms immediate feedback; 150-300 ms state change; 300-500 ms layout/overlay/view transition; 500-800 only for one authored focal moment.
  Exponential ease-out; spring is the iOS personality (Apple ios-ui-craft) but system transitions must be honoured (push slides, sheets rise, dismiss
  reverses).
- Motion conveys state, never decoration; one authored moment, not the same fade-slide-up on every section; no orchestrated page-load.
- Morph between states (glass containers, matched transitions) rather than swapping; haptics on meaningful interactions; pressed feedback 80-150 ms
  without layout shift (scale ~0.97 is ok).
- Reduce Motion: cross-fade instead of parallax/large slides; chart entrance animations respect it and data is readable immediately.

### 3.7 Charts and data (Taste 6, UUPM charts.csv + quick-reference 10, Apple charts)
- Chart by question: over time = one 2px straight line (area fill <=15%, no markers/spline); per period = columns with square corners; ranking = sorted
  horizontal bars; share = thin ring or 100% stacked bar (<=5 parts); target = progress/bullet with both ends labelled and the true ratio; plan/budget =
  a track as long as the plan, spent filled, committed lighter, overrun past the end in the negative colour; habit consistency = calendar heat-grid
  (Jalali month rows).
- One question, one series (max 3 per screen); switch metric via a segmented control, not overlays. Single series -> no legend; 3-5 faint gridlines, no
  y-axis line; direct-label small datasets; forecast dashed with the end value labelled.
- Few numbers? Draw no chart. Pie/donut only <=5 categories (UUPM no-pie-overuse).
- Accessibility: never colour alone (pattern/shape/text); a table alternative + one-sentence summary for VoiceOver; >=44pt targets for chart points; data
  marks >=3:1, labels >=4.5:1; tooltips reachable without hover; locale-aware number/date/currency formatting (Toman IRT scale 0, Persian digits).
- KPIs: no icon-in-tinted-circle, no sparkline on every KPI, no "+12.5%" pill everywhere; bare type or one container split by hairlines; deltas in words
  with their window; a fact shown twice is one variable (counts follow the view); totals computed from rows.
- Tables/lists: rules and alignment, no zebra/header bands; numbers trailing-aligned tabular; zero printed as zero; missing = grey dash; below ~640px
  rows become two-line (identity + key number; secondary fields on line 2); swipe actions for transactions (UUPM personal-finance row).

### 3.8 Empty / loading / error states (Taste 11, Impeccable)
- Empty section keeps frame + header + ONE action-oriented sentence ("teach the interface"); an empty chart is drawn (zero line), no illustration + "No data yet".
- First run: keep frame and title, put the first action where data will appear; setup progress at its true percentage.
- Loading: final layout with value-sized flat grey bars (skeleton), no shimmer, zero layout shift; refresh keeps old values + freshness stamp.
- Error: inside the failed block, never a full-screen banner: what failed, when data was last good, Retry text button; offline-first apps show "last synced".
- Words of the trade in labels ("Due on the 28th", not "Items/Records/Status"); copy: active voice, sentence case, same verb through a flow ("Save" -> "Saved").

### 3.9 Accessibility checklist for native (Impeccable audit.native, UUPM pro-rules, HIG)
- Touch targets 44x44pt (iOS) / 48x48dp (Android) with spacing; Dynamic Type / font scale to the largest; VoiceOver/TalkBack labels with order = visual
  order (RTL!); Reduce Motion, Reduce Transparency, Increase Contrast, Bold Text; focus not obscured by sticky bars/glass; swipe/drag actions have button
  alternatives; colour never the sole indicator; verify Dark and Light independently.

### 3.10 Platform files: iOS vs Android (Impeccable ios.md / android.md / adapt.native.md)
- iOS: tab bar (2-5 sections), nav stack, sheets, large titles, edge-swipe back, SF Symbols (never mix web icon sets), system materials not hand-rolled
  glass, grouped lists, platform switches/pickers/segmented/action sheets/context menus/swipe actions, deliberate modality, system transitions, Reduce Motion.
- Android: Material 3 only on Android; navigation bar (3-5) on compact, rail/drawer on expanded; predictive Back always works; edge-to-edge insets; top app
  bar + at most one FAB; Material type roles + sp units; colour roles + Dynamic Color with static fallback; tonal elevation, no arbitrary shadows;
  snackbars for transient feedback; Material motion (container transform, shared axis, fade-through); honour Remove animations.
- Translation table: Tab bar <-> Navigation bar/rail; edge-swipe back <-> predictive Back; segmented control <-> chips; action sheet <-> bottom sheet;
  SF Symbols/SF Pro <-> Material Symbols/Roboto; system colours/materials <-> colour roles/tonal elevation; push/sheet <-> container transform.
  "Translate idioms; never transplant them." A Material-everywhere Flutter app on iPhone still owes iOS its OS guarantees (safe area, Reduce Motion, edge swipe).
- Adapt, don't scale: phone -> tablet/desktop restructures (sidebar + master-detail + multi-column). Our macOS/Linux/Windows targets need a sidebar
  shell, keyboard + pointer affordances (focus rings, shortcuts, context menus) and window-resize behaviour (size classes by width, not device).
- Verify with real captures (simulator / adb screencap / Flutter screenshots at 375, 390, tablet, landscape; Dark; largest text) and say which source
  produced the evidence.

---------------------------------------------------------------------------------------------------

## 4. Critique checklists to run against mockups

### 4.1 Impeccable critique (target /40 for Operate; renormalise if n/a)
(1) Design-specificity verdict FIRST: authored for this product, or category-interchangeable? (2) Nielsen 10 heuristics, each 0-4: 1 visibility of
system status; 2 match system/real world (words of the trade, Jalali, Toman); 3 user control and freedom (undo, cancel, back); 4 consistency and
standards (platform conventions); 5 error prevention; 6 recognition over recall; 7 flexibility/efficiency (shortcuts, bulk); 8 aesthetic and minimalist
design; 9 recover from errors; 10 help/documentation. Bands: 36-40 Excellent, 28-35 Good, 20-27 Acceptable, 12-19 Poor, 0-11 Critical (percent bands
90/70/50/30 when some are n/a). (3) Cognitive-load checklist, 8 items, count FAILS (0-1 low, 2-3 moderate, 4+ critical): single focus; chunking (<=4 per
group); grouping; visual hierarchy; one thing at a time; minimal choices (<=4 visible options); working memory; progressive disclosure. (4) Severity per
issue: P0 blocks the task, P1 major (fix before release), P2 minor, P3 polish ("would a user contact support? then >=P1"). (5) Persona red flags: Alex
(power user: shortcuts, speed), Jordan (first-timer: orientation, empty states), Sam (accessibility: VoiceOver/contrast/targets), Riley (stress tester:
odd data, RTL text, long values), Casey (distracted one-handed mobile: thumb-zone actions, state preserved, 44pt). (6) Report: 2-3 strengths, 3-5 priority
issues, minor observations, provocative questions.

### 4.2 Impeccable native audit (code-level, /20)
Five dimensions 0-4: Accessibility (labels, order, text scaling, targets, Reduce Motion, contrast); Performance (startup, virtualised lists, jank,
rebuilds, images); Appearance and theming (semantic colours, real dark, Dynamic Color fallback, system materials); Platform conformance (CRITICAL:
gestures, insets, navigation, web-shaped controls, icon drift); Adaptivity (tablet, orientation, keyboard/IME, multitasking, foldables). Bands: 18-20
excellent, 14-17 good, 10-13 acceptable, 6-9 poor, 0-5 critical. Opening verdict: pass/fail "native app or ported website?"

### 4.3 Impeccable craft floor (verify on the render)
Contrast 4.5/3; shadows have offset + blur; tight groups / generous separation; type measure, scale steps, real copy at every breakpoint; motion = one
authored moment; all states (hover/disabled/loading/error/empty) + real content + working controls + responsive + keyboard focus; theme the parts you did
not draw (selection, caret, scrollbars, focus rings, tabular numerals); copy in the product's language; every requirement findable within seconds.
Refuse list: identical icon+heading+text cards as page structure; the hero-metric template; kicker/eyebrow above a heading (BAN); section numbers without a
sequence; a modal for a non-interrupting task; gradient text; glass/blur as decoration; coloured side border >1px on cards/alerts; hard offset shadows;
sparklines/progress rings/soft rounded rectangles standing in for content; mono as a "technical" costume; emoji/unicode as icons; geometric masks for organic
shapes; light/dark picked by category (pick by use scene: who, where, light).

### 4.4 Taste Skill look-passes (on screenshots, not code), adapted for app screens
1 One second, then five: one clear answer? 2 Squint: 2-3 masses with clear size differences. 3 Cover the logo: competitor-swappable? 4 Edges: count
distinct start edges, 2-3 reused on purpose. 5 Space and frame: related close / unrelated far; holes vs rests; equal margins. 6 Type: decisive jump, <=5
sizes, no orphan words. 7 Colour proportions: name them; accent on the action + one detail. 9 Sameness: one word per section/layout. 10 Phone: its own
composition, not a squeezed desktop.
App-screen check (their 2.7): (1) is the screen's question answered by the biggest thing, read first? (2) do all blocks share the screen's edges (no dead
strip, stopped card, orphan cell, stretched card with blank band)? (3) colour only on data/status/primary action, with the main data element carrying the
one hue? (4) do numbers add up and align digit for digit, do repeated facts agree, does each relative figure name its base? (5) zeros are zeros, missing is a
dash, badges only on queues needing action? (6) legend swatches match marks, no label collisions? (7) phone: nav folded, each block still answers its
question? Fix the worst three, re-inspect, max three rounds.
Tells to scan for: dark/tinted sidebar with a coloured active pill; "Welcome back, X" + emoji; 4 KPI cards with icon circles; green "+12.5%" pill on every
KPI; sparkline on every KPI; KPI at 36-48 bold in the brand colour; gradient area chart with spline + dots; rainbow palette; fat donut with the total in the
hole; 16-24px radius + border + large soft shadow; zebra table with uppercase headers; saturated chips with white text; accent on every button/tab/link; top
bar with search + bell + avatar on every screen; export/share/date-picker cluster by the title; placeholder people and round vanity totals; neon-on-dark /
glow / glass (for web dashboards; for our native chrome glass is correct but only on the control layer); coloured icon per category; illustration + "No
data yet".
Their own warning: a screen with every tell removed and nothing put in their place is a tidy template and loses to richer screens. Quiet is the start, not
the goal: add the product's own data, its objects/people as themselves, one next action, and a first screen that shows every block the brief names.

### 4.5 Interface Design "design-deslop" squint order
No focal point > flat hierarchy > monotone layout > timid colour > borders doing the work of space. Then scan: generic token names (use semantic/world
names), size-only hierarchy, proportional digits on updating numbers, harsh 1px borders, dramatic elevation jumps, mixed depth strategies, the same radius
on nested parent/child (use concentric), missing hover/focus/active/disabled, `transition: all`, off-grid spacing (17/23px), structural hacks.

### 4.6 UI/UX Pro Max pre-delivery checklist (native/mobile; canonical)
Process: relevant searches only; review quick-reference 1-3; test 375px small phone + landscape; reduced-motion + largest Dynamic Type; dark contrast
independently; all touch targets >=44pt, nothing under safe areas.
Visual: no emoji icons; one icon family / stroke / fill discipline; official brand assets; pressed states don't shift layout; semantic tokens only.
Interaction: pressed feedback 80-150 ms; targets 44/48; shared platform-appropriate timing tokens; disabled states clear and inert; screen-reader order =
visual order with descriptive labels; no gesture conflicts (tap/drag/back-swipe).
Light/Dark: body text >=4.5:1 in both themes; dividers and interaction states distinguishable in both; scrim measured on the real background; both themes
tested.
Layout: safe areas for headers/tab bars/CTAs; scroll content not hidden behind fixed bars; small phone, large phone, tablet portrait + landscape; gutters
adapt; 4/8 spacing rhythm at all levels; readable measure on large devices.
Accessibility: decorative icons hidden from the a11y tree; meaningful icons labelled with state; form labels/hints/errors; colour not the sole indicator;
reduced motion + dynamic text without breakage; sticky UI doesn't obscure focus; drag/swipe have alternatives; no auto-rotating content without pause;
inline errors + a linked error summary.
UUPM review priority: 1 Accessibility (CRITICAL), 2 Touch/interaction (CRITICAL), 3 Performance, 4 Style selection, 5 Layout/responsive, 6 Typography/colour
(16px base, 1.5 line-height, semantic tokens, no gray-on-gray, no raw hex), 7 Animation, 8 Forms/feedback, 9 Navigation (bottom nav <=5, predictable
back, deep links), 10 Charts/data.

### 4.7 Apple HIG scorecard (alirezarezvani apple-hig-expert)
Start at 100, -10 per failed measurable check (text contrast pair <4.5:1, tap target <44x44). 90-100 ship, 70-80 fix before release, <70 systematic
rework. Classic fail: caption #8E8E93 on white = 3.26:1; use a darker secondary or the system secondaryLabel.

---------------------------------------------------------------------------------------------------

## 5. UI/UX Pro Max data rows (quoted compactly)

### 5.1 Products (columns: primary style | secondary | dashboard style | colour focus | key considerations | rtl_level)
- #91 Personal Finance Tracker: Glassmorphism + Dark Mode (OLED) | Minimalism & Swiss, Flat | Financial Dashboard | Calm blue + success green + alert red +
  chart accents | "Category pie/donut charts. Monthly trend lines. Budget progress bars. Transaction list with swipe actions. Receipt camera. Currency
  formatting. Recurring entries." | partial. Reasoning row: anti-pattern "Pure white backgrounds"; if light needed provide a theme toggle; if low
  performance use flat design.
- #6 Financial Dashboard: Dark Mode (OLED) + Data-Dense Dashboard | Swiss, Accessible | dark bg + red/green alerts + trust blue | "High contrast, real-time
  updates, accuracy paramount" | partial.
- #42 Banking/Traditional Finance: Minimalism & Swiss + Accessible & Ethical | Swiss Modernism 2.0, Dark OLED | Navy #0A1628 + trust blue + gold |
  "Security-first. Account overview. Transaction history. Accessibility critical." | partial.
- #94 Habit Tracker: Claymorphism + Vibrant & Block-based | Micro-interactions, Flat | User Behavior Analytics | streak warm (amber/orange) + progress green |
  "Streak calendar heatmap. Daily check-in interaction. Gamification (badges/levels/fire). Reminder push. Progress ring charts. Weekly/monthly stats.
  Motivational micro-copy." | full. Anti-pattern listed: "Muted colors + Low energy" (we consciously ignore this; our direction is calmer/native).
- #16 Productivity Tool: Flat Design + Micro-interactions | Swiss, Soft UI Evolution | Drill-Down Analytics | clear hierarchy + functional colours | "Ease of
  use. Speed & efficiency focus." Reasoning: must-have keyboard shortcuts; quick actions 150 ms; anti: complex onboarding, slow performance | partial.
- #110 Calendar & Scheduling App: Flat Design + Micro-interactions | Swiss, Soft UI | clean blue + event-category accent colours + success green | "Event
  colour coding. Week/month/day views. Recurring events. Conflict detection. Multi-calendar sync." | rtl_level CAVEATS (reading direction is encoded):
  must mirror week order (Saturday start in Iran) and month navigation. Anti: complex shadows + 3D.
- #138 Mood Tracker: Soft UI Evolution + Swiss; "One-tap daily check-in. Mood calendar heatmap. Pattern insights" | partial. #100 Diary/Journal: Soft UI +
  Swiss, warm paper tones, calendar month view | partial. #104 Booking/Appointment: calendar strip or month picker, time-slot grid | partial. #112 Expense
  Splitter: Flat + Vibrant block, success green + alert red | full. #93 Notes & Writing: Minimalism & Swiss + Flat, typography-first | partial.

### 5.2 Styles (rtl_level / perf / a11y)
- Liquid Glass (full; perf moderate: animation, blur; a11y conditional): "dynamic material, optical glass, translucency, lensing, refraction, fluid
  morphing, system navigation. Adaptive translucent material derived from surrounding content; use colour judiciously. Best for Apple-platform
  navigation, controls, system-aligned app chrome. Do not use for content layers, dense reading surfaces, or custom effects without accessibility
  fallbacks. Checklist: use for navigation and controls; keep content on a separate layer; colour judiciously; test Reduced Transparency; test Reduced
  Motion; verify text and control contrast."
- Glassmorphism (full; perf low; a11y conditional): "Backdrop blur 10-20px, translucent white 10-30%, 1px border rgba white 0.2, light reflection, z-depth.
  Best for modern SaaS, financial dashboards, nav, modal overlays. Do not use for low-contrast backgrounds, critical accessibility, performance-limited,
  dark text on dark. Checklist: vibrant background verified; text contrast 4.5:1 checked." (Generic web CSS; on content it contradicts our rule.)
- Alternatives that could carry a native-feeling Persian dashboard (all rtl full unless noted):
  * Minimalism & Swiss / Swiss Modernism 2.0: grid system, modular, rational; #000/#FFF/#F5F5F5 + single vibrant accent; 12-col strict; mathematical spacing;
    no decorations; best for dashboards, docs, professional tools; not for playful/emotional. -> "ledger/precision" direction.
  * Soft UI Evolution: better-contrast pastels, softer multi-layer shadows, radius 8-12, 200-300 ms, focus visible, contrast 4.5+; best for modern
    enterprise, health/wellness. -> "calm wellness" direction.
  * Bento Box Grid: modular cards, asymmetric spans, Apple-style tiles, 16-24 radius, subtle shadow; best for dashboards; NOT for dense tables or
    real-time monitoring. -> risk: exactly the rounded-card sameness unless spans and content truly differ.
  * Flat Design Mobile (Touch-First): zero elevation, colour-blocking full-width sections, solid icon containers, 48px targets, bold flat bottom tabs (not
    floating), 4/8/16/24/32/48 spacing; best for information-dense dashboards; dark only conditional. -> "colour-block" direction (keep chrome glass).
  * Material 3 Expressive (Mobile): tonal elevation, pill shapes, state layers 10-15%, emphasised easing (0.2,0,0,1), floating labels. -> Android fallback.
  * E-Ink / Paper: off-white #FDFBF7, ink #1A1A1A, no motion blur, grain, serif for reading; dark mode not recommended. -> journal/habit subview only.
  * Fluent 2: Microsoft conventions; use as the Windows platform reference.
  * Spatial UI (visionOS): frosted glass 15-30%, blur 40px saturate 180%, radius 24; do not use for text-heavy documents (shows where deep glass fails).
  * Rejected for Operate: Bauhaus / Neubrutalism / Brutalism (hard offset shadows; "do not use for enterprise dashboards, data-heavy screens"); Editorial
    Grid (rtl caveats; not for dashboards).

### 5.3 Charts (charts.csv, selected)
Trend over time = Line (not <4 points -> stat card; not >6 series). Compare categories = Bar sorted descending (not >15 categories). Part-to-whole = Pie /
Donut (not >5 categories or slices <5% apart; largest slice at 12 o'clock; label slices). Heatmap = Heat map (not <20 cells; always a numeric colour
legend; colour-blind users need pattern). Performance vs target = Gauge/Bullet (needs a target). Forecast = line with confidence band (actual solid,
forecast dashed). Proportional = Waffle (3-5 categories). Every entry: accessibility fallback = visible data table + concise summary; keyboard focus reveals values.

### 5.4 Design dials (SKILL.md step 2c) as a variety lever
`--variance` 1-10 (centred/minimal ... asymmetric/bento), `--motion` 1-10, `--density` 1-10 (dashboard = 8-32px scale). Use as explicit per-candidate
parameters (e.g. A: variance 2 / density 8, B: variance 8 / density 5, C: variance 5 / density 3).

---------------------------------------------------------------------------------------------------

## 6. Synthesis for our project (actionable)

1. Constants: native iOS/macOS 27 shell (tab bar / sidebar, large titles, sheets, grouped lists), glass ONLY on chrome, content on solid/system grouped
   surfaces, full RTL, Jalali, Persian digits, semantic light/dark/high-contrast tokens, Reduce Transparency/Motion fallbacks.
2. Variables (must differ per candidate): navigation topology, lead object / screen question, density, type & figure voice, colour strategy, ONE named
   cultural signature move, content-layer surface treatment (flat tone-steps vs hairline ledger vs tinted pastel fields vs colour-blocked sections).
3. Process: shape (1 round) -> screen question + inventory + real data -> deal 3 directions by dice from the deck + 1 "native default" exit -> 2-pass plan
   reviewed against defaults -> build real screens at 3 widths in light + dark + RTL -> critique (4.1 + 4.4 + 4.6) -> fix worst 3 -> pick.
4. Mockup ban list: eyebrow labels; identical rounded cards on a gradient; icon-in-tinted-circle KPIs; sparkline on every KPI; glass on cards;
   purple/indigo gradients; coloured left borders; emoji icons; "Welcome back" + wave; rainbow charts; hero-metric template; modal-first flows; one radius
   and one shadow on everything; the same font in every candidate.
5. Evidence rule (their shared lesson): judge the RENDER, not the code; batch checks; max 3 fix rounds.

---------------------------------------------------------------------------------------------------

## 7. Sources
- Impeccable: https://github.com/pbakaus/impeccable (SKILL.md; reference/{new-work,shape,mode-operate,operate,critique,layout,typeset,colorize,delight,bolder,animate,harden,live,generate,ios,android,adapt.native,audit.native,craft-floor}.md)
- Taste Skill: https://github.com/Leonxlnx/taste-skill (skills/taste-skill/SKILL.md, references/app-screens.md, references/critique.md, library/app.json); https://claudemarketplaces.com/skills/leonxlnx/taste-skill/design-taste-frontend-v1
- UI/UX Pro Max: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill (SKILL.md, references/pro-rules.md, references/quick-reference.md, data/{products,styles,charts,ui-reasoning,typography}.csv)
- Anthropic frontend-design plugin: ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/frontend-design/skills/frontend-design/SKILL.md
- Interface Design: https://github.com/Dammyjay93/interface-design (.claude/skills/interface-design/SKILL.md, commands/design-deslop.md)
- Apple skills bundle (skills/hig, skills/ios-liquid-glass, disabled-skills/ios-design-consultant, ios-ui-craft)
- Axiom: https://github.com/charleswiltgen/axiom ; ECC: https://github.com/affaan-m/ecc ; https://claudemarketplaces.com/skills/affaan-m/ecc/liquid-glass-design
- haider-nawaz/liquid-glass-skill: https://github.com/haider-nawaz/liquid-glass-skill
- alirezarezvani/claude-skills apple-hig-expert: https://github.com/alirezarezvani/claude-skills
- Directory overview (third party; star counts vary by date): https://pasqualepillitteri.it/en/news/576/claude-code-skills-design-uiux

---------------------------------------------------------------------------------------------------

## 8. A deck of 10 direction cards for Dashboard Shakhsi

Fixed for every card: native iOS/macOS 27 chrome (glass only on tab bar / toolbar / sidebar / sheet chrome; content on solid or grouped surfaces), RTL,
Jalali dates, Persian digits, Toman IRT scale 0, semantic light/dark/high-contrast tokens, Reduce Transparency/Motion fallbacks. Per the skills, each
direction lends only type, palette, density and ONE signature move; navigation and controls stay platform-standard. The Apple app named is where the
interaction model is borrowed from (how the app behaves), not its look.

Axes compared: T = navigation topology, L = lead data object (the screen's one question), D = density, F = type/figure voice, C = colour strategy.

| # | Name | T topology | L lead object | D | F type / figure voice | C colour strategy | Iranian signature move | Borrows from |
|---|---|---|---|---|---|---|---|---|
| 1 | Daftar | 4-tab bar + large titles | "Left to spend this month" as one figure | airy | system Persian face, regular-weight Persian digits at 34pt, label ramp does the hierarchy | Restrained achromatic + one ink-blue accent | Ledger columns: transactions in a ruled two-column bedehkar/bestankar (debit/credit) rhythm, the only non-standard list | Wallet (card + transaction list) |
| 2 | Taghvim | iPad/macOS sidebar; phone day-strip + month sheet | Jalali month grid showing money due + tasks per day | medium | bold tabular numerals for dates; Saturday-first week | Committed: one saturated turquoise (firuzeh) owns the header region | Wall-calendar sheet: the selected day is a "tear-off" page with holidays in the traditional red | Calendar |
| 3 | Rooz | single scrolling day timeline, no tab bar, glass toolbar only | Today as one chronological stream of spends, tasks, notes | low-medium | calligraphic Persian display for the date heading only, system body | Full palette, warm: saffron + pomegranate + indigo | Daily poetry line (fal-style verse) under the nastaliq date heading | Journal |
| 4 | Hesab | top segmented control + bottom command/search bar | Ranked, filterable transaction table | high | compact tabular figures, small weights, trailing-aligned | Restrained achromatic, quiet sign polarity (no red/green blocks) | Abacus bead-row (choortke) for category share instead of a donut | Stocks (list + detail with range selector) |
| 5 | Halqe | 3-tab bar, Summary first | Three daily rings: tasks done, habits kept, spend under budget | medium | rounded heavy figures | Full palette on true dark: lapis, turquoise, saffron (no glow, no gradient) | Rings drawn as segmented arcs echoing girih tile geometry | Fitness (rings + trends) |
| 6 | Bazar | 3-pane sidebar / list / detail (macOS first; phone collapses to push stack) | Category lanes with transactions as stalls sized by amount | high | small workhorse sans, dense captions | Restrained with a warm clay (brick) second-neutral layer for sidebar/toolbar | Bazaar "rasteh" rows: each category is a market lane along which items sit | Screen Time (category bars, day/week segmented) |
| 7 | Fasl | full-bleed hero + sheet with detents | Cash-flow forecast to month end (dashed after today) | low | ultra-light very large numerals | Drenched: one hue fills the screen and shifts with the Jalali season (spring green, summer gold, autumn rust, winter lapis) | Season-tinted ground; the month's name and proverb change with the season | Weather (hero + hourly strip + detail cards) |
| 8 | Sofreh | 4-tab bar + horizontally paged carousel | Budget envelopes as plates (spent vs allotted) | low | friendly rounded Persian face, large touch-first labels | Pastel fields: one low-chroma hue per envelope, quiet money polarity | Sofreh layout: round envelopes on a cloth ground, termeh-style border as the only ornament | Home (tiles with state, long-press to detail) |
| 9 | Saat | floating glass mode picker (Timer / Tasks / Habits) at the bottom | Next-up task with a running timer | medium-low | wide clock-face digits, Persian numerals | True black, Restrained: a single accent for the running state | Day divided into named day-parts (sobh, zohr, asr, shab) as the timeline segments | Clock (timers, big digits) |
| 10 | Fehrest | sidebar of lists with smart-list tiles on top (Today / Scheduled / Overdue / Installments) | Smart-list counts leading into the task + payment list | medium-high | system Persian face, medium weight, tabular counts | Restrained with coloured list dots as identity | Ghesti chain: instalments and recurring payments shown as a linked timetable inside the list | Reminders (smart lists, swipe actions, quick add) |

Spare (not in the 10): a Health-style Summary with pinned favourite trend cards and a Jalali month heat-grid with tile-shaped cells for habits.

Pairwise check (each pair differs on at least two of T, L, D, F, C; also on the borrowed Apple app and signature move):
- Same topology family pairs: 1/5/8 (tab bars) differ on L, F and C (1 achromatic ledger vs 5 dark rings vs 8 pastel plates; D airy / medium / low).
  2/6/10 (sidebars) differ on L, C and D (calendar grid + turquoise vs category lanes + clay vs smart lists + list dots; D medium / high / medium-high),
  2/10 additionally on F.
- Same colour strategy pairs: 1/4/10 (Restrained) differ on T, L, D and F; 5/3 (full palette) differ on T, L, D, F; 9 (true black) vs 5 (dark) differ on T, L,
  F, and C (single accent vs full palette).
- Same density pairs: 1/7 (airy/low) differ on T, L, F, C; 4/6 (high) differ on T, L, F and C (achromatic vs clay); 3/9 (low-medium / medium-low) differ on
  T, L, F, C.
- Sameness test (one layout word each): ledger-list, calendar-grid, timeline, table, rings, lanes, hero, carousel, timer, smart-lists: all ten distinct.
- Dice deal: pick by (timestamp mod 10) without replacement; always add the pure-native "standing exit" as a fourth column for comparison.
- Cultural-reference caution: every signature must stay a type/palette/density/single-move contribution (no costume ornament); verify the reference with a
  native Persian speaker before building (day-part names, ledger terms and the fal verse in particular).
