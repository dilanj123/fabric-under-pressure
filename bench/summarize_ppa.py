"""Summarize the frozen synthesis and routed timing reports."""
import csv
import json
from pathlib import Path
import re
import sys


REQUIRED_RESOURCES = {"LUT4", "TRELLIS_FF"}
OPTIONAL_RESOURCES = {"CCU2C", "PFUMX", "DP16KD", "TRELLIS_RAMW"}
RESOURCE_NAMES = REQUIRED_RESOURCES | OPTIONAL_RESOURCES


class PPAReportError(ValueError):
    """A Yosys report cannot be safely summarized."""


def _resource_counts(block: str, context: str) -> dict:
    counts = {}
    for line in block.splitlines():
        stripped = line.strip()
        # A mention of a known cell type that is not a count row is malformed,
        # rather than evidence of zero use.
        if any(re.search(rf"\b{re.escape(name)}\b", stripped) for name in RESOURCE_NAMES):
            match = re.fullmatch(r"(\d+)\s+(LUT4|TRELLIS_FF|CCU2C|PFUMX|DP16KD|TRELLIS_RAMW)", stripped)
            if not match:
                raise PPAReportError(f"{context}: malformed resource count line: {stripped!r}")
            count, name = int(match.group(1)), match.group(2)
            if name in counts:
                raise PPAReportError(f"{context}: duplicate resource count for {name}")
            counts[name] = count
    missing = REQUIRED_RESOURCES - counts.keys()
    if missing:
        raise PPAReportError(f"{context}: missing required resource counts {sorted(missing)}")
    for name in OPTIONAL_RESOURCES:
        counts.setdefault(name, 0)
    return {name: counts[name] for name in sorted(RESOURCE_NAMES)}


def direct_synth_counts(path: Path, expected_top: str) -> dict:
    text = path.read_text(errors="replace")
    if re.search(r"(?:ERROR:|synthesis failed)", text, re.IGNORECASE):
        raise PPAReportError(f"{path}: synthesis log reports failure")
    blocks = re.findall(rf"^=== {re.escape(expected_top)} ===\n(.*?)(?=^=== |^Warnings:)",
                        text, re.S | re.M)
    if not blocks:
        wrong = re.findall(r"^=== (axi_fabric_[ab]) ===", text, re.M)
        if wrong:
            raise PPAReportError(f"{path}: expected DUT top {expected_top}, found {wrong[-1]}")
        raise PPAReportError(f"{path}: missing Yosys report section for DUT top {expected_top}")
    candidates = [block for block in blocks if "Local Count, excluding submodules." in block and
                  re.search(r"^\s*\d+\s+cells\s*$", block, re.M)]
    if not candidates:
        raise PPAReportError(f"{path}: unsupported Yosys local-stat report format for {expected_top}")
    return _resource_counts(candidates[-1], f"{path} ({expected_top})")


def wrapped_synth_counts(path: Path, expected_top: str) -> dict:
    text = path.read_text(errors="replace")
    if re.search(r"(?:ERROR:|synthesis failed)", text, re.IGNORECASE):
        raise PPAReportError(f"{path}: synthesis log reports failure")
    blocks = re.findall(r"^=== design hierarchy ===\n(.*?)(?=^=== |^Warnings:)",
                        text, re.S | re.M)
    if not blocks:
        raise PPAReportError(f"{path}: missing Yosys design hierarchy report section")
    block = blocks[-1]
    if "Count including submodules." not in block or "arch_fabric_wrapper" not in block:
        raise PPAReportError(f"{path}: unsupported or wrong wrapped hierarchy report")
    if not re.search(rf"^\s*\d+\s+{re.escape(expected_top)}\s*$", block, re.M):
        raise PPAReportError(f"{path}: wrapped hierarchy does not contain expected DUT {expected_top}")
    if not re.search(r"^\s*\d+\s+cells\s*$", block, re.M):
        raise PPAReportError(f"{path}: wrapped hierarchy has no total cell count")
    return _resource_counts(block, f"{path} (arch_fabric_wrapper containing {expected_top})")


