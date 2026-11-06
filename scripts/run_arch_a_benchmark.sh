#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "${ROOT}/scripts/oss_cad_env.sh"
export PYTHONPATH="$ROOT/bench:$ROOT/tb/model:$ROOT/tb/cocotb${PYTHONPATH:+:$PYTHONPATH}"
export ROOT
export CXXFLAGS="${CXXFLAGS:-} -std=c++17"
export LIBPYTHON_LOC="${LIBPYTHON_LOC:-$(find "${OSS_CAD_SUITE_LIB}" -maxdepth 1 -name 'libpython*.dylib' -print -quit)}"
export DYLD_LIBRARY_PATH="${OSS_CAD_SUITE_LIB}${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"

OUT="${ARCH_BENCH_OUT_ROOT:-$ROOT/results/raw/arch_a_qualification}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
ln -sfn "${OSS_CAD_SUITE_LIB}" "$OUT/lib"
export ARCH_BENCH_OUT_ROOT="$OUT"
ARCH="${ARCH_BENCH_ARCH:-A}"
if [[ "$ARCH" == "A" ]]; then
  DUT_TOP=axi_fabric_a
  rtl=(
    rtl/fabric_addr_map_pkg.sv rtl/axi_address_decoder.sv rtl/axi_request_legal.sv
    rtl/axi_outstanding_tracker.sv rtl/axi_write_owner.sv rtl/axi_write_state_bank.sv
    rtl/axi_read_state_bank.sv rtl/axi_rr_arbiter_3.sv rtl/axi_rr_arbiter_4.sv
    rtl/axi_aw_target_scheduler_a.sv rtl/axi_aw_target_path_a.sv
    rtl/axi_ar_target_scheduler_a.sv rtl/axi_ar_target_path_a.sv rtl/axi_w_target_path.sv
    rtl/axi_b_response_router.sv rtl/axi_r_response_router.sv rtl/axi_s3_error_target.sv
    rtl/axi_fabric_a.sv
  )
  BUILD_ARGS=(-Wno-fatal)
elif [[ "$ARCH" == "B" ]]; then
  DUT_TOP=axi_fabric_b
  rtl=(
    rtl/fabric_addr_map_pkg.sv rtl/axi_address_decoder.sv rtl/axi_request_legal.sv
    rtl/axi_outstanding_tracker.sv rtl/axi_write_owner.sv rtl/axi_write_state_bank.sv
    rtl/axi_read_state_bank.sv rtl/axi_rr_arbiter_3.sv rtl/axi_rr_arbiter_4.sv
    rtl/axi_qos_aging_arbiter_3.sv rtl/axi_aw_target_scheduler_b.sv
    rtl/axi_aw_target_path_b.sv rtl/axi_ar_target_scheduler_b.sv
    rtl/axi_ar_target_path_b.sv rtl/axi_w_target_path.sv rtl/axi_b_response_router.sv
    rtl/axi_r_response_router.sv rtl/axi_s3_error_target.sv rtl/axi_fabric_b.sv
  )
  BUILD_ARGS=(-Wno-fatal -DARCHITECTURE_B)
else
  echo "ARCH_BENCH_ARCH must be A or B" >&2
  exit 2
fi
export ARCH_BENCH_ARCH="$ARCH" ARCH_BENCH_TOP="$DUT_TOP"
export ARCH_BENCH_RTL="$(IFS=:; echo "${rtl[*]}")"
export ARCH_BENCH_BUILD_ARGS="${BUILD_ARGS[*]}"
export ARCH_BENCH_INTENTS_PER_MANAGER="${ARCH_BENCH_INTENTS_PER_MANAGER:-50000}"
QUAL="${ARCH_BENCH_QUALIFICATION:-0}"
export ARCH_BENCH_QUALIFICATION="$QUAL"
if [[ "$QUAL" == 1 ]]; then
  export ARCH_BENCH_WARMUP="${ARCH_BENCH_WARMUP:-25}"
  export ARCH_BENCH_SAMPLES="${ARCH_BENCH_SAMPLES:-75}"
else
  export ARCH_BENCH_WARMUP="${ARCH_BENCH_WARMUP:-500}"
  export ARCH_BENCH_SAMPLES="${ARCH_BENCH_SAMPLES:-5000}"
fi

WORKLOADS="${ARCH_BENCH_WORKLOADS:-$(seq -f 'W%02g' 0 13 | paste -sd, -)}"
SEEDS="${ARCH_BENCH_SEEDS:-0xFABC0001,0xFABC0002,0xFABC0003,0xFABC0004,0xFABC0005}"
export ARCH_BENCH_WORKLOADS="$WORKLOADS"
export ARCH_BENCH_SEEDS="$SEEDS"

python3 - <<'PY' 2>&1 | tee "$OUT/runner.log"
import hashlib, json, os, re, shutil, subprocess, xml.etree.ElementTree as ET
from pathlib import Path
from cocotb_tools.runner import get_runner

