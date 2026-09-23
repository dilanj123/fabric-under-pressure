#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/request_legality"
BUILD="$OUT/sim_work"
mkdir -p "$OUT"
rm -rf "$BUILD" "$OUT/formal_prove" "$OUT/formal_cover"

verilator --lint-only --timing -Wall \
  "$ROOT/rtl/fabric_addr_map_pkg.sv" "$ROOT/rtl/axi_request_legal.sv" \
  2>&1 | tee "$OUT/verilator_lint.log"

verilator --binary --timing --top-module request_legality_tb --Mdir "$BUILD" \
  -o request_legality_tb \
  "$ROOT/rtl/fabric_addr_map_pkg.sv" "$ROOT/rtl/axi_request_legal.sv" \
  "$ROOT/tb/directed/request_legality_tb.sv" \
  2>&1 | tee "$OUT/verilator_build.log"
"$BUILD/request_legality_tb" 2>&1 | tee "$OUT/simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/fabric_addr_map_pkg.sv $ROOT/rtl/axi_request_legal.sv; synth_ecp5 -top axi_request_legal -json $OUT/axi_request_legal_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" request_legality.sby prove
  sby -f -d "$OUT/formal_cover" request_legality.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -s "$OUT/simulation.log"
test -s "$OUT/yosys_synth.log"
test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
