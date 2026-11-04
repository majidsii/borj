# Apple first-party app design patterns (iOS 26/27, macOS 26/27) as sources for a Persian RTL dashboard

Research date: 2026-11-04 (rewritten 2026-11-05 after the scratchpad copy was lost).

## Method and reliability legend

Web access was partial. apple.com (newsroom, ios, macos pages) and several
third-party domains (cultofmac, tomsguide, designfornative) were blocked by the
fetch tool. developer.apple.com WWDC video pages, 9to5Mac, MacRumors and
MacStories were readable. The Apple HIG pages returned empty bodies.

Labels:
- [V] verified in a page fetched during this research (source in section 5).
- [S] only seen in a search-result summary, not in a fetched page.
- [BK] background knowledge from the iOS 17 to iOS 26 era, not re-checked.
- UNVERIFIED: could not be confirmed; do not rely on it.

Everything tagged [BK] is long-standing app structure and likely accurate, but
confirm against a device or screenshot before designing from it.

---

## 1. Platform patterns: 26 vs 27

### 1.1 Liquid Glass fundamentals (iOS 26 / macOS 26, still true in 27)

- Glass is the NAVIGATION/CONTROL layer floating above content. Not content
  (not table rows, not data cards). [V WWDC25 219]
- Two variants: Regular (adaptive, default, any size/content) and Clear
  (always transparent, needs a dimming layer; only over media-rich backgrounds
  with bold bright content). Never mix them. [V]
- No glass on glass. Things placed on glass use fills/vibrancy instead. [V]
- Small elements (nav bars, tab bars) can flip light/dark; large elements
  (menus, sidebars) adapt but do not flip. Larger glass looks thicker: deeper
  shadows, stronger refraction. [V]
- Lensing: glass bends light; elements appear by modulating lensing, not by
  fading. Controls "energize" on touch; resting state stays quiet. [V]
- A window that loses focus: glass recedes. [V]
- Tint is for primary actions only (blue Done checkmark on iOS, prominent text
  button on macOS). App color belongs in the content layer. [V]
- Spatial continuity: sheets and menus spring from the control that triggered
  them; menus pop open in place. [V]
- Sheets: dragged up, glass becomes more opaque and grows slightly to signal
  depth; a dimming layer signals modality. [V]
- Half sheets are inset from screen edges with glass; fully expanded sheets
  become opaque. [V MacStories 26]

### 1.2 Shapes: concentric corners [V WWDC25 356]

- Three shape kinds: fixed, capsule (radius = half height), concentric
  (radius = parent radius minus padding).
- iPhone: capsules with extra margin near screen edges. iPad/Mac: concentric
  shape aligned to the window edge.
- macOS: Mini/Small/Medium controls keep rounded rectangles (dense layouts);
  Large and new X-Large controls are capsules.
- "Pinched or flared" corners mean a shape should be concentric.

### 1.3 Scroll edge effect and background extension [V]

- Scroll edge effect replaces hard dividers: where pinned UI overlaps scrolling
  content, content blurs/dissolves softly (dims over dark content). It is not an
  overlay. One effect per view/pane.
- Soft (default, iOS-leaning): for glass buttons and inputs. Hard (mostly
  macOS): uniform edge for toolbars with pinned column headers, interactive
  text, controls without backgrounds. Do not mix or stack them.
- Consequence: many iOS views have no pinned title bar; content flows under
  floating controls. [V]
- Background extension effect: artwork/color extends full-width behind an inset
  sidebar; text and controls layer above so they are not distorted. [V]
- On iPad/Mac, sidebars pick up ambient light from nearby colorful content. [V]

### 1.4 Tab bar (iPhone) [V MacStories 26; S for API names]

- Floating pill, width fits the item count (two tabs look intentional).
- Minimizes on scroll to a small button for the active tab (opt-in via
  tabBarMinimizeBehavior). A bottom accessory (mini player) docks beside or
  above the collapsed bar. Accessories are for persistent app-wide features
  (playback), not screen-specific actions (checkout). [V]
- Dedicated Search tab role: separated from other tabs, morphs into a search
  field when selected. [S]
- iPhone search sits at the bottom (field, or search button in the tab bar).
  Shortcuts and App Library keep top search (criticized). [V]
- Long-press a tab for a selection bubble; long-press-and-swipe on the
  collapsed tab switches tabs (low discoverability). [V]
