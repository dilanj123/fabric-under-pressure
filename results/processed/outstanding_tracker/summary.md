# Per-manager/per-direction outstanding tracker

**Date:** 2026-09-23

## Scope and contract

`rtl/axi_outstanding_tracker.sv` is one reusable stateful instance for one manager and one read/write direction. It tracks a 16-bit busy bitmap, a 3-bit count limited to four, and per-ID 4-bit target plus 8-bit length metadata. It has no AXI channel ports, arbitration, response routing, manager index, or transaction admission logic.

Stateful MVP RTL uses `always_ff @(posedge ACLK or negedge ARESETn)`: reset asserts asynchronously, deassertion is coordinated synchronously by the environment, and reset clears all bitmap, count and metadata state.

Allocation and completion eligibility use registered pre-state. A completion cannot recycle its ID or count capacity into a same-cycle allocation. A different-ID completion/allocation is accepted in the same cycle only when the pre-state count is below four and the allocation ID is already free. Invalid events raise violations and do not mutate state.

## Results

| Check | Command/flow | Exit | Classification | Evidence |
|---|---|---:|---|---|
| Verilator lint/build | `bash scripts/run_outstanding_tracker_checks.sh` | 0 | REPRO / frontend evidence | `results/raw/outstanding_tracker/verilator_lint.log`, `verilator_build.log` |
| Directed simulation | Clocked Verilator binary for `outstanding_tracker_tb` | 0 | RTL SIMULATION VERIFIED | `results/raw/outstanding_tracker/simulation.log` |
| Formal prove | `sby -f -d results/raw/outstanding_tracker/formal_prove outstanding_tracker.sby prove` | 0 | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS (bounded) | `results/raw/outstanding_tracker/formal_prove/logfile.txt` |
| Formal cover | `sby -f -d results/raw/outstanding_tracker/formal_cover outstanding_tracker.sby cover` | 0 | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS (bounded) | `results/raw/outstanding_tracker/formal_cover/logfile.txt` |
| Full synthesis | `yosys -Q -p "read_verilog -sv rtl/axi_outstanding_tracker.sv; synth_ecp5 -top axi_outstanding_tracker -json results/raw/outstanding_tracker/axi_outstanding_tracker_ecp5.json; stat"` | 0 | SYNTHESISED | `results/raw/outstanding_tracker/yosys_synth.log` |

The directed test reports `PASS outstanding_tracker_tb checks=19`. It covers reset, one and four allocations, fifth and duplicate allocation violations, known and unknown completion, metadata lookup/clear, same-ID completion/reallocation blocking, full-count completion/allocation blocking, following-cycle capacity reuse, reset with active state, count/bitmap consistency, and independent read/write trackers using the same numeric ID.

Formal uses Yices through SBY with unconstrained event and metadata inputs, initialized by an assumed initial reset assertion. No allocation/completion legality assumptions are used; the DUT guards invalid events. The prove task is bounded BMC to depth 6. The cover task runs to depth 8 so the reset-after-full sequence can be reached. This is bounded evidence and is not an unbounded sequential proof.

Formal checks cover count/bitmap consistency, count <= 4, exact pre-state allocation/completion outputs, invalid-event non-corruption, metadata lookup and stability through the reference transition model, reset clearing, and both same-cycle policies. Covers reach counts 0, 1, 2, 3 and 4, duplicate allocation, unknown completion, valid different-ID simultaneous completion/allocation, same-ID blocking, full-count blocking, and reset after a full state.

Target-aware synthesis reports 489 LUT4, 211 TRELLIS_FF, 39 PFUMX, 6 CCU2C and 7 L6MUX21. Yosys reports expected memory-to-register lowering, conflicting constant-driver diagnostics from the reset-seeded formal reference only in formal preprocessing, the known experimental `write_xaiger2` warning and ABC's combinational-network warning; the synthesis run reports `Found and reported 0 problems`. These are primitive-only figures and are not Fabric PPA.
