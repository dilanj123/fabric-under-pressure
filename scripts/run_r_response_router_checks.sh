#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/r_response_router"
BUILD="$OUT/sim_work"
python3 - "$OUT/formal_prove" "$OUT/formal_cover" "$BUILD" <<'PY'
import shutil, sys
for path in sys.argv[1:]:
    shutil.rmtree(path, ignore_errors=True)
PY
mkdir -p "$OUT" "$BUILD/router" "$BUILD/burst" "$BUILD/lifecycle"

source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
{
  echo "commit=$(git -C "$ROOT" rev-parse HEAD)"
  verilator --version
  yosys --version
  sby --version 2>&1 | head -1
  yices-smt2 --version 2>&1 | head -1
} 2>&1 | tee "$OUT/tool_versions.log"

verilator --lint-only --timing -Wall --top-module axi_r_response_router \
  "$ROOT/rtl/axi_rr_arbiter_4.sv" "$ROOT/rtl/axi_r_response_router.sv" \
  2>&1 | tee "$OUT/verilator_lint.log"

verilator --binary --timing --top-module axi_r_response_router_tb --Mdir "$BUILD/router" \
  -o axi_r_response_router_tb "$ROOT/rtl/axi_rr_arbiter_4.sv" \
  "$ROOT/rtl/axi_r_response_router.sv" "$ROOT/tb/directed/axi_r_response_router_tb.sv" \
  2>&1 | tee "$OUT/router_build.log"
"$BUILD/router/axi_r_response_router_tb" 2>&1 | tee "$OUT/router_simulation.log"

verilator --binary --timing --top-module axi_r_burst_lengths_tb --Mdir "$BUILD/burst" \
  -o axi_r_burst_lengths_tb "$ROOT/rtl/axi_rr_arbiter_4.sv" \
  "$ROOT/rtl/axi_r_response_router.sv" "$ROOT/tb/directed/axi_r_burst_lengths_tb.sv" \
  2>&1 | tee "$OUT/burst_build.log"
"$BUILD/burst/axi_r_burst_lengths_tb" 2>&1 | tee "$OUT/burst_simulation.log"

verilator --binary --timing --top-module axi_ar_r_read_lifecycle_tb --Mdir "$BUILD/lifecycle" \
  -o axi_ar_r_read_lifecycle_tb "$ROOT/rtl/axi_rr_arbiter_3.sv" \
  "$ROOT/rtl/axi_outstanding_tracker.sv" "$ROOT/rtl/axi_ar_target_scheduler_a.sv" \
  "$ROOT/rtl/axi_ar_target_path_a.sv" "$ROOT/rtl/axi_read_state_bank.sv" \
  "$ROOT/rtl/axi_rr_arbiter_4.sv" "$ROOT/rtl/axi_r_response_router.sv" \
  "$ROOT/tb/directed/axi_ar_r_read_lifecycle_tb.sv" \
  2>&1 | tee "$OUT/lifecycle_build.log"
"$BUILD/lifecycle/axi_ar_r_read_lifecycle_tb" 2>&1 | tee "$OUT/lifecycle_simulation.log"

yosys -Q -p "read_verilog -sv $ROOT/rtl/axi_rr_arbiter_4.sv $ROOT/rtl/axi_r_response_router.sv; synth_ecp5 -top axi_r_response_router -json $OUT/axi_r_response_router_ecp5.json; stat" \
  2>&1 | tee "$OUT/yosys_r_router_synth.log"

(
  cd "$ROOT/formal"
  sby -f -d "$OUT/formal_prove" axi_r_response_router.sby prove
  sby -f -d "$OUT/formal_cover" axi_r_response_router.sby cover
) 2>&1 | tee "$OUT/formal.log"

test -f "$OUT/formal_prove/PASS"
test -f "$OUT/formal_cover/PASS"
