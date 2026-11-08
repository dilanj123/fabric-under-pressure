# Gate-2 R-channel handshake correlation repair

## Result

The Gate-2 cocotb R response helper could replay an accepted beat. In the historical M0/S1, ID 11, LEN=3 diagnostic, the intended response had four beats, but the recorded public interfaces accepted six beats each. Beats 1 and 2 were each accepted twice; the helper advanced its reference-model loop four times because it advanced by intended beat rather than by sampled transfer. This was a testbench stimulus/oracle-correlation defect. No production RTL defect was reproduced.

The replacement R driver presents data before the active edge and holds the complete R payload until sampled target `RVALID && RREADY`. Each edge snapshot independently counts target and manager transfers. The oracle receives each manager beat only after that sampled handshake, while target-source observation is recorded independently. The focused LEN=3 case uses distinct data per beat and checks exact order, RID, RRESP, RLAST, four target accepts, four manager accepts, four oracle updates, model retirement, and two post-completion cycles without an extra transfer.

| Case | Target R accepts | Manager R accepts | Oracle R updates | Result |
|---|---:|---:|---:|---|
| M0/S1/ID11 LEN=3, unstalled | 4 | 4 | 4 | PASS |
| M0/S1/ID11 LEN=3, manager backpressure | 4 | 4 | 4 | PASS |
| Historical pre-repair diagnostic | 6 | 6 | 4 | FAIL detected |

The saved trace compares a falling-edge settled sample immediately before the active edge with the `RisingEdge` callback sample. All sampled pre-edge and active-edge values match. `ReadOnly` values can reflect the post-edge registered update (for example, target RREADY rises after the edge at 100 ns), so the monitor uses the pre-edge snapshot as the handshake sample and treats ReadOnly as diagnostic only. This phase check was performed with the project's qualified Verilator 5.053 and Cocotb 2.1 environment; it is not a cross-simulator scheduling claim.

## Adjacent AR observation

The read-capacity test had also inspected ARREADY after the edge on which the fifth pending AR was admitted. The RTL had correctly accepted the request; the post-edge READY value then reflected the updated full outstanding state. The revised test samples manager AR `VALID && READY` at the active boundary, records the admission once, observes the later target AR transfer, and checks the D028 next-cycle reuse rule. This was a testbench observation correction, not a DUT change.

Targeted source review of AW/W/B helpers found no comparable reproducible duplicate or missed transfer in the exercised cases. Those helpers remain coroutine-based; this repair does not claim a general central-cycle monitor for every legacy helper.

## Fault sensitivity

The bus-level fault modes below were caught by the focused driver’s accepted-payload/sequence checks before any invalid manager beat was committed to the model. The wrong-RID case is blocked by the DUT and reported as a driver boundary check; it does not demonstrate model rejection at a manager handshake. Separately, the reference-model unit tests inject the corresponding invalid observed events directly and verify that the model raises `OracleViolation`.

| Injection | Bus-boundary result |
|---|---|
| Duplicate beat | duplicate accepted R beat |
| Missing beat | missing accepted R beat |
| Bad RDATA | bad RDATA |
| Early RLAST | early RLAST |
| Missing final RLAST | missing final RLAST |
| Wrong RID | DUT target RREADY remains low; driver reports wrong RID blocked before an accepted manager transfer |

The 21 reference-model unit tests include direct duplicate, missing, bad-data, early/missing-RLAST and wrong-ID checks. The existing deliberate DUT-facing bad-RDATA closure mode also continues to fail only the designated testcase for the expected mismatch. These are expected-failure sensitivity checks; they are not counted as passing functional transactions.

## Requalification

The final source was exercised with clean output directories:

| Qualification | Result |
|---|---|
| Focused LEN=3 R driver, both cases | PASS; 4/4/4 counts per case |
| Gate-2 Architecture-A oracle closure | PASS; 3 cocotb cases, no failures/errors/skips; reference-model suite 21 tests; directed whole-DUT suite 384 checks; bad-RDATA sensitivity PASS |
| Gate-2 Architecture-B oracle matrix | PASS; 3 cocotb cases, no failures/errors/skips |
| Focused DUT RVALID-retention test | PASS; 1 testcase |
| R fault injections | PASS; all six rejected for intended assertions |
| A functional random plans | PASS; five seeds at 512 and five at 2,048 operations |
| B functional random plans | PASS; five seeds at 512 and five at 2,048 operations |
| Architecture-B whole-DUT directed suite | PASS; 444 checks |
| Reference-model Python tests | PASS; 21 tests |

The final raw results are under `results/raw/oracle_repair/final_gate2_A/`, `final_gate2_B/`, `focused_R_current_A/`, `final_r_faults/`, `r_retention_A/`, `fabric_b_directed/`, and the four `final_{A,B}_{512,2048}/` directories. The earlier failed attempts remain in the same raw tree; selected logs, XML, traces and per-seed coverage records are included in the evidence commit. Build products and verbose tool output remain local and are not committed.

An independent patch review found no handshake-counting defect in the new focused driver. It confirmed 25/25 pre-edge/immediate-edge snapshot matches and 18 samples where `ReadOnly` showed post-edge changes. The review requested the fault-sensitivity distinction above. The focused beat vector is seeded from the project oracle’s initialized memory, so this case establishes exact handshake correlation, ordered data delivery and RLAST behavior; independent memory prediction remains covered by the broader mapped-read closure, whose endpoint memory is separate from the reference model.

No RTL, formal source, workload, benchmark engine/endpoint, D045/D047, or processed A/B measurement result changed. Canonical A/B benchmark remeasurement is not required because the repaired module is the separate Gate-2 oracle test and the random regressions were rerun to requalify the affected shared helper.

## Limitations

The monitor/driver repair establishes handshake agreement for the focused R path and requalified Gate-2/A/B functional suites on the qualified simulator. It does not rewrite all legacy helper tasks into one monitor architecture and does not resolve the separately documented response-target metadata-matching limitation. The historical pre-repair PASS records are retained and superseded for this scenario by the exact handshake-count evidence above.
