# B response router backpressure repair evidence

## Scope

This evidence covers the repaired focused four-target, three-manager registered B response router and its existing shared write-state composition. It does not claim four-target production Fabric integration, source-target metadata matching, S3 DECERR generation, or complete AXI write-path correctness.

## Defect and repair

The pre-repair RTL derived `response_admit_fire` from a registered RR grant and a validated response without requiring the actual target-side `target_b_fire`. It also allowed candidate requests to remain visible while a manager B slot was occupied. Under manager B backpressure, a held successor grant could therefore write over the occupied slot.

The repair:

- separates `raw_candidate_request` from `arbiter_request`;
- drives `arbiter_request[m]` to zero while `slot_valid[m]` is set;
- suppresses same-edge successor selection when `response_admit_fire[m]` occurs;
- defines `response_admit_fire[m]` as `|(arb_grant[m] & target_b_fire)`;
- gates `target_bready` by the decoded manager's registered slot availability;
- keeps slot writes restricted to the real target-side admission event.

The mandatory two-response stalled-slot reproducer aborts on the pre-repair `f57b4fd` RTL in a temporary checkout and passes on the repaired RTL.

## Commands and results

Command:

```text
./scripts/run_b_response_router_repair_checks.sh
```

The script sources the qualified OSS CAD Suite environment and records the source commit and tool versions in `results/raw/b_response_router_repair/tool_versions.log`.

| Check | Exit | Evidence | Result |
|---|---:|---|---|
| RR4 Verilator simulation | 0 | `results/raw/b_response_router_repair/rr4_simulation.log` | PASS, 79 checks |
| Repaired B-router Verilator simulation | 0 | `results/raw/b_response_router_repair/router_simulation.log` | PASS, 36 checks |
| B-router/shared-write-state composition | 0 | `results/raw/b_response_router_repair/composition_simulation.log` | PASS, 8 checks |
| B-router formal prove | 0 | `results/raw/b_response_router_repair/formal_router_prove/PASS` | PASS, smtbmc/Yices, bounded depth 20 |
| B-router formal cover | 0 | `results/raw/b_response_router_repair/formal_router_cover/PASS` | PASS, smtbmc/Yices, bounded cover depth 32 |
| RR4 formal prove/cover | 0 | `results/raw/b_response_router_repair/formal_rr4_prove/PASS`, `formal_rr4_cover/PASS` | PASS; unchanged RR4 evidence rerun |
| Repaired B-router ECP5 synthesis | 0 | `results/raw/b_response_router_repair/router_yosys_synth.log` | PASS; 598 LUT4, 61 TRELLIS_FF, 128 PFUMX, 48 L6MUX21 |

## Formal assumptions and properties

Target stability assumptions are per target: if `target_bvalid[t] && !target_bready[t]` was true in the prior cycle, only target `t` is constrained to hold BVALID, BID and BRESP. Other target channels remain independent.

The bounded prove covers invalid prefix/nonbusy rejection, occupied-slot arbitration suppression, no target BREADY for a response decoded to an occupied manager slot, target-handshake-based admission, completion-event separation, slot validity wiring and manager payload mapping. The cover reaches each target BREADY, manager backpressure, a populated manager slot, and S3 transport.

These are bounded formal results under the documented assumptions, not unbounded liveness or whole-Fabric proofs.

## Limitations

The focused bank interface does not expose recorded target metadata, so returned-target versus recorded-target matching is not proven. Four-target production write composition, AR/R, S3 DECERR generation, full Architecture-A behavior, Architecture B, timing and Fabric PPA remain unproven.