- sidebarAdaptable: tab bar becomes a sidebar on iPad/Mac. [BK]

### 1.5 Toolbars and buttons [V]

- Floating rounded bars; related controls share a capsule (group by function
  and frequency). Do not group symbol and text buttons together. Standalone
  text buttons get their own container.
- Done = circular checkmark, Close = X; SF Symbols replace most text labels.
- ToolbarSpacer: flexible (push groups apart) and fixed (separate groups). [S]
- Strip custom backgrounds/borders from bars; emphasis comes from layout and
  grouping. Secondary actions go into a menu. [V]
- Sheets opened from toolbar buttons can morph out of the button. [S]

### 1.6 Menus and share sheet [V]

- Menus open in place, anchored to the triggering control.
- iOS 27: context menus gain a darker edge so they appear to float, and use a
  glassy material instead of iOS 26's dark style. [V MacStories 27]
- iOS 26 half-sheet share layout: "More" takes the fourth favorite's slot; the
  share sheet corner radius does not match other corners. [V]

### 1.7 Home Screen, Lock Screen, icons, widgets

- iOS 26 app icons: Default / Dark / Clear / Tinted looks. [BK iOS; V for macOS]
- iOS 26.1 added the Clear vs Tinted toggle (iOS and macOS). [S]
- Lock Screen glass clock that stretches to fill space: [BK].
- Control Center / widgets in clear vs tinted: [BK], UNVERIFIED in detail.
- macOS 26: menu bar transparent by default with option to restore the old
  semi-transparent look; system app icons are squircles with edge highlights;
  icon styles default/dark/clear/tinted; nine theme colors, nine highlight
  colors, eight folder colors. [V MacStories macOS 26]
- macOS 26: toolbars and sidebars more translucent than Sequoia, window
  corners rounder, toolbar button groups always visible, Safari tabs are pills
  in a slot. Music and Photos use a very transparent bottom control pill
  (legibility complaints); Maps puts buttons at the right with more opaque
  backgrounds. [V]

### 1.8 Accessibility [V WWDC25 219 + search]

- Reduce Transparency: frostier glass hiding more background.
- Increase Contrast: predominantly black/white elements with contrasting
  borders.
- Reduce Motion: fewer effects, no elastic behavior.
- 26.1 Clear / Tinted option; 27 replaces it with a slider.
- At the clearest 27 setting, content scrolling under floating bars can be
  hard to read. [V MacStories 27]

### 1.9 NEW in 27 (marked clearly)

Refinements, not a redesign. Apps built with older SDKs get the new material
automatically. Reportedly, apps built with Xcode 27 can no longer opt out of
Liquid Glass on native components. [S for the opt-out; V WWDC26 269 for
automatic adoption]

NEW in iOS 27:
- Liquid Glass SLIDER (Settings > Appearance), continuous "More Clear" to "More
  Tinted" with three named stops; Default is more tinted than iOS 26's Clear;
  also in setup. Preview shows real UI over photos. [V]
- Material refinements: better diffusion, refraction, darker edges, brighter
  specular highlights. [V] More defined borders instead of drop shadows and
  lighter dark-mode glass. [S]
- App icons get extra glass layers: more detail and sharpness in light, dark,
  tinted and all-clear. [V]
- Search button sits back INSIDE the tab bar in Apple's apps (separate style
  still supported); selected tab (Music Home) more legible. [V]
- New tab role `.prominent`: one tab at bottom-trailing, distinct from others.
  [V]
- Toolbar APIs: visibilityPriority(.high), ToolbarOverflowMenu,
  topBarPinnedTrailing, toolbarMinimizeBehavior(.onScrollDown, for:
  .navigationBar). [V]
- Custom glass can be "interactive" on macOS too. [V]
- iPhone apps are resizable. [V]
- Toolbars partly return so floating buttons feel less unmoored; overly round
  corners and unnecessary sidebar bezels reined in. [S, UNVERIFIED detail]
- Context menus glassier with darker floating edge. [V]
- Extra Large widget fills a Home Screen page: Calendar, Home, Mail, Music,
  Notes, Photos, Reminders, Shortcuts, Stocks, Weather. Shortcuts XL runs up to
  16 shortcuts; Home XL controls up to 14 accessories/scenes. [V]
- Lock Screen: compact clock beside the date; Now Playing clearable by swipe.
  [V]
- Health, Home, Music, Weather, Watch work in landscape. [S]

