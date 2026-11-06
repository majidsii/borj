# Motion System and Today Customization — Design

**Date:** 2026-11-06
**Status:** DRAFT for owner review. Direction approved in chat (2026-11-06): customize Today in place
(move, resize by dragging to fixed sizes with a faint preview, hide, add back), and motion on every screen
with professional data reveals.
**Extends:** `2026-11-05-liquid-glass-redesign-design.md` (§3.3 motion note, §4 motion tokens, §7 phases).
Boards still win on layout; this spec adds behaviour over time.
**Prototype:** https://claude.ai/artifact/9EMLdeoU2PEjJfur64Nv1W (web approximation; glass is CSS).

## 1. Sources and how they were used

Installed skills (`~/.claude/skills/`): `emil-design-eng`, `choreograph`, `review-animations`,
`find-animation-opportunities`, `apple-design`, `mobile-native` (Emil Kowalski, MIT), `motion-design`
(LottieFiles, MIT), `data-visualization-motion`, `accessible-motion` (dylantarre, MIT). The prototype was
audited against them; §8 lists what changed because of that audit.

Rules adopted from them, in the words we design with:

1. **Frequency decides.** Things used tens of times a day (tab switch, opening Today, keyboard actions)
   get no entrance choreography. Occasional things (sheets, toasts, edit mode) get standard motion.
   Rare things (first launch, onboarding, a finished goal) may get delight.
2. **Critically damped by default.** Springs with damping ratio 1.0. A little bounce (≈0.8) only when the
   user's own gesture carried momentum: a dropped card, a flicked sheet, a released resize handle, a
   completed task.
3. **One entrance per container.** A sheet slides in with its content already in place; never animate a
   parent and stagger its children.
4. **Data moves only when data changes.** Numbers roll and bars grow from their previous value when the
   value changes, and once on a cold start; not every time a screen is shown.
5. **Spatial continuity.** Things leave the way they came and grow from their trigger (sheet from its
   button, inspector from its edge, detail from its row). Exits are 65–75% of entrance time, ease-out,
   never ease-in.
6. **Leaving frees space immediately.** A removed element is taken out of layout at once; siblings close
   the gap while it fades.
7. **Never block, always interruptible.** Every animation starts from the current on-screen value; any
   element can be grabbed mid-flight; nothing waits for an animation to finish before accepting input.
8. **Direct manipulation is 1:1.** Drags keep the grab offset, track the finger every frame, hand the
   release velocity to the settling spring, and resist at bounds (rubber band) instead of hard stops.
9. **Feedback on press, not release.** Press state appears on pointer-down within 100 ms.
10. **Reduced motion is calmer, not dead.** Movement, scale and springs are replaced by ~200 ms opacity
    cross-fades; numbers jump to the final value; nothing loops.

## 2. Motion tokens (`AppTheme.motion`)

Springs are `SpringDescription.withDampingRatio` built from Apple-style *response* (seconds) and damping
ratio (stiffness = (2π / response)², mass 1). Curves are for non-physical transitions.

| Token | Kind | Value | Use |
|---|---|---|---|
| `press` | curve | 120 ms, `Cubic(0.23, 1, 0.32, 1)` | press scale 0.97 and release |
| `quick` | curve | 200 ms, same curve | badges, chips, toggles, small fades |
| `standard` | spring | response 0.40, damping 1.0 | layout reflow, page/inspector moves, lens |
| `snappy` | spring | response 0.28, damping 1.0 | tab lens, segmented thumb, small moves |
| `soft` | spring | response 0.35, damping 0.80 | sheet open, card drop, resize settle, task complete |
| `dataUpdate` | curve | 350 ms, `Cubic(0.23, 1, 0.32, 1)` | number roll, bar/ring/track value changes |
| `dataEnter` | curve | 450 ms, same curve | cold-start chart reveal (bars grow, line draws) |
| `exitFactor` | number | 0.7 | exit duration = entrance × 0.7 |
| `stagger` | list | 0, 50, 95, 135, 170, 200, 225, 240 ms | cold-start cascade by importance (cap 240) |
| `reduced` | curve | 200 ms opacity, `Curves.easeOut` | replacement for every movement under Reduce Motion |

`ease-in` curves are not used anywhere. Existing `apple_visual/foundation/apple_visual_motion.dart`
(`defaultSpring`, `interactiveSpring`) is mapped onto `standard` and `snappy`; no second motion vocabulary.

**Reduce Motion source:** `MediaQuery.disableAnimationsOf(context)` OR the in-app setting
«کاهش حرکت» (Settings → Appearance, default off). Linux has no reliable system flag, so the app setting is
required. One `MotionScope.of(context)` answers `reduced` for every widget.

