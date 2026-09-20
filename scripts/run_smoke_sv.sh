#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/gate0/env"
mkdir -p "$OUT"
: > "$OUT/sv_frontends.log"
for cmd in verilator yosys; do command -v "$cmd" >/dev/null || { echo "ERROR: $cmd missing" | tee -a "$OUT/sv_frontends.log"; exit 2; }; done
verilator --lint-only --timing -Wall "$ROOT/smoke/sv_features.sv" 2>&1 | tee -a "$OUT/sv_frontends.log"
if command -v slang >/dev/null 2>&1; then
  slang --lint-only "$ROOT/smoke/sv_features.sv" 2>&1 | tee -a "$OUT/sv_frontends.log"
else
  echo "NOTE: slang CLI absent; if yosys-slang plugin is present, add its local command to evidence." | tee -a "$OUT/sv_frontends.log"
fi
yosys -Q -p "read_verilog -sv $ROOT/smoke/sv_features.sv; hierarchy -top sv_features; proc; check" 2>&1 | tee -a "$OUT/sv_frontends.log"