NEW in macOS 27 (Golden Gate):
- Same Liquid Glass slider (System Settings > Appearance, default medium, also
  in setup). Affects Dock (most visible), dimmed widgets, Now Playing bars,
  sidebars, toolbars and toolbar buttons in apps like Photos and Safari. One
  setting for the whole system. [V 9to5Mac]
- Sidebars are EDGE-TO-EDGE again (flush with window edges) rather than
  floating inset; horizontally scrolling content still shows under them. [V]
- Sidebar icons colored again, for the focused app. [S]
- Uniform frosted toolbar across the window top; toolbar controls more
  legible. [V/S]
- All window corners share one radius, including un-updated third-party apps.
  [V]
- Active window stands out; inactive windows dim icons and text
  (`appearsActive` environment value). [V WWDC26 269]
- Menu bar menus show a minimal icon set by default; icons opt-in per item. [V]
- Refraction more uniform, contrast improved. [V]

Not found: any new material beyond the slider; sheet behavior changes in 27.

---

## 2. Per-app findings

Per app: structure/IA, signature interaction, glass use, type/color, empty
states, phone vs Mac. Empty states were not verified for any app.

### Reminders
- Home is smart lists (Today, Scheduled, All, Flagged, Completed...) then My
  Lists with groups, sections, subtasks; colored list glyphs. [BK]
- iOS 26: quick-entry control (Control Center / Lock Screen / Action button)
  opens an interactive snippet with keyboard, list, date, location, flag
  without launching the app. Per-reminder time zone. It relies on private APIs
  so third-party apps cannot match it. [V MacStories 26]
- iOS 27: the metadata bar above the keyboard moved into a box around the
  active reminder card (Date, Location, Tag, Flag, Camera, plus Time, Urgent,
  Repeat). "Describe a reminder" (Apple Intelligence); recognized tokens are
  highlighted. Still no fast "change list". [V 9to5Mac, MacStories 27]
- Glass: only toolbar/new-item controls; rows are flat on grouped background. [BK]
- Mac: sidebar of lists + content. [BK]
- Borrow: smart-list tiles with live counts, inline expanding card editor,
  token highlighting, system-wide quick-entry snippet.

### Calendar
- iOS 27 redesigned Event Details and Create/Edit: more info per screen, icons
  as cues, headings grouping settings. Natural-language entry: recognized
  tokens turn red with an Apple Intelligence symbol; date applied only after
  accepting the suggestion above the keyboard. [V]
- iPhone: Year > Month > Day, month strip over an hour-grid timeline. Mac:
  sidebar of calendars, Day/Week/Month/Year segmented control, popover
  inspector. [BK]
- Glass: toolbar buttons and bottom controls (Today/Calendars/Inbox). [BK]
- Borrow: vertical time grid with event blocks, month strip with dots,
  segmented zoom, "Today" jump.

### Wallet
- iOS 27: loyalty/membership passes get a "Poster Generic" style (full
  background image, logo, header, up to two bottom action buttons); Create a
  Pass via Visual Intelligence with Standard/Membership/Event templates, 12
  background colors with textures. Boarding-pass redesign came in 26. [V MacRumors]
- iOS 27 Insights: link financial accounts to see spending, recurring
  transactions, balances; builds on Connected Accounts; works with banks
  supporting Connected Cards (mostly UK). US availability conflicting:
  UNVERIFIED. [S/V mix]
- Cards are a stacked deck of overlapping cards; tap lifts one to the front,
  others collapse at the bottom; detail shows latest transactions. [BK]
- Glass only on navigation chrome; cards are opaque colorful content. [BK]
- Borrow: overlapping stack with focus-lift; per-card transaction list;
  themed full-bleed card color + texture.

### Health (Summary, highlights, trends)
- iOS 27: Browse changed from alphabetical list to colorful cards. [S]
- iOS 27.2/27.3 beta overhaul: Insights tab (activity rings, heart rate, sleep
  score, vitals; readiness score on new Watch hardware) and Longevity tab
  (Health Age from activity, VO2 max, sleep; lab uploads). Not in the 27.2
  release; 27.3 expected. [V MacRumors hands-on]
- Summary: pinned favorite cards (metric, trend glyph, mini chart), Highlights
  (auto-surfaced notable changes), Trends (direction arrow vs averages),
  category colors. [BK]
- Borrow: pinned metric cards with sparkline and delta, plain-language
  Highlights, Trends arrows.