root = Path(os.environ["ROOT"])
out_root = Path(os.environ["ARCH_BENCH_OUT_ROOT"])
rtl = [(root / p).resolve() for p in os.environ["ARCH_BENCH_RTL"].split(":")]
workloads = os.environ["ARCH_BENCH_WORKLOADS"].split(",")
seeds = os.environ["ARCH_BENCH_SEEDS"].split(",")
arch = os.environ["ARCH_BENCH_ARCH"]
top = os.environ["ARCH_BENCH_TOP"]
def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
manifest = {
    "architecture": arch, "dut_top": top,
    "rtl_sources": [{"path": str(p.relative_to(root)), "sha256": sha(p)} for p in rtl],
    "benchmark_engine": {"path": "tb/cocotb/test_axi_fabric_a_benchmark.py",
                         "sha256": sha(root / "tb/cocotb/test_axi_fabric_a_benchmark.py")},
    "generator": {"path": "bench/benchmark_plan.py", "sha256": sha(root / "bench/benchmark_plan.py")},
    "workload": {"path": "bench/workloads.yaml", "sha256": sha(root / "bench/workloads.yaml")},
    "runner": {"path": "scripts/run_arch_a_benchmark.sh", "sha256": sha(root / "scripts/run_arch_a_benchmark.sh")},
    "wrapper": {"path": "bench/arch_fabric_wrapper.sv", "sha256": sha(root / "bench/arch_fabric_wrapper.sv")},
    "endpoint": {"queue_depth_per_target": 8, "read_start_latency_cycles": 2,
                 "b_response_latency_cycles": 2, "r_rate_beats_per_cycle": 1,
                 "response_order": "per-target FIFO by direction"},
    "warmup": int(os.environ["ARCH_BENCH_WARMUP"]),
    "samples": int(os.environ["ARCH_BENCH_SAMPLES"]),
    "qualification_only": os.environ["ARCH_BENCH_QUALIFICATION"] == "1",
    "workloads": workloads, "seeds": [f"0x{int(x,0):08X}" for x in seeds],
    "verilator": subprocess.check_output(["verilator", "--version"], text=True).strip(),
    "python": subprocess.check_output(["python3", "--version"], text=True).strip(),
}
manifest_path = out_root / "source_manifest.json"
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
manifest_sha = sha(manifest_path)
runner = get_runner("verilator")
build = out_root / "build"
runner.build(sources=rtl, hdl_toplevel=top, build_dir=build,
             always=True, build_args=os.environ["ARCH_BENCH_BUILD_ARGS"].split())

for workload in workloads:
    if not re.fullmatch(r"W(?:0[0-9]|1[0-3])", workload):
        raise SystemExit(f"invalid workload {workload}")
    for seed_text in seeds:
        seed = int(seed_text, 0)
        folder = out_root / workload / f"seed_{seed:08X}"
        folder.mkdir(parents=True, exist_ok=True)
        os.environ["ARCH_BENCH_WORKLOAD"] = workload
        os.environ["ARCH_BENCH_SEED"] = f"0x{seed:08X}"
        os.environ["ARCH_BENCH_OUT"] = str(folder)
        os.environ["COCOTB_RANDOM_SEED"] = f"0x{seed:08X}"
        (folder / "run_config.json").write_text(json.dumps({
            "architecture": arch, "dut_top": top, "source_manifest_sha256": manifest_sha,
            "workload": workload,
            "seed": f"0x{seed:08X}",
            "warmup": int(os.environ["ARCH_BENCH_WARMUP"]),
            "samples": int(os.environ["ARCH_BENCH_SAMPLES"]),
            "intent_limit_per_manager": int(os.environ["ARCH_BENCH_INTENTS_PER_MANAGER"]),
            "qualification_only": os.environ["ARCH_BENCH_QUALIFICATION"] == "1",
        }, indent=2) + "\n")
        xml = folder / "results.xml"
        runner.test(hdl_toplevel=top,
                    test_module="test_axi_fabric_a_benchmark",
                    test_dir=root / "tb/cocotb", results_xml=str(xml))
        doc = ET.parse(xml).getroot()
        cases = list(doc.iter("testcase"))
        errors = [x for c in cases for x in list(c.iter("failure")) + list(c.iter("error"))]
        skipped = [x for c in cases for x in c.iter("skipped")]
        if len(cases) != 1 or errors or skipped:
            raise SystemExit(f"invalid cocotb XML for {workload} {seed_text}: cases={len(cases)}")
        meta = json.loads((folder / "run_meta.json").read_text())
        if meta["architecture"] != arch or meta["dut_top"] != top or \
                meta["source_manifest_sha256"] != manifest_sha:
            raise SystemExit(f"DUT/source metadata mismatch for {workload} {seed_text}")
        if meta["measured_count_by_manager"] != [
                meta["retained_completions_per_manager"] if m in meta["active_managers"] else 0
                for m in range(3)]:
            raise SystemExit(f"sample quota mismatch for {workload} {seed_text}")
        print(f"PASS {workload} seed=0x{seed:08X} active={meta['active_managers']} "
              f"completed={meta['completion_count_by_manager']} "
              f"cycles={meta['measurement_cycles']}")

# Generated C++ and simulator products are disposable; raw logs/XML and
# transaction traces remain in the per-run folders.
shutil.rmtree(build, ignore_errors=True)
PY
