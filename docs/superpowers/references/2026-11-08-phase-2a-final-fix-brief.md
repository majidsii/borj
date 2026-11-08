# Phase 2A final fix wave (from the whole-branch review, opus a0716c0417812506a)

Worktree /home/shabin/projects/personal/borj/phase-2a, branch feat/redesign-phase-2a, base ee1e298. Global constraints: global-constraints.md in this folder (binding). Rulings in force: see the reviewer prompt list in progress.md ("Controller rulings in force").

## I1 (Important) Keyboard covers fields in the legacy panels
- lib/app/shell/app_shell.dart `_content` and lib/app/router/app_router.dart `_BranchPage`: no Scaffold between MaterialApp and the branch pages and nothing reads viewInsets (the old dashboard Scaffold resized for the keyboard).
- Probe at 390x844: focusing the first Finance `_EntryForm` field with a 300 px keyboard inset leaves it at y=790-805 under the keyboard (top 544); even without the inset the reveal scroll leaves it under the tab bar (758-820).
- Fix: shrink the content region by `MediaQuery.viewInsetsOf(context).bottom` on every class (like Scaffold resizeToAvoidBottomInset); strip viewInsets from the MediaQuery handed to the navigator; keep the chrome in the full-size Stack. Also make the reveal account for the tab bar: the page bottom padding already includes the tab bar, so after shrinking, a focused field must end above both the keyboard and (when the keyboard is closed) the tab bar.
- Tests (fail on ee1e298): with a 300 px bottom inset, focus a Finance field (tab-finance, the first EditableText) and assert its bottom ≤ 844 - 300; with no inset, a focused field near the bottom is revealed above the tab bar's top. Also add the deferred Task 6 test: on medium and expanded, a page's MediaQuery.paddingOf top == pad.top + 58 and start side == 0.
## I2 (Important) Desktop sidebar cannot reach FinancePanel; /finance selects no row
- Ruling (until Phase 4 rebuilds finance): the «تراکنش‌ها» row's location becomes `/finance`, the «قسط و بدهی» row's location becomes `/finance?section=debts` (the legacy FinancePanel ignores the query); both show FinancePanel. The routes /finance/transactions and /finance/debts (and their :id children) stay as they are for notifications.
- `GlassSidebar._selected()`: when no item matches exactly or by path prefix, fall back to the first item of the current location's section (pass the current section in, or derive it from the path's first segment).
- Update tests in test/app/shell/shell_destinations_test.dart and glass_sidebar tests accordingly; add a test: expanded, tap «تراکنش‌ها» → FinancePanel visible and that row selected; tap «قسط و بدهی» → FinancePanel visible and that row selected.
## Minors included
- M1 Dark-mode background seam on branch pushes in medium/expanded: GlassPushPage paints AppBackground sized to the content area. Skip the page's own AppBackground when the page is inside the shell group on medium/expanded (the push is instant there and the shell paints the window background); keep it on compact and for root pushes. Test: expanded branch push → no AppBackground inside the pushed page; root push → one.
- M2 test/app/shell/app_shell_test.dart:341: delete the unfocus line so "Ctrl+K survives text focus" presses Ctrl+K while the field is focused (the reviewer's probe shows it works).
- M3 lib/app/shell/today_interim_page.dart:28: debug review long-press uses `context.push`, not `go`.
- M4 Shortcuts: add `meta: true` variants (⌘K, ⌘,) when `defaultTargetPlatform == TargetPlatform.macOS`; test with debugDefaultTargetPlatformOverride.
- Task 3 deferred: rail `Tooltip(excludeFromSemantics: true, …)` so the label is announced once.
## Verify
Focused tests, `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test integration_test`, full `flutter test --exclude-tags device`, `tool/ci.sh --device`. Commits: one per item group is fine; messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; explicit paths; do not push; never stage .superpowers/.
