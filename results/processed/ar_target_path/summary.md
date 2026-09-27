# Architecture-A AR target path and shared read-state evidence

## Scope

This evidence covers one parameterized Architecture-A AR target path and a shared three-manager read outstanding-state bank. It does not cover R routing, RLAST completion integration, S3 DECERR generation, four-target production composition, or a complete Fabric.

## Contract

D036 freezes manager-facing AR handshake as read transaction admission, shared read state per manager, target-side AR consumption as slot transport only, same-cycle successor suppression, and D032 one-entry pre-state address-slot behavior. The path uses the frozen 32-bit address, full AR attribute bundle, and exact `{manager_index, manager_arid}` six-bit internal ID mapping.

## Commands and results

The reproducible command was:

```text
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
scripts/run_ar_target_path_checks.sh
```

The script completed with exit status 0. It ran Verilator lint/build/simulation, Yosys ECP5-targeted synthesis for `axi_ar_target_path_a` and `axi_read_state_bank`, and SBY `smtbmc` with Yices for prove and cover.

Directed simulations:

- `axi_ar_target_path_tb`: PASS, 42 self-checking checks covering all three managers, full payload selection, blockers, stalled slot stability, D032 no drain/refill and reset.
- `axi_ar_s3_tb`: PASS, 1 check covering legal S3 target transport and widened ID.
- `axi_read_state_bank_tb`: PASS, 14 self-checking checks covering reset, allocation, four-entry capacity, same-ID exclusion, completion pre-state, manager independence and invalid admission gating.
- `axi_ar_read_state_composition_tb`: PASS, 7 self-checking checks covering AR admission into shared state, target consumption without a second allocation, target payload, same-ID completion timing and following-cycle reuse.
- `axi_read_write_id_independence_tb`: PASS, 2 self-checking checks demonstrating that the same numeric ID may be busy in the write domain while being admitted independently in the read domain.

Formal:

- AR path prove: PASS, SBY `smtbmc`, Yices, bounded BMC depth 20.
- AR path cover: PASS, bounded cover depth 24.
- Read-state bank prove: PASS, SBY `smtbmc`, Yices, bounded BMC depth 8; count bound, count/popcount, admission gating and invalid completion assumptions were checked.
- Read-state bank cover: PASS, bounded cover depth 24.
- AR/read-state composition prove: PASS, SBY `smtbmc`, Yices, bounded BMC depth 12 with per-manager source-stability and busy-completion assumptions. It proves manager AR fire is committed into the corresponding shared read lane and target AR fire alone does not commit state.
- AR/read-state composition cover: PASS, bounded cover depth 20; admission, target consumption and populated count-one states are reachable.

The formal harness uses reset initialization and keeps completion events tied to currently busy IDs where needed for the bank environment. It does not assume target readiness for the AR path. The AR path proof is bounded; no unbounded Fabric claim is made.

Synthesis:

- `yosys -Q -p "read_verilog -sv rtl/axi_rr_arbiter_3.sv rtl/axi_ar_target_scheduler_a.sv rtl/axi_ar_target_path_a.sv; synth_ecp5 -top axi_ar_target_path_a -json results/raw/ar_target_path/axi_ar_target_path_a_ecp5.json; stat"` exited 0. Primitive/path result: 198 LUT4 and 74 TRELLIS_FF.
- `yosys -Q -p "read_verilog -sv rtl/axi_outstanding_tracker.sv rtl/axi_read_state_bank.sv; synth_ecp5 -top axi_read_state_bank -json results/raw/ar_target_path/axi_read_state_bank_ecp5.json; stat"` exited 0. Shared-bank result: 550 LUT4 and 57 TRELLIS_FF.

Yosys reported its qualified experimental-feature warning and memory-to-register lowering warnings for the tracker tables; no synthesis error occurred. These are primitive/composition figures, not Fabric PPA.

## Evidence classification

- One-target Architecture-A AR eligibility/admission/payload transport: RTL SIMULATION VERIFIED.
- Shared per-manager read outstanding allocation, four-entry capacity and same-ID pre-state behavior: RTL SIMULATION VERIFIED.
- AR slot stability, D032 no drain/refill and D036 suppression: FORMALLY CHECKED UNDER DOCUMENTED BOUNDED ASSUMPTIONS.
- Read-state count/bitmap and admission invariants: FORMALLY CHECKED UNDER DOCUMENTED BOUNDED ASSUMPTIONS.
- AR target path and shared read-state bank complete ECP5-targeted Yosys synthesis: SYNTHESISED, primitive/composition scope only.

## Limitations

R response routing, accepted-RLAST completion, four-target read/write composition, S3 DECERR generation, complete Architecture A, Architecture B, timing, performance and PPA remain unproven.
