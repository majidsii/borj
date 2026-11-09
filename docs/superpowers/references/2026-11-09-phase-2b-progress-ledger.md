# SDD ledger — plan: docs/superpowers/plans/2026-11-09-redesign-phase-2b-today.md
Branch: feat/redesign-phase-2b (worktree ~/projects/personal/borj/phase-2b), base 56b3b91
Waves (advisor): {1,3} -> {2,4,5,7} -> 6 -> 8 -> 9.
Wave 1: Task 1 (phase-2b, sonnet a06ffb8de5fd7ff40), Task 3 (../phase-2b-t3, sonnet a704f875979428644) dispatched from 56b3b91.
Task 3: implemented 0dc9e06 (13 tests; full 1793/1).
Task 1: implemented 044828f (18 tests pass default/UTC/Tokyo; full 1791/1; builder takes nowUtc per A1).
Task 3: review a1750e27ff7ddff9a Approved. ⚠️ "TodayCard fills its slot" -> verify in Task 4/8 (card inside a grid slot is slot-sized).
Task 3: minor (deferred): no 4-column pull-into-gap test ([small,large,small,small] -> 0,0 1,0 3,0 0,2) nor [wide,small,small]; unbounded width breaks grid; assert(columns >= 1).
Task 3: complete (56b3b91..0dc9e06).
Task 1: review a9151af0bb9005c04 Approved (TZ=UTC rerun 31 pass). Minor folded into Task 2: tie-break sort by displayNumber then taskId; boundary tests (00:00 in, 23:59 in, 24:00 out); exception tests (moved in, moved out, skipped).
Task 1: minor (deferred): dartdoc warn PersianDateLabel inputs are naive wall-clock; "rule but no times" documentation test.
Task 1: complete (56b3b91..044828f).
Task 3 merged at 607c6ca. Wave 2 dispatched from 607c6ca: T2 (../phase-2b-t2, sonnet a46a87d5a5fc99f31, + builder stable sort/edge/exception tests), T4 (../phase-2b-t4, sonnet ace3ef50f6e4ac47c), T5 (../phase-2b-t5, sonnet aaa689e9512f89abf), T7 (../phase-2b-t7, sonnet acf6e35c8513ec0bf, + A3 contrast). formatClock in shared lib/features/today/presentation/today_format.dart created identically by T4 and T5 (content: shared-today-format.dart).
Task 7: STOPPED at A3 (onTint white on clear glass over white page = 1.00:1 light; dark 11-17:1). Ruling = plan Decision 6: chip keeps GlassRole.clear, text tones primary (title) / secondaryStrong (subtitle); navy tinted-dark chip deferred (needs a new glass role + token). Contrast test both modes, fails with onTint. Resumed same agent.
Task 5: implemented ae8ba7e (full 1815/1; AppText.decoration added; row Pressable toggles).
Task 7: implemented 79eb226 (Decision 6 applied; contrast test both modes + onTint fails 1.00; full 1827/1; today-title key on whole compact header).
Task 4: implemented 500c587 (37 today tests, TZ=UTC; slot-size test; full 1821/1). Concern: dark now-pill white on pink danger. Ruling: add AppTextTone.inverse (= colors.background) for the pill; contrast test both modes. Fix round 1/5 sent before review. Deferred: elapsed tint faint in dark.
Task 7: review dispatched (sonnet abd9e06c6dac3454c).
Task 5: review a0b62309a374f6ac7 Needs fixes: I1 row Pressable excludeSemantics hides time + duplicate title; I2 capacity paths untested. Fix round 1/5 sent (FIX_BASE ae8ba7e).
Task 7: review abd9e06c6dac3454c Approved (contrast test reads painted colours; key consistent; 44 pt target real).
Task 7: minor (deferred): today-title key shape differs per class (doc comment; Task 8 tests use descendant finder); no tap test in the 4 pt band; naive _now comment.
Task 7: complete (607c6ca..79eb226).
Task 5: fix round 1/5 (3 addressed; ae8ba7e..cb02958). Controller re-review by diff + 17/17 rerun.
Task 5: minor (deferred): row Pressable inside ExcludeSemantics still takes keyboard focus -> two tab stops per row (consider skipTraversal on the row); semantics test needs Pressable's enabled/focus flags.
Task 5: complete (607c6ca..cb02958).
Task 4: fix round 1 -> d2d2d39 (AppTextTone.inverse for now-pill; contrast tests both modes, onTint fails dark; full 1823/1). Task review dispatched on 607c6ca..d2d2d39.
Task 4: review ac17d7c75773ff309 Approved with I1 now-pill overflows card glass near scale ends. Fix round 2/5 sent: clamp pill; clamp short blocks to lane end; minutes via hour*60+minute.
Task 4: minor (deferred): third overlapping entry stacks in lane 2 on large card (document or 3rd lane, Part C); WCAG helper duplicated in tests.
Task 2: implemented e7c40f0, c3be882 (full 1819/1; today 36 under UTC/Tokyo; builder made non-final for a counting subclass; completion tests override scheduler + tz source).
Task 4: fix round 2/5 (3 addressed; d2d2d39..031efc7; controller diff check + rerun). Hour labels at ends extend ~12 px past the lane but inside the card's 14 px padding (OK).
Task 4: complete (607c6ca..031efc7).
Task 4 merged (app_text_test conflict: kept both decoration and inverse tests; analyze clean; today + app_text 91 pass).
Task 2: review a7eea542d0fed0551 (opus) Approved; risks a-d no defect. ⚠️ app_bootstrap_test and borj_app_appearance_test pump BorjApp without the helper -> Task 8 must add the minuteTickProvider override there.
Task 2: minors sent as a small follow-up round to the same agent: fakeAsync timer test, guarded getLocation -> AsyncValue.error, private named initializing formals in TodayCompletion, originalLocalDateTime last tiebreak + a comparator test that fails without the tiebreak, `base class` builder.
Task 2: complete for downstream use (607c6ca..c3be882); merged.
Task 6: dispatched (../phase-2b-t6, base e6871d2, sonnet a42f944a163588c57). Task 2 follow-up minors in ../phase-2b-t2 (same agent).
Task 6: implemented 36360b4 (12 tests; full 1894/1). Controller review by diff + rerun: OK. Small variant at 1.3: sub line maxLines 1, amount FittedBox scaleDown (accepted; default layout uses wide).
Task 6: complete (e6871d2..36360b4).
Task 2 follow-up d907d4a merged (fakeAsync tick test, guarded zone, private fields, base class; fake_async dev dep). RED for tiebreak not achievable (projector already sorts) — accepted as regression guard.
Task 8: dispatched (phase-2b, base fe74672, sonnet abdcbdd2d2ba8715b) with notes: override minuteTick in bootstrap tests, today-title descendant finder, TodayEntrance.reset, bare-fade check.
Task 8: BLOCKED at A4 (600x844: wide card 2/4 cols ~222 px; timeline header Row overflows 14 px @1.0, 75 px @1.3; 1024 passes). Ruling = plan Decision 7: grid columns follow the grid width (>=720 -> 4, else 2); timeline header robust (Flexible/ellipsis, tests at 222/160 @1.3). Resumed same agent.
Task 8: decision-7 fix committed 0a9c900 by the agent; remaining Task 8 work committed as WIP (unverified) when the owner paused (tokens). PAUSED 2026-11-09.
2026-11-09 13:12 resumed by owner. Task 8: same agent resumed from WIP 8bdb90a (base 5908b51).
Task 8: eec1c15 (empty commit with brief message; code = 0a9c900 + 8bdb90a; analyze clean, format OK, full 1918/1, TZ=UTC today 133). Review (opus) on fe74672..eec1c15.
Task 8: review ac867bbfa0d4f17de (opus) Needs fixes: I1 timeline header lost space-between (0a9c900); I2 reduced-motion fade never proven; I3 300 ms bound masked by pumpAndSettle; minors: entrance replays on onboarding->grid / later installment (real), CurvedAnimation not disposed, budget entrance not proven sampled, roll-over absence-only, «بعدی» assertion unscoped, loading drops header, dead MediaQuery + no 4-col widget test. Ruling: 1024x800 expanded = 2 columns under Decision 7 (accepted, assert). Fix round 1/5 sent (FIX_BASE eec1c15).
Task 8: fix round 1 -> cde9106 (RED: end-edge header, no-replay, reduced fade; extra: AnimationBehavior.preserve so the reduced fade keeps 200 ms under system disableAnimations; full 1921/1; TZ=UTC today 136). Re-review next.
Task 8: fix round 1/5 (10 addressed; eec1c15..cde9106). Re-review ad8da777cdf973cac all addressed; AnimationBehavior.preserve accepted.
Task 8: minor (-> FINAL FIX WAVE, visible): timeline header title is Flexible(flex 1) vs group flex 3 -> «برنامهٔ امروز» likely ellipsized at 358 px @1.3 (title should keep natural width; test 358 @1.0/1.3). Deferred: no test for header while agenda loads; const columns tautology; no dedicated test for a later installment card not replaying.
Task 8: complete (fe74672..cde9106).
Task 9: dispatched (phase-2b, base cde9106, sonnet a0ded9fa360fabbbf) incl. A5 cold-start probe.
Task 9: a933ae7 (samples; probe seeded via pumpBorjTestApp(seed, settle:false); ci --device exit 0; phoneShell today 2, todayEntrance 2, searchPush 3 (=budget), settingsPush 5 / settled 3 (legacy), tasks 8, finance 16; desktop today 2, entrance 2, search 3; profile p90 phone 2.243, desktop legacy 2.132). Controller-accepted by report.
Task 9: minor (-> final wave): Main samples lack a MediaQuery override (wide review page shows desktop group headers); probe seeds dueAt = now (could cross Tehran midnight) -> seed at today 12:00 zone time.
Task 9: complete (cde9106..a933ae7).
Final review: whole-branch 56b3b91..a933ae7 dispatched (opus acb229e61024cb45b) with deferred triage.
Final review acb229e61024cb45b (opus): Approved with fixes. I1 duplicate taskId (moved recurring occurrence) crashes timeline (Duplicate keys) — must fix. I2 plan contradiction: completed untimed task vanishes -> Ruling = plan Decision 8 (untimed one-off completed today stays, done). Before-merge minors: header double indent, installment semantics, installment id tie-break, AppRoutes.finance, row ExcludeFocus, Main samples MediaQuery, timeline title natural width, loading-header/columns/late-installment tests, PersianDateLabel dartdoc. Deferred: DST naive carrier, tz db init/fallback, toggle Future/double tap, banner capture, Part C grid items, owner visual elapsed tint. T8 title flex less severe than recorded. T9 seed dueAt=now dropped (cannot flake).
Final fix wave dispatched (brief final-fix-brief.md).
Final fix wave: sonnet a63d2e1b7f5b4d214 (base a933ae7).
Final fix wave -> cdfdfbb, a229a0e, e19aeea, 9ab2cd0 (full 1934/1, TZ=UTC today 148, ci --device exit 0; title via LayoutBuilder-capped FittedBox). Scoped re-review next.
Final fix wave re-review a6ebe7de21d8b67cc: all addressed. Phase 2B COMPLETE. Checkpoint 2026-11-09-redesign-phase-2b-checkpoint.md.