## 3. Shared patterns (L4/L5 components own their motion)

Screens never write animation code; they use these patterns, so motion is consistent and testable.

| Pattern | Motion |
|---|---|
| `GlassButton` / any pressable | scale 0.97 on pointer-down (`press`), release with `press`; hover highlight only with a mouse |
| `GlassSheet` | grows from the trigger's rect (origin = trigger centre), `soft`; scrim fades `quick`; drag-to-dismiss tracks 1:1, dismiss on velocity > 0.11 px/ms or past 40%, else springs back; closes back into the trigger, `standard` × 0.7 |
| `GlassInspector` (desktop) | slides in from the leading edge (left in RTL), `standard`; content already in place; closes the same way |
| Push navigation (phone) | new page enters from the left (RTL forward), old page shifts 30% and dims; back gesture tracks 1:1 from the right edge; `standard` |
| Tab / section switch | **no content animation**; the glass lens slides with `snappy` and stretches ≤ 12% along the travel axis mid-way (liquid feel); content swaps instantly (frequency rule) |
| `GlassSegmented` | thumb slides `snappy`; content below cross-fades `quick` |
| `GlassRow` insert / remove | insert: height opens `standard` while row fades in `quick`; remove: row leaves layout at once, siblings close with `standard`, the row's ghost fades and shrinks to 0.96 in 180 ms |
| List reorder / kanban drag | lifted card scales 1.03 with deeper shadow; others reflow with `standard`; drop settles with `soft` using release velocity; target column tint fades `quick` |
| `RoundCheck` (complete) | fill grows `soft` (bounce), then the checkmark draws (sequence: draw starts as fill lands, 200 ms); title strikes through `quick`; on list screens the row leaves after 600 ms (undo toast covers it) |
| `UndoToast` | rises from the bottom 16 px + fade, `standard`; auto-hides after 5 s; exits the same path ×0.7 |
| Numbers (`AnimatedNumber`) | rolls from old to new value with `dataUpdate`; Persian digits; tabular figures so width does not jump; under Reduce Motion jumps |
| Tracks, rings, bars (`ProgressTrack`, `BarChart`, `CategoryTracks`) | animate from the previous value with `dataUpdate`; on cold start grow from 0 with `dataEnter`, bars staggered 30 ms by importance (largest first) |
| `DayTimeline` now-lens | moves continuously with the clock (linear, recomputed each minute); no pulse |
| `EmptyState` | appears with `quick` fade only |
| Theme change (light/dark/auto) | 300 ms cross-fade of the whole surface; no flashing |
| Glass materialize | a glass shape entering animates opacity and scale 0.96 → 1 together with renderer thickness; never a bare fade of a refraction layer |

## 4. Choreography per screen

Cold start = the first time a screen is built in this app process. Afterwards the same screen appears
instantly. Every entry lists the lead (what moves first) and what deliberately does not move.

### Today (`Main`, `MacToday`, `PhoneEmptyToday`)
- Cold start: cards rise 8 px + fade, `quick`, in `stagger` order of the user's layout (lead = first card);
  tracks/rings inside grow from 0 with `dataEnter` once their card is in. Total ≤ 300 ms before content is
  usable; everything is tappable immediately.
- Later visits: no entrance. Data changes (task done, transaction added) roll/grow in place.
- Static: date line, large title, tab bar.
- Customization motion: §5.

### Tasks list, Kanban, Calendar, Day, Timer, Templates, Task detail, Reminder/Recurrence edit, Quick entry
- List ↔ board ↔ calendar view switch: segmented thumb `snappy`, content cross-fades `quick` (no slide).
- Task complete: `RoundCheck`; counts in headers roll.
- Add task (quick entry sheet): sheet from the + button; on save the new row inserts with `GlassRow`
  insert where it lands; the sheet closes back into the button.
- Kanban: drag pattern; changing status animates the card into the target column with `soft`.
- Calendar month change: grid slides 24 px in the reading direction + fade, `standard` (month = forward is
  left in RTL); swipe tracks 1:1.
- Day timeline: blocks keep their positions; the now-lens glides; dragging a block to reschedule is 1:1
  with 15-minute snap ticks (haptic on Android).
- Timer: running state shows the digits rolling each second (no pulse, no loop); start/stop button morphs
  play ↔ pause icon with `quick`.
- Task detail: sheet (phone) / inspector (desktop) from the row; no inner stagger.

### Money overview, Transactions, Add transaction, Debts & installments, Reports, Budgets, Accounts
- Cold start: balance number rolls from 0 once (`dataEnter`); budget tracks and category tracks grow;
  report bars grow largest-first with 30 ms stagger; line charts draw left-to-right in reading order
  (RTL: right-to-left) over 500 ms.
