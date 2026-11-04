"""Pair Architecture-A/B canonical run summaries by workload and seed."""
from __future__ import annotations

import csv
import json
import statistics
import sys
from pathlib import Path
import xml.etree.ElementTree as ET


METRICS = (
    "admission_p50", "admission_p95", "admission_p99", "admission_max",
    "first_response_p50", "first_response_p95", "first_response_p99", "first_response_max",
    "accepted_response_p50", "accepted_response_p95", "accepted_response_p99",
    "accepted_response_max", "end_to_end_p50", "end_to_end_p95", "end_to_end_p99",
    "end_to_end_max", "payload_bytes_per_cycle", "max_wall_pending_cycles",
    "max_lost_service_opportunities",
)


def read_csv(path: Path) -> list[dict]:
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def number(value: str):
    return None if value in ("", "None") else float(value)


def validate_root(root: Path, arch: str, top: str) -> tuple[dict, list[dict]]:
    manifest = json.loads((root / "source_manifest.json").read_text())
    if manifest["architecture"] != arch or manifest["dut_top"] != top:
        raise SystemExit(f"wrong selected DUT in {root}/source_manifest.json")
    paths = sorted(root.glob("W*/seed_*/run_meta.json"))
    if len(paths) != 70:
        raise SystemExit(f"expected 70 run metadata files under {root}, found {len(paths)}")
    matrix=[]
    for path in paths:
        meta=json.loads(path.read_text())
        cfg=json.loads((path.parent/"run_config.json").read_text())
        xml=ET.parse(path.parent/"results.xml").getroot()
        cases=list(xml.iter("testcase"))
        if (meta["architecture"]!=arch or meta["dut_top"]!=top or
            cfg["architecture"]!=arch or cfg["dut_top"]!=top or
            meta["qualification_only"] or cfg["qualification_only"]):
            raise SystemExit(f"architecture/test configuration mismatch: {path.parent}")
        if meta["retained_completions_per_manager"]!=5000 or meta["warmup_per_manager"]!=500:
            raise SystemExit(f"sample contract mismatch: {path.parent}")
        expected=[5000 if m in meta["active_managers"] else 0 for m in range(3)]
        if meta["measured_count_by_manager"]!=expected:
            raise SystemExit(f"measured quota mismatch: {path.parent}")
        if len(cases)!=1 or list(xml.iter("failure")) or list(xml.iter("error")) or list(xml.iter("skipped")):
            raise SystemExit(f"JUnit is not one passing testcase: {path.parent}/results.xml")
        if meta["source_manifest_sha256"]!=cfg["source_manifest_sha256"]:
            raise SystemExit(f"source manifest mismatch: {path.parent}")
        matrix.append({"architecture":arch,"workload":meta["workload"],"seed":meta["seed"],
                       "dut_top":top,"xml":"PASS","intent_sha256":meta["intent_sha256"],
                       "active_managers":";".join(map(str,meta["active_managers"])),
                       "warmup_per_manager":meta["warmup_per_manager"],
                       "measured_count_by_manager":";".join(map(str,meta["measured_count_by_manager"])),
                       "measurement_cycles":meta["measurement_cycles"]})
    return manifest,matrix


