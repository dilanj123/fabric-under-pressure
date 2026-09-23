#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/id_mapping"
BUILD="$OUT/sim_work"
mkdir -p "$OUT"
rm -rf "$BUILD" "$OUT/formal_prove" "$OUT/formal_cover"

verilator --lint-only --timing -Wall \
  "$ROOT/rtl/axi_id_mapper.sv" \
  2>&1 | tee "$OUT/verilator_lint.log"

verilator --binary --timing --top-module id_mapper_tb --Mdir "$BUILD" \
  -o id_mapper_tb \
  "$ROOT/rtl/axi_id_mapper.sv" \
  "$ROOT/tb/directed/id_mapper_tb.sv" \
  2>&1 | tee "$OUT/verilator_build.log"
"$BUILD/id_mapper_tb" 2>&1 | tee "$OUT/simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_id_mapper.sv; synth_ecp5 -top axi_id_mapper -json $OUT/axi_id_mapper_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" id_mapper.sby prove
  sby -f -d "$OUT/formal_cover" id_mapper.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -s "$OUT/simulation.log"
test -s "$OUT/yosys_synth.log"
test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