- Filter / period change: bars and lines morph from old to new values with `dataUpdate` (axes stay put;
  scales never jump during the morph).
- Add transaction: sheet from the + button; after save, the balance and the affected budget roll to new
  values while the new row inserts.
- Over-budget crossing: the track's colour fades to pomegranate with `quick`; no shake, no pulse.
- Installment paid: `RoundCheck` + remaining amount rolls down.

### Habits, Goals (visual targets for their future specs)
- Habit check: day cell fills with `soft`; streak number rolls; reaching a streak milestone (7, 30, 100)
  gets one celebration (ring burst ≤ 600 ms, rare event).
- Goal progress: ring grows from previous value with `dataUpdate`; reaching 100% gets the same celebration.

### Search (`PhoneSearch`, `MacSearch` Ctrl+K)
- Phone: the search circle morphs into the field (`soft`). Desktop Ctrl+K: **no animation** (keyboard,
  high frequency); results update instantly while typing.

### Settings, Appearance, Notifications, Backup, Import v1, Trash, Onboarding
- Settings: push navigation only; toggles `quick`.
- Glass-intensity slider: glass updates live 1:1 with the thumb.
- Import v1 / Backup: progress track `dataUpdate`; completion check with `RoundCheck`.
- Trash: restore = row leaves trash list (remove pattern) and the undo toast confirms.
- Onboarding (rare, first run): the only place with a longer sequence: logo bricks lay in one by one
  (Banna'i cells, 30 ms apart, ≤ 500 ms), then the title, then the first action. Skippable by tapping.

## 5. Today customization

### 5.1 Grid and sizes
- Phone (< 600): 2 columns; Medium: 4 columns; Desktop (≥ 1024): 4 columns. Row unit 76 dp, gap 12.
- Sizes: **small** 1 col × 2 rows, **wide** 2 cols × 2 rows, **large** 2 cols × 4 rows. Each card type
  declares its allowed sizes and its content per size (more detail at larger sizes, never just stretched).
- Layout is an ordered list of `(cardId, size)`; positions are computed by dense auto-flow: no overlaps,
  and later small cards are pulled into gaps. A gap can remain only beside a lone small card; the edit
  mode shows it as an empty dashed slot so the user sees why. No free positioning.

Initial catalogue (cards whose feature does not exist yet are not offered until it ships):

| Card | Sizes | Default (phone) |
|---|---|---|
| Today timeline | wide, large | wide, 1st |
| Today's tasks | small, wide, large | large, 2nd |
| Budget remaining | small, wide | small, 3rd |
| Upcoming installment | small, wide | small, 4th (beside budget) |
| Timer | small, wide | hidden |
| Weekly report | wide, large | hidden |
| Debts and receivables | small, wide | hidden |
| Habits, Goals | small, wide (, large) | added when those features ship |

### 5.2 Edit mode
- Enter: long-press any card 500 ms (haptic on Android) or the «ویرایش» toolbar button; desktop also via
  the card's context menu. Exit: «تمام», Escape, or tapping empty space.
- In edit mode cards settle to 0.965 scale (`quick`), content stops reacting, a remove badge (−) appears at
  the top-trailing corner and a resize handle at the bottom-leading corner (RTL: top-right, bottom-left),
  both fade/scale from 0.9 with `quick`. No continuous jiggle (calm, battery, Reduce Motion).
- «+ افزودن کارت» appears under the grid.

### 5.3 Move
- Drag a card (in edit mode, immediately; outside edit mode the long-press enters edit mode first and the
  same touch continues as a drag). The card lifts 1.04 with a deeper shadow, follows 1:1 with the grab
  offset; when the pointer is over another card the order changes and the others reflow with `standard`;
  release settles into the slot with `soft` and the release velocity.

### 5.4 Resize (owner request)
- Drag the handle with a finger or mouse. The card's frame follows freely (width grows towards the leading
  side, height downward) with Apple's rubber band past the smallest/largest allowed size.
- The nearest allowed size is chosen continuously; at its real slot the card shows a **faint preview**:
  the card's content for that size at ~30% opacity with a dashed accent outline, plus a size label
  («کوچک / پهن / بزرگ»). Other cards make room for the preview live (`standard`).
- Crossing to another size gives a selection haptic on Android.
- Release: the frame springs into the preview slot with `soft`, carrying the release velocity; a flick is
  projected (Apple projection, deceleration 0.998) so a quick flick can jump to the next size.
- A plain tap on the handle cycles to the next allowed size (also the screen-reader action).

### 5.5 Hide, add, reset
- Remove badge hides the card (never deletes data); it leaves layout immediately and the rest close the
  gap while its ghost fades; undo toast for 5 s.
