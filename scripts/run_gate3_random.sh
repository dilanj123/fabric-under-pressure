#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
export PYTHONPATH="$ROOT/tb/model:$ROOT/tb/cocotb:$ROOT${PYTHONPATH:+:$PYTHONPATH}"
export ROOT
export CXXFLAGS="${CXXFLAGS:-} -std=c++17"
export LIBPYTHON_LOC="${LIBPYTHON_LOC:-$(find /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib -maxdepth 1 -name 'libpython*.dylib' -print -quit)}"
export DYLD_LIBRARY_PATH="/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"

OUT="$ROOT/results/raw/gate3_random"
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
  export COCOTB_RANDOM_SEED="0x$seed"
  {
    echo "git_commit=$(env -u DYLD_LIBRARY_PATH git rev-parse HEAD)"
    echo "architecture=A"
    echo "seed=0x$seed"
    echo "plan=$plan"
    echo "configuration=96 planned operations plus four-entry pressure prologue and 10000 idle qualification cycles"
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
runner.test(hdl_toplevel="axi_fabric_a", test_module="test_axi_fabric_a_random",
            test_dir=root / "tb/cocotb", results_xml=str(out / "results.xml"))
PY
  python3 - "$seed_out/results.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
suite = root.find("testsuite")
if suite is None and root.tag == "testsuite": suite = root
assert suite is not None
assert suite.attrib.get("errors", "0") == "0", suite.attrib
assert suite.attrib.get("failures", "0") == "0", suite.attrib
PY
  python3 - "$seed_out" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1]) / "coverage.json"
c = json.loads(p.read_text())
assert c["max_live_reads"] >= 4 and c["max_live_writes"] >= 4, c
PY
  python3 - <<'PY'
from pathlib import Path
import shutil, os
p=Path(os.environ["GATE3_OUT"])/"work"
if p.exists(): shutil.rmtree(p)
PY
  echo "PASS seed=0x$seed"
done

python3 - "$OUT" <<'PY'
import json, sys
from pathlib import Path
out = Path(sys.argv[1])
files = sorted(out.glob("seed_*/coverage.json"))
assert files, "no Gate-3 coverage files"
aggregate = {"seeds": [], "targets": [0]*4, "lengths": [0]*16,
             "accepted_reads": [0]*3, "accepted_writes": [0]*3,
             "resets": 0, "max_live_reads": 0, "max_live_writes": 0,
             "pressure_depth_four": 0, "same_id_cross_manager": 0,
             "out_of_order_completions": 0, "same_target_contention": 0,
             "target_aw_stalls": 0, "target_ar_stalls": 0,
             "target_w_stalls": 0, "response_delays": 0,
             "manager_b_stalls": 0, "manager_r_stalls": 0,
             "all_manager_active_cycles": 0}
for path in files:
    c = json.loads(path.read_text())
    aggregate["seeds"].append(c["seed"])
    for key in ("targets", "lengths", "accepted_reads", "accepted_writes"):
        aggregate[key] = [a+b for a,b in zip(aggregate[key], c[key])]
    for key in ("resets", "pressure_depth_four", "target_aw_stalls",
                "target_ar_stalls", "target_w_stalls", "response_delays",
                "manager_b_stalls", "manager_r_stalls",
                "all_manager_active_cycles"):
        aggregate[key] += c[key]
    for key in ("max_live_reads", "max_live_writes"):
        aggregate[key] = max(aggregate[key], c[key])
    aggregate["same_id_cross_manager"] |= c["same_id_cross_manager"]
    aggregate["out_of_order_completions"] |= c["out_of_order_completions"]
    aggregate["same_target_contention"] |= c["same_target_contention"]
assert all(aggregate["accepted_reads"]), aggregate
assert all(aggregate["accepted_writes"]), aggregate
assert all(aggregate["targets"]), aggregate
assert all(aggregate["lengths"]), aggregate
assert aggregate["max_live_reads"] >= 4 and aggregate["max_live_writes"] >= 4, aggregate
assert aggregate["resets"] >= 2, aggregate
assert aggregate["same_id_cross_manager"] and aggregate["out_of_order_completions"], aggregate
assert aggregate["same_target_contention"] and aggregate["all_manager_active_cycles"], aggregate
assert aggregate["target_aw_stalls"] and aggregate["target_ar_stalls"] and aggregate["target_w_stalls"], aggregate
assert aggregate["manager_b_stalls"] and aggregate["manager_r_stalls"] and aggregate["response_delays"], aggregate
(out / "aggregate_coverage.json").write_text(json.dumps(aggregate, indent=2) + "\n")
PY
echo "PASS Gate-3 random qualification"
