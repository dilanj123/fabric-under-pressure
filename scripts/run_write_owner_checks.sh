#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/write_owner"
BUILD="$OUT/sim_work"
mkdir -p "$OUT"
rm -rf "$BUILD" "$OUT/formal_prove" "$OUT/formal_cover"
mkdir -p "$BUILD/main" "$BUILD/three"

verilator --lint-only --timing -Wall \
  "$ROOT/rtl/axi_write_owner.sv" \
  2>&1 | tee "$OUT/verilator_lint.log"

verilator --binary --timing --top-module axi_write_owner_tb --Mdir "$BUILD/main" \
  -o axi_write_owner_tb \
  "$ROOT/rtl/axi_write_owner.sv" \
  "$ROOT/tb/directed/axi_write_owner_tb.sv" \
  2>&1 | tee "$OUT/verilator_build.log"
"$BUILD/main/axi_write_owner_tb" 2>&1 | tee "$OUT/simulation.log"

verilator --binary --timing --top-module axi_write_owner_3_tb --Mdir "$BUILD/three" \
  -o axi_write_owner_3_tb \
  "$ROOT/rtl/axi_write_owner.sv" \
  "$ROOT/tb/directed/axi_write_owner_3_tb.sv" \
  2>&1 | tee "$OUT/verilator_three_build.log"
"$BUILD/three/axi_write_owner_3_tb" 2>&1 | tee "$OUT/composition_simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_write_owner.sv; synth_ecp5 -top axi_write_owner -json $OUT/axi_write_owner_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" axi_write_owner.sby prove
  sby -f -d "$OUT/formal_cover" axi_write_owner.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -s "$OUT/simulation.log"
test -s "$OUT/composition_simulation.log"
test -s "$OUT/yosys_synth.log"
test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
