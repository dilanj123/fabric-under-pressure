#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/gate0/synth"
mkdir -p "$OUT"
command -v yosys >/dev/null || { echo "ERROR: yosys missing" | tee "$OUT/run.log"; exit 2; }
yosys -Q -p "read_verilog -sv $ROOT/smoke/ecp5_smoke.sv; synth_ecp5 -top ecp5_smoke -json $OUT/ecp5_smoke.json; stat" 2>&1 | tee "$OUT/run.log"
test -s "$OUT/ecp5_smoke.json"
