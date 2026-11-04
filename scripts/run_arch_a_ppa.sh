#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${ARCH_PPA_ARCH:-A}"
if [[ "$ARCH" == "A" ]]; then
  DUT_TOP=axi_fabric_a
  OUT_DEFAULT="$ROOT/results/raw/arch_a_ppa_v1"
  rtl=(
    rtl/fabric_addr_map_pkg.sv rtl/axi_address_decoder.sv rtl/axi_request_legal.sv
    rtl/axi_outstanding_tracker.sv rtl/axi_write_owner.sv rtl/axi_write_state_bank.sv
    rtl/axi_read_state_bank.sv rtl/axi_rr_arbiter_3.sv rtl/axi_rr_arbiter_4.sv
    rtl/axi_aw_target_scheduler_a.sv rtl/axi_aw_target_path_a.sv
    rtl/axi_ar_target_scheduler_a.sv rtl/axi_ar_target_path_a.sv rtl/axi_w_target_path.sv
    rtl/axi_b_response_router.sv rtl/axi_r_response_router.sv rtl/axi_s3_error_target.sv
    rtl/axi_fabric_a.sv
  )
elif [[ "$ARCH" == "B" ]]; then
  DUT_TOP=axi_fabric_b
  OUT_DEFAULT="$ROOT/results/raw/arch_b_ppa_v1"
  rtl=(
    rtl/fabric_addr_map_pkg.sv rtl/axi_address_decoder.sv rtl/axi_request_legal.sv
    rtl/axi_outstanding_tracker.sv rtl/axi_write_owner.sv rtl/axi_write_state_bank.sv
    rtl/axi_read_state_bank.sv rtl/axi_rr_arbiter_3.sv rtl/axi_rr_arbiter_4.sv
    rtl/axi_qos_aging_arbiter_3.sv rtl/axi_aw_target_scheduler_b.sv
    rtl/axi_aw_target_path_b.sv rtl/axi_ar_target_scheduler_b.sv
    rtl/axi_ar_target_path_b.sv rtl/axi_w_target_path.sv rtl/axi_b_response_router.sv
    rtl/axi_r_response_router.sv rtl/axi_s3_error_target.sv rtl/axi_fabric_b.sv
  )
else
  echo "ARCH_PPA_ARCH must be A or B" >&2
  exit 2
fi
OUT="${ARCH_A_PPA_OUT:-$OUT_DEFAULT}"
mkdir -p "$OUT/direct" "$OUT/wrapped/routes"
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment

read_cmd="read_verilog -sv"
wrapper_read="read_verilog -sv"
if [[ "$ARCH" == "B" ]]; then
  read_cmd+=" -DARCHITECTURE_B"
  wrapper_read+=" -DARCHITECTURE_B"
fi
for file in "${rtl[@]}"; do read_cmd+=" $ROOT/$file"; done

printf 'architecture=%s\ndut_top=%s\n' "$ARCH" "$DUT_TOP" > "$OUT/run_config.txt"
yosys -V > "$OUT/tool_versions.txt"
nextpnr-ecp5 --version >> "$OUT/tool_versions.txt" 2>&1
ecppack --version >> "$OUT/tool_versions.txt" 2>&1 || true
sha256sum "$ROOT/bench/arch_fabric_wrapper.sv" "$ROOT/scripts/run_arch_a_ppa.sh" \
  "$ROOT/bench/workloads.yaml" "$ROOT/bench/benchmark_plan.py" \
  "$ROOT/tb/cocotb/test_axi_fabric_a_benchmark.py" "${rtl[@]/#/$ROOT/}" > "$OUT/source_hashes.txt"

echo "synth direct Fabric"
yosys -Q -p "$read_cmd; synth_ecp5 -top $DUT_TOP -json $OUT/direct/$DUT_TOP.json; stat" \
  > "$OUT/direct/yosys.log" 2>&1 || { echo "direct synthesis failed; see $OUT/direct/yosys.log"; exit 1; }

echo "synth common wrapper"
yosys -Q -p "$read_cmd; $wrapper_read $ROOT/bench/arch_fabric_wrapper.sv; synth_ecp5 -top arch_fabric_wrapper -json $OUT/wrapped/arch_fabric_wrapper.json; stat" \
  > "$OUT/wrapped/yosys.log" 2>&1 || { echo "wrapper synthesis failed; see $OUT/wrapped/yosys.log"; exit 1; }

if [[ "${ARCH_A_PPA_ONLY_SYNTH:-0}" == 1 ]]; then
  echo "synthesis-only artifacts: $OUT"
  exit 0
fi

echo "frequency_mhz,seed,exit_code,achieved_mhz,timing_clean,route_log,report,textcfg" > "$OUT/route_matrix.csv"
run_route() {
  local freq="$1" seed="$2" stem="$3"
  local log="$OUT/wrapped/routes/$stem.log"
  local report="$OUT/wrapped/routes/$stem.json"
  local config="$OUT/wrapped/routes/$stem.config"
  set +e
  nextpnr-ecp5 --45k --package CABGA381 --speed 6 \
    --json "$OUT/wrapped/arch_fabric_wrapper.json" --textcfg "$config" \
    --report "$report" --freq "$freq" --seed "$seed" > "$log" 2>&1
  local rc=$?
  set -e
  local achieved=""
  if [[ -s "$report" ]]; then
    achieved="$(python3 - "$report" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
values = [clock.get("achieved") for clock in doc.get("fmax", {}).values()
          if isinstance(clock, dict) and isinstance(clock.get("achieved"), (int, float))]
print(max(values) if values else "")
PY
)"
  fi
  local clean=false
  if [[ $rc -eq 0 && -n "$achieved" ]] && \
     python3 -c 'import sys; raise SystemExit(float(sys.argv[1]) < float(sys.argv[2]))' "$achieved" "$freq"; then
    clean=true
  fi
  printf '%s,%s,%s,%s,%s,%s,%s,%s\n' "$freq" "$seed" "$rc" "$achieved" "$clean" \
    "$log" "$report" "$config" >> "$OUT/route_matrix.csv"
  echo "route $stem exit=$rc achieved_mhz=${achieved:-NA} timing_clean=$clean"
}

for freq in 50 75 100 125 150 175 200; do
  for seed in 1 2 3 4 5; do run_route "$freq" "$seed" "f${freq}_s${seed}"; done
done

# Refine the all-seed pass/fail boundary at 5-MHz steps. Use the same refined
# frequencies for every seed so the clean threshold remains directly comparable.
good=0
bad=0
for freq in 50 75 100 125 150 175 200; do
  clean_count="$(awk -F, -v f="$freq" '$1==f && $5=="true" {n++} END {print n+0}' \
    "$OUT/route_matrix.csv")"
  if [[ "$clean_count" -eq 5 ]]; then
    good=$freq
  elif [[ $good -gt 0 ]]; then
    bad=$freq
    break
  fi
done
if [[ $good -gt 0 && $bad -gt $good ]]; then
  for ((freq=good+5; freq<bad; freq+=5)); do
    for seed in 1 2 3 4 5; do run_route "$freq" "$seed" "refine_f${freq}_s${seed}"; done
  done
fi

"$ROOT/.venv/bin/python" "$ROOT/bench/summarize_ppa.py" "$OUT" \
  > "$OUT/ppa_summary.log" 2>&1
echo "PPA artifacts: $OUT"