### Fitness (rings, trends, summary)
- iOS 27: more accurate workout route maps (minor). [S]
- Summary: three concentric rings with daily numbers, weekly bars, trends,
  awards; Sharing tab; saturated rings on black; completion animation. [BK]
- Borrow: concentric rings per habit group, weekly bars, award moments. Rings
  are content, not glass.

### Journal
- iOS 27: entries show timestamps; generative writing prompts in purple. [V]
  Journal arrived on iPad and Mac in 26. [V MacStories 26 TOC]
- Timeline feed with date headers and photo thumbnails, prominent "+",
  suggestion cards. [BK]
- Borrow: reflective timeline + suggestion cards for Habits/Goals.

### Stocks
- iOS 27: XL widget. [V]
- Watchlist rows with change pill (tap toggles percent/absolute), detail chart
  with 1D/1W/1M/1Y/ALL range, scrub crosshair, news below; Mac sidebar
  watchlists + detail. [BK]
- Borrow: range-segmented scrubbable charts and delta pills for Reports.

### Weather
- iOS 27: new Highlights card (changes over about the next day) and an icon
  switch above the home forecast between Conditions (default), Precipitation,
  Wind; selection persists. [V techbetweenthelines]
- Full-bleed condition/time-of-day background, stacked glassy module cards,
  collapsing large-temperature header. [BK]
- Borrow: condition-driven Today background, range-bar rows for budgets,
  collapsing hero.

### Home
- iOS 27: XL widget controls up to 14 accessories/scenes; landscape. [V/S]
- Room sections, scene tiles that toggle on tap, status summary row. [BK]
- Borrow: status chips + toggle tiles.

### Clock (timers/stopwatch)
- iOS 26: Liquid Glass redesign; snooze duration (1-15 min) in Edit Alarm;
  Lock Screen alarm has larger equal Stop/Snooze buttons. iOS 27: alarm volume
  separated from alerts. [V MacStories]
- Tabs: World Clock / Alarm / Stopwatch / Timers; large wheel pickers, Recents,
  running timers in Live Activities / Dynamic Island; stopwatch big digits and
  Lap list. [BK]
- Borrow: giant tabular digits, wheel picker, big start/stop pair.

### Screen Time
- iOS 27 redesign: at-a-glance usage and most-used apps for parents, in-the-
  moment controls, time allowances by category, "Ask to Browse". [S] Layout
  detail UNVERIFIED (see section 6).
- Day/Week toggle, stacked-category bar chart, app list below, limits and
  Downtime. [BK]
- Borrow: stacked-category bars with tap-to-filter list.

### Notes
- iOS 27: Markdown copy/paste and export, section links, dividers; toolbars
  change visibly between clear and tinted; XL widget; drawing in Notes on Mac.
  [V/S]
- Folders > list > editor; Mac 3-pane; pinned notes; smart folders. [BK]

### Mail (Mac 3-column)
- iOS 27: much better search (new indexing), order-tracking links. [V MacStories]
- Mac: sidebar | message list (unread dots, bold sender, two-line preview) |
  reading pane; toolbar with compose/filter/search. iPhone: list to message
  push. [BK] macOS 27 Mail-specific changes: UNVERIFIED.
- Borrow: 3-column for Tasks (lists | tasks | detail).

### Passwords
- Sidebar with category tiles (Passkeys, Codes, Wi-Fi, Security, Deleted) over
  all-items list; detail with copyable fields. [BK]
- iOS 27 AI password replacement: reports conflict (MacRumors/Wikipedia yes;
  Macworld says pulled). UNVERIFIED.

### Games app (new in 26)
- Tabs Home, Arcade, Play Together (Friends in some sources), Library, plus
  Search button; Library sortable by name/recent. [S]
- Low value for our modules.

### Preview (new on iPhone/iPad in 26)
- Document app for images/PDF; fill, rotate, crop. Inspector appears as a
  sidebar on iPad and a bottom-rising sheet on iPhone. [V MacStories 26]
- Borrow: one inspector component, sidebar on desktop and sheet on phone.

### Phone (unified layout in 26)
- "Unified" Calls: favorites plus chronological calls and voicemails in one
  view; filter button for Missed/Voicemail/Unknown/Spam; can switch back to
  Classic tabs. Apple reverted a similar unified Photos layout in 26 after
  criticism, returning to Library/Collections tabs. [V MacStories 26, Apple
  support in search]
