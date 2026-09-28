# Gate-3 Task 1 — Architecture-A randomized qualification

Status: **PASS** for the fixed qualification matrix; Gate 3 remains open.

The harness uses D040 pre-generated plans and the project-owned Python oracle. The five functional seeds are `0xA3F30001` through `0xA3F30005`. Each saved plan contains 96 legal operations, finite independent pause/delay schedules and a 10,000-cycle post-drain interval; the driver also injects scheduled resets and a live-write reset epoch. No DUT arbitration result is used to generate later plan values.

## Results

- All five seeds passed; no randomized failure or RTL change was required.
- Aggregate accepted traffic: 80 reads and 80 writes per manager.
- Targets S0/S1/S2/S3: 120 observations each.
- LEN 0–15: 30 occurrences each.
- Maximum live reads and writes: 4 per manager pressure scenario.
- Target AW/AR/W stalls, manager B/R stalls and finite response delays were all observed.
- Same-visible-ID cross-manager overlap, same-target three-manager contention, all-manager activity and legal different-ID reverse completion were exercised.
- Three coordinated reset epochs per seed were executed, including one reset with a completed data phase waiting for B; traces retain epoch transitions and the pre-reset transaction is abandoned.

## Evidence

Per-seed plans, logs, coverage and JSONL event traces are under `results/raw/gate3_random/seed_*/`; aggregate counters are in `results/raw/gate3_random/aggregate_coverage.json`. Replay is provided by `scripts/run_gate3_random.sh --seed ...` and `--plan ...`.

This is deterministic functional qualification evidence. It makes no claim about long seeded contention, adversarial fairness, latency/throughput, timing, PPA, CDC or whole-Fabric formal proof. Architecture B remains absent.
