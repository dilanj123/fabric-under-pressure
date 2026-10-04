#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export ROOT
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
export PYTHONPATH="$ROOT/tb/model:$ROOT/tb/cocotb:$ROOT/tb/random:$ROOT${PYTHONPATH:+:$PYTHONPATH}"
export CXXFLAGS="${CXXFLAGS:-} -std=c++17"
export LIBPYTHON_LOC="${LIBPYTHON_LOC:-$(find /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib -maxdepth 1 -name 'libpython*.dylib' -print -quit)}"
export DYLD_LIBRARY_PATH="/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"

out="$ROOT/results/raw/manager_scheduler"
mkdir -p "$out"
ln -sfn "/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib" "$out/lib"
rtl=(
  "$ROOT/rtl/fabric_addr_map_pkg.sv" "$ROOT/rtl/axi_address_decoder.sv"
  "$ROOT/rtl/axi_request_legal.sv" "$ROOT/rtl/axi_outstanding_tracker.sv"
  "$ROOT/rtl/axi_write_owner.sv" "$ROOT/rtl/axi_write_state_bank.sv"
  "$ROOT/rtl/axi_read_state_bank.sv" "$ROOT/rtl/axi_rr_arbiter_3.sv"
  "$ROOT/rtl/axi_rr_arbiter_4.sv" "$ROOT/rtl/axi_aw_target_scheduler_a.sv"
  "$ROOT/rtl/axi_aw_target_path_a.sv" "$ROOT/rtl/axi_ar_target_scheduler_a.sv"
  "$ROOT/rtl/axi_ar_target_path_a.sv" "$ROOT/rtl/axi_w_target_path.sv"
  "$ROOT/rtl/axi_b_response_router.sv" "$ROOT/rtl/axi_r_response_router.sv"
  "$ROOT/rtl/axi_s3_error_target.sv" "$ROOT/rtl/axi_fabric_a.sv"
)
GATE3_RTL=$(IFS=:; echo "${rtl[*]}")
export GATE3_RTL

python3 - <<'PY' >"$out/run.log" 2>&1
import os
from pathlib import Path
from cocotb_tools.runner import get_runner

root = Path(os.environ["ROOT"])
out = root / "results/raw/manager_scheduler"
rtl = [Path(p) for p in os.environ["GATE3_RTL"].split(":")]
runner = get_runner("verilator")
runner.build(sources=rtl, hdl_toplevel="axi_fabric_a", build_dir=out / "work",
             always=True, build_args=["-Wno-fatal"])
runner.test(hdl_toplevel="axi_fabric_a",
            test_module="test_axi_fabric_a_manager_scheduler",
            test_dir=root / "tb/cocotb", results_xml=str(out / "results.xml"))
PY

python3 - "$out/results.xml" <<'PY'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
suite = root.find("testsuite") if root.tag == "testsuites" else root
assert suite is not None
assert suite.attrib.get("errors", "0") == "0"
assert suite.attrib.get("failures", "0") == "0"
PY
echo "PASS manager scheduler checks"
