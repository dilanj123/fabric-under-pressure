#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/oss_cad_env.sh"
OUT="$ROOT_DIR/results/raw/fabric_b_directed"
mkdir -p "$OUT"
RTL=(
  rtl/fabric_addr_map_pkg.sv rtl/axi_address_decoder.sv rtl/axi_request_legal.sv
  rtl/axi_outstanding_tracker.sv rtl/axi_write_owner.sv rtl/axi_write_state_bank.sv
  rtl/axi_read_state_bank.sv rtl/axi_rr_arbiter_3.sv rtl/axi_rr_arbiter_4.sv
  rtl/axi_qos_aging_arbiter_3.sv rtl/axi_aw_target_scheduler_b.sv rtl/axi_aw_target_path_b.sv
  rtl/axi_ar_target_scheduler_b.sv rtl/axi_ar_target_path_b.sv rtl/axi_w_target_path.sv
  rtl/axi_b_response_router.sv rtl/axi_r_response_router.sv rtl/axi_s3_error_target.sv
  rtl/axi_fabric_b.sv
)
verilator --lint-only --timing -Wall -Wno-fatal --top-module axi_fabric_b "${RTL[@]}" >"$OUT/lint.log" 2>&1
verilator --binary --timing -Wall -Wno-fatal -DARCHITECTURE_B --top-module axi_fabric_a_tb \
  "${RTL[@]}" tb/directed/axi_fabric_a_tb.sv -o "$OUT/axi_fabric_b_tb" >"$OUT/build.log" 2>&1
"$OUT/axi_fabric_b_tb" >"$OUT/simulation.log" 2>&1
grep -q '^PASS axi_fabric_b_tb checks=' "$OUT/simulation.log"
echo "PASS Fabric-B whole-DUT directed functional regression"
