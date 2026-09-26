#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/rr_arbiter"
BUILD="$OUT/sim_work"
mkdir -p "$OUT"
rm -rf "$BUILD" "$OUT/formal_prove" "$OUT/formal_cover" "$OUT/formal_fairness_m0" "$OUT/formal_fairness_m1" "$OUT/formal_fairness_m2"

verilator --lint-only --timing -Wall \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" \
  2>&1 | tee "$OUT/verilator_lint.log"

verilator --binary --timing --top-module rr_arbiter_tb --Mdir "$BUILD" \
  -o rr_arbiter_tb \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" \
  "$ROOT/tb/directed/rr_arbiter_tb.sv" \
  2>&1 | tee "$OUT/verilator_build.log"
"$BUILD/rr_arbiter_tb" 2>&1 | tee "$OUT/simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_rr_arbiter_3.sv; synth_ecp5 -top axi_rr_arbiter_3 -json $OUT/axi_rr_arbiter_3_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" rr_arbiter.sby prove
  sby -f -d "$OUT/formal_cover" rr_arbiter.sby cover
  sby -f -d "$OUT/formal_fairness_m0" rr_arbiter_fairness.sby m0
  sby -f -d "$OUT/formal_fairness_m1" rr_arbiter_fairness.sby m1
  sby -f -d "$OUT/formal_fairness_m2" rr_arbiter_fairness.sby m2
) 2>&1 | tee "$OUT/formal.log"

test -s "$OUT/simulation.log"
test -s "$OUT/yosys_synth.log"
test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
test -f "$OUT/formal_fairness_m0/PASS"
test -f "$OUT/formal_fairness_m1/PASS"
test -f "$OUT/formal_fairness_m2/PASS"
