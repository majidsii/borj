# CI Baseline — Checkpoint

**Date:** 2026-11-03
**Implementation commits:** 2317824 (test: remove superseded apple pixel-golden comparisons), 085ff31 (style: apply dart format), 752e885 (fix: resolve analyzer warnings in apple glass rendering), 493b0aa (build: add local CI script), 7b6ec34 (ci: run checks on every push and pull request)
**Green CI run:** https://github.com/majidsii/dashboard-shakhsi/actions/runs/41539038228 on 7b6ec34, 5m03s

## Evidence
- Local `tool/ci.sh`: passed, 11m55s (clean worktree, `TZ=UTC LANG=C.UTF-8`)
- Tests: 1345/1/0 on CI (passed/skipped/failed)
- Negative checks (each red at the expected step): format https://github.com/majidsii/dashboard-shakhsi/actions/runs/41540208848, analyze https://github.com/majidsii/dashboard-shakhsi/actions/runs/41540606453, test https://github.com/majidsii/dashboard-shakhsi/actions/runs/41541438870, generated code https://github.com/majidsii/dashboard-shakhsi/actions/runs/41542105797
- Tests tagged `device`: none
- 6 analyzer issues pre-existed from Gate C commits (roadmap claimed clean); 5 in committed code fixed in 752e885, 1 in untracked WIP.

## Invariants
- `.flutter-version` drives the CI Flutter version.
- Actions pinned by SHA; workflow permissions `contents: read`.
- Checkpoints cite CI runs; no new `tool/verify_*` scripts.
