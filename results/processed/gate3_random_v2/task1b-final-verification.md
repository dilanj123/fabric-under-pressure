# Task-1B final independent verification

Implementation parent: `121d903297ea3d1fc31974bcab0855ea655cba0f`

This evidence record is committed on top of that implementation parent. The
review target is the exact commit containing this report and the accompanying
`task1b-final-coverage.json` and `final-run-artifacts/A3F30001.json` through
`A3F30005.json`; the parent/evidence relationship is recorded in
that JSON so the evidence cannot be confused with the older raw artifacts.

This processed record binds the independent CAO/Codex verifier run to the
repair commit. Raw simulator output remains under the repository's ignored
`results/raw/` policy; this file is the version-controlled summary.

## Commands and exits

| Command | Exit | Result |
|---|---:|---|
| `bin/prepare-eda-worktree "$PWD"` | 0 | PASS |
| `scripts/run_manager_scheduler_checks.sh` | 0 | PASS |
| `python3 -m unittest -v tb/random/test_axi_random_plan.py tb/random/test_concurrent_endpoint.py tb/random/test_concurrent_bus.py` | 0 | PASS |
| `scripts/run_gate3_random_v2.sh` | 0 | PASS; all five seeds |
| `scripts/run_gate3_random_v2.sh --plan results/raw/gate3_random_v2/plans/seed_A3F30001.json` | 0 | PASS replay |
| `scripts/run_gate2_closure.sh` | 0 | PASS |

The verifier also independently reran the scheduler, five-seed matrix, and
Gate-2 closure; each rerun exited 0. Production RTL had no diff, and the
scoped source/document check passed. Generated raw outputs were not edited for
whitespace.

## Fresh random-body coverage

All rows are from the post-repair event-derived coverage recorded in the
source-controlled `final-run-artifacts/` snapshots and summarized in
`task1b-final-coverage.json`. Their SHA-256 values bind them to the fresh raw
coverage/events captured by the independent verifier. The
global 12 means four live transactions per each of the three managers; the
event audit independently measured per-manager maxima `[4,4,4]` for both
reads and writes. All final outstanding counts were zero.

| Seed | Ops | Read max | Write max | Target AW/AR/W stalls | Manager B/R stalls |
|---|---:|---:|---:|---|---|
| `A3F30001` | 512 | 12 | 12 | 218 / 219 / 39 | 183 / 184 |
| `A3F30002` | 512 | 12 | 12 | 204 / 237 / 35 | 169 / 193 |
| `A3F30003` | 512 | 12 | 12 | 209 / 225 / 37 | 174 / 186 |
| `A3F30004` | 512 | 12 | 12 | 239 / 211 / 41 | 196 / 174 |
| `A3F30005` | 512 | 12 | 12 | 221 / 211 / 34 | 194 / 179 |

The older tracked `results/raw/gate3_random_v2` coverage and
`random_depth_reachability.json` depth-2 result are historical pre-repair
evidence. They are intentionally preserved and are not used for this final
acceptance decision.

## Scope

Task-1B only. No Mission 2, Architecture-A benchmarking, or Architecture B
was started. Gate-2 baseline closure remains PASS.
