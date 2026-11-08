# Task 8 report: STOPPED per A4 (no commit)

Status: BLOCKED. At 600x844 with 4 columns the populated Today overflows (A4 stop condition).

Evidence: TimelineCard header Row (timeline_card.dart:51) overflows by 14 px at text 1.0 and 75 px at 1.3 when the wide card is 2 of 4 columns at window width 600 (medium shell with 72 px rail). 1024x800 passes at both scales. Needs a ruling on medium columns (or a TimelineCard header fix).

Work in tree, uncommitted:
- lib/features/today/presentation/today_page.dart (TodayPage, TodayEntrance, _Enter with one controller + Interval, reads todayNowProvider; loading renders an empty ListView)
- router `/` -> TodayPage; today_interim_page.dart removed with git rm; test references updated
- test/support/borj_test_app.dart: default taskCalendarTimeZoneProvider override 'Asia/Tehran' + tz init
- app_bootstrap_test / borj_app_appearance_test: minuteTickProvider and zone overrides. No other test pumps BorjApp directly.
- test/features/today/today_page_test.dart: all pass except the two 600 px cases.
- NOT done: today_budget_test.dart, full test run, TZ=UTC run, format/analyze final check (analyze was clean before the page test was added), commit.

TDD note: implementation was written before the page tests (RED not recorded for the page tests).
Notes: markPlayed fires in the first post-frame even while the grid is still loading; the entrance still plays because _coldStart is captured in initState. IndexedStack keeps Today alive across tab switches, so the "second build" test marks played beforehand instead of switching tabs.
