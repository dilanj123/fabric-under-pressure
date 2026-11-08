"""Pair Architecture-A/B canonical run summaries by workload and seed."""
from __future__ import annotations

import csv
import json
import statistics
import sys
from pathlib import Path
import xml.etree.ElementTree as ET
import re


METRICS = (
    "admission_p50", "admission_p95", "admission_p99", "admission_max",
    "first_response_p50", "first_response_p95", "first_response_p99", "first_response_max",
    "accepted_response_p50", "accepted_response_p95", "accepted_response_p99",
    "accepted_response_max", "end_to_end_p50", "end_to_end_p95", "end_to_end_p99",
    "end_to_end_max", "payload_bytes_per_cycle", "max_wall_pending_cycles",
    "max_lost_service_opportunities",
)

WORKLOADS = tuple(f"W{i:02d}" for i in range(14))
SEEDS = tuple(f"0xFABC000{i}" for i in range(1, 6))
FROZEN_WORKLOAD_SHA256 = "31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4"
ACTIVE_MANAGERS = {
    "W00": [], "W01": [0], "W02": [1], "W03": [2],
    "W04": [0, 1, 2], "W05": [0, 1], "W06": [1, 2],
    **{f"W{i:02d}": [0, 1, 2] for i in range(7, 14)},
}
SHARED_MANIFEST_COMPONENTS = ("benchmark_engine", "generator", "workload", "runner", "endpoint")
MANIFEST_COMPONENTS = SHARED_MANIFEST_COMPONENTS + ("wrapper",)
HASHED_COMPONENTS = ("benchmark_engine", "generator", "workload", "runner", "wrapper")
SUMMARY_IDENTITY_FIELDS = (
    "architecture", "dut_top", "source_manifest_sha256", "run_config_sha256",
    "benchmark_driver_sha256", "generator_sha256", "workload", "seed",
    "workload_sha256", "generator_version", "intent_count", "intent_sha256",
    "active_managers", "completion_count_by_manager",
    "premeasurement_completions_by_manager", "measured_count_by_manager",
    "measurement_cycles",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256_text(value: object, context: str) -> str:
    require(isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None,
            f"{context}: expected a lowercase SHA-256")
    return value


def read_csv(path: Path) -> list[dict]:
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def number(value: str):
    return None if value in ("", "None") else float(value)


def validate_root(root: Path, arch: str, top: str) -> tuple[dict, list[dict]]:
    manifest_path = root / "source_manifest.json"
    manifest = json.loads(manifest_path.read_text())
    require(manifest.get("architecture") == arch and manifest.get("dut_top") == top,
            f"{root}: wrong selected DUT in source_manifest.json")
    require(manifest.get("qualification_only") is False and
            manifest.get("workloads") == list(WORKLOADS) and manifest.get("seeds") == list(SEEDS),
            f"{root}: manifest does not declare the frozen W00-W13/five-seed matrix")
    require(manifest.get("warmup") == 500 and manifest.get("samples") == 5000,
            f"{root}: manifest sample policy is not 500 warm-up/5000 samples")
    for component in HASHED_COMPONENTS:
        record = manifest.get(component)
        require(isinstance(record, dict) and isinstance(record.get("path"), str),
                f"{root}: missing {component} manifest path")
        sha256_text(record.get("sha256"), f"{root}: {component}")
    require(manifest["workload"]["sha256"] == FROZEN_WORKLOAD_SHA256,
            f"{root}: workload hash differs from the frozen W00-W13 definition")
    require(manifest["endpoint"] == {
        "queue_depth_per_target": 8, "read_start_latency_cycles": 2,
        "b_response_latency_cycles": 2, "r_rate_beats_per_cycle": 1,
        "response_order": "per-target FIFO by direction"},
        f"{root}: endpoint configuration differs from the frozen model")
    rtl_sources = manifest.get("rtl_sources")
    require(isinstance(rtl_sources, list) and rtl_sources,
            f"{root}: missing RTL source manifest")
    rtl_paths = [item.get("path") for item in rtl_sources if isinstance(item, dict)]
    require(len(rtl_paths) == len(rtl_sources) and len(rtl_paths) == len(set(rtl_paths)),
            f"{root}: malformed or duplicate RTL source entries")
    for item in rtl_sources:
        sha256_text(item.get("sha256"), f"{root}: RTL {item.get('path')}")
    selected_path = f"rtl/{top}.sv"
    other_top = "rtl/axi_fabric_b.sv" if arch == "A" else "rtl/axi_fabric_a.sv"
    require(selected_path in rtl_paths and other_top not in rtl_paths,
            f"{root}: RTL manifest does not select only {top}")

    expected_pairs = {(workload, seed) for workload in WORKLOADS for seed in SEEDS}
    run_dirs = {(p.parent.parent.name, "0x" + p.parent.name.removeprefix("seed_").upper()): p.parent
                for p in root.glob("W*/seed_*/run_meta.json")}
    require(set(run_dirs) == expected_pairs,
            f"{root}: run directory matrix mismatch; missing={sorted(expected_pairs-set(run_dirs))}, "
            f"extra={sorted(set(run_dirs)-expected_pairs)}")
    paths = [run_dirs[pair] / "run_meta.json" for pair in sorted(expected_pairs)]
    source_hash = hashlib_file(manifest_path)
    matrix=[]
    summary_records = json.loads((root / "run_summary.json").read_text())
    require(isinstance(summary_records, list), f"{root}: run_summary.json must be a list")
    summary_by_pair = {}
    for record in summary_records:
        require(isinstance(record, dict), f"{root}: malformed run summary record")
        pair = (record.get("workload"), record.get("seed"))
        require(pair not in summary_by_pair, f"{root}: duplicate summary pair {pair}")
        summary_by_pair[pair] = record
    require(set(summary_by_pair) == expected_pairs,
            f"{root}: summary matrix mismatch; missing={sorted(expected_pairs-set(summary_by_pair))}, "
            f"extra={sorted(set(summary_by_pair)-expected_pairs)}")
    latency_rows = read_csv(root / "latency_throughput.csv")
    latency_by_key = {}
    for row in latency_rows:
        try:
            key = (row["workload"], row["seed"], int(row["manager"]), row["direction"])
        except (KeyError, ValueError) as exc:
            raise ValueError(f"{root}: malformed latency row identity: {row}") from exc
        require(key not in latency_by_key, f"{root}: duplicate latency row {key}")
        latency_by_key[key] = row
    required_metrics = set(METRICS) | {"samples", "measurement_cycles", "payload_bytes"}
    for path in paths:
        meta=json.loads(path.read_text())
        cfg=json.loads((path.parent/"run_config.json").read_text())
        pair = (path.parent.parent.name, "0x" + path.parent.name.removeprefix("seed_").upper())
        summary = summary_by_pair[pair]
        require(path.parent.parent.name == meta.get("workload") == cfg.get("workload") == summary.get("workload"),
                f"{path.parent}: workload path/metadata/config/summary mismatch")
        require(pair[1] == meta.get("seed") == cfg.get("seed") == summary.get("seed"),
                f"{path.parent}: seed path/metadata/config/summary mismatch")
        xml=ET.parse(path.parent/"results.xml").getroot()
        cases=list(xml.iter("testcase"))
        suites = list(xml.iter("testsuite"))
        require(meta.get("architecture")==arch and meta.get("dut_top")==top and
                cfg.get("architecture")==arch and cfg.get("dut_top")==top and
                meta.get("qualification_only") is False and cfg.get("qualification_only") is False,
                f"{path.parent}: architecture/test configuration mismatch")
        require(meta.get("source_manifest_sha256")==cfg.get("source_manifest_sha256")==source_hash==
                summary.get("source_manifest_sha256"),
                f"{path.parent}: source manifest hash mismatch")
        cfg_hash = hashlib_file(path.parent / "run_config.json")
        require(meta.get("run_config_sha256")==cfg_hash==summary.get("run_config_sha256"),
                f"{path.parent}: run configuration hash mismatch")
        for field, value in (("benchmark_driver_sha256", manifest["benchmark_engine"]["sha256"]),
                             ("generator_sha256", manifest["generator"]["sha256"]),
                             ("workload_sha256", manifest["workload"]["sha256"])):
            require(meta.get(field)==summary.get(field)==value,
                    f"{path.parent}: {field} does not match its source manifest")
        require(meta.get("warmup_per_manager")==cfg.get("warmup")==manifest["warmup"] and
                meta.get("retained_completions_per_manager")==cfg.get("samples")==manifest["samples"],
                f"{path.parent}: sample contract mismatch")
        active_managers = meta.get("active_managers")
        require(isinstance(active_managers, list) and
                all(type(manager) is int and manager in (0, 1, 2) for manager in active_managers) and
                len(active_managers) == len(set(active_managers)) and
                active_managers == summary.get("active_managers"),
                f"{path.parent}: invalid active manager list")
        expected_active = ACTIVE_MANAGERS[pair[0]]
        require(active_managers == expected_active,
                f"{path.parent}: active managers {active_managers} do not match {pair[0]} policy "
                f"{expected_active}")
        expected_counts=[manifest["samples"] if m in active_managers else 0 for m in range(3)]
        require(meta.get("measured_count_by_manager")==expected_counts==summary.get("measured_count_by_manager"),
                f"{path.parent}: measured quota mismatch")
        require(len(cases)==1 and len(suites)==1 and suites[0].get("tests", "1") == "1" and
                suites[0].get("failures", "0") == "0" and suites[0].get("errors", "0") == "0" and
                suites[0].get("skipped", "0") == "0" and
                not list(xml.iter("failure")) and not list(xml.iter("error")) and
                not list(xml.iter("skipped")),
                f"{path.parent}/results.xml: expected one passing testcase")
        for field in SUMMARY_IDENTITY_FIELDS:
            require(field in meta and field in summary,
                    f"{path.parent}: missing required summary field {field}")
            require(meta[field] == summary[field],
                    f"{path.parent}: metadata and summary disagree on {field}")
        for field in ("intent_sha256", "transaction_trace_sha256"):
            sha256_text(summary.get(field), f"{path.parent}: {field}")
        expected_latency_keys = {(pair[0], pair[1], manager, direction)
                                 for manager in meta["active_managers"]
                                 for direction in ("read", "write")}
        actual_latency_keys = {key for key in latency_by_key if key[:2] == pair}
        require(actual_latency_keys == expected_latency_keys,
                f"{path.parent}: latency row set mismatch; expected={sorted(expected_latency_keys)}, "
                f"found={sorted(actual_latency_keys)}")
        for key in expected_latency_keys:
            row = latency_by_key[key]
            require(row.get("architecture")==arch and row.get("measurement_cycles")==str(meta["measurement_cycles"]),
                    f"{path.parent}: latency row architecture/window mismatch for {key}")
            require(required_metrics.issubset(row),
                    f"{path.parent}: missing latency fields for {key}: {sorted(required_metrics-set(row))}")
            try:
                samples = int(row["samples"])
                require(samples >= 0, f"{path.parent}: negative sample count for {key}")
                for metric in METRICS:
                    value = number(row[metric])
                    require(samples == 0 or value is not None,
                            f"{path.parent}: missing {metric} with nonzero samples for {key}")
                int(row["payload_bytes"])
            except (ValueError, TypeError) as exc:
                raise ValueError(f"{path.parent}: malformed required latency values for {key}: {exc}") from exc
        for manager in meta["active_managers"]:
            direction_samples = {
                direction: int(latency_by_key[(pair[0], pair[1], manager, direction)]["samples"])
                for direction in ("read", "write")
            }
            require(all(samples > 0 for samples in direction_samples.values()),
                    f"{path.parent}: M{manager} missing measured samples for a required direction: "
                    f"{direction_samples}")
            measured_samples = sum(direction_samples.values())
            require(measured_samples == manifest["samples"],
                    f"{path.parent}: M{manager} read/write rows total {measured_samples}, "
                    f"expected {manifest['samples']} retained completions")
        matrix.append({"architecture":arch,"workload":meta["workload"],"seed":meta["seed"],
                       "dut_top":top,"xml":"PASS","intent_sha256":meta["intent_sha256"],
                       "active_managers":";".join(map(str,meta["active_managers"])),
                       "warmup_per_manager":meta["warmup_per_manager"],
                       "measured_count_by_manager":";".join(map(str,meta["measured_count_by_manager"])),
                       "measurement_cycles":meta["measurement_cycles"]})
    return manifest,matrix


def hashlib_file(path: Path) -> str:
    import hashlib
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_shared_manifests(amanifest: dict, bmanifest: dict) -> None:
    for component in SHARED_MANIFEST_COMPONENTS:
        if amanifest[component] != bmanifest[component]:
            raise ValueError(f"A/B shared benchmark component differs: {component}")
    if amanifest["wrapper"]["path"] != bmanifest["wrapper"]["path"]:
        raise ValueError("A/B wrapper source path differs")
    if amanifest["wrapper"]["sha256"] != bmanifest["wrapper"]["sha256"]:
        # Recorded historical exception: only a comment-only edit separated
        # the cocotb runs; the wrapper is not compiled by that simulation.
        allowed = (
            amanifest["wrapper"]["sha256"] == "41391b0b5c84c0637732bb257c407a8ec60a433e5de1ba74f49312ddf628b234" and
            bmanifest["wrapper"]["sha256"] == "8c4a44d4db1947399b8722a5cb6b1cefc643ce17470955ff46b4fc6900fd9cd5")
        if not allowed:
            raise ValueError("A/B wrapper hash differs without the documented historical exception")


def validate_intent_pair_records(arows: list[dict], brows: list[dict]) -> dict:
    expected_pairs = {(w, s) for w in WORKLOADS for s in SEEDS}
    def index(rows, arch):
        indexed = {}
        for row in rows:
            pair = (row.get("workload"), row.get("seed"))
            if pair in indexed:
                raise ValueError(f"duplicate {arch} run detail pair {pair}")
            indexed[pair] = row
        if set(indexed) != expected_pairs:
            raise ValueError(f"{arch} run detail set is not the exact frozen 70-pair matrix")
        return indexed
    aa, bb = index(arows, "A"), index(brows, "B")
    for pair in sorted(expected_pairs):
        for field in ("intent_sha256", "generator_sha256", "workload_sha256", "generator_version"):
            if aa[pair].get(field) != bb[pair].get(field):
                raise ValueError(f"mismatched A/B {field} for {pair}")
        sha256_text(aa[pair].get("intent_sha256"), f"A intent plan {pair}")
        sha256_text(aa[pair].get("generator_sha256"), f"A generator {pair}")
        sha256_text(aa[pair].get("workload_sha256"), f"A workload {pair}")
    return aa


def main() -> None:
    aroot, broot, out = map(Path, sys.argv[1:4])
    amanifest, amatrix = validate_root(aroot,"A","axi_fabric_a")
    bmanifest, bmatrix = validate_root(broot,"B","axi_fabric_b")
    validate_shared_manifests(amanifest, bmanifest)
    arows, brows = read_csv(aroot / "latency_throughput.csv"), read_csv(broot / "latency_throughput.csv")
    key = lambda r: (r["workload"], r["seed"], int(r["manager"]), r["direction"])
    aa, bb = {key(r): r for r in arows}, {key(r): r for r in brows}
    if len(aa) != len(arows) or len(bb) != len(brows):
        raise SystemExit("duplicate A/B latency metric rows")
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
    try:
        detail_map = validate_intent_pair_records(adetails, bdetails)
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    detail_b = {(d["workload"], d["seed"]): d for d in bdetails}
    details_out = []
    for k in sorted(detail_map):
        a, b = detail_map[k], detail_b[k]
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
