#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/gate0/pnr"
mkdir -p "$OUT"
for c in yosys nextpnr-ecp5; do command -v "$c" >/dev/null || { echo "ERROR: $c missing" | tee "$OUT/run.log"; exit 2; }; done
yosys -Q -p "read_verilog -sv $ROOT/smoke/ecp5_smoke.sv; synth_ecp5 -top ecp5_smoke -json $OUT/ecp5_smoke.json" > "$OUT/yosys.log" 2>&1
nextpnr-ecp5 --45k --package CABGA381 --speed 6 --json "$OUT/ecp5_smoke.json" --textcfg "$OUT/ecp5_smoke.config" --freq 100 --seed 1 2>&1 | tee "$OUT/run.log"
test -s "$OUT/ecp5_smoke.config"
if command -v ecppack >/dev/null; then ecppack "$OUT/ecp5_smoke.config" "$OUT/ecp5_smoke.bit" >> "$OUT/run.log" 2>&1 || true; fi
