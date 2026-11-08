# SDD ledger — plan: docs/superpowers/plans/2026-11-08-redesign-phase-2a-shell.md
Branch: feat/redesign-phase-2a (worktree ~/projects/personal/borj/phase-2a), base c413149
Parallel worktree: ../phase-2a-t11 (feat/2a-t11-icons) for Task 11 (independent files).
Task 1: dispatched (base c413149, haiku a3e879ea0a55941c7)
Task 11: dispatched in ../phase-2a-t11 (base c413149, sonnet adb6267245e699ae3)
Task 11: implemented c52638a (DONE_WITH_CONCERNS: Android width test passed on old code - vacuous; sqlite asset cache copied)
Task 11: review dispatched (sonnet af830ef05b9e2b25f)
Task 11: review af830ef05b9e2b25f Approved (spec ✅). ⚠️ build output verified by controller (bundle/data/borj-app-icon-256.png identical to kit). Runtime window icon not visually checked (owner sees it when running the app).
Task 11: minor (deferred): Android width test passed on old mipmaps (does not prove brand content; content verified by reviewer pixel diff); borj.ico uses the master mark at 16/32 (kit-side, README); Linux test only greps the runner source.
Task 11: complete (c413149..c52638a, review clean). Merge into feat/redesign-phase-2a after Task 1.
Task 1: implemented 96df7a3 (DONE_WITH_CONCERNS: sqlite asset cache copied; collection-if not flagged dead_code)
Task 1: review dispatched (sonnet a83a90d35e27fdbb5)
Task 1: review a83a90d35e27fdbb5 Approved; ⚠️ analyze re-run by controller (clean).
Task 1: minor (deferred): habits/goals flags unused until those features; SidebarItem duplicates ShellDestination label/icon; flags-false change-detector test.
Task 1: complete (c413149..96df7a3, review clean). Task 11 merged.
Env note: sqlite3 native asset download fails in sandbox; agents copy verified libsqlite3 into .dart_tool (untracked). Check on a clean clone before release.
Tasks 2-5: dispatched in parallel worktrees ../phase-2a-tN (feat/2a-tN, base c7b2baf), sonnet: T2 a71606c72fdc3cd96, T3 aa791dae722dff61b, T4 ad3afc1bdf9d865bb, T5 a7c52ffd8ed863b6c. Barrel design.dart conflicts expected at merge (controller resolves).
Task 4: implemented ba42685 (DONE_WITH_CONCERNS). Controller ruling: desktop toolbar buttons stay 44 (GlassButton min = Global Constraint 44 hit target; the board's 36 visual is deferred, record in checkpoint). bareFadesAboveGlass(tester, boundary) adaptation accepted.
Task 4: review a5fefc18e7e6d3090 Approved. ⚠️ 36 vs 44: ruled above (44, min hit target). 
Task 4: minor (deferred): EmptyState fade duration fixed at first didChangeDependencies; label without onAction hides button silently (assert); reduced/quick both 200 ms so reduced test can't tell durations; shared `calls` list in toolbar test; LargeTitleHeader long-press hit area = glyphs only.
Task 4: complete (c7b2baf..ba42685, review clean). Merge after Tasks 2/3/5.
Task 5: implemented 0aeb250 (DONE; glassTestTheme added; bareFadesAboveGlass boundary = Navigator)
Task 5: review dispatched (opus a6e42d4c9941d1413)
Task 2: implemented 1514eeb (DONE_WITH_CONCERNS: semantics container key, extra semantics flags, lens tolerance+snap)
Task 2: review dispatched (sonnet a18365120b961df76)
Task 2: review a18365120b961df76 Approved (⚠️ hit target / cycle). Controller resolved: no import cycle (shell_destinations imports only material); hit area full cell (opaque GestureDetector on tight Stack) BUT Important: Pressable Stack is loose/topStart -> tab content shrinks and sits at cell start, not centred under the lens. Fix round 1/5 dispatched (FIX_BASE 1514eeb): full-width content + icon/label centre tests + lens-position tests RTL/LTR + tighter interruption test.
Task 2: minor (deferred): relayout-driven target change animates with stretch; reduce-motion toggled mid-flight doesn't stop; two height expressions; literal paddings/gap/icon size (plan-mandated board values); design/ pattern imports app/shell (layering); 1e-6 tolerance keeps ticker a few extra frames.
Task 2: fix round 1/5 (1 addressed, 0 open; 1514eeb..508e03e; centring test RED 566 vs 539.33 on 1514eeb; lens-position and interruption tests pass on both). Controller re-review by diff + 17/17 rerun.
Task 2: complete (c7b2baf..508e03e). Note: the same loose-Stack issue may affect any Pressable child that expects full width (check in Task 3 sidebar rows and final review).
Task 3: implemented 0e41586 (DONE_WITH_CONCERNS: 36 pt rows < 44; test surface 800x1000 in tap test; sidebar height infinity; Pressable.selected). Controller ruling: expanded sidebar rows stay 36 (board, pointer) = recorded deviation; medium rail rows 44 (touch tablets). Fix round 1/5 sent (FIX_BASE 0e41586) before task review; review follows on c7b2baf..HEAD.
Task 3: fix round 1 -> d6aa5b7 (rail rows 44, RED 36 on 0e41586; full suite 1644/1). Task review dispatched on c7b2baf..d6aa5b7.
Task 3: review dispatched (sonnet ad950cbafc6ed1601) on c7b2baf..d6aa5b7.
Task 5: review a6e42d4c9941d1413 (opus) Needs fixes: I1 no outgoing parallax for non-Cupertino covered routes (delegatedTransition), I2 framework barrierColor 0x18000000 stacked under scrim, I3 (plan-mandated, ruling fix) vacuous bare-fade check (no AppGlass in pages). Included minors: stale durations on pop after resize/reduce toggle (didPop), back gesture disabled tests + expectNoMovement for reduced. Ruling: scrim drawn by incoming route behind its page accepted. Fix round 1/5 dispatched (FIX_BASE 0aeb250).
Task 5: minor (deferred): scrim test checks existence only; inspector onClose unused; reduced inspector close untested; "closes faster" test doesn't compare and hard-codes 0.7.
Task 3: review ad950cbafc6ed1601 Approved. ⚠️ resolved by controller: no two sidebar items of different sections share a path prefix (shell_destinations); bounded height comes from Task 6 Positioned top/bottom.
Task 3: minor (deferred): rail Tooltip + Pressable label may announce twice; no test for /settings highlight or section-prefix; Uri.parse per item per build.
Task 3: complete (c7b2baf..d6aa5b7, review clean).
Tasks 2,3,4 merged at 3dbbf3b (barrel conflicts resolved by controller; analyze clean; test/app/design + shell 202 pass). Task 5 fix round 1 in flight.
Task 5: fix round 1 -> 00b5031 (delegatedTransition, barrierColor null, AppGlass on pages, didPop reverseDuration, gesture-disabled tests; RED 3 fail on old). Scoped re-review dispatched (sonnet a552d2ad7bfd520bd).
CROSS-TASK (for Task 7 brief): MaterialPage routes on Linux use Material transitions containing FadeTransition -> would bare-fade glass. Every GoRoute in the shell router must use pageBuilder with NoTransitionPage (branch roots, pending) or GlassPushPage; no `builder:` (MaterialPage) routes. Add to Task 7 dispatch.
Task 5: fix round 1/5 (5 addressed, 0 open; 0aeb250..00b5031). Re-review a552d2ad7bfd520bd all addressed.
Task 5: minor (deferred): loop test homeX sampled before push (vacuous); not-animated null delegatedTransition not exercised over a Material home.
Task 5: complete (c7b2baf..00b5031).
Task 5 merged at b76b80f (226 design+shell tests pass, analyze clean, pushed). Task 6: dispatched (base b76b80f, sonnet a9b2aa3cc7eab02f6).
Task 6: agent hit API 5-hour limit before writing files; resumed 17:21 Tehran (same agent).
Task 6: implemented 1c076a5 (DONE; tests set DPR 1; FakeGlass counts compact 2/2, medium 2, expanded 2, +inspector 2 — inspector shares the content group key since it sits inside shell-content)
Task 6: review dispatched (opus a9db095c641baf439) with named risks: navigator reparent, padding arithmetic, inspector budget sharing content key, autofocus.
Task 6: review a9db095c641baf439 (opus) Needs fixes (plan-mandated I1: budget test can't fail — inspector shares content key, slack bounds, desktop only at settle, overlays never exercised). Shell code correct (paint order, padding arithmetic, state across class change).
Ruling (controller, Phase 1 precedent: strictness fixes for plan-mandated test gaps): fix. Inspector: page-hosted inspector joins content key and cannot refract content -> Phase 3 adds a shell-level inspector slot outside the content group with its own budget test; inspector case removed from Task 6 budget test. Record in checkpoint decisions.
Fix round 1/5 dispatched (FIX_BASE 1c076a5): exact idle 2, interaction sampling on all classes, overlay = 3, safe-area tests + desktop chrome offset by safe area, Focus skipTraversal + shortcut tests, compact->medium / expanded->compact state tests.
Task 6: minor (deferred): KeyedSubtree redundant (go_router keys the shell); no-page-group test checks the fixture; Task 8 forward note: autofocus inside shell chrome is suppressed by the shell Focus.
Task 6: fix round 1 -> a445f6b (RED: only medium safe-area test failed on 1c076a5; strict counts already held: idle 2, selection 2, overlay 3). Re-review next.
Task 6: fix round 1/5 (4 addressed, 0 open; 1c076a5..a445f6b). Re-review a4b674c208f317da3 all addressed.
Task 6: minor (deferred): no test of page-visible MediaQuery padding on medium/expanded (start inset, top = pad.top + 58).
Task 6: complete (b76b80f..a445f6b).
Task 7: dispatched (base a445f6b, sonnet a4e3ae1ea97a755aa) with rulings: no builder: GoRoutes (NoTransitionPage / GlassPushPage) + walker test.
Task 7: implemented c6f9662 (DONE; RED 10/10 notification locations; useWindowSize + pumpPage helpers; errorPageBuilder; 2 bootstrap tests re-anchored to today-title)
Task 7: review dispatched (opus a32f4dc4cd53bfd2f; risks: notification go + back, lost dashboard behaviour, pumpPage, root routes over shell).
Task 7: review a32f4dc4cd53bfd2f (opus) Approved; probes: branch deep links back correctly; root /settings push covers chrome and returns to branch state.
Task 7: minor (deferred -> final wave triage): settings push tests pass mid-push (assert covered route offstage); notification resolve test has no positive page assert (plan-mandated); notification go to a ROOT location (/settings, /habits/:id, /goals/:id, /challenges/:id) drops the shell, Android back then exits (UX gap: consider push for root locations in the adapter); global rootNavigatorKey shared across router rebuilds; _size wrapper; PendingScreen double Material; no tests for branch-detail system back, medium «افزودن», compact calendar action; legacy TasksPanel prints "2 independent backdrop captures" (Decision 7); stale tool/verify_* scripts read deleted dashboard files (not in CI).
Task 7: complete (a445f6b..c6f9662, review clean).
Task 8: dispatched (base c6f9662, sonnet ab88149d75f05103d).
Task 8: implemented 0efbde4 (DONE; bare-fade test vs baseline because "the app's first page route already fades the shell"; medium Ctrl+K test; capsule end offset 52/trailing action).
CROSS-TASK (controller, from Task 8 concern): the StatefulShellRoute uses `builder:` -> its page is a MaterialPage whose Linux transition holds FadeTransition above ALL chrome and content glass (bare fade when the shell route animates, e.g. returning from a root route via go). Fix: StatefulShellRoute pageBuilder: NoTransitionPage(child: AppShell). Also: pushed root pages (GlassPushPage) have no backdrop group -> each glass shape own capture ("2 independent captures" on /search). Consider GlassPushPage wrapping its content in GlassBackdropGroup. Both -> final fix wave unless the Task 8 review demands earlier.
Task 8: review a6c5d616fb9870d51 Approved; confirmed the shell's MaterialPage FadeTransition (cross-task item above -> final wave). ⚠️ chrome shape count (expanded cap 6): check in final review.
Task 8: minor (deferred): no geometry test for capsule (1/2 trailing actions, RTL) nor second Ctrl+K while open; 52 magic number (expose from ShellToolbar); rootNavigatorKey.currentContext! bang and overlay not closed when shrinking to compact; duplicated field plumbing; Escape only while focus inside overlay (wrap FocusScope/DismissIntent); pushed /search page glass not grouped ("2 independent captures" log).
Task 8: complete (c6f9662..0efbde4, review clean).
Tasks 9 (../phase-2a-t9, sonnet ab8cb043c46dfb4af) and 10 (phase-2a, sonnet ab1c956a1c8f3ffaf) dispatched in parallel from 0efbde4.
Task 10: first run DONE_WITH_CONCERNS (no commit): real glass phone settingsPush=4 (>3), today=1, tasks=7, finance=16 (legacy, printed); desktop today 1 / search 2; LG_PERF 0.0 (no frames recorded); profile KeyEventSimulator crash. Controller: A) GlassPushPage wraps content in GlassBackdropGroup (pushed page = one content capture); B) StatefulShellRoute -> NoTransitionPage (cross-task item), search bare-fade test -> isEmpty; C) investigate perf 0.0, continuous frames; D) open overlay by tap in profile. Sent to same agent.
Task 9: implemented 631188d (7 samples; review test scrollUntilVisible accepted). Controller review by diff: toolbar sample used wrong actions -> fix round 1/5 sent.
Task 9: fix round 1/5 (1 addressed; 631188d..d4f8039; controller re-check by report: toolbar sample = compact Today actions; test/app/apple_visual 94/1). Task 9: complete (0efbde4..d4f8039). Merge into phase-2a AFTER Task 10 commits (its agent is working in the phase-2a tree).
Task 10: a74aa16 (A: GlassPushPage group; B: shell NoTransitionPage, search bare-fade isEmpty; full suite 1763). Phone settingsPush still 4 = outgoing chrome 1 + Appearance group 1 + 2 keyless OriginalGlass in LegacyImportSection (legacy); settled Settings 3.
Ruling: Decision 7 extended to Settings (legacy, Phase 5): printed not asserted. Phone push budget asserted on /search push (≤3, ≥2, seeded floor). Perf: phone push/pop /search loop; desktop fling TasksPanel on /tasks. Sent to same agent.
Task 10: 0a9c54e probe committed. ci --device exit 0: phoneShell today 1, searchPush 2 (assert), settingsPush 4 / settled 3 (legacy, printed), tasks 7 / finance 16 (legacy); desktopShell today 1, search 2; desktop raster p90 debug 1.878, profile 2.006; PHONE raster p90 0.0 (tester.view override yields no raster timing). Extra attempt sent: setSurfaceSize + MediaQuery override wrap for phone perf.
Task 10: f4a068b phone perf via setSurfaceSize + MediaQuery wrap: phone p90 debug 1.567 / profile 1.305; desktop 1.538 / 1.591; ci --device exit 0. Review dispatched on 0efbde4..f4a068b.
Task 10: review aee4057a81c59a720 Needs fixes: I1 branch-pushed GlassPushPages nest a 2nd group under shell-content (rule breach, untested); I2 perf assert passes on 0.0 (no floor). Fix round 1/5 dispatched (FIX_BASE f4a068b): conditional page group via GlassContext.inBackdropGroup + tests; p90>0 and frame count floor; phone app constrained to 390x844; desktop overlay ≥2 floor; push-page 1-vs-3 floor; desktop perf labelled legacy.
Task 10: fix round 1 -> a39680b (inBackdropGroup conditional page group; RED both new tests on old lib; profile floors; phone 390x844 surface; LG phone p90 debug 1.699 profile 1.19; desktop legacy 1.845/1.601; full 1765/1; ci --device exit 0). Re-review next.
Task 10: fix round 1/5 (5 addressed; f4a068b..a39680b). Re-review a3e877903cfbe44e6 all addressed. Task 10: complete (0efbde4..a39680b).
Task 9 merged at ee1e298.
Final review: whole-branch c413149..ee1e298 dispatched (opus a0716c0417812506a) with deferred-minor triage.
Final review a0716c0417812506a (opus): Approved with fixes. I1 keyboard covers legacy panel fields (no Scaffold/viewInsets after dashboard deletion; probe-confirmed). I2 desktop «پول» rows open pending pages, FinancePanel unreachable, /finance selects no row (plan issue). Minors M1 dark seam on branch pushes (medium/expanded), M2 overclaiming test, M3 debug review uses go, M4 ⌘ shortcuts on macOS.
Ruling I2 (controller, until Phase 4): تراکنش‌ها -> /finance, قسط و بدهی -> /finance?section=debts (both FinancePanel); sidebar falls back to the section's first item. Triage: Task 8 "pushed /search not grouped" RESOLVED by a74aa16/a39680b; rest deferred to named phases per review (Phase 3: inspector slot/adaptive detail, push/overlay/test gaps; Part B/C: lens/EmptyState; habits phase: root-location notification back stack via adapter go('/')+push; brand kit: ico small cut).
Final fix wave dispatched (one agent, brief final-fix-brief.md).
Final fix wave: dispatched (sonnet a5b2179987eefd590, base ee1e298).
2026-11-09 00:05 resumed by owner («ادامه بده»). Final fix wave re-dispatched (sonnet a39ea27f0b3551bc3, base 1c2d9b3). GitHub fetch hung (network) — push later.
Final fix wave -> 33bc38d, 3636e7b (full 1776/1, ci --device exit 0; /finance/debts/42 now selects تراکنش‌ها by prefix; tooltip/M2/padding tests can't fail on old code). Pushed. Stash clean. Scoped re-review next.
Final fix wave re-review ab1eac3406177fa0c (opus): I1, I2, M1-M4, tooltip all ADDRESSED; app_shell.dart intact after the cp incident. NEW Important: sidebar rows equal to a branch root use goBranch -> restore the branch's last state (wrong row highlighted / pushed debt page shown). Ruling: one last targeted fix (same agent): sidebar rows always go(item.location); + minors stable pushed-page tree across compact boundary, stronger M2 focus assert.
Final wave minor (deferred): reveal jumps per keyboard-animation frame and measures EditableText not the decorated field (legacy panels; Phase 3/4); /finance/debts/:id selects تراکنش‌ها (Phase 4).
Final fix: 1292151 (sidebar rows go(location); KeyedSubtree GlobalKey stable pushed page; stronger focus assert; 3 RED router tests; full 1780/1). Controller diff check OK. Final verification (format/analyze/full/ci --device/profile) running.
Final verification at 1292151: format OK, analyze clean, 1780 pass / 1 skip, tool/ci.sh --device exit 0 (phoneShell 2, searchPush 2, desktopShell 2; debug p90 phone 1.97, desktop legacy 1.462); profile p90 phone 1.289, desktop legacy 1.657. Final wave complete. Checkpoint docs/superpowers/checkpoints/2026-11-09-redesign-phase-2a-checkpoint.md. Phase 2A COMPLETE.
