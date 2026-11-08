"""Fail-closed input validation tests for the frozen A/B comparison."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from bench.compare_ab import (ACTIVE_MANAGERS, FROZEN_WORKLOAD_SHA256, METRICS, SEEDS, WORKLOADS, validate_intent_pair_records,
                              validate_root, validate_shared_manifests)


ENDPOINT = {
    "queue_depth_per_target": 8, "read_start_latency_cycles": 2,
    "b_response_latency_cycles": 2, "r_rate_beats_per_cycle": 1,
    "response_order": "per-target FIFO by direction",
}


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def make_root(root: Path, arch="A"):
    top = f"axi_fabric_{arch.lower()}"
    manifest = {
        "architecture": arch, "dut_top": top,
        "rtl_sources": [{"path": f"rtl/{top}.sv", "sha256": "a" * 64}],
        "benchmark_engine": {"path": "tb/engine.py", "sha256": "b" * 64},
        "generator": {"path": "bench/generator.py", "sha256": "c" * 64},
        "workload": {"path": "bench/workloads.yaml", "sha256": FROZEN_WORKLOAD_SHA256},
        "runner": {"path": "scripts/run.sh", "sha256": "e" * 64},
        "wrapper": {"path": "bench/wrapper.sv", "sha256": "f" * 64},
        "endpoint": ENDPOINT, "warmup": 500, "samples": 5000,
        "qualification_only": False, "workloads": list(WORKLOADS), "seeds": list(SEEDS),
    }
    write_json(root / "source_manifest.json", manifest)
    manifest_hash = digest(root / "source_manifest.json")
    summaries = []
    latency = []
    for workload in WORKLOADS:
        for seed in SEEDS:
            active = ACTIVE_MANAGERS[workload]
            cfg = {"architecture": arch, "dut_top": top, "source_manifest_sha256": manifest_hash,
                   "workload": workload, "seed": seed, "warmup": 500, "samples": 5000,
                   "intent_limit_per_manager": 50000, "qualification_only": False}
            run = root / workload / f"seed_{seed[2:]}"
            write_json(run / "run_config.json", cfg)
            cfg_hash = digest(run / "run_config.json")
            meta = {
                "architecture": arch, "dut_top": top, "source_manifest_sha256": manifest_hash,
                "run_config_sha256": cfg_hash, "benchmark_driver_sha256": "b" * 64,
                "generator_sha256": "c" * 64, "workload_sha256": FROZEN_WORKLOAD_SHA256,
                "workload": workload, "seed": seed, "generator_version": "unit-test-v1",
                "intent_count": 0 if workload == "W00" else 50000,
                "intent_sha256": hashlib.sha256(b"plan").hexdigest(),
                "qualification_only": False, "active_managers": active,
                "warmup_per_manager": 500, "retained_completions_per_manager": 5000,
                "completion_count_by_manager": [5500 if m in active else 0 for m in range(3)],
                "premeasurement_completions_by_manager": [500 if m in active else 0 for m in range(3)],
                "measured_count_by_manager": [5000 if m in active else 0 for m in range(3)],
                "measurement_cycles": 1000,
            }
            write_json(run / "run_meta.json", meta)
            (run / "results.xml").write_text(
                '<testsuites><testsuite tests="1" failures="0" errors="0" skipped="0">'
                '<testcase name="canonical"/></testsuite></testsuites>\n')
            summary = dict(meta)
            summary["transaction_trace_sha256"] = hashlib.sha256(b"trace").hexdigest()
            summaries.append(summary)
            for manager in active:
                for direction in ("read", "write"):
                    row = {"architecture": arch, "workload": workload, "seed": seed,
                           "manager": str(manager), "direction": direction,
                           "samples": "2500", "measurement_cycles": "1000",
                           "payload_bytes": "20000"}
                    for metric in ("admission_p50", "admission_p95", "admission_p99", "admission_max",
                                   "first_response_p50", "first_response_p95", "first_response_p99",
                                   "first_response_max", "accepted_response_p50", "accepted_response_p95",
                                   "accepted_response_p99", "accepted_response_max", "end_to_end_p50",
                                   "end_to_end_p95", "end_to_end_p99", "end_to_end_max",
                                   "payload_bytes_per_cycle", "max_wall_pending_cycles",
                                   "max_lost_service_opportunities"):
                        row[metric] = "1"
                    latency.append(row)
    write_json(root / "run_summary.json", summaries)
    import csv
    with (root / "latency_throughput.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(latency[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(latency)


class CompareValidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "A"
        make_root(self.root)

    def tearDown(self):
        self.temp.cleanup()

    def test_complete_frozen_matrix_passes(self):
        manifest, matrix = validate_root(self.root, "A", "axi_fabric_a")
        self.assertEqual(len(matrix), 70)
        self.assertEqual(manifest["seeds"], list(SEEDS))

    def test_missing_pair_is_rejected(self):
        (self.root / "W13" / f"seed_{SEEDS[-1][2:]}").rename(self.root / "missing_pair")
        with self.assertRaisesRegex(ValueError, "run directory matrix mismatch"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_path_metadata_mismatch_is_rejected(self):
        path = self.root / "W01" / f"seed_{SEEDS[0][2:]}" / "run_meta.json"
        data = json.loads(path.read_text())
        data["workload"] = "W02"
        write_json(path, data)
        with self.assertRaisesRegex(ValueError, "workload path/metadata/config/summary mismatch"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_summary_intent_hash_mismatch_is_rejected(self):
        path = self.root / "run_summary.json"
        records = json.loads(path.read_text())
        records[1]["intent_sha256"] = "0" * 64
        write_json(path, records)
        with self.assertRaisesRegex(ValueError, "metadata and summary disagree on intent_sha256"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_wrong_dut_source_is_rejected(self):
        path = self.root / "source_manifest.json"
        data = json.loads(path.read_text())
        data["rtl_sources"] = [{"path": "rtl/axi_fabric_b.sv", "sha256": "a" * 64}]
        write_json(path, data)
        with self.assertRaisesRegex(ValueError, "RTL manifest does not select only"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_wrong_declared_seed_matrix_is_rejected(self):
        path = self.root / "source_manifest.json"
        data = json.loads(path.read_text())
        data["seeds"][-1] = "0xFABC0099"
        write_json(path, data)
        with self.assertRaisesRegex(ValueError, "manifest does not declare the frozen"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_wrong_workload_source_hash_is_rejected(self):
        path = self.root / "source_manifest.json"
        data = json.loads(path.read_text())
        data["workload"]["sha256"] = "d" * 64
        write_json(path, data)
        with self.assertRaisesRegex(ValueError, "workload hash differs from the frozen"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_duplicate_metric_row_is_rejected(self):
        path = self.root / "latency_throughput.csv"
        import csv
        with path.open(newline="") as stream:
            reader = csv.DictReader(stream)
            fieldnames, rows = reader.fieldnames, list(reader)
        rows.append(dict(rows[0]))
        with path.open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=fieldnames, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
        with self.assertRaisesRegex(ValueError, "duplicate latency row"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_a_b_intent_hash_mismatch_is_rejected(self):
        b_root = Path(self.temp.name) / "B"
        make_root(b_root, "B")
        a_records = json.loads((self.root / "run_summary.json").read_text())
        b_records = json.loads((b_root / "run_summary.json").read_text())
        b_records[0]["intent_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "mismatched A/B intent_sha256"):
            validate_intent_pair_records(a_records, b_records)

    def test_shared_generator_identity_mismatch_is_rejected(self):
        b_root = Path(self.temp.name) / "B"
        make_root(b_root, "B")
        a_manifest = json.loads((self.root / "source_manifest.json").read_text())
        b_manifest = json.loads((b_root / "source_manifest.json").read_text())
        b_manifest["generator"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "shared benchmark component differs: generator"):
            validate_shared_manifests(a_manifest, b_manifest)

    def test_duplicate_active_manager_is_rejected(self):
        path = self.root / "W01" / f"seed_{SEEDS[0][2:]}" / "run_meta.json"
        data = json.loads(path.read_text())
        data["active_managers"] = [0, 0, 1, 2]
        write_json(path, data)
        with self.assertRaisesRegex(ValueError, "invalid active manager list"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_boolean_active_manager_is_rejected(self):
        path = self.root / "W01" / f"seed_{SEEDS[0][2:]}" / "run_meta.json"
        data = json.loads(path.read_text())
        data["active_managers"] = [False, 1, 2]
        write_json(path, data)
        with self.assertRaisesRegex(ValueError, "invalid active manager list"):
            validate_root(self.root, "A", "axi_fabric_a")

    def test_zero_samples_for_a_direction_is_rejected(self):
        path = self.root / "latency_throughput.csv"
        import csv
        with path.open(newline="") as stream:
            reader = csv.DictReader(stream)
            fieldnames, rows = reader.fieldnames, list(reader)
        rows[0]["samples"] = "0"
        for metric in METRICS:
            rows[0][metric] = ""
        rows[0]["payload_bytes"] = "0"
        with path.open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=fieldnames, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
        with self.assertRaisesRegex(ValueError, "missing measured samples for a required direction"):
            validate_root(self.root, "A", "axi_fabric_a")


if __name__ == "__main__":
    unittest.main()
