# Gate-3 Task 1 — Architecture-A randomized qualification

Status: **historical / reclassified**. This matrix remains useful replayable evidence, but it is not sufficient to claim genuinely randomized concurrent qualification.

The harness uses D040 pre-generated plans and the project-owned Python oracle. The five functional seeds are `0xA3F30001` through `0xA3F30005`. Each saved plan contains 96 legal operations, finite pause/delay schedules and deterministic pressure prologues. The operation values and reset plan are replayable, but the 96-operation forced prefix consumed the intended random branch, the manager/direction/target/LEN fields were therefore not genuinely seeded, and the driver completed operations serially. The prior 10,000-cycle interval was post-drain idle time rather than active stress.

## Results

- All five historical runs passed; no randomized RTL claim is made from them.
- Aggregate accepted traffic: 80 reads and 80 writes per manager.
- Targets S0/S1/S2/S3: 120 observations each.
- LEN 0–15: 30 occurrences each.
- Maximum live reads and writes: 4 per manager pressure scenario.
- Target AW/AR/W stalls, manager B/R stalls and finite response delays were all observed.
- Same-visible-ID cross-manager overlap, same-target three-manager contention, all-manager activity and legal different-ID reverse completion were exercised.
- Three coordinated reset epochs per seed were executed, including one reset with a completed data phase waiting for B; traces retain epoch transitions and the pre-reset transaction is abandoned.

## Evidence

Per-seed plans, logs, coverage and JSONL event traces are under `results/raw/gate3_random/seed_*/`; aggregate counters are in `results/raw/gate3_random/aggregate_coverage.json`. Replay is provided by `scripts/run_gate3_random.sh --seed ...` and `--plan ...`.

This is deterministic functional evidence with randomized parameter metadata and deterministic pressure prologues. It makes no claim about genuine random-body concurrency, long seeded contention, adversarial fairness, latency/throughput, timing, PPA, CDC or whole-Fabric formal proof. Architecture B remains absent.