def main() -> None:
    aroot, broot, out = map(Path, sys.argv[1:4])
    amanifest, amatrix = validate_root(aroot,"A","axi_fabric_a")
    bmanifest, bmatrix = validate_root(broot,"B","axi_fabric_b")
    for component in ("benchmark_engine","generator","workload","runner","endpoint"):
        if amanifest[component] != bmanifest[component]:
            raise SystemExit(f"A/B shared benchmark component differs: {component}")
    arows, brows = read_csv(aroot / "latency_throughput.csv"), read_csv(broot / "latency_throughput.csv")
    key = lambda r: (r["workload"], r["seed"], int(r["manager"]), r["direction"])
    aa, bb = {key(r): r for r in arows}, {key(r): r for r in brows}
    if aa.keys() != bb.keys():
        raise SystemExit(f"A/B manager-direction run sets differ: A={len(aa)} B={len(bb)}")

    per_seed = []
    grouped: dict[tuple, list[dict]] = {}
    for k in sorted(aa):
        ar, br = aa[k], bb[k]
        for metric in METRICS:
            av, bv = number(ar.get(metric, "")), number(br.get(metric, ""))
            if av is None or bv is None:
                continue
            delta = bv - av
            record = {"workload": k[0], "seed": k[1], "manager": k[2],
                      "direction": k[3], "metric": metric,
                      "A": av, "B": bv, "absolute_delta_B_minus_A": delta,
                      "percent_delta_vs_A": 100.0 * delta / av if av else None,
                      "samples_A": int(ar["samples"]), "samples_B": int(br["samples"])}
            per_seed.append(record)
            grouped.setdefault((k[0], k[2], k[3], metric), []).append(record)

    medians = []
    for group_key, rows in sorted(grouped.items()):
        if len(rows) != 5:
            raise SystemExit(f"expected five seeds for {group_key}, found {len(rows)}")
        av, bv = statistics.median(x["A"] for x in rows), statistics.median(x["B"] for x in rows)
        delta = bv - av
        medians.append({"workload": group_key[0], "manager": group_key[1],
                        "direction": group_key[2], "metric": group_key[3],
                        "seeds": 5, "A_median": av, "B_median": bv,
                        "absolute_delta_B_minus_A": delta,
                        "percent_delta_vs_A": 100.0 * delta / av if av else None})

    out.mkdir(parents=True, exist_ok=True)
    with (out/"run_matrix.csv").open("w",newline="") as stream:
        writer=csv.DictWriter(stream,fieldnames=list(amatrix[0]),lineterminator="\n");writer.writeheader()
        writer.writerows(amatrix+bmatrix)
    source_comparison={"A":{"top":amanifest["dut_top"],"rtl_sources":amanifest["rtl_sources"],
                              "benchmark_engine":amanifest["benchmark_engine"],"generator":amanifest["generator"],
                              "workload":amanifest["workload"],"runner":amanifest["runner"],
                              "wrapper":amanifest["wrapper"],"endpoint":amanifest["endpoint"]},
                       "B":{"top":bmanifest["dut_top"],"rtl_sources":bmanifest["rtl_sources"],
                              "benchmark_engine":bmanifest["benchmark_engine"],"generator":bmanifest["generator"],
                              "workload":bmanifest["workload"],"runner":bmanifest["runner"],
                              "wrapper":bmanifest["wrapper"],"endpoint":bmanifest["endpoint"]},
                       "wrapper_hash_note":"The full simulation manifests record different wrapper SHA-256 values due solely to a comment-only edit made between A and B execution. The wrapper is not compiled in the cocotb benchmark; the A/B PPA runs below use the identical final wrapper SHA-256. The functional wrapper RTL is unchanged between the two comment versions."}
    (out/"source_manifest_comparison.json").write_text(json.dumps(source_comparison,indent=2)+"\n")
    for name, rows in (("matched_per_seed.csv", per_seed), ("matched_median_of_five.csv", medians)):
        with (out / name).open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]) if rows else [],
                                    lineterminator="\n")
            writer.writeheader(); writer.writerows(rows)

    # Per-manager aggregate payload rates pair read and write within each
    # seed/window; absent direction rows contribute zero bytes/cycle.
    throughput = [r for r in per_seed if r["metric"] == "payload_bytes_per_cycle"]
    aggregate_seed = []
    for workload in sorted({r["workload"] for r in throughput}):
        for seed in sorted({r["seed"] for r in throughput if r["workload"] == workload}):
            for manager in sorted({r["manager"] for r in throughput
                                   if r["workload"] == workload and r["seed"] == seed}):
                a_total = b_total = 0.0
                for direction in ("read", "write"):
                    row = next((r for r in throughput if r["workload"] == workload and
                                r["seed"] == seed and r["manager"] == manager and
                                r["direction"] == direction), None)
                    if row:
                        a_total += row["A"]; b_total += row["B"]
                delta = b_total - a_total
                aggregate_seed.append({"workload": workload, "seed": seed, "manager": manager,
                                       "A_bytes_per_cycle": a_total, "B_bytes_per_cycle": b_total,
                                       "absolute_delta_B_minus_A": delta,
                                       "percent_delta_vs_A": 100*delta/a_total if a_total else None})
    with (out / "manager_aggregate_throughput_per_seed.csv").open("w", newline="") as stream:
        writer=csv.DictWriter(stream,fieldnames=list(aggregate_seed[0]) if aggregate_seed else [],
                              lineterminator="\n")
        writer.writeheader();writer.writerows(aggregate_seed)
    aggregate_median=[]
    groups={}
    for row in aggregate_seed: groups.setdefault((row["workload"],row["manager"]),[]).append(row)
    for (workload,manager), group in sorted(groups.items()):
        if len(group)!=5: raise SystemExit(f"expected five throughput seeds for {workload} M{manager}")
        av=statistics.median(x["A_bytes_per_cycle"] for x in group)
        bv=statistics.median(x["B_bytes_per_cycle"] for x in group)
        aggregate_median.append({"workload":workload,"manager":manager,"seeds":5,
                                 "A_median_bytes_per_cycle":av,"B_median_bytes_per_cycle":bv,
                                 "absolute_delta_B_minus_A":bv-av,
                                 "percent_delta_vs_A":100*(bv-av)/av if av else None})
    with (out / "manager_aggregate_throughput_median.csv").open("w",newline="") as stream:
        writer=csv.DictWriter(stream,fieldnames=list(aggregate_median[0]) if aggregate_median else [],
                              lineterminator="\n")
        writer.writeheader();writer.writerows(aggregate_median)

    adetails = json.loads((aroot / "run_summary.json").read_text())
    bdetails = json.loads((broot / "run_summary.json").read_text())
    detail_map = {(d["workload"], d["seed"]): d for d in adetails}
    detail_b = {(d["workload"], d["seed"]): d for d in bdetails}
    if detail_map.keys() != detail_b.keys() or len(detail_map) != 70:
        raise SystemExit("run detail sets are not the complete 70 matched workload/seed pairs")
    details_out = []
    for k in sorted(detail_map):
        a, b = detail_map[k], detail_b[k]
        for field in ("intent_sha256", "generator_sha256", "workload_sha256", "generator_version"):
            if a[field] != b[field]:
                raise SystemExit(f"mismatched A/B {field} for {k}")
        details_out.append({"workload": k[0], "seed": k[1],
                            "A_source_manifest_sha256": a["source_manifest_sha256"],
                            "B_source_manifest_sha256": b["source_manifest_sha256"],
                            "A_intent_sha256": a["intent_sha256"], "B_intent_sha256": b["intent_sha256"],
                            "A_measurement_cycles": a["measurement_cycles"],
                            "B_measurement_cycles": b["measurement_cycles"],
                            "A_w12_jain": a["w12_jain_address_grant_rate"],
                            "B_w12_jain": b["w12_jain_address_grant_rate"],
                            "A_all_manager_active_cycles": a["all_manager_active_cycles"],
                            "B_all_manager_active_cycles": b["all_manager_active_cycles"],
                            "A_parallel_target_address_cycles": a["parallel_target_address_cycles"],
                            "B_parallel_target_address_cycles": b["parallel_target_address_cycles"],
                            "A_lost_service_opportunities": a["lost_service_opportunities"],
                            "B_lost_service_opportunities": b["lost_service_opportunities"]})
    (out / "matched_run_details.json").write_text(json.dumps(details_out, indent=2) + "\n")

    # Frozen D045 checks: median over five per-seed values, retaining exact
    # CSV precision for threshold comparisons.
    lookup = {(r["workload"], r["manager"], r["direction"], r["metric"]): r for r in medians}
    w08m2 = lookup[("W08", 2, "read", "admission_p99")]["B_median"]
    w08m0r = lookup[("W08", 0, "read", "admission_p99")]
    w08m0w = lookup[("W08", 0, "write", "admission_p99")]
    w08m1_by_seed = {}
    for architecture in ("A", "B"):
        w08m1_by_seed[architecture] = []
        for seed in sorted({r["seed"] for r in per_seed}):
            read = next(r for r in per_seed if r["workload"] == "W08" and r["seed"] == seed and
                        r["manager"] == 1 and r["direction"] == "read" and
                        r["metric"] == "payload_bytes_per_cycle")
            write = next(r for r in per_seed if r["workload"] == "W08" and r["seed"] == seed and
                         r["manager"] == 1 and r["direction"] == "write" and
                         r["metric"] == "payload_bytes_per_cycle")
            w08m1_by_seed[architecture].append(read[architecture] + write[architecture])
    w08a_m1 = statistics.median(w08m1_by_seed["A"])
    w08b_m1 = statistics.median(w08m1_by_seed["B"])
    w08m1_ratio = w08b_m1 / w08a_m1
    w12a = [d["A_w12_jain"] for d in details_out if d["workload"] == "W12"]
    w12b = [d["B_w12_jain"] for d in details_out if d["workload"] == "W12"]
    criteria = [
        {"criterion": "W08 M2 read admission P99 <= 16 cycles", "value": w08m2,
         "result": "PASS" if w08m2 <= 16 else "FAIL"},
        {"criterion": "W08 M1 read+write throughput >= 10.07665 bytes/cycle", "value": w08b_m1,
         "A_bytes_per_cycle": w08a_m1, "B_bytes_per_cycle": w08b_m1,
         "B_over_A_ratio": w08m1_ratio,
         "result": "PASS" if w08b_m1 >= 10.07665 else "FAIL"},
        {"criterion": "W08 M0 read admission P99 <= 23 cycles", "value": w08m0r["B_median"],
         "A_value": w08m0r["A_median"],
         "result": "PASS" if w08m0r["B_median"] <= 23 else "FAIL"},
        {"criterion": "W08 M0 write admission P99 <= 29 cycles", "value": w08m0w["B_median"],
         "A_value": w08m0w["A_median"],
         "result": "PASS" if w08m0w["B_median"] <= 29 else "FAIL"},
        {"criterion": "W12 median Jain grant-rate index >= 0.98", "value": statistics.median(w12b),
         "A_median": statistics.median(w12a),
         "result": "PASS" if statistics.median(w12b) >= 0.98 else "FAIL"},
    ]
    (out / "d045_evaluation.json").write_text(json.dumps(criteria, indent=2) + "\n")
    print(f"paired {len(detail_map)} runs, {len(per_seed)} per-seed manager/direction metric rows")
    print(json.dumps(criteria, indent=2))


if __name__ == "__main__":
    main()
