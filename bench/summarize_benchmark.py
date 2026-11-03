"""Recompute canonical benchmark latency and throughput from handshake records."""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import sys

import numpy as np

if np.__version__ != "2.3.5":
    raise RuntimeError(f"frozen percentile environment requires NumPy 2.3.5, got {np.__version__}")


def nearest(values, percentile):
    return float(np.percentile(np.asarray(values, dtype=np.float64), percentile,
                               method="nearest")) if values else None


def summarize_run(folder: Path) -> tuple[list[dict], dict]:
    meta = json.loads((folder / "run_meta.json").read_text())
    events = [json.loads(line) for line in (folder / "transactions.jsonl").read_text().splitlines()]
    txs = [row for row in events if "complete_cycle" in row]
    start, end = meta["measurement_start_cycle"], meta["measurement_end_cycle"]
    window = meta["measurement_cycles"]
    rows = []
    for manager in meta["active_managers"]:
        for direction in ("read", "write"):
            sample = [tx for tx in txs if tx["manager"] == manager and
                      tx["direction"] == direction and tx["sampled_latency"]]
            if not sample:
                continue
            admission = [tx["t_addr_accept"] - tx["t_present"] for tx in sample]
            first_response = [tx["t_first_resp"] - tx["t_addr_accept"] for tx in sample]
            accepted_response = [tx["t_complete"] - tx["t_addr_accept"] for tx in sample]
            end_to_end = [tx["t_complete"] - tx["t_present"] for tx in sample]
            pending = [tx["max_pending_cycles"] for tx in sample]
            opp_by_tx = [sum(start <= cycle <= end for cycle in tx["opportunity_loss_cycles"])
                         for tx in sample]
            stalls = {channel: sum(
                sum(start <= cycle <= end for cycle in tx["target_backpressure_event_cycles"][channel])
                for tx in txs if tx["manager"] == manager and tx["direction"] == direction)
                for channel in ("aw", "ar", "w")}
            data_phase = [tx["t_wlast_manager"] - tx["t_addr_accept"] for tx in sample
                          if direction == "write"]
            b_after_w = [tx["t_complete"] - tx["t_wlast_manager"] for tx in sample
                         if direction == "write"]
            beat_field = "manager_r_cycles" if direction == "read" else "manager_w_cycles"
            payload_bytes = 8 * sum(sum(start <= cycle <= end for cycle in tx[beat_field])
                                    for tx in txs if tx["manager"] == manager and
                                    tx["direction"] == direction)
            row = {
                "workload": meta["workload"], "seed": meta["seed"], "manager": manager,
                "direction": direction, "samples": len(sample), "measurement_cycles": window,
                "admission_p50": nearest(admission, 50), "admission_p95": nearest(admission, 95),
                "admission_p99": nearest(admission, 99), "admission_max": max(admission),
                "first_response_p50": nearest(first_response, 50),
                "first_response_p95": nearest(first_response, 95),
                "first_response_p99": nearest(first_response, 99),
                "first_response_max": max(first_response),
                "accepted_response_p50": nearest(accepted_response, 50),
                "accepted_response_p95": nearest(accepted_response, 95),
                "accepted_response_p99": nearest(accepted_response, 99),
                "accepted_response_max": max(accepted_response),
                "write_data_phase_p50": nearest(data_phase, 50),
                "write_data_phase_p95": nearest(data_phase, 95),
                "write_data_phase_p99": nearest(data_phase, 99),
                "write_data_phase_max": max(data_phase) if data_phase else None,
                "write_b_after_w_p50": nearest(b_after_w, 50),
                "write_b_after_w_p95": nearest(b_after_w, 95),
                "write_b_after_w_p99": nearest(b_after_w, 99),
                "write_b_after_w_max": max(b_after_w) if b_after_w else None,
                "end_to_end_p50": nearest(end_to_end, 50),
                "end_to_end_p95": nearest(end_to_end, 95),
                "end_to_end_p99": nearest(end_to_end, 99), "end_to_end_max": max(end_to_end),
                "max_wall_pending_cycles": max(pending),
                "max_lost_service_opportunities": max(opp_by_tx, default=0),
                "measured_lost_service_opportunities": sum(opp_by_tx),
                "target_aw_stall_cycles": stalls["aw"], "target_ar_stall_cycles": stalls["ar"],
                "target_w_stall_cycles": stalls["w"],
                "manager_b_stall_cycles": meta["manager_stall_cycles_by_manager"]["b"][manager],
                "manager_r_stall_cycles": meta["manager_stall_cycles_by_manager"]["r"][manager],
                "manager_b_stall_episodes": meta["manager_stall_episodes_by_manager"]["b"][manager],
                "manager_r_stall_episodes": meta["manager_stall_episodes_by_manager"]["r"][manager],
                "payload_bytes": payload_bytes,
                "payload_bytes_per_cycle": payload_bytes / window if window else 0.0,
            }
            rows.append(row)

    in_window = [tx for tx in txs if start <= tx["t_addr_accept"] <= end]
    admissions_by_manager = [sum(tx["manager"] == m for tx in in_window) for m in range(3)]
    rates = [count / window if window else 0.0 for count in admissions_by_manager]
    sum_sq = sum(x * x for x in rates)
    jain = (sum(rates) ** 2 / (3 * sum_sq)) if sum_sq else None
    detail = {
        "workload": meta["workload"], "seed": meta["seed"],
        "workload_sha256": meta["workload_sha256"],
        "generator_version": meta["generator_version"],
        "intent_count": meta["intent_count"],
        "intent_sha256": meta["intent_sha256"],
        "transaction_trace_sha256": hashlib.sha256(
            (folder / "transactions.jsonl").read_bytes()).hexdigest(),
        "benchmark_driver_sha256": meta["benchmark_driver_sha256"],
        "generator_sha256": meta["generator_sha256"],
        "numpy_version": np.__version__, "percentile_method": "nearest",
        "measurement_start_cycle": start, "measurement_end_cycle": end,
        "measurement_cycles": window, "active_managers": meta["active_managers"],
        "completion_count_by_manager": meta["completion_count_by_manager"],
        "premeasurement_completions_by_manager": meta["premeasurement_completions_by_manager"],
        "measured_count_by_manager": meta["measured_count_by_manager"],
        "max_live_reads_by_manager": meta["max_live_reads_by_manager"],
        "max_live_writes_by_manager": meta["max_live_writes_by_manager"],
        "manager_stall_cycles_by_manager": meta["manager_stall_cycles_by_manager"],
        "manager_stall_episodes_by_manager": meta["manager_stall_episodes_by_manager"],
        "target_stall_cycles_by_target": meta["target_stall_cycles_by_target"],
        "target_stall_episodes_by_target": meta["target_stall_episodes_by_target"],
        "lost_service_opportunities": meta["lost_service_opportunities"],
        "all_manager_active_cycles": meta["all_manager_active_cycles"],
        "parallel_target_address_cycles": meta["parallel_target_address_cycles"],
        "endpoint_max_write_depth": meta["endpoint_max_write_depth"],
        "endpoint_max_read_depth": meta["endpoint_max_read_depth"],
        "w12_jain_address_grant_rate": jain if meta["workload"] == "W12" else None,
        "manager_address_grants_in_window": admissions_by_manager,
    }
    return rows, detail


def main():
    root = Path(sys.argv[1])
    rows, details = [], []
    for meta_path in sorted(root.glob("W*/seed_*/run_meta.json")):
        run_rows, detail = summarize_run(meta_path.parent)
        rows.extend(run_rows)
        details.append(detail)
    if not details:
        raise SystemExit(f"no run_meta.json files found under {root}")
    fields = list(rows[0]) if rows else []
    with (root / "latency_throughput.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    (root / "run_summary.json").write_text(json.dumps(details, indent=2) + "\n")
    print(f"summarized {len(details)} runs, {len(rows)} manager/direction rows")
    print(f"CSV: {root / 'latency_throughput.csv'}")


if __name__ == "__main__":
    main()
