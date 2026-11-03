"""Compact synthesis and routed timing summary for the frozen PPA run."""
import csv
import json
from pathlib import Path
import re
import sys


def direct_synth_counts(path: Path) -> dict:
    text = path.read_text(errors="replace")
    blocks = re.findall(r"=== axi_fabric_a ===\n(.*?)(?=\n===|\nWarnings:)", text, re.S)
    if not blocks:
        return {}
    return {name: int(count) for count, name in
            re.findall(r"^\s*(\d+)\s+(LUT4|TRELLIS_FF|CCU2C|PFUMX|DP16KD|TRELLIS_RAMW)\s*$",
                       blocks[-1], re.M)}


def wrapped_synth_counts(path: Path) -> dict:
    text = path.read_text(errors="replace")
    blocks = re.findall(r"=== design hierarchy ===\n(.*?)(?=\nWarnings:)", text, re.S)
    if not blocks:
        return {}
    return {name: int(count) for count, name in
            re.findall(r"^\s*(\d+)\s+(LUT4|TRELLIS_FF|CCU2C|PFUMX|DP16KD|TRELLIS_RAMW)\s*$",
                       blocks[-1], re.M)}


def main():
    root = Path(sys.argv[1])
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
        "direct_fabric_synthesis": direct_synth_counts(root / "direct/yosys.log"),
        "wrapper_synthesis": wrapped_synth_counts(root / "wrapped/yosys.log"),
        "route_summary_csv": str(summary),
    }
    (root / "ppa_summary.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
