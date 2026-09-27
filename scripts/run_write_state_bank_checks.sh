#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/write_state_bank"
BUILD="$OUT/sim_work"
mkdir -p "$OUT"

if [[ -f /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment ]]; then
  # shellcheck disable=SC1091
  source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
fi

verilator --lint-only --timing -Wall --top-module axi_write_state_bank \
  "$ROOT/rtl/axi_outstanding_tracker.sv" \
  "$ROOT/rtl/axi_write_owner.sv" \
  "$ROOT/rtl/axi_write_state_bank.sv" \
  2>&1 | tee "$OUT/verilator_bank_lint.log"

verilator --lint-only --timing -Wall --top-module axi_aw_target_path_a \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" \
  "$ROOT/rtl/axi_aw_target_scheduler_a.sv" \
  "$ROOT/rtl/axi_aw_target_path_a.sv" \
  2>&1 | tee "$OUT/verilator_path_lint.log"

verilator --binary --timing --top-module axi_write_state_bank_tb --Mdir "$BUILD/bank" \
  -o axi_write_state_bank_tb \
  "$ROOT/rtl/axi_outstanding_tracker.sv" \
  "$ROOT/rtl/axi_write_owner.sv" \
  "$ROOT/rtl/axi_write_state_bank.sv" \
  "$ROOT/tb/directed/axi_write_state_bank_tb.sv" \
  2>&1 | tee "$OUT/verilator_bank_build.log"
"$BUILD/bank/axi_write_state_bank_tb" 2>&1 | tee "$OUT/bank_simulation.log"

verilator --binary --timing --top-module axi_aw_write_state_composition_tb --Mdir "$BUILD/composition" \
  -o axi_aw_write_state_composition_tb \
  "$ROOT/rtl/axi_outstanding_tracker.sv" \
  "$ROOT/rtl/axi_write_owner.sv" \
  "$ROOT/rtl/axi_write_state_bank.sv" \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" \
  "$ROOT/rtl/axi_aw_target_scheduler_a.sv" \
  "$ROOT/rtl/axi_aw_target_path_a.sv" \
  "$ROOT/tb/directed/axi_aw_write_state_composition_tb.sv" \
  2>&1 | tee "$OUT/verilator_composition_build.log"
"$BUILD/composition/axi_aw_write_state_composition_tb" 2>&1 | tee "$OUT/composition_simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_outstanding_tracker.sv $ROOT/rtl/axi_write_owner.sv $ROOT/rtl/axi_write_state_bank.sv; synth_ecp5 -top axi_write_state_bank -json $OUT/axi_write_state_bank_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_bank_prove" axi_write_state_bank.sby prove
  sby -f -d "$OUT/formal_bank_cover" axi_write_state_bank.sby cover
  sby -f -d "$OUT/formal_comp_prove" axi_aw_write_state_composition.sby prove
  sby -f -d "$OUT/formal_comp_cover" axi_aw_write_state_composition.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -f "$OUT/formal_bank_prove/PASS"
test -f "$OUT/formal_bank_cover/PASS"
test -f "$OUT/formal_comp_prove/PASS"
test -f "$OUT/formal_comp_cover/PASS"