def _read_run_config(root: Path) -> tuple[str, str]:
    config = root / "run_config.txt"
    if not config.is_file():
        raise PPAReportError(f"{root}: missing run_config.txt; refusing to infer DUT top")
    values = {}
    for line in config.read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip()
    arch = values.get("architecture")
    top = values.get("dut_top")
    expected = {"A": "axi_fabric_a", "B": "axi_fabric_b"}
    if arch not in expected or top != expected[arch]:
        raise PPAReportError(f"{config}: wrong or malformed DUT selection ({arch!r}, {top!r})")
    return arch, top


def main():
    root = Path(sys.argv[1])
    _, top = _read_run_config(root)
    matrix = list(csv.DictReader((root / "route_matrix.csv").open()))
    rows = []
    for row in matrix:
        report_path = Path(row["report"])
        report = json.loads(report_path.read_text()) if report_path.exists() else {}
        clocks = [value for value in report.get("fmax", {}).values()
                  if isinstance(value, dict) and isinstance(value.get("achieved"), (int, float))]
        achieved = max((clock["achieved"] for clock in clocks), default=None)
        util = report.get("utilization", {})
        def used(name):
            cell = util.get(name, {})
            return cell.get("used")
        paths = report.get("critical_paths", [])
        critical = paths[0] if paths else {}
        path_steps = critical.get("path", [])
        path_delay_ns = sum(float(step.get("delay", 0.0)) for step in path_steps)
        path_start = path_steps[0].get("from", {}).get("cell") if path_steps else None
        path_end = path_steps[-1].get("to", {}).get("cell") if path_steps else None
        target_mhz = int(row["frequency_mhz"])
        rows.append({
            "frequency_mhz": target_mhz, "seed": int(row["seed"]),
            "exit_code": int(row["exit_code"]), "achieved_mhz": achieved,
            "critical_path_delay_ns": path_delay_ns,
            "wns_ns_from_routed_path": (1000.0 / target_mhz - path_delay_ns),
            "timing_clean": row["timing_clean"],
            "trellis_comb": used("TRELLIS_COMB"), "trellis_ff": used("TRELLIS_FF"),
            "dp16kd": used("DP16KD"), "trellis_ramw": used("TRELLIS_RAMW"),
            "critical_from": path_start, "critical_to": path_end,
            "route_log": row["route_log"], "report": row["report"],
        })
    summary = root / "route_summary.csv"
    with summary.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]) if rows else [])
        writer.writeheader()
        writer.writerows(rows)

    all_seed = []
    for freq in sorted({x["frequency_mhz"] for x in rows}):
        group = [x for x in rows if x["frequency_mhz"] == freq and x["seed"] in range(1, 6)]
        if len(group) == 5:
            all_seed.append({"frequency_mhz": freq,
                             "all_seeds_timing_clean": all(x["timing_clean"] == "true" for x in group),
                             "seeds": [x["seed"] for x in group],
                             "min_achieved_mhz": min((x["achieved_mhz"] for x in group
                                                       if x["achieved_mhz"] is not None), default=None)})
    payload = {
        "device": "LFE5U-45F", "package": "CABGA381", "speed_grade": 6,
        "route_attempts": len(rows), "all_seed_frequency_results": all_seed,
        "highest_all_seed_timing_clean_mhz": max(
            (x["frequency_mhz"] for x in all_seed if x["all_seeds_timing_clean"]), default=None),
        "direct_fabric_synthesis": direct_synth_counts(root / "direct/yosys.log", top),
        "wrapper_synthesis": wrapped_synth_counts(root / "wrapped/yosys.log", top),
        "route_summary_csv": str(summary),
    }
    (root / "ppa_summary.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
