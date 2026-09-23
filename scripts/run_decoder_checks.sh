#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/decoder"
BUILD="$OUT/sim_work"
mkdir -p "$OUT"
rm -rf "$BUILD" "$OUT/formal_prove" "$OUT/formal_cover"

verilator --lint-only --timing -Wall \
  "$ROOT/rtl/fabric_addr_map_pkg.sv" "$ROOT/rtl/axi_address_decoder.sv" \
  2>&1 | tee "$OUT/verilator_lint.log"

verilator --binary --timing --top-module address_decoder_tb --Mdir "$BUILD" \
  -o address_decoder_tb \
  "$ROOT/rtl/fabric_addr_map_pkg.sv" "$ROOT/rtl/axi_address_decoder.sv" \
  "$ROOT/tb/directed/address_decoder_tb.sv" \
  2>&1 | tee "$OUT/verilator_build.log"
"$BUILD/address_decoder_tb" 2>&1 | tee "$OUT/simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/fabric_addr_map_pkg.sv $ROOT/rtl/axi_address_decoder.sv; hierarchy -top axi_address_decoder; proc; check; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" address_decoder.sby prove
  sby -f -d "$OUT/formal_cover" address_decoder.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -s "$OUT/simulation.log"
test -s "$OUT/yosys_synth.log"
test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
