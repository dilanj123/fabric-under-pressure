#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
export PYTHONPATH="$ROOT/tb/model:$ROOT/tb/cocotb:$ROOT/tb/random:$ROOT${PYTHONPATH:+:$PYTHONPATH}"
export ROOT
export CXXFLAGS="${CXXFLAGS:-} -std=c++17"
export LIBPYTHON_LOC="${LIBPYTHON_LOC:-$(find /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib -maxdepth 1 -name 'libpython*.dylib' -print -quit)}"
export DYLD_LIBRARY_PATH="/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"

OUT="$ROOT/results/raw/gate3_random_v2"
PLAN_DIR="$OUT/plans"
mkdir -p "$PLAN_DIR"
SEEDS=(0xA3F30001 0xA3F30002 0xA3F30003 0xA3F30004 0xA3F30005)
requested_seed=""
requested_plan=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --seed) requested_seed="$2"; shift 2;;
    --plan) requested_plan="$2"; shift 2;;
    *) echo "usage: $0 [--seed SEED | --plan PLAN]" >&2; exit 2;;
  esac
done

if [ -n "$requested_plan" ]; then
  plans=("$requested_plan")
elif [ -n "$requested_seed" ]; then
  seed_value=$((requested_seed))
  plan="$PLAN_DIR/seed_$(printf '%08X' "$seed_value").json"
  python3 tb/random/axi_random_plan.py --seed "$requested_seed" --output "$plan"
  plans=("$plan")
else
  plans=()
  for seed in "${SEEDS[@]}"; do
    seed_value=$((seed))
    plan="$PLAN_DIR/seed_$(printf '%08X' "$seed_value").json"
    python3 tb/random/axi_random_plan.py --seed "$seed" --output "$plan"
    plans+=("$plan")
  done
fi

python3 - "${plans[@]}" <<'PY'
import hashlib, json, os, sys
from pathlib import Path
import sys as _sys
_sys.path.insert(0, "tb/model")
from axi_reference_model import legal_request
plans = [json.loads(Path(p).read_text()) for p in sys.argv[1:]]
assert plans
for plan in plans:
    ops = plan["random_operations"]
    if not os.environ.get("GATE3_ALLOW_SHORT_PLAN"):
        assert len(ops) >= 512
    for op in ops:
        assert 0 <= op["manager"] < 3
        assert op["direction"] in ("read", "write")
        assert 0 <= op["id"] < 16 and 0 <= op["length"] < 16
        assert 0 <= op["qos"] < 16 and op["launch_cycle"] >= 0
        if op["direction"] == "write":
            assert len(op["strobes"]) == op["length"] + 1
        assert legal_request(op["address"], op["length"], 3, 1, 0), op
    plan["_body_digest"] = hashlib.sha256(
        json.dumps(ops, sort_keys=True).encode()).hexdigest()
if len(plans) > 1:
    assert len({p["_body_digest"] for p in plans}) == len(plans), "seed plans are identical"
PY

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

for plan in "${plans[@]}"; do
  seed=$(python3 -c 'import json,sys; print("%08X" % json.load(open(sys.argv[1]))["seed"])' "$plan")
  seed_out="$OUT/seed_$seed"
  mkdir -p "$seed_out"
  ln -sfn "/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib" "$seed_out/lib"
  export GATE3_PLAN="$plan"
  export GATE3_OUT="$seed_out"
  export GATE3_BOUNDARY_TRACE="$ROOT/results/raw/gate3_rdata_investigation/boundary_trace.jsonl"
  export GATE3_AR_DIAG="$ROOT/results/raw/gate3_random_v2/repaired/ar_deadlock_investigation.jsonl"
  : > "$GATE3_BOUNDARY_TRACE"
  rm -f "$seed_out/results.xml" "$seed_out/coverage.json" "$seed_out/events.jsonl"
  export COCOTB_RANDOM_SEED="0x$seed"
  {
    echo "git_commit=$(env -u DYLD_LIBRARY_PATH git rev-parse HEAD)"
    echo "architecture=A"
    echo "seed=0x$seed"
    echo "plan=$plan"
    echo "configuration=24 anchors plus 512 genuinely random operations with bounded drain"
    echo "verilator=$(verilator --version | head -1)"
  } >"$seed_out/run.log"
  python3 - <<'PY' >>"$seed_out/run.log" 2>&1
