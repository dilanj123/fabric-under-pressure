# Manager/internal ID mapping primitive

**Date:** 2026-09-23

| Check | Command/flow | Exit | Classification | Evidence |
|---|---|---:|---|---|
| Verilator lint | `verilator --lint-only --timing -Wall rtl/axi_id_mapper.sv` | 0 | REPRO / frontend evidence | `results/raw/id_mapping/verilator_lint.log` |
| Directed simulation | Verilator binary for `id_mapper_tb` | 0 | RTL SIMULATION VERIFIED | `results/raw/id_mapping/simulation.log` |
| Full synthesis | `yosys -Q -p "read_verilog -sv rtl/axi_id_mapper.sv; synth_ecp5 -top axi_id_mapper -json results/raw/id_mapping/axi_id_mapper_ecp5.json; stat"` | 0 | SYNTHESISED | `results/raw/id_mapping/yosys_synth.log` |
| Formal prove | `sby -f -d results/raw/id_mapping/formal_prove id_mapper.sby prove` | 0 | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS | `results/raw/id_mapping/formal_prove/logfile.txt` |
| Formal cover | `sby -f -d results/raw/id_mapping/formal_cover id_mapper.sby cover` | 0 | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS | `results/raw/id_mapping/formal_cover/logfile.txt` |

The combinational primitive implements `internal_id = {manager_index, manager_id}` and extracts `return_manager_index = return_internal_id[5:4]`, `return_manager_id = return_internal_id[3:0]`. `return_manager_valid` is asserted exactly when the returned manager prefix is not `2'b11`. Forward `manager_index == 2'b11` is illegal stimulus and is not remapped.

The directed test reports `PASS id_mapper_tb tests=472`: 48 valid forward/round-trip cases, 16 reserved return cases, 48 pairwise same-ID cross-manager comparisons, and 360 pairwise within-manager comparisons.

Formal proof uses unconstrained manager index, manager ID and return internal ID with no environmental assumptions. It proves forward exactness, valid-manager round-trip identity, pairwise uniqueness of manager prefixes, reserved-prefix invalidity, and low-ID preservation. Covers reach M0, M1 and M2 mappings, IDs 0 and 15, reserved return code, and the same visible ID under multiple manager prefixes at depth 1 using Yices through SBY.

The target-aware Yosys run reports 1 LUT4 and `Found and reported 0 problems`. The known Yosys experimental `write_xaiger2` warning and ABC combinational-network warning were reviewed. The resource result is primitive-only and is not Fabric PPA.

The first formal run exposed an SBY source-path error and then a harness error that compared an independent return input with the forward mapping. Both were corrected before the passing rerun; the final raw logs contain the passing rerun.
