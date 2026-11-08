#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "${ROOT}/scripts/oss_cad_env.sh"
OUT="${GATE2_R_FAULT_OUT:-$ROOT/results/raw/gate2_r_fault_sensitivity}"
mkdir -p "$OUT"
export ROOT OUT
export PYTHONPATH="$ROOT/tb/model:$ROOT/tb/cocotb:$ROOT${PYTHONPATH:+:$PYTHONPATH}"
export CXXFLAGS="${CXXFLAGS:-} -std=c++17"
export LIBPYTHON_LOC="${LIBPYTHON_LOC:-$(find "$OSS_CAD_SUITE_LIB" -maxdepth 1 -name 'libpython*.dylib' -print -quit)}"
export DYLD_LIBRARY_PATH="$OSS_CAD_SUITE_LIB${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
ln -sfn "$OSS_CAD_SUITE_LIB" "$OUT/lib"
python3 - <<'PY' >"$OUT/fault_sensitivity.log" 2>&1
import os
from pathlib import Path
import xml.etree.ElementTree as ET
from cocotb_tools.runner import get_runner

root = Path(os.environ["ROOT"])
out = Path(os.environ["OUT"])
rtl = [root / p for p in [
    "rtl/fabric_addr_map_pkg.sv", "rtl/axi_address_decoder.sv", "rtl/axi_request_legal.sv",
    "rtl/axi_outstanding_tracker.sv", "rtl/axi_write_owner.sv", "rtl/axi_write_state_bank.sv",
    "rtl/axi_read_state_bank.sv", "rtl/axi_rr_arbiter_3.sv", "rtl/axi_rr_arbiter_4.sv",
    "rtl/axi_aw_target_scheduler_a.sv", "rtl/axi_aw_target_path_a.sv",
    "rtl/axi_ar_target_scheduler_a.sv", "rtl/axi_ar_target_path_a.sv", "rtl/axi_w_target_path.sv",
    "rtl/axi_b_response_router.sv", "rtl/axi_r_response_router.sv", "rtl/axi_s3_error_target.sv",
    "rtl/axi_fabric_a.sv"]]
runner = get_runner("verilator")
runner.build(sources=rtl, hdl_toplevel="axi_fabric_a", build_dir=out / "work",
             always=True, build_args=["-Wno-fatal"])
expected = {
    "duplicate": "duplicate accepted R beat",
    "missing": "missing accepted R beat",
    "bad_rdata": "bad RDATA",
    "early_rlast": "early RLAST",
    "missing_rlast": "missing final RLAST",
    "wrong_rid": "wrong RID",
}
for mode, reason in expected.items():
    xml_path = out / f"{mode}.xml"
    trace_path = out / f"{mode}.trace.jsonl"
    try:
        runner.test(hdl_toplevel="axi_fabric_a", test_module="test_axi_fabric_a_oracle",
                    testcase="fabric_a_oracle_r_edge_safe",
                    test_dir=root / "tb/cocotb", build_dir=out / "work",
                    results_xml=str(xml_path),
                    extra_env={"ORACLE_R_FAULT_MODE": mode,
                               "GATE3_BOUNDARY_TRACE": str(trace_path)})
    except SystemExit:
        pass
    report = ET.parse(xml_path).getroot()
    suite = report.find("testsuite")
    if suite is None:
        suite = report
    cases = list(suite.iter("testcase"))
    selected = [case for case in cases
                if case.attrib.get("name") == "fabric_a_oracle_r_edge_safe" and
                case.find("skipped") is None]
    failures = [(case, case.find("failure"), case.find("error")) for case in selected
                if case.find("failure") is not None or case.find("error") is not None]
    assert len(cases) == 3 and len(selected) == 1, (mode, len(cases), len(selected))
    assert len(failures) == 1, (mode, failures)
    case, failure, error = failures[0]
    assert error is None, (mode, ET.tostring(case, encoding="unicode"))
    failure_text = (failure.attrib.get("error_msg", "") + " " + (failure.text or ""))
    assert f"ORACLE_EXPECTED_FAULT:{mode}:" in failure_text, (mode, failure_text)
    assert reason in failure_text, (mode, failure_text)
    assert len(failures) == 1 and all(case.find("error") is None for case in cases)
    print(f"PASS {mode}: rejected for intended reason ({reason})")
PY
cat "$OUT/fault_sensitivity.log"
