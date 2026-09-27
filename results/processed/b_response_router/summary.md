# Focused B response routing evidence

Scope: one registered B response network with four logical targets and three managers. This is focused write-path evidence; it is not complete Fabric or AXI compliance evidence.

## Commands

```text
scripts/run_b_response_router_checks.sh
```

The script ran Verilator lint/build/simulation, ECP5-targeted Yosys synthesis, and SBY prove/cover flows. The exact tool versions and source commit are in `results/raw/b_response_router/tool_versions.log`.

## Simulation

- `axi_rr_arbiter_4_tb`: PASS, 15 self-checking checks. Reset-to-S0, held grant, cyclic rotation, subsets, withdrawal and reset-during-hold are covered.
- `axi_b_response_router_tb`: PASS, 15 self-checking checks. All-four same-manager contention, RR continuation, manager backpressure, invalid prefix, nonbusy ID, different-manager concurrency with the same visible ID, BRESP propagation, S3 transport and reset are covered.
- `axi_b_write_state_composition_tb`: PASS, 8 self-checking checks. Target B admission does not complete the write; manager B handshake clears the outstanding entry; owner release remains separate; same-ID reuse is blocked on the completion cycle and available on the following cycle.

## Formal

- `rr_arbiter_4.sby prove`: PASS, Yices through SBY `smtbmc`, bounded BMC depth 16.
- `rr_arbiter_4.sby cover`: PASS, bounded cover depth 20.
- `axi_b_response_router.sby prove`: PASS, Yices through SBY `smtbmc`, bounded BMC depth 20.
- `axi_b_response_router.sby cover`: PASS, bounded cover depth 24.

The RR4 proof checks one-hot/no-phantom grant, held-grant stability, pointer update and four-source reachability. The B-router proof checks invalid-prefix rejection, nonbusy rejection as reported by the validation logic, target-ready validation, slot gating, completion-event mapping and registered manager-valid wiring. Target-side source stability while stalled is assumed according to AXI. No source-target-versus-recorded-target metadata check is claimed.

## Synthesis

- RR4 command: `yosys -Q -p "read_verilog -sv rtl/axi_rr_arbiter_4.sv; synth_ecp5 -top axi_rr_arbiter_4 -json results/raw/b_response_router/axi_rr_arbiter_4_ecp5.json; stat"`; exit 0; 29 LUT4, 9 TRELLIS_FF, 10 PFUMX, 4 L6MUX21.
- Router command: `yosys -Q -p "read_verilog -sv rtl/axi_rr_arbiter_4.sv rtl/axi_b_response_router.sv; synth_ecp5 -top axi_b_response_router -json results/raw/b_response_router/axi_b_response_router_ecp5.json; stat"`; exit 0; 596 LUT4, 62 TRELLIS_FF, 131 PFUMX, 57 L6MUX21.

Yosys reported one experimental-feature warning in each synthesis log and no synthesis problems. These are primitive/path synthesis figures, not Fabric PPA.

## Classifications

- Per-manager S0-S3 B response arbitration and registered manager-facing transport: `RTL SIMULATION VERIFIED` at focused router scope.
- Widened BID decode/strip, invalid-prefix/nonbusy rejection and manager completion-event mapping: `FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS` at bounded focused-router scope, with directed state-composition simulation.
- Write outstanding clears only on manager-facing B handshake: `RTL SIMULATION VERIFIED` at focused B/write-state scope.
- RR4 and B response router: `SYNTHESISED` by target-aware Yosys ECP5 flow.

## Limits

No claim is made for four-target production write composition, source-target metadata matching, S3 DECERR generation, AR/R integration, complete Architecture-A behavior, Architecture-B behavior, timing, throughput, latency or Fabric PPA.
