# Gate-3 Architecture-A verification closure

**Decision: PASS.** Architecture A passed the frozen functional random seeds, the declared long random extension, integrated whole-DUT AW/AR fairness, Gate-2 closure and Fabric integration checks. Production RTL is unchanged. This is functional verification evidence; it contains no benchmark, PPA, P99 or timing-closure claim.

## Qualification runs

| Run | Seeds | Random operations per seed | Result |
|---|---|---:|---|
| Functional | `0xA3F30001`–`0xA3F30005` | 512 | PASS, all 5 XML results have 1 test, 0 failures/errors/skips; clean bounded drain |
| Long stress | `0xA3F30001`–`0xA3F30005` | 2,048 | PASS, all 5 XML results have 1 test, 0 failures/errors/skips; clean bounded drain |

Fresh outputs are under `results/raw/gate3_final/random_512/` and `results/raw/gate3_final/random_2048/`. The runs use the saved seed-derived plans, pre-simulation legality checks and the project-owned Python oracle. The plan validator checks decoded target against the frozen address map and all supported burst constraints.

## Random-body observations

Counts below are public-handshake coverage from the five 2,048-operation random bodies; deterministic anchors are excluded.

| Item | Observed result | Classification |
|---|---|---|
| Read/write admissions by manager | Reads M0/M1/M2: 1,709 / 1,715 / 1,683; writes: 1,696 / 1,798 / 1,639 | PASS — random |
| Target routing | S0/S1/S2/S3: 4,155 / 3,021 / 2,034 / 1,030 | PASS — random |
| Burst lengths | LEN 0–15 all hit; counts 610–689 each | PASS — random |
| AW/W styles | AW-before-W 1,692; W-before-AW 1,693; near-cycle 1,748 | PASS — random |
| Target AW/AR/W backpressure | 4,624 / 4,586 / 777 stall episodes | PASS — random |
| Manager B/R backpressure | 3,856 / 3,828 stall observations; 8,595 finite response-delay events | PASS — random |
| Three-manager activity | 24,915 all-manager-active cycles across the five runs | PASS — random |
| Random live depth | Maximum 2 reads and 2 writes; D042 makes no random depth-four claim | PASS — directed depth-four evidence below |
| Same-target overlap, cross-manager same-ID overlap, different-ID reorder, reset with live random work | Random counters are 0 for each | Covered by directed evidence below; not claimed as random |

## Directed integration and architectural capacity

- Gate-2 whole-DUT/oracle closure demonstrates four live reads and four live writes, fifth-request blocking and following-cycle recovery. Same-ID protection, different-ID response ordering, target/manager backpressure and reset with live work are also checked there. D042 retains this allocation; v2 random traffic reached depth two only.
- Integrated AR RR fairness passed with nine actual manager handshakes: `0 1 2 0 1 2 0 1 2`.
- Integrated AW RR fairness passed with nine actual manager handshakes: `0 1 2 0 1 2 0 1 2`. Each manager admitted three writes using IDs 0, 1 and 2; nine manager W handshakes, nine target WLAST handshakes and nine manager B completions were observed. S0 owner overlap count was zero, and held target AW payload remained stable through the injected stall.
- The complete directed test reports 384 checks: the prior 348 Gate-2 checks plus the integrated fairness checks.

## Address-plan defect history

The original long-plan generator produced 3,800 claimed-target/address mismatches across the five 2,048-operation plans. In particular, sequence 960 claimed S0 for address `0x00010040`, which the frozen decoder maps to S3. The seed-independent region-aware allocator and independent validator now report zero invalid associations. Original plans and failure traces remain preserved under `results/raw/gate3_random_long/` and the earlier investigation paths; repaired plans/runs are separate.

The first Gate-3 endpoint defect remains classified `HARNESS_ENDPOINT`: an endpoint response beat could be withdrawn without a sampled target R handshake. The minimized reproducer and focused RVALID-retention regression pass with the repaired handshake-driven endpoint. No production RTL was changed for these harness/generator defects.

## Regression commands and results

- `python3 -m unittest discover -s tb/random -p 'test_*.py' -v` — PASS, 15 plan/legality/endpoint/bus/scheduler tests.
- `GATE3_OUT_DIR=results/raw/gate3_final/random_512 scripts/run_gate3_random_v2.sh` — PASS, all five seeds.
- `GATE3_OUT_DIR=results/raw/gate3_final/random_2048 scripts/run_gate3_random_long.sh` — PASS, all five seeds.
- `scripts/run_fabric_a_gate2_directed.sh` — PASS, 384 checks, including both integrated fairness scenarios.
- `scripts/run_gate2_closure.sh` — PASS; 15 oracle model tests, DUT matrix and expected bad-RDATA fault sensitivity.
- `scripts/run_fabric_a_integration_checks.sh` — PASS; lint, whole-top simulation and ECP5 synthesis flow completed. Synthesis is implementation evidence only, not timing closure or PPA comparison.
- Bounded formal rechecks: decoder, request legality, outstanding tracker, write owner/state bank, AW scheduler/path, AR path/state bank, W path/composition, B/R routers, S3 endpoint and RR arbiter/fairness — PASS. RR fairness is bounded to depth 12 and assumes the watched requester remains asserted and READY is continuously high; this is not an unconditional liveness proof.

## Remaining limits

No exhaustive whole-Fabric proof, full AXI4 compliance claim, recorded-target/returned-response source matching, Architecture B, benchmark measurement, P99, Fmax or routed timing result is claimed. The formal results are named bounded properties with their local assumptions, not end-to-end unbounded proofs.
