#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/gate0/wrapper"
mkdir -p "$OUT"
command -v yosys >/dev/null || { echo "ERROR: yosys missing" | tee "$OUT/run.log"; exit 2; }
yosys -Q -p "read_verilog -sv $ROOT/smoke/preserve_harness.sv; hierarchy -top preserve_harness; synth_ecp5 -top preserve_harness -json $OUT/preserve_harness.json; stat" 2>&1 | tee "$OUT/run.log"
test -s "$OUT/preserve_harness.json"
python3 - "$OUT/preserve_harness.json" <<'PY' | tee "$OUT/check.log"
import json,sys
p=sys.argv[1]
d=json.load(open(p))
mods=d.get('modules',{})
assert 'preserve_harness' in mods, 'top module missing'
cells=mods['preserve_harness'].get('cells',{})
print('top_cells', len(cells))
assert len(cells) > 0, 'wrapper optimized to empty'
PY
