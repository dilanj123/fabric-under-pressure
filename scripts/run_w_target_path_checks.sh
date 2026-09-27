#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/w_target_path"
BUILD="$OUT/sim_work"
mkdir -p "$OUT" "$BUILD"

if [[ -f /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment ]]; then
  # shellcheck disable=SC1091
  source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
fi

verilator --lint-only --timing -Wall --top-module axi_w_target_path \
  "$ROOT/rtl/axi_w_target_path.sv" 2>&1 | tee "$OUT/verilator_w_path_lint.log"

verilator --binary --timing --top-module axi_w_target_path_tb \
  --Mdir "$BUILD/standalone" -o axi_w_target_path_tb \
  "$ROOT/rtl/axi_w_target_path.sv" \
  "$ROOT/tb/directed/axi_w_target_path_tb.sv" 2>&1 | tee "$OUT/verilator_standalone_build.log"
"$BUILD/standalone/axi_w_target_path_tb" 2>&1 | tee "$OUT/standalone_simulation.log"

verilator --binary --timing --top-module axi_w_target_route_tb \
  --Mdir "$BUILD/routes" -o axi_w_target_route_tb \
  "$ROOT/rtl/axi_w_target_path.sv" \
  "$ROOT/tb/directed/axi_w_target_route_tb.sv" 2>&1 | tee "$OUT/verilator_route_build.log"
"$BUILD/routes/axi_w_target_route_tb" 2>&1 | tee "$OUT/route_simulation.log"

verilator --binary --timing --top-module axi_aw_w_state_composition_tb \
  --Mdir "$BUILD/composition" -o axi_aw_w_state_composition_tb \
  "$ROOT/rtl/axi_outstanding_tracker.sv" \
  "$ROOT/rtl/axi_write_owner.sv" \
  "$ROOT/rtl/axi_write_state_bank.sv" \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" \
  "$ROOT/rtl/axi_aw_target_scheduler_a.sv" \
  "$ROOT/rtl/axi_aw_target_path_a.sv" \
  "$ROOT/rtl/axi_w_target_path.sv" \
  "$ROOT/tb/directed/axi_aw_w_state_composition_tb.sv" \
  2>&1 | tee "$OUT/verilator_composition_build.log"
"$BUILD/composition/axi_aw_w_state_composition_tb" 2>&1 | tee "$OUT/composition_simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_w_target_path.sv; synth_ecp5 -top axi_w_target_path -json $OUT/axi_w_target_path_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" axi_w_target_path.sby prove
  sby -f -d "$OUT/formal_cover" axi_w_target_path.sby cover
) 2>&1 | tee "$OUT/formal.log"

mkdir -p "$ROOT/results/raw/aw_w_composition"
(
  cd "$ROOT/formal"
  sby -f -d "$ROOT/results/raw/aw_w_composition/formal_prove" axi_aw_w_state_composition.sby prove
  sby -f -d "$ROOT/results/raw/aw_w_composition/formal_cover" axi_aw_w_state_composition.sby cover
) 2>&1 | tee "$ROOT/results/raw/aw_w_composition/formal.log"

test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
test -f "$ROOT/results/raw/aw_w_composition/formal_prove/PASS"
test -f "$ROOT/results/raw/aw_w_composition/formal_cover/PASS"
