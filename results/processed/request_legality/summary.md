# AXI request-legality primitive

**Date:** 2026-09-23

| Check | Command/flow | Exit | Classification | Evidence |
|---|---|---:|---|---|
| Verilator lint | `verilator --lint-only --timing -Wall rtl/fabric_addr_map_pkg.sv rtl/axi_request_legal.sv` | 0 | REPRO / frontend evidence | `results/raw/request_legality/verilator_lint.log` |
| Directed simulation | Verilator binary for `request_legality_tb` | 0 | RTL SIMULATION VERIFIED | `results/raw/request_legality/simulation.log` |
| Full synthesis | `yosys -Q -p "read_verilog -sv rtl/fabric_addr_map_pkg.sv rtl/axi_request_legal.sv; synth_ecp5 -top axi_request_legal -json results/raw/request_legality/axi_request_legal_ecp5.json; stat"` | 0 | SYNTHESISED | `results/raw/request_legality/yosys_synth.log` |
| Formal prove | `sby -f -d results/raw/request_legality/formal_prove request_legality.sby prove` | 0 | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS | `results/raw/request_legality/formal_prove/logfile.txt` |
| Formal cover | `sby -f -d results/raw/request_legality/formal_cover request_legality.sby cover` | 0 | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS | `results/raw/request_legality/formal_cover/logfile.txt` |

The directed testbench reports `PASS request_legality_tb tests=36`. It covers legal mapped and unmapped requests, supported boundary lengths, unsupported length/size/burst/lock cases, all alignment offsets, mapped and S3 4-KiB boundaries, and the upper 32-bit address edge.

The legality predicate is combinational and accepts exactly the conjunction of INCR burst, `LEN <= 15`, `SIZE == 3`, normal `LOCK == 0`, 8-byte alignment, and a widened 4-KiB endpoint check. The 33-bit endpoint calculation prevents `LEN == 8'hFF` or 32-bit address wraparound from becoming legal.

Formal proof uses unconstrained `addr`, `len`, `size`, `burst`, and `lock`; no environmental assumptions are used. Yosys `prep` plus `smtbmc` with Yices proves equivalence, all invalid-shape implications, no 4-KiB crossing, no endpoint overflow, and same target selection between the existing decoder at the first and last byte of every legal request. Covers reach legal one-beat, legal 16-beat, exact-page-end, crossing, S0, S1, S2, and S3 cases at depth 1.

The target-aware Yosys run reports 16 LUT4 and 5 PFUMX cells for this primitive. These are primitive synthesis figures only and are not Fabric PPA. Yosys reports its known experimental `write_xaiger2` warning and ABC's expected combinational-network warning; it reports `Found and reported 0 problems`. Verilator warnings are intentionally suppressed only for the unused upper address bits and shared package constants, with source comments explaining both cases.
