#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/aw_target_scheduler"
BUILD="$OUT/sim_work"
mkdir -p "$OUT"
rm -rf "$BUILD" "$OUT/formal_prove" "$OUT/formal_cover" \
  "$OUT/formal_composition_prove" "$OUT/formal_composition_cover"

verilator --lint-only --timing -Wall \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" \
  "$ROOT/rtl/axi_aw_target_scheduler_a.sv" \
  2>&1 | tee "$OUT/verilator_lint.log"

verilator --binary --timing --top-module axi_aw_target_scheduler_tb --Mdir "$BUILD" \
  -o axi_aw_target_scheduler_tb \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" \
  "$ROOT/rtl/axi_aw_target_scheduler_a.sv" \
  "$ROOT/tb/directed/axi_aw_target_scheduler_tb.sv" \
  2>&1 | tee "$OUT/verilator_build.log"
"$BUILD/axi_aw_target_scheduler_tb" 2>&1 | tee "$OUT/simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_rr_arbiter_3.sv $ROOT/rtl/axi_aw_target_scheduler_a.sv; synth_ecp5 -top axi_aw_target_scheduler_a -json $OUT/axi_aw_target_scheduler_a_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" aw_target_scheduler.sby prove
  sby -f -d "$OUT/formal_cover" aw_target_scheduler.sby cover
  sby -f -d "$OUT/formal_composition_prove" aw_target_scheduler_composition.sby prove
  sby -f -d "$OUT/formal_composition_cover" aw_target_scheduler_composition.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -s "$OUT/simulation.log"
test -s "$OUT/yosys_synth.log"
test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
test -f "$OUT/formal_composition_prove/PASS"
test -f "$OUT/formal_composition_cover/PASS"
