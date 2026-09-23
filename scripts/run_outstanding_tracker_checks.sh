#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/outstanding_tracker"
BUILD="$OUT/sim_work"
mkdir -p "$OUT"
rm -rf "$BUILD" "$OUT/formal_prove" "$OUT/formal_cover"

verilator --lint-only --timing -Wall \
  "$ROOT/rtl/axi_outstanding_tracker.sv" \
  2>&1 | tee "$OUT/verilator_lint.log"

verilator --binary --timing --top-module outstanding_tracker_tb --Mdir "$BUILD" \
  -o outstanding_tracker_tb \
  "$ROOT/rtl/axi_outstanding_tracker.sv" \
  "$ROOT/tb/directed/outstanding_tracker_tb.sv" \
  2>&1 | tee "$OUT/verilator_build.log"
"$BUILD/outstanding_tracker_tb" 2>&1 | tee "$OUT/simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_outstanding_tracker.sv; synth_ecp5 -top axi_outstanding_tracker -json $OUT/axi_outstanding_tracker_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" outstanding_tracker.sby prove
  sby -f -d "$OUT/formal_cover" outstanding_tracker.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -s "$OUT/simulation.log"
test -s "$OUT/yosys_synth.log"
test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
