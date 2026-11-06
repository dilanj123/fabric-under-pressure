#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "${ROOT}/scripts/oss_cad_env.sh"
OUT="$ROOT/results/raw/gate2_oracle_b"
mkdir -p "$OUT"
export PYTHONPATH="$ROOT/tb/model:$ROOT/tb/cocotb:$ROOT/tb/random:$ROOT${PYTHONPATH:+:$PYTHONPATH}"
export ROOT OUT
export CXXFLAGS="${CXXFLAGS:-} -std=c++17"
export LIBPYTHON_LOC="${LIBPYTHON_LOC:-$(find "${OSS_CAD_SUITE_LIB}" -maxdepth 1 -name 'libpython*.dylib' -print -quit)}"
export DYLD_LIBRARY_PATH="${OSS_CAD_SUITE_LIB}${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
ln -sfn "${OSS_CAD_SUITE_LIB}" "$OUT/lib"
{
  echo "architecture=B"
  echo "dut_top=axi_fabric_b"
  echo "oracle=test_axi_fabric_a_oracle"
  echo "verilator=$(verilator --version | head -1)"
} >"$OUT/run.log"
python3 - <<'PY' >"$OUT/build_and_test.log" 2>&1
import os
from pathlib import Path
from cocotb_tools.runner import get_runner
root=Path(os.environ['ROOT']); out=Path(os.environ['OUT'])
rtl=[root/p for p in [
 'rtl/fabric_addr_map_pkg.sv','rtl/axi_address_decoder.sv','rtl/axi_request_legal.sv',
 'rtl/axi_outstanding_tracker.sv','rtl/axi_write_owner.sv','rtl/axi_write_state_bank.sv',
 'rtl/axi_read_state_bank.sv','rtl/axi_rr_arbiter_3.sv','rtl/axi_rr_arbiter_4.sv',
 'rtl/axi_qos_aging_arbiter_3.sv','rtl/axi_aw_target_scheduler_b.sv','rtl/axi_aw_target_path_b.sv',
 'rtl/axi_ar_target_scheduler_b.sv','rtl/axi_ar_target_path_b.sv','rtl/axi_w_target_path.sv',
 'rtl/axi_b_response_router.sv','rtl/axi_r_response_router.sv','rtl/axi_s3_error_target.sv',
 'rtl/axi_fabric_b.sv']]
r=get_runner('verilator')
r.build(sources=rtl,hdl_toplevel='axi_fabric_b',build_dir=out/'work',always=True,build_args=['-Wno-fatal'])
r.test(hdl_toplevel='axi_fabric_b',test_module='test_axi_fabric_a_oracle',test_dir=root/'tb/cocotb',results_xml=str(out/'results.xml'))
PY
python3 - "$OUT/results.xml" <<'PY'
import sys,xml.etree.ElementTree as ET
r=ET.parse(sys.argv[1]).getroot(); s=r.find('testsuite') or r
cases=s.findall('.//testcase')
assert len(cases)==2
assert s.attrib.get('failures','0')=='0' and s.attrib.get('errors','0')=='0' and s.attrib.get('skipped','0')=='0'
assert all(c.find('failure') is None and c.find('error') is None for c in cases)
PY
for marker in \
  'oracle four-write capacity and D028 recovery PASS' \
  'oracle four-read capacity and D028 recovery PASS' \
  'oracle same-visible-ID read concurrency PASS' \
  'oracle distinct-ID out-of-order B/R PASS' \
  'oracle live-work reset epoch and fresh same-ID reuse PASS'; do
  grep -q "$marker" "$OUT/build_and_test.log"
done
echo "PASS Architecture-B independent Gate-2 oracle matrix"