import os
from pathlib import Path
from cocotb_tools.runner import get_runner
root = Path(os.environ["ROOT"])
out = Path(os.environ["GATE3_OUT"])
rtl = [Path(p) for p in os.environ["GATE3_RTL"].split(":")]
runner = get_runner("verilator")
runner.build(sources=rtl, hdl_toplevel="axi_fabric_a", build_dir=out / "work", always=True,
             build_args=["-Wno-fatal"])
runner.test(hdl_toplevel="axi_fabric_a", test_module="test_axi_fabric_a_random_v2",
            test_dir=root / "tb/cocotb", results_xml=str(out / "results.xml"))
PY
python3 - "$seed_out/results.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
root=ET.parse(sys.argv[1]).getroot(); suite=root.find("testsuite")
if suite is None and root.tag == "testsuite": suite=root
assert suite is not None
cases = suite.findall("testcase")
if not cases and root.tag == "testsuites":
    cases = root.findall(".//testcase")
failures = [case for case in cases if case.find("failure") is not None or case.find("error") is not None]
assert not failures and suite.attrib.get("errors","0")=="0" and suite.attrib.get("failures","0")=="0", failures
PY
  python3 - "$seed_out" <<'PY'
import json,os,sys
from pathlib import Path
c=json.loads((Path(sys.argv[1])/"coverage.json").read_text())
if not os.environ.get("GATE3_ALLOW_SHORT_PLAN"):
    assert c["random_operations"] == 512
    assert all(c["accepted_reads"]) and all(c["accepted_writes"])
    assert all(c["targets"]) and all(c["lengths"])
PY
  python3 - <<'PY'
from pathlib import Path
import shutil,os
p=Path(os.environ["GATE3_OUT"])/"work"
if p.exists(): shutil.rmtree(p)
PY
  echo "PASS seed=0x$seed"
done

if [ -z "$requested_seed" ] && [ -z "$requested_plan" ]; then
python3 - "$OUT" <<'PY'
import json,sys
from pathlib import Path
out=Path(sys.argv[1]); files=sorted(out.glob("seed_*/coverage.json")); assert len(files)==5
agg={"seeds":[],"accepted_reads":[0]*3,"accepted_writes":[0]*3,"targets":[0]*4,"lengths":[0]*16,
     "random_max_live_reads":0,"random_max_live_writes":0,"random_all_manager_active_cycles":0,
     "target_aw_stalls":0,"target_ar_stalls":0,"target_w_stalls":0,"manager_b_stalls":0,"manager_r_stalls":0,"response_delays":0}
for p in files:
 c=json.loads(p.read_text()); agg["seeds"].append(c["seed"])
 for k in ("accepted_reads","accepted_writes","targets","lengths"): agg[k]=[a+b for a,b in zip(agg[k],c[k])]
 for k in ("random_max_live_reads","random_max_live_writes","random_all_manager_active_cycles","target_aw_stalls","target_ar_stalls","target_w_stalls","manager_b_stalls","manager_r_stalls","response_delays"): agg[k]=max(agg[k],c[k])
assert all(agg["accepted_reads"]) and all(agg["accepted_writes"])
assert all(agg["targets"]) and all(agg["lengths"])
assert agg["random_all_manager_active_cycles"]>0
assert agg["target_aw_stalls"] and agg["target_ar_stalls"] and agg["target_w_stalls"]
assert agg["manager_b_stalls"] and agg["manager_r_stalls"] and agg["response_delays"]
(out/"aggregate_coverage.json").write_text(json.dumps(agg,indent=2)+"\n")
PY
fi
echo "PASS Gate-3 Task-1B concurrent qualification"
