## Decisions recorded by this plan

1. **Installment without a date.** `InstallmentPlan` has no due date; the card shows «قسط n از m» and the amount, not the board's «۱۰ آذر». A due date needs its own finance spec (Phase 4).
2. **Onboarding has one step.** The account and habit steps return when those features ship.
3. **Default installment size is wide**, not the catalogue's small: with the budget card hidden, a lone small card would leave a gap beside it.
4. **"Today" for tasks** = occurrences whose instant (due, else start) falls in the local calendar day `[00:00, 24:00)` in the task calendar time zone (`taskCalendarTimeZoneProvider`), excluding skipped and canceled occurrences, plus active one-off tasks with no start and no due time (untimed). Overdue tasks from earlier days are not shown (Phase 3 decides overdue handling with the Tasks screen).
5. **Desktop has a timeline card too.** The `MacToday` board shows only tasks, budget and habits; with budget and habits hidden, the catalogue's timeline card keeps the desktop Today useful. The board wins again when those features ship.