- «+ افزودن کارت» opens a sheet (from the button) with the hidden and available cards, each previewed at
  its default size; tapping one adds it at the end with a grow-in (`soft`).
- «بازگردانی چیدمان پیش‌فرض» in that sheet restores the default with an undo toast (no confirmation
  dialog: the action is reversible).
- If every card is hidden, Today shows the `EmptyState` with «افزودن کارت».

### 5.6 Without dragging
- The existing `PhoneDashboardCards` board becomes the accessible path: a list with show/hide switches,
  drag handles and a size picker per row, plus move up/down actions.
- Screen reader actions on each card in edit mode: «جابه‌جایی به قبل», «جابه‌جایی به بعد», «تغییر اندازه»,
  «پنهان کردن».
- Desktop keyboard in edit mode: arrow keys move the focused card, `S` cycles size, `Delete` hides,
  `Escape` exits. Keyboard actions are instant (no animation) by the frequency rule.

### 5.7 Persistence
- New Drift table `today_layout_items(layout_class TEXT, card_id TEXT, position INT, size TEXT,
  hidden BOOL)`, primary key `(layout_class, card_id)`; `layout_class` ∈ `compact | expanded` so phone and
  desktop layouts are separate (roadmap 2.10 "per-device layout"). Schema 9 → 10, append-only migration;
  no rows means the default layout.
- Parsing is exact: unknown `card_id` or `size` values are ignored (not crashes); a stored size not allowed
  for that card falls back to its first allowed size.
- Layout state is independent of task/finance domain data (roadmap 2.10).
- Edits write on each committed change (drop, resize release, hide, add, reset), in one transaction per
  change; undo writes the previous state back.

## 6. Liquid Glass constraints

- Animating glass geometry costs a backdrop capture per frame. While a card is being dragged or resized,
  the moving card renders with the `inner`/FakeGlass material; real glass returns when it settles. Cards
  that reflow keep real glass but move as one `GlassScope` translate where possible.
- At most one glass layer animates its geometry at a time; others animate transform/opacity only.
- The perf probe (redesign spec §3.3) adds a Today edit-mode scenario: drag and resize for 3 s; p90 raster
  within the existing budgets.
- Under Reduce Transparency the same motions run on frosted fallback.

## 7. Testing and acceptance

- Unit: spring token values; reduced-motion resolution (system flag OR app setting); layout packing
  (dense flow, no holes, allowed sizes, fallbacks); size snapping from frame dimensions and from projected
  flicks; migration 9 → 10 and restart tests for `today_layout_items`.
- Widget (FakeGlass): edit mode enter/exit, move, resize by handle drag and by tap, hide + undo, add, reset
  + undo, empty state, screen-reader actions, keyboard path; every pattern in §3 under Reduce Motion
  produces no transforms (only opacity).
- Golden-free perceptual acceptance on the review page: each pattern has a demo next to the prototype
  link; the owner judges feel on Linux and on the A34.
- Device: perf probe scenario of §6.

## 8. What the skill audit changed in the prototype

- Reflow and badges used overshoot; now critically damped (bounce kept only for drop, sheet, completion).
- Removing a card waited for its exit before siblings moved (a queue); now it leaves layout at once.
- Sheet close and card removal used ease-in; now ease-out and shorter than their entrances.
- Badges grew from 40% scale; now from 90% (nothing appears from nothing).
- Press feedback scaled to 0.94 with bounce; now 0.97, 120 ms ease-out.
- Rubber band was a linear 25%; now Apple's formula.
- Reset had no way back; now it has undo.
- Reduce Motion removed all feedback; now it cross-fades in 200 ms.
- Added: cold-start cascade by importance (≤ 240 ms), bars growing from 0 only on cold start.

## 9. Scope and order

- Phase 1 (Foundation) gains: `AppTheme.motion` tokens, `MotionScope` + «کاهش حرکت» setting,
  `AnimatedNumber`, press/sheet/toast/row/check patterns with tests.
- Phase 2 (Shell + Today) gains: tab lens, push/inspector motion, Today cold-start choreography, Today
  customization (§5, replaces roadmap Task 2.10's narrower "visibility and ordering"), schema 10, and the
  deferred icon/brand wiring (logo kit in `assets/brand/`).
- Phases 3–5 apply §4 per screen as they rebuild each screen.

## 10. Risks

- Glass + motion cost on the A34: mitigated by §6 and measured in the perf probe before Phase 2 ships.
- The web prototype cannot show real refraction or Flutter spring feel; acceptance is on device.
- Over-animation creep: every new motion must name its frequency class (§1.1) in review.
