#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/ar_target_path"
BUILD="$OUT/sim_work"
python3 - "$OUT/formal_ar_prove" "$OUT/formal_ar_cover" "$OUT/formal_bank_prove" "$OUT/formal_bank_cover" "$OUT/formal_comp_prove" "$OUT/formal_comp_cover" "$BUILD" <<'PY'
import shutil,sys
for p in sys.argv[1:]: shutil.rmtree(p, ignore_errors=True)
PY
mkdir -p "$OUT" "$BUILD/path" "$BUILD/s3" "$BUILD/bank" "$BUILD/comp" "$BUILD/ind"
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
{
  verilator --version
  yosys --version
  sby --version
  yices-smt2 --version
} 2>&1 | tee "$OUT/tool_versions.log"
verilator --lint-only --timing -Wall --top-module axi_ar_target_path_a \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" "$ROOT/rtl/axi_ar_target_scheduler_a.sv" \
  "$ROOT/rtl/axi_ar_target_path_a.sv" "$ROOT/rtl/axi_outstanding_tracker.sv" \
  "$ROOT/rtl/axi_read_state_bank.sv" 2>&1 | tee "$OUT/verilator_lint.log"
verilator --binary --timing --top-module axi_ar_target_path_tb --Mdir "$BUILD/path" -o axi_ar_target_path_tb \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" "$ROOT/rtl/axi_ar_target_scheduler_a.sv" "$ROOT/rtl/axi_ar_target_path_a.sv" \
  "$ROOT/tb/directed/axi_ar_target_path_tb.sv" 2>&1 | tee "$OUT/path_build.log"
"$BUILD/path/axi_ar_target_path_tb" 2>&1 | tee "$OUT/path_simulation.log"
verilator --binary --timing --top-module axi_ar_s3_tb --Mdir "$BUILD/s3" -o axi_ar_s3_tb \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" "$ROOT/rtl/axi_ar_target_scheduler_a.sv" "$ROOT/rtl/axi_ar_target_path_a.sv" \
  "$ROOT/tb/directed/axi_ar_s3_tb.sv" 2>&1 | tee "$OUT/s3_build.log"
"$BUILD/s3/axi_ar_s3_tb" 2>&1 | tee "$OUT/s3_simulation.log"
verilator --binary --timing --top-module axi_read_state_bank_tb --Mdir "$BUILD/bank" -o axi_read_state_bank_tb \
  "$ROOT/rtl/axi_outstanding_tracker.sv" "$ROOT/rtl/axi_read_state_bank.sv" \
  "$ROOT/tb/directed/axi_read_state_bank_tb.sv" 2>&1 | tee "$OUT/bank_build.log"
"$BUILD/bank/axi_read_state_bank_tb" 2>&1 | tee "$OUT/bank_simulation.log"
verilator --binary --timing --top-module axi_ar_read_state_composition_tb --Mdir "$BUILD/comp" -o axi_ar_read_state_composition_tb \
  "$ROOT/rtl/axi_rr_arbiter_3.sv" "$ROOT/rtl/axi_ar_target_scheduler_a.sv" "$ROOT/rtl/axi_ar_target_path_a.sv" \
  "$ROOT/rtl/axi_outstanding_tracker.sv" "$ROOT/rtl/axi_read_state_bank.sv" "$ROOT/tb/directed/axi_ar_read_state_composition_tb.sv" 2>&1 | tee "$OUT/composition_build.log"
"$BUILD/comp/axi_ar_read_state_composition_tb" 2>&1 | tee "$OUT/composition_simulation.log"
verilator --binary --timing --top-module axi_read_write_id_independence_tb --Mdir "$BUILD/ind" -o axi_read_write_id_independence_tb \
  "$ROOT/rtl/axi_outstanding_tracker.sv" "$ROOT/rtl/axi_read_state_bank.sv" "$ROOT/rtl/axi_write_owner.sv" "$ROOT/rtl/axi_write_state_bank.sv" \
  "$ROOT/tb/directed/axi_read_write_id_independence_tb.sv" 2>&1 | tee "$OUT/independence_build.log"
"$BUILD/ind/axi_read_write_id_independence_tb" 2>&1 | tee "$OUT/independence_simulation.log"
yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_rr_arbiter_3.sv $ROOT/rtl/axi_ar_target_scheduler_a.sv $ROOT/rtl/axi_ar_target_path_a.sv; synth_ecp5 -top axi_ar_target_path_a -json $OUT/axi_ar_target_path_a_ecp5.json; stat" 2>&1 | tee "$OUT/yosys_ar_path_synth.log"
yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_outstanding_tracker.sv $ROOT/rtl/axi_read_state_bank.sv; synth_ecp5 -top axi_read_state_bank -json $OUT/axi_read_state_bank_ecp5.json; stat" 2>&1 | tee "$OUT/yosys_read_bank_synth.log"
(cd "$ROOT/formal" && sby -f -d "$OUT/formal_ar_prove" axi_ar_target_path.sby prove && sby -f -d "$OUT/formal_ar_cover" axi_ar_target_path.sby cover && sby -f -d "$OUT/formal_bank_prove" axi_read_state_bank.sby prove && sby -f -d "$OUT/formal_bank_cover" axi_read_state_bank.sby cover && sby -f -d "$OUT/formal_comp_prove" axi_ar_read_state_composition.sby prove && sby -f -d "$OUT/formal_comp_cover" axi_ar_read_state_composition.sby cover) 2>&1 | tee "$OUT/formal.log"
test -f "$OUT/formal_ar_prove/PASS"; test -f "$OUT/formal_ar_cover/PASS"; test -f "$OUT/formal_bank_prove/PASS"; test -f "$OUT/formal_bank_cover/PASS"; test -f "$OUT/formal_comp_prove/PASS"; test -f "$OUT/formal_comp_cover/PASS"
