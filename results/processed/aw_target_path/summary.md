# Architecture-A one-target AW path evidence

Date: 2026-09-26

## Scope

`rtl/axi_aw_target_path_a.sv` composes the verified target-specific AW scheduler with one registered target-facing AW holding slot. It covers one logical target selected by `TARGET_INDEX`; it does not connect outstanding tracking, write-owner allocation, W routing, response routing, AR/R, or S3 completion.

The address contract is D032: a manager-facing AW handshake is `t_addr_accept` and captures directly into the one-entry registered target slot. Slot availability is derived from registered pre-state, so a slot drained on cycle N cannot be refilled until the following cycle. There is no manager-side ingress queue.

## Commands and results

All commands were run after:

```sh
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
```

The reproducible driver was:

```sh
scripts/run_aw_target_path_checks.sh
```

Exit status: 0. The driver ran Verilator lint, Verilator timed build/simulation, target-aware Yosys synthesis, SBY prove, and SBY cover.

Direct focused simulation result: `PASS axi_aw_target_path_tb checks=23`.

Formal prove:

- Engine: `smtbmc`
- Solver: Yices
- Mode: bounded BMC
- Depth: 20
- Assumptions: initial reset low; AXI source stability is assumed only after `AWVALID && !AWREADY`.
- Result: PASS
- Evidence: `results/raw/aw_target_path/formal_prove/logfile.txt`

Formal cover:

- Engine: `smtbmc`
- Solver: Yices
- Mode: bounded cover
- Depth: 24
- Result: PASS
- Evidence: `results/raw/aw_target_path/formal_cover/logfile.txt`

## Directed coverage

The 23 checks cover individual manager admission with distinct values in every AW field, S3 admission, target stall and payload stability, D032 no drain/refill, held RR selection, reset while a slot is valid, target-owner blocking, request-legality blocking, outstanding blocking, and target-match blocking.

## Synthesis

Exact command used by the driver:

```sh
yosys -Q -p "read_verilog -sv rtl/axi_rr_arbiter_3.sv rtl/axi_aw_target_scheduler_a.sv rtl/axi_aw_target_path_a.sv; synth_ecp5 -top axi_aw_target_path_a -json results/raw/aw_target_path/axi_aw_target_path_a_ecp5.json; stat"
```

Exit status: 0. Yosys reported `Found and reported 0 problems`.

Primitive/path statistics:

- LUT4: 210
- TRELLIS_FF: 74
- PFUMX: 29
- L6MUX21: 11
- CCU2C: none reported
- EBR/DSP: none reported

The warning is one experimental-feature warning for `write_xaiger2`; it did not prevent synthesis. These are target-path synthesis figures, not Fabric PPA.

## Evidence classification

- One-target Architecture-A AW eligibility/RR and registered VALID/READY/payload boundary: `RTL SIMULATION VERIFIED`.
- AWREADY/fire one-hot, target-owner exclusion, D031 suppression, admission safety, payload capture, stalled payload stability, and D032 no-overwrite properties: `FORMALLY CHECKED UNDER DOCUMENTED BOUNDED ASSUMPTIONS`.
- One-target Architecture-A AW path completes ECP5-targeted Yosys synthesis: `SYNTHESISED`.

## Limitations

Production outstanding allocation and write-owner allocation are not connected. AWREADY/VALID are verified only for this one target boundary. W routing, B response, AR/R, S3 completion, four-target integration, full Architecture-A behavior, Architecture B, performance, timing, and Fabric PPA remain unproven.
