# Architecture-B Functional and Scheduler Qualification

**Status:** B-specific directed, randomized functional, and targeted scheduler checks PASS. Canonical W00–W13 benchmarking and the matched Architecture-A/B PPA comparison have not been run.

## Frozen experiment and implementation

Architecture B implements the D045 scheduler hypothesis without changing D045. B-specific modules are `axi_qos_aging_arbiter_3`, the AW/AR B schedulers and their target paths, and top `axi_fabric_b`. The existing registered target address slots remain in place. The B top is a source-normalized copy of the A top with only the four AW/AR path module references changed. The B target paths differ from A paths only by connecting manager AxQOS to the B scheduler. Shared address decode/legality, outstanding and write-owner state, W path, B/R routers, S3 endpoint, signal bundles and reset behavior are reused unchanged. No B-only FIFO or pipeline stage was added.

The arbiter gives the highest AxQOS among eligible requests unless an eligible request has age at least 64; then selection is restricted to the starved eligible set. RR resolves ties in either set. Each target/direction/manager has an 8-bit saturating age. Legal-pending is manager AxVALID, request legality and target match. Age advances each clock while legal-pending and without manager address admission, independently of credit, target READY/slot and AW-owner service eligibility. Selection uses registered pre-state. A held grant is not preempted; the common RR pointer advances only on accepted manager address admission.

## Results

| Evidence | Result |
|---|---|
| Standalone scheduler directed test | PASS, 28 checks; QoS priority, RR ties, age 63/64/255, escape, clearing, held grant, withdrawn request and reset |
| Scheduler formal prove | PASS, Yices/SBY bounded BMC depth 20 |
| Scheduler formal cover | PASS, depth 80; covers reach age 63, threshold crossing/escape with a competing fresh request at step 64, and multiple-starved RR at step 65 |
| B whole-DUT directed regression | PASS, 444 checks; includes the existing functional matrix, integrated AW/AR RR, B QoS priority, 96-cycle age/escape case and AR progress during an active AW/W owner |
| B independent Gate-2 oracle matrix | PASS, 2 XML testcases; four-read/four-write capacity, D028 recovery, same-ID protection, distinct-ID B/R reordering, S3 and live-work reset epoch |
| Python model/plan/endpoint/bus/scheduler tests | PASS, 15 tests; reference-model tests PASS, 15 tests |
| B lint | PASS, Verilator `-Wall -Wno-fatal`; no warnings in the final lint log |
| ECP5 synthesis sanity | PASS, direct `axi_fabric_b` synthesis only: 5,542 LUT4, 1,427 TRELLIS_FF, 373 CCU2C, 746 PFUMX and 209 L6MUX21 (8,297 mapped cells total) |

Synthesis is a feasibility check, not an A/B resource comparison. No B nextpnr route, canonical B benchmark, P99/throughput result or timing-closure claim is made.

D045's frozen evaluation remains pending for the later matched benchmark: W08 M2 read-admission P99 at most 16 cycles versus A's 21; W08 M1 aggregate payload throughput at least 95% of A's 10.607 bytes/cycle; W08 M0 read and write admission P99 each no more than 10% worse than A; and W12 Jain grant-rate index at least 0.98, alongside starvation, resources and routed timing review. None of these performance criteria was evaluated by the functional runs here.

## Frozen functional seeds

Every run used the unchanged Gate-3 plan methodology and seed identities. Each XML has exactly one testcase with zero failures/errors.

