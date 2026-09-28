#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
OUT=results/raw/s3_error_target_repair
mkdir -p "$OUT"
verilator --lint-only --timing -Wall --top-module axi_s3_error_target rtl/axi_s3_error_target.sv > "$OUT/verilator_lint.log" 2>&1
verilator --binary --timing --top-module axi_s3_error_target_tb --Mdir /tmp/s3_tb_repair -o axi_s3_error_target_tb rtl/axi_s3_error_target.sv tb/directed/axi_s3_error_target_tb.sv >/tmp/s3repair_tb_build.log 2>&1
/tmp/s3_tb_repair/axi_s3_error_target_tb > "$OUT/standalone_simulation.log" 2>&1
verilator --binary --timing --top-module axi_s3_write_lifecycle_tb --Mdir /tmp/s3_w_repair -o axi_s3_write_lifecycle_tb rtl/axi_outstanding_tracker.sv rtl/axi_write_owner.sv rtl/axi_write_state_bank.sv rtl/axi_rr_arbiter_3.sv rtl/axi_aw_target_scheduler_a.sv rtl/axi_aw_target_path_a.sv rtl/axi_w_target_path.sv rtl/axi_rr_arbiter_4.sv rtl/axi_b_response_router.sv rtl/axi_s3_error_target.sv tb/directed/axi_s3_write_lifecycle_tb.sv >/tmp/s3repair_w_build.log 2>&1
/tmp/s3_w_repair/axi_s3_write_lifecycle_tb > "$OUT/write_lifecycle_simulation.log" 2>&1
verilator --binary --timing --top-module axi_s3_read_lifecycle_tb --Mdir /tmp/s3_r_repair -o axi_s3_read_lifecycle_tb rtl/axi_outstanding_tracker.sv rtl/axi_read_state_bank.sv rtl/axi_rr_arbiter_3.sv rtl/axi_ar_target_scheduler_a.sv rtl/axi_ar_target_path_a.sv rtl/axi_rr_arbiter_4.sv rtl/axi_r_response_router.sv rtl/axi_s3_error_target.sv tb/directed/axi_s3_read_lifecycle_tb.sv >/tmp/s3repair_r_build.log 2>&1
/tmp/s3_r_repair/axi_s3_read_lifecycle_tb > "$OUT/read_lifecycle_simulation.log" 2>&1
(cd formal && sby -f axi_s3_error_target_write.sby) > "$OUT/formal_write_run.log" 2>&1
(cd formal && sby -f axi_s3_error_target_read.sby) > "$OUT/formal_read_run.log" 2>&1
yosys -Q -p "read_verilog -sv rtl/axi_s3_error_target.sv; synth_ecp5 -top axi_s3_error_target -json $OUT/axi_s3_error_target_ecp5.json; stat" > "$OUT/synthesis.log" 2>&1
echo "PASS S3 W-before-AW repair checks"
