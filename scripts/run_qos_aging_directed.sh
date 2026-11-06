#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "${ROOT}/scripts/oss_cad_env.sh"
OUT="$ROOT/results/raw/architecture_b_scheduler"
mkdir -p "$OUT"
verilator --binary --timing -Wall -Wno-fatal --top-module axi_qos_aging_arbiter_3_tb \
  rtl/axi_qos_aging_arbiter_3.sv tb/directed/axi_qos_aging_arbiter_3_tb.sv \
  -o "$OUT/axi_qos_aging_arbiter_3_tb" >"$OUT/directed_build.log" 2>&1
"$OUT/axi_qos_aging_arbiter_3_tb" >"$OUT/directed.log" 2>&1
grep -q '^PASS axi_qos_aging_arbiter_3_tb checks=' "$OUT/directed.log"
