#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/gate0/bfm"
mkdir -p "$OUT"
command -v verilator >/dev/null || { echo "ERROR: verilator missing" | tee "$OUT/run.log"; exit 2; }
python3 - <<'PY' || { echo "ERROR: cocotb/cocotbext-axi missing" | tee "$OUT/run.log"; exit 2; }
import cocotb
import cocotbext.axi
print("cocotb", cocotb.__version__)
print("cocotbext.axi import PASS")
PY
export FABRIC_SEED="${FABRIC_SEED:-0xFABC0001}"
export ROOT
python3 - <<'PY' 2>&1 | tee "$OUT/run.log"
import os
from pathlib import Path
from cocotb_tools.runner import get_runner
root=Path(os.environ['ROOT'])
out=root/'results/raw/gate0/bfm'
runner=get_runner('verilator')
runner.build(sources=[root/'smoke/axi_bfm_bus.sv'], hdl_toplevel='axi_bfm_bus', build_dir=out/'work', parameters={'DATA_W':64,'ADDR_W':32,'ID_W':4}, always=True)
runner.test(hdl_toplevel='axi_bfm_bus', test_module='test_axi_bfm_smoke', test_dir=root/'tb/cocotb', results_xml=str(out/'results.xml'))
PY
test -s "$OUT/results.xml"