| Operations | Seed | Result | Accepted reads | Accepted writes | Planned resets | Random max live R/W |
|---:|---|---|---:|---:|---:|---:|
| 512 | A3F30001 | PASS | 260 | 252 | 3 | 2 / 2 |
| 512 | A3F30002 | PASS | 269 | 243 | 3 | 2 / 2 |
| 512 | A3F30003 | PASS | 264 | 248 | 3 | 2 / 2 |
| 512 | A3F30004 | PASS | 238 | 274 | 3 | 2 / 2 |
| 512 | A3F30005 | PASS | 250 | 262 | 3 | 2 / 2 |
| 2,048 | A3F30001 | PASS | 1,000 | 1,048 | 3 | 2 / 2 |
| 2,048 | A3F30002 | PASS | 1,029 | 1,019 | 3 | 2 / 2 |
| 2,048 | A3F30003 | PASS | 1,064 | 984 | 3 | 2 / 2 |
| 2,048 | A3F30004 | PASS | 992 | 1,056 | 3 | 2 / 2 |
| 2,048 | A3F30005 | PASS | 1,022 | 1,026 | 3 | 2 / 2 |

Random-body observations include all managers and S0–S3, every LEN and QoS value, AW-before-W/W-before-AW/near-cycle modes, target AW/AR/W stalls, manager B/R stalls, finite response delays and sustained all-manager activity. For the five 2,048-operation runs, observed aggregate counts are: AW stalls 4,624 episodes/4,945 cycles; AR 4,586/5,063; W 777/1,554; manager B stalls 3,856; manager R stalls 3,828; response-delay events 8,595; and 24,915 cycles with all managers active.

The random harness reports zero same-target contention episodes, cross-manager same-ID overlaps, out-of-order completions and reset-with-live-work events; these are **not claimed as random coverage**. Directed whole-DUT/oracle regressions cover same-target RR contention, same visible IDs across managers, different-ID B/R reorder, and reset with live work. Random depth remains two reads and two writes; the four-outstanding capability is established by directed B DUT tests, not randomized depth-four evidence. Plans contain reset markers, but the v2 random test does not execute scheduled live resets; only reset events actually observed in the event stream count.

## Structural audit

| Area | A/B relationship |
|---|---|
| QoS/aging scheduler and age state | B-only; four AW and four AR target instances |
| Registered AW/AR target slots | Same one-entry slot structure and timing; B-specific paths connect QoS to scheduler |
| Outstanding IDs/counts, write ownership and W routing | Shared unchanged modules |
| B/R response handling and S3 behavior | Shared unchanged modules |
| Address map, AXI subset, topology, reset, endpoint | Unchanged |
| Benchmark workloads, seeds, metrics, generator and analysis | Unchanged; no B canonical benchmark run |

Architecture-A RTL, workloads, benchmark scripts and D045 were not modified. The shared Gate-3 random runner gained a default-A/B source-selection option; A remains the default. The directed testbench gained a compile-time B DUT selection and B-only scenarios.

## Reproduction and evidence

Commands:

```sh
python3 -m unittest discover -v -s tb/random -p 'test_*.py'
PYTHONPATH=tb/model python3 -m unittest -v tb/model/test_axi_reference_model.py
scripts/run_qos_aging_directed.sh
scripts/run_qos_aging_formal.sh
scripts/run_fabric_b_directed.sh
scripts/run_gate2_oracle_b.sh
scripts/run_gate3_random_b.sh
scripts/run_gate3_random_b_long.sh
scripts/run_gate2_closure.sh
scripts/run_fabric_a_integration_checks.sh
```

Per-seed replay plans, event traces, XML and logs are under `results/raw/gate3_random_b_512/` and `results/raw/gate3_random_b_2048/` (large plans, event streams and run logs are losslessly gzip-compressed). Directed, oracle, formal and synthesis records are under `results/raw/fabric_b_directed/`, `results/raw/gate2_oracle_b/` and `results/raw/architecture_b_scheduler/`. Aggregate counters and per-seed completion counts are in `coverage_512.json`, `coverage_2048.json` and `seed_results.csv` in this directory.

Gate-2 closure and Fabric-A integration checks were rerun and PASS; their fresh raw logs are preserved under `results/raw/architecture_b_scheduler/a_requalification/` (the synthesis log is losslessly gzip-compressed). Production Architecture-A RTL remains unchanged. D045 remains frozen. B functional verification is complete; B performance and matched PPA measurement remain future work.
