"""Generate the four small A/B figures from processed benchmark/PPA tables."""
from __future__ import annotations

import csv
import json
from pathlib import Path
import statistics
import sys

import matplotlib.pyplot as plt
import numpy as np


def csv_rows(path):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def main():
    processed = Path(sys.argv[1] if len(sys.argv) > 1 else "results/processed/ab_comparison")
    aroot = Path(sys.argv[2] if len(sys.argv) > 2 else "results/raw/arch_a_matched_v2")
    broot = Path(sys.argv[3] if len(sys.argv) > 3 else "results/raw/arch_b_full_v1")
    figures = processed / "figures"
    figures.mkdir(parents=True, exist_ok=True)
    rows = csv_rows(processed / "matched_median_of_five.csv")
    per_seed = csv_rows(processed / "matched_per_seed.csv")
    workloads = [f"W{i:02}" for i in range(1, 14)]

    # Admission P99, split by manager and direction. Values are medians of five
    # per-seed nearest-method P99 samples; each active run retains 5,000 samples.
    fig, axes = plt.subplots(1, 3, figsize=(15, 4.8), sharey=True)
    styles = {"A": "-", "B": "--"}
    colors = {"read": "#276FBF", "write": "#D1495B"}
    for manager, ax in enumerate(axes):
        for direction in ("read", "write"):
            for architecture in ("A", "B"):
                points = [r for r in rows if r["manager"] == str(manager) and
                          r["direction"] == direction and r["metric"] == "admission_p99"]
                values = {r["workload"]: float(r[f"{architecture}_median"]) for r in points}
                xs = [i for i, w in enumerate(workloads) if w in values]
                ax.plot(xs, [values[workloads[i]] for i in xs], marker="o",
                        linestyle=styles[architecture], color=colors[direction],
                        label=f"{architecture} {direction}")
        ax.set_title(f"M{manager}"); ax.set_xticks(range(len(workloads)), workloads, rotation=45)
        ax.grid(True, axis="y", alpha=.25)
    axes[0].set_ylabel("Admission P99 (cycles)")
    axes[-1].legend(fontsize=8, loc="upper left", bbox_to_anchor=(1.02, 1))
    fig.suptitle("Address admission P99 — median of five seeds; 5,000 retained samples/active manager")
    fig.tight_layout(); fig.savefig(figures / "admission_p99.png", dpi=180); plt.close(fig)

    # Paired per-seed payload throughput: sum read+write bytes for the same
    # manager/seed, divide by its shared measurement window, then median seeds.
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.8))
    for ax, manager_set, title in ((axes[0], [1], "M1 read + write"),
                                   (axes[1], [0, 1, 2], "All active managers")):
        data = {arch: [] for arch in ("A", "B")}
        for workload in workloads:
            for arch in ("A", "B"):
                seeds = sorted({r["seed"] for r in per_seed if r["workload"] == workload})
                values = []
                for seed in seeds:
                    selected = [r for r in per_seed if r["workload"] == workload and
                                r["seed"] == seed and int(r["manager"]) in manager_set and
                                r["metric"] == "payload_bytes_per_cycle"]
                    values.append(sum(float(r[arch]) for r in selected))
                data[arch].append(statistics.median(values) if values else 0.0)
        x = np.arange(len(workloads)); width = .38
        ax.bar(x-width/2, data["A"], width, label="A", color="#276FBF")
        ax.bar(x+width/2, data["B"], width, label="B", color="#D1495B")
        ax.set_title(title); ax.set_ylabel("Payload throughput (bytes/cycle)")
        ax.set_xticks(x, workloads, rotation=45); ax.grid(True, axis="y", alpha=.25)
    axes[0].legend(); fig.suptitle("Matched throughput — median of five paired seed results")
    fig.tight_layout(); fig.savefig(figures / "throughput.png", dpi=180); plt.close(fig)

    # Scheduler opportunity-loss indicator plus equal-demand grant-rate Jain.
    fig, ax = plt.subplots(figsize=(10, 5))
    selected_workloads = ["W08", "W10", "W12", "W13"]
    x = np.arange(len(selected_workloads)); width = .12
    for manager in range(3):
        for arch_i, arch in enumerate(("A", "B")):
            vals = []
            for workload in selected_workloads:
                r = next(r for r in rows if r["workload"] == workload and
                         r["manager"] == str(manager) and r["direction"] == "read" and
                         r["metric"] == "max_lost_service_opportunities")
                vals.append(float(r[f"{arch}_median"]))
            offset = (manager*2 + arch_i - 2.5) * width
            ax.bar(x+offset, vals, width, label=f"M{manager} {arch}",
                   color=("#276FBF" if arch == "A" else "#D1495B"),
                   alpha=1.0 - manager*.16)
    ax.set_xticks(x, selected_workloads); ax.set_ylabel("Median per-run max eligible service losses")
    ax.set_title("Scheduler waiting under contention (not target-backpressure cycles)")
    ax.grid(True, axis="y", alpha=.25)
    detail_a=json.loads((aroot/"run_summary.json").read_text())
    detail_b=json.loads((broot/"run_summary.json").read_text())
    jain_a=statistics.median(d["w12_jain_address_grant_rate"] for d in detail_a if d["workload"]=="W12")
    jain_b=statistics.median(d["w12_jain_address_grant_rate"] for d in detail_b if d["workload"]=="W12")
    ax.text(.99,.97,f"W12 Jain grant-rate index: A {jain_a:.6f} | B {jain_b:.6f}\nMedian of 5 seeds",
            ha="right",va="top",transform=ax.transAxes,fontsize=9,
            bbox={"boxstyle":"round","facecolor":"white","alpha":.85})
    ax.legend(ncol=3,fontsize=8); fig.tight_layout()
    fig.savefig(figures/"starvation_fairness.png",dpi=180);plt.close(fig)

    # Direct synthesis plus routed wrapper all-seed threshold.
    ppa_a_root = Path("results/raw/arch_a_ppa_matched_v1")
    ppa_b_root = Path("results/raw/arch_b_ppa_matched_v1")
    ppa_a=json.loads((ppa_a_root/"ppa_summary.json").read_text())
    ppa_b=json.loads((ppa_b_root/"ppa_summary.json").read_text())
    route_rows = []
    for architecture, root in (("A", ppa_a_root), ("B", ppa_b_root)):
        for row in csv_rows(root / "route_summary.csv"):
            route_rows.append({"architecture": architecture, **row})
    with (processed / "ppa_route_comparison.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(route_rows[0]), lineterminator="\n")
        writer.writeheader(); writer.writerows(route_rows)
    ppa_comparison = {
        "device": ppa_a["device"], "package": ppa_a["package"],
        "speed_grade": ppa_a["speed_grade"], "route_attempts_per_architecture": {
            "A": ppa_a["route_attempts"], "B": ppa_b["route_attempts"]},
        "all_seed_timing_clean_target_mhz": {
            "A": ppa_a["highest_all_seed_timing_clean_mhz"],
            "B": ppa_b["highest_all_seed_timing_clean_mhz"]},
        "direct_fabric_synthesis": {"A": ppa_a["direct_fabric_synthesis"],
                                     "B": ppa_b["direct_fabric_synthesis"]},
        "wrapper_synthesis": {"A": ppa_a["wrapper_synthesis"],
                              "B": ppa_b["wrapper_synthesis"]},
        "route_csv": "ppa_route_comparison.csv",
    }
    (processed / "ppa_resource_comparison.json").write_text(
        json.dumps(ppa_comparison, indent=2) + "\n")
    fig, axes=plt.subplots(1,2,figsize=(9,4.5))
    for ax,key,title in ((axes[0],"direct_fabric_synthesis","Direct Fabric synthesis"),
                         (axes[1],"wrapper_synthesis","Common wrapper synthesis")):
        vals=[ppa_a[key],ppa_b[key]]; x=np.arange(2); width=.34
        ax.bar(x-width/2,[v.get("LUT4",0) for v in vals],width,label="LUT4",color="#276FBF")
        ax.bar(x+width/2,[v.get("TRELLIS_FF",0) for v in vals],width,label="FF",color="#D1495B")
        ax.set_xticks(x,["A","B"]);ax.set_title(title);ax.grid(True,axis="y",alpha=.25);ax.legend()
    fig.suptitle("Synthesis resources and routed timing are reported separately")
    fig.text(.5,.01,f"All-five-seed timing-clean target: A {ppa_a['highest_all_seed_timing_clean_mhz']} MHz; B {ppa_b['highest_all_seed_timing_clean_mhz']} MHz",
             ha="center",fontsize=9)
    fig.tight_layout(rect=(0,.05,1,.93));fig.savefig(figures/"resources_routed_timing.png",dpi=180);plt.close(fig)
    print(f"generated four figures under {figures}")


if __name__ == "__main__":
    main()
