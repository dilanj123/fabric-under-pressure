#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GIT_COMMIT="$(git rev-parse HEAD)"
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
OUT="$ROOT/results/raw/gate2_oracle"
mkdir -p "$OUT"
export PYTHONPATH="$ROOT/tb/model${PYTHONPATH:+:$PYTHONPATH}"
export ROOT
export CXXFLAGS="${CXXFLAGS:-} -std=c++17"
export COCOTB_RANDOM_SEED="${COCOTB_RANDOM_SEED:-0xA0C20001}"
# Verilator's macOS launcher loads Python dynamically.  Keep the qualified
# OSS CAD Suite Python library visible to the generated executable.
if [ -z "${LIBPYTHON_LOC:-}" ]; then
  suite_root="/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite"
  libpython="$(find "$suite_root/lib" -maxdepth 1 -name 'libpython*.dylib' -print -quit 2>/dev/null)"
  [ -n "$libpython" ] && export LIBPYTHON_LOC="$libpython"
  export DYLD_LIBRARY_PATH="$suite_root/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
fi
# The bundled libpython uses @executable_path/../lib for its gettext
# dependency.  The cocotb executable lives below OUT/work, so expose the
# suite library directory at the corresponding runtime-relative location.
ln -sfn "/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib" "$OUT/lib"
{
  echo "git_commit=$GIT_COMMIT"
  echo "functional_seed=$COCOTB_RANDOM_SEED"
  echo "verilator=$(verilator --version | head -1)"
  echo "python=$(python3 --version 2>&1)"
} >"$OUT/gate2_closure.log"

python3 -m unittest -v tb/model/test_axi_reference_model.py >"$OUT/pytest_oracle_model.log" 2>&1
scripts/run_fabric_a_gate2_directed.sh >"$OUT/directed_regression.log" 2>&1

python3 - <<'PY' >"results/raw/gate2_oracle/cocotb_build.log" 2>&1
import os
from pathlib import Path
from cocotb_tools.runner import get_runner

root = Path(os.environ["ROOT"])
out = root / "results/raw/gate2_oracle"
rtl = [root / p for p in [
    "rtl/fabric_addr_map_pkg.sv", "rtl/axi_address_decoder.sv", "rtl/axi_request_legal.sv",
    "rtl/axi_outstanding_tracker.sv", "rtl/axi_write_owner.sv", "rtl/axi_write_state_bank.sv",
    "rtl/axi_read_state_bank.sv", "rtl/axi_rr_arbiter_3.sv", "rtl/axi_rr_arbiter_4.sv",
    "rtl/axi_aw_target_scheduler_a.sv", "rtl/axi_aw_target_path_a.sv",
    "rtl/axi_ar_target_scheduler_a.sv", "rtl/axi_ar_target_path_a.sv", "rtl/axi_w_target_path.sv",
    "rtl/axi_b_response_router.sv", "rtl/axi_r_response_router.sv", "rtl/axi_s3_error_target.sv",
    "rtl/axi_fabric_a.sv"]]
runner = get_runner("verilator")
runner.build(sources=rtl, hdl_toplevel="axi_fabric_a", build_dir=out / "work", always=True,
             build_args=["-Wno-fatal"])
runner.test(hdl_toplevel="axi_fabric_a", test_module="test_axi_fabric_a_oracle",
            test_dir=root / "tb/cocotb", results_xml=str(out / "results.xml"))
PY

test -s "$OUT/results.xml"
python3 - "$OUT/results.xml" <<'PY'
import sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
suite = root.find("testsuite")
if suite is None and root.tag == "testsuite":
    suite = root
assert suite is not None, root.tag
assert suite.attrib.get("errors", "0") == "0", suite.attrib
assert suite.attrib.get("failures", "0") == "0", suite.attrib
assert all(tc.find("failure") is None and tc.find("error") is None
           for tc in suite.findall("testcase")), "cocotb testcase failure"
PY

echo "PASS Gate-2 oracle closure"