- Takeaway: single feed + filter menu, with an opt-out.

### Camera
- iOS 26: mode row hidden by default (Photo/Video), six-dot button or swipe up
  opens a glass menu that morphs into a sub-menu; long-press night/flash for
  sub-menus. iOS 27: customizable quick-access strip (grid button > Edit). [V]
- Borrow: progressive disclosure through morphing glass menus for quick entry.

### Music (Mac sidebar)
- iOS 26: Pins (limit six) in iPad sidebar and widgets; playlist folders
  collapsing in the sidebar. iOS 27: artist pages with artwork color spreading
  across the page; landscape Now Playing. [V]
- macOS 26: playback controls in a very transparent bottom pill. [V]
- Sidebar: Search, Home, New, Radio, Library, Playlists. [BK]
- Borrow: pinned items at top of sidebar, color-spread header.

### System Settings (Mac)
- Sidebar with search at top, colored rounded-square icons, grouped inset form
  panes, drill-down with back chevron. [BK] Appearance holds the Liquid Glass
  control (26.1 Clear/Tinted, 27 slider). [V/S]
- Borrow: searchable settings sidebar, grouped forms.

### Finder (Mac 26/27)
- macOS 26: translucent toolbar/sidebar, rounder corners, always-visible toolbar
  groups, eight folder colors plus custom. [V]
- macOS 27: edge-to-edge sidebar, colored sidebar icons, uniform toolbar. [V/S]
- Finder-specific 27 changes beyond these: UNVERIFIED.

---

## 3. Module to pattern-source mapping

- Tasks (list/kanban/calendar): Reminders smart tiles + inline card editor +
  token highlighting; Mail 3-column; Calendar day timeline; Preview inspector.
- Reminders/quick entry: Reminders quick-entry snippet; Camera morphing menu;
  Calendar token highlighting; desktop floating panel.
- Timers: Clock (digits, wheel, start/stop) + Music-style bottom accessory.
- Finance accounts: Wallet card stack with focus-lift and per-card
  transactions.
- Finance reports: Stocks (range chart, pills), Screen Time (stacked bars,
  Day/Week), Health Trends.
- Budgets: Fitness rings and Weather range bars.
- Debts/installments: ticket-like pass cards (Wallet passes) with progress.
- Habits: Fitness rings + weekly bars + awards; Health pinned sparkline cards.
- Goals: Fitness awards/progress, Health Longevity-style score over time,
  Journal reflections.
- Today/home: Health Summary (pinned cards + Highlights), Weather (Highlights,
  condition background, icon switch), Home status chips, XL widget page.
- Global search: Search tab role morphing into a field, bottom search, grouped
  results sections.
- Settings: System Settings sidebar with search.

---

## 4. Distinct concepts (8)

Phone ~390 wide. RTL: sidebars on the right, back chevrons point right, Jalali
weeks start Saturday. Wireframes mix Persian labels and glyph placeholders.

### A. "Smart Tiles" (Reminders) for Tasks
A 2x3 grid of smart tiles (Today, Scheduled, Flagged, All, Done, Recurring)
with big live counts, then colored user lists. Tapping a tile pushes a flat
list; tapping a row expands it in place into a card with metadata chips. Glass
only on the floating add/search pill.
```
 PHONE
 +------------------------+
 |  [...]         [+ جدید] |
 | +--------+ +--------+  |
 | | 12     | | 5      |  |
 | | امروز  | | برنامه |  |
 | +--------+ +--------+  |
 | +--------+ +--------+  |
 | | 3 پرچم | | 40 همه |  |
 | +--------+ +--------+  |
 |  لیست‌های من            |
 |  o خانه          8 >   |
 |  o کار          14 >   |
 |       ( search pill )  |
 +------------------------+
 DESKTOP
 +-------------------------------------------+
 | detail | task list | lists sidebar (right) |
 +-------------------------------------------+
```

### B. "Card Stack" (Wallet) for Finance
Accounts are an overlapping deck of colored cards; tapping lifts one, the rest
collapse to a thin stack, and its transactions slide up in a half sheet that
turns opaque when expanded. Debts and installments are ticket-shaped cards with
progress bars.
```
 PHONE
 +------------------------+
 |  ====== حساب ملی ===== |
 |  ====== پس‌انداز ===== |
 |  == کارت اعتباری ====  |
 |  ----------------------|
 |  (half sheet)          |
 |  امروز                  |
 |  خرید      -250,000    |
 +------------------------+
 DESKTOP
 +--------------------------------------+
 | txn table + inspector |  card stack  |
 +--------------------------------------+
```

