### Task 9: Review samples and the device probe on a populated Today

**Files:**
- Modify: `lib/app/apple_visual/review/design_review_samples.dart`, `integration_test/glass_shell_probe_test.dart`
- Test: the existing review test; the device probe

Steps:
- [ ] **Step 1: Review samples** (follow the existing entries): `TimelineCard` (board `Main`, a fixed agenda with three blocks and now at 14:30), `TodayTasksCard` large (board `Main`), `TodayTasksCard` expanded grouping (board `MacToday`, in a 572 × 340 box with a 1440 MediaQuery), `InstallmentCard` wide and small (board `Main`), `TodayHeader` date chip (board `MacToday`), `TodayOnboarding` (board `PhoneEmptyToday`). Samples use fixed data, never providers.
- [ ] **Step 2: Run** `flutter test test/app/apple_visual`. Expected: PASS.
- [ ] **Step 3: Device probe.** In `integration_test/glass_shell_probe_test.dart`, before sampling Today, create one task due today and one active installment plan through the real repositories (via the container returned by `pumpBorjTestApp`), wait for the grid (`find.byKey(ValueKey('today-grid'))`), then sample. Change the phone and desktop Today assertions to `today ≤ budget` AND `today ≥ 2` (content + chrome now that Today has content glass), and print `today=` as before. Run `flutter test integration_test/glass_shell_probe_test.dart -d linux`, the full `tool/ci.sh --device`, and the profile drive (`flutter drive --profile -d linux --driver=test_driver/integration_test.dart --target=integration_test/glass_shell_probe_test.dart`); report every `LG_` line.
- [ ] **Step 4: Commit** `test(today): review samples and the device probe on a populated Today`.

---

