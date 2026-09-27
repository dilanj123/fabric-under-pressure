#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/b_response_router_repair"
BUILD="$OUT/sim_work"
mkdir -p "$OUT" "$BUILD"

if [[ -f /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment ]]; then
  # shellcheck disable=SC1091
  source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
fi

{
  echo "commit=$(git -C "$ROOT" rev-parse HEAD)"
  echo "verilator=$(verilator --version)"
  echo "yosys=$(yosys --version)"
  echo "sby=$(sby --version 2>&1 | head -1)"
  echo "solver=$(yices --version 2>&1 | head -1 || true)"
} | tee "$OUT/tool_versions.log"

verilator --lint-only --timing -Wall --top-module axi_rr_arbiter_4 \
  "$ROOT/rtl/axi_rr_arbiter_4.sv" \
  2>&1 | tee "$OUT/rr4_verilator_lint.log"

verilator --lint-only --timing -Wall --top-module axi_b_response_router \
  "$ROOT/rtl/axi_rr_arbiter_4.sv" \
  "$ROOT/rtl/axi_b_response_router.sv" \
  2>&1 | tee "$OUT/router_verilator_lint.log"

verilator --binary --timing --top-module axi_rr_arbiter_4_tb --Mdir "$BUILD/rr4" \
  -o axi_rr_arbiter_4_tb \
  "$ROOT/rtl/axi_rr_arbiter_4.sv" \
  "$ROOT/tb/directed/axi_rr_arbiter_4_tb.sv" \
  2>&1 | tee "$OUT/rr4_verilator_build.log"
"$BUILD/rr4/axi_rr_arbiter_4_tb" 2>&1 | tee "$OUT/rr4_simulation.log"

verilator --binary --timing --top-module axi_b_response_router_tb --Mdir "$BUILD/router" \
  -o axi_b_response_router_tb \
  "$ROOT/rtl/axi_rr_arbiter_4.sv" \
  "$ROOT/rtl/axi_b_response_router.sv" \
  "$ROOT/tb/directed/axi_b_response_router_tb.sv" \
  2>&1 | tee "$OUT/router_verilator_build.log"
"$BUILD/router/axi_b_response_router_tb" 2>&1 | tee "$OUT/router_simulation.log"

verilator --binary --timing --top-module axi_b_write_state_composition_tb --Mdir "$BUILD/composition" \
  -o axi_b_write_state_composition_tb \
  "$ROOT/rtl/axi_outstanding_tracker.sv" \
  "$ROOT/rtl/axi_write_owner.sv" \
  "$ROOT/rtl/axi_write_state_bank.sv" \
  "$ROOT/rtl/axi_rr_arbiter_4.sv" \
  "$ROOT/rtl/axi_b_response_router.sv" \
  "$ROOT/tb/directed/axi_b_write_state_composition_tb.sv" \
  2>&1 | tee "$OUT/composition_verilator_build.log"
"$BUILD/composition/axi_b_write_state_composition_tb" 2>&1 | tee "$OUT/composition_simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_rr_arbiter_4.sv; synth_ecp5 -top axi_rr_arbiter_4 -json $OUT/axi_rr_arbiter_4_ecp5.json; stat" \
  2>&1 | tee "$OUT/rr4_yosys_synth.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_rr_arbiter_4.sv $ROOT/rtl/axi_b_response_router.sv; synth_ecp5 -top axi_b_response_router -json $OUT/axi_b_response_router_ecp5.json; stat" \
  2>&1 | tee "$OUT/router_yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_rr4_prove" rr_arbiter_4.sby prove
  sby -f -d "$OUT/formal_rr4_cover" rr_arbiter_4.sby cover
  sby -f -d "$OUT/formal_router_prove" axi_b_response_router.sby prove
  sby -f -d "$OUT/formal_router_cover" axi_b_response_router.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -f "$OUT/formal_rr4_prove/PASS"
test -f "$OUT/formal_rr4_cover/PASS"
test -f "$OUT/formal_router_prove/PASS"
test -f "$OUT/formal_router_cover/PASS"