### C. "Rings and Trends" (Fitness + Health) for Habits
Concentric rings (one per habit group), a week strip, pinned habit cards with
sparklines and trend arrows, and a plain-language Highlights row. Completion
pulses the ring. Rings are content, never glass.
```
 PHONE
 +------------------------+
 |      (( (o) ))         |
 |   ش ی د س چ پ ج        |
 |  +------------------+  |
 |  | ورزش  ~~~~ up 12%|  |
 |  +------------------+  |
 |  Highlights: ...       |
 +------------------------+
 DESKTOP
 +--------------------------------+
 | trend grid | rings + week strip|
 +--------------------------------+
```

### D. "Summary + Highlights" (Health Summary + Weather) for Today
A vertical feed: conditional hero (tint reflects calm/busy/overdue), a
Highlights card for the next day, pinned module cards with sparkline and
delta, and an icon switch above the hero (Tasks / Money / Habits) like
Weather's Conditions/Precipitation/Wind. Hero collapses on scroll.
```
 PHONE
 +------------------------+
 |  [Tasks|Money|Habits]  |
 |   امروز ۱۴ آبان        |
 |   ۵ کار، بودجه ۷۲٪     |
 | +--------------------+ |
 | | Highlights ...     | |
 | +--------------------+ |
 |  pinned cards + spark  |
 +------------------------+
 DESKTOP
 +-----------------------------------+
 | inspector | feed with hero         |
 +-----------------------------------+
```

### E. "Day Timeline" (Calendar + Preview inspector) for Calendar tasks
Vertical hour grid in Jalali, blocks colored by list, month strip with dots.
Tapping a block opens an inspector: bottom sheet on phone, right sidebar on
desktop. Add field highlights natural-language tokens.
```
 PHONE
 +------------------------+
 | ش ی د س چ پ ج          |
 | 10 ----------------    |
 | 11 [== جلسه ==]        |
 | 12 ----------------    |
 |  (sheet inspector)     |
 +------------------------+
 DESKTOP
 +------------------------------------+
 | inspector | week grid | calendars   |
 +------------------------------------+
```

### F. "Chart Lab" (Stocks + Screen Time) for Reports
Top range segmented control over one scrubbable chart; stacked-category bar
variant; a flat list below that filters when a bar is tapped; delta pills
that are shape-coded as well as colored.
```
 PHONE
 +------------------------+
 |  [هفته|ماه|سال]        |
 |  |||||||| stacked bars |
 |  خوراک  32%  +4% pill  |
 |  حمل‌ونقل 18% -2% pill |
 +------------------------+
 DESKTOP
 +------------------------------------+
 | breakdown | chart | reports sidebar |
 +------------------------------------+
```

### G. "Clock Dock" (Clock + Music mini player) for Timers
Giant tabular digits and a circular start/stop. Running timers dock as a
bottom accessory above the minimized tab bar on every screen; tap expands to a
sheet. Desktop: a toolbar capsule shows the running timer.
```
 PHONE
 +------------------------+
 |   ۲۵:۰۰   ( start )    |
 |   wheel picker         |
 | ( timer 12:03  || )    | <- accessory
 |  [tabs minimized]      |
 +------------------------+
 DESKTOP
 +------------------------------------+
 |     [ toolbar: timer 12:03 ||]     |
 +------------------------------------+
```

### H. "Command Surface" (Search tab + Camera morph) for Search and Quick Entry
A Search tab role that morphs into a field with grouped result sections
(Tasks, Transactions, Habits, Goals); a floating quick-entry glass pill that
morphs into a small sheet with token highlighting and recent templates. On
desktop a centered floating panel via global shortcut.
```
 PHONE
 +------------------------+
 |  results sections      |
 |  ( [+]  جستجو...  )    |
 +------------------------+
 DESKTOP
 +--------------------------+
 |  dimmed window           |
 |   +------------------+   |
 |   | quick entry/find |   |
 |   +------------------+   |
 +--------------------------+
```

Design cautions: no glass behind dense Persian text at the clearest slider
setting; one scroll edge effect per pane; tint only the primary action; keep
data cards flat and opaque.

---

## 5. Sources

