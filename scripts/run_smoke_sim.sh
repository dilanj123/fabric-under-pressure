#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/gate0/sim"
mkdir -p "$OUT"
command -v verilator >/dev/null || { echo "ERROR: verilator missing" | tee "$OUT/run.log"; exit 2; }
python3 - <<'PY' || { echo "ERROR: cocotb missing" | tee "$OUT/run.log"; exit 2; }
import cocotb
print(cocotb.__version__)
PY
export FABRIC_SEED="${FABRIC_SEED:-0xFABC0001}"
export ROOT
python3 - <<'PY' 2>&1 | tee "$OUT/run.log"
import os
from pathlib import Path
from cocotb_tools.runner import get_runner
root=Path(os.environ['ROOT'])
out=root/'results/raw/gate0/sim'
runner=get_runner('verilator')
runner.build(sources=[root/'smoke/handshake_counter.sv'], hdl_toplevel='handshake_counter', build_dir=out/'work', always=True)
runner.test(hdl_toplevel='handshake_counter', test_module='test_smoke_counter', test_dir=root/'tb/cocotb', results_xml=str(out/'results.xml'))
PY
test -s "$OUT/results.xml"