Apple
- https://developer.apple.com/videos/play/wwdc2025/219/ (fetched)
- https://developer.apple.com/videos/play/wwdc2025/356/ (fetched)
- https://developer.apple.com/videos/play/wwdc2026/269/ (fetched)
- https://developer.apple.com/design/human-interface-guidelines/materials and /tab-bars (fetch empty)
- https://support.apple.com/en-gb/126076 (Phone Unified layout; search result)
- apple.com newsroom pages: blocked, UNVERIFIED.

Reviews and news
- https://www.macstories.net/stories/ios-and-ipados-27-review/2/
- https://www.macstories.net/stories/ios-and-ipados-27-review/3/
- https://www.macstories.net/stories/ios-and-ipados-27-review/9/
- https://www.macstories.net/stories/ios-and-ipados-27-review/10/
- https://www.macstories.net/stories/ios-and-ipados-27-review/12/
- https://www.macstories.net/stories/ios-and-ipados-26-the-macstories-review/3
- https://www.macstories.net/stories/ios-and-ipados-26-the-macstories-review/14/
- https://www.macstories.net/stories/ios-and-ipados-26-the-macstories-review/15/
- https://www.macstories.net/stories/ios-and-ipados-26-the-macstories-review/16/
- https://www.macstories.net/stories/macos-26-tahoe-the-macstories-review/2/
- https://9to5mac.com/2026/06/09/macos-27-golden-gate-includes-these-changes-that-tahoe-critics-will-appreciate/
- https://9to5mac.com/2026/09/22/macos-27-gives-you-more-control-over-liquid-glass/
- https://9to5mac.com/2026/09/29/heres-everything-new-for-reminders-in-ios-27/
- https://9to5mac.com/2026/09/03/apples-calendar-app-in-ios-27-has-brand-new-design-for-key-features/
- https://www.macrumors.com/guide/ios-27-wallet/
- https://www.macrumors.com/2026/09/16/ios-27-2-health-app-beta/
- https://www.macrumors.com/guide/ios-27-ultimate-mega-guide/
- https://www.techbetweenthelines.com/whats-new-in-the-ios-27-weather-app-highlights-and-new-forecast-views-explained/
- Search-only: cultofmac Liquid Glass changes iOS 27/macOS 27; Tom's Guide iOS 27 refined Liquid Glass; BGR; Macworld iOS 27; Wikipedia iOS 27; MacRumors Games app guide.

## 6. Gaps

Gap-filling pass (2026-11-05), search-summary level only [S]:
- macOS 27 Finder / System Settings / Mail: no independent hands-on found.
  One vendor blog (Canary Mail) says the Mail sidebar icon-size setting in
  System Settings > Appearance also affects Finder and Photos, and that
  Control-Command-S hides the sidebar; single vendor source, treat as weak.
  Still UNVERIFIED: any Finder/Settings/Mail redesign in 27.
- Screen Time (iOS 27) [S]: rebuilt as an at-a-glance view for parents with
  weekly summaries and most-used apps for a given day, replacing a dense
  settings menu; Time Allowances by category (Entertainment, Games, Social)
  with age-based suggestions; daily Schedules for app availability; Ask to
  Browse. Needs every Family Sharing device on the 2026 OS. Exact screen
  layout (charts, tiles) remains UNVERIFIED; sources are June previews.
- Liquid Glass slider scope [S]: MacRumors guide says it affects Control
  Center, Home Screen folders, app overlays and Lock Screen notifications.
  Beta 5 widened the most-transparent end. An Apple DTS reply on the forums
  says glass "automatically responds to the new Liquid Glass slider to adjust
  its tint". A request for separate Control Center clear/tinted options is
  only a forum request, not a feature.
- Sheet-specific styling in 27 and widget layout changes: nothing found.
  UNVERIFIED.
- Per-app empty states: not researched; UNVERIFIED.

Additional sources from this pass (search-only):
- https://www.macrumors.com/2026/06/08/ios-27-parental-controls/
- https://appleinsider.com/articles/26/06/08/revamped-parental-controls-are-coming-to-iphone-mac-and-more
- https://9to5mac.com/2026/06/15/ios-27-adds-new-liquid-glass-slider-on-iphone-heres-what-it-lets-you-do/
- https://macrumors.com/how-to/ios-27-tone-down-liquid-glass-transparency
- https://developer.apple.com/forums/thread/840496
- https://canarymail.io/blog/mac-mail-customize-sidebar (weak, vendor)
