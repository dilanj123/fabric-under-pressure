import csv
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from portfolio_audit.build_ai_provenance_register import (
    CLASSIFICATIONS,
    PINNED_REVISION,
    PROCESSED_GENERATORS,
    classify,
)


ROOT = Path(__file__).resolve().parents[1]
REGISTER = ROOT / "portfolio_audit/generated/ai_provenance_register.csv"
BASELINE = ROOT / "portfolio_audit/generated/authorship_baseline.json"
CONTEXT = ROOT / "portfolio_audit/generated/project_ai_workflow_context.json"


class ProvenanceRegisterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline = json.loads(BASELINE.read_text())
        with REGISTER.open(newline="", encoding="utf-8") as stream:
            cls.rows = {row["path"]: row for row in csv.DictReader(stream)}

    def test_paths_and_blobs_match_recorded_git_tree(self):
        tree = subprocess.check_output(
            ["git", "ls-tree", "-rlz", "--full-tree", PINNED_REVISION], cwd=ROOT
        ).split(b"\0")
        expected = {}
        for item in tree:
            if not item:
                continue
            meta, path = item.split(b"\t", 1)
            mode, kind, oid, size = meta.decode().split()
            if kind == "blob":
                expected[path.decode("utf-8", "surrogateescape")] = (oid, int(size))
        actual = {path: (row["git_blob_sha"], int(row["blob_size_bytes"])) for path, row in self.rows.items()}
        self.assertEqual(len(self.rows), self.baseline["tracked_path_count"])
        self.assertEqual(actual, expected)

    def test_project_ai_context_is_separate_from_file_origin(self):
        context = json.loads(CONTEXT.read_text())
        self.assertEqual(context["classification"], "AI_ASSISTED_CONFIRMED")
        self.assertIn("not an authorship label for any file", context["scope"])
        self.assertTrue(all(row["project_ai_workflow_context_id"] == context["id"] for row in self.rows.values()))
        self.assertTrue(all(row["origin_classification"] in CLASSIFICATIONS for row in self.rows.values()))
        self.assertEqual(self.rows["rtl/axi_fabric_a.sv"]["origin_classification"], "UNKNOWN")
        self.assertEqual(self.rows[".github/workflows/gate0-macos-arm64.yml"]["origin_classification"], "UNKNOWN")
        self.assertEqual(self.rows["requirements/phase0.txt"]["origin_classification"], "UNKNOWN")

    def test_processed_machine_data_and_narrative_are_distinguished(self):
        for path in (
            "results/processed/ab_comparison/matched_per_seed.csv",
            "results/processed/ab_comparison/d045_evaluation.json",
            "results/processed/ab_comparison/figures/admission_p99.png",
            "results/processed/gate5_reproduction/ab_comparison/run_matrix.csv",
        ):
            self.assertEqual(self.rows[path]["origin_classification"], "TOOL_GENERATED", path)
        self.assertEqual(self.rows["results/processed/ab_comparison/summary.md"]["origin_classification"], "UNKNOWN")
        self.assertEqual(self.rows["results/processed/oracle_edge_repair/functional_matrix.csv"]["origin_classification"], "UNKNOWN")
        self.assertEqual(classify("results/processed/ab_comparison/new_unmapped.csv", 12)["origin_classification"], "UNKNOWN")
        self.assertEqual(classify("results/processed/architecture_b_functional/else/coverage_512.json", 12)["origin_classification"], "UNKNOWN")
        actual_generated = {
            path for path, row in self.rows.items()
            if path.startswith("results/processed/") and row["origin_classification"] == "TOOL_GENERATED"
        }
        self.assertEqual(actual_generated, set(PROCESSED_GENERATORS))
        self.assertTrue(all((ROOT / producer).is_file() for producer in PROCESSED_GENERATORS.values()))

    def test_empty_placeholders_and_empty_output_are_not_authored(self):
        self.assertEqual(self.rows["rtl/.keep"]["category"], "empty placeholder")
        self.assertEqual(self.rows["rtl/.keep"]["origin_classification"], "UNKNOWN")
        self.assertEqual(self.rows["results/raw/gate2_oracle/fault_event_trace.jsonl"]["category"], "empty file or output")
        self.assertEqual(self.rows["results/raw/gate2_oracle/fault_event_trace.jsonl"]["origin_classification"], "UNKNOWN")

    def test_classification_plumbing_accepts_explicit_direct_evidence(self):
        row = classify("example.py", 10, direct_evidence={
            "classification": "HUMAN_CONFIRMED",
            "evidence": "Explicit signed authorship record for this file.",
            "confidence": "HIGH",
        })
        self.assertEqual(row["origin_classification"], "HUMAN_CONFIRMED")
        self.assertEqual(classify("README.md", 10)["origin_classification"], "AI_ASSISTED_CONFIRMED")
        self.assertEqual(classify("unattributed.py", 10)["origin_classification"], "UNKNOWN")

    def test_raw_files_require_content_evidence_not_directory_membership(self):
        log = classify("results/raw/run/simulation.log", 120, b"PASS tb checks=1\n- tb.sv:3: Verilog $finish\n- S i m u l a t i o n   R e p o r t: Verilator 5.053 devel\n")
        generic_log = classify("results/raw/run/output.log", 50, b"note: Verilator 5.053 appears in an authored note\n%Warning: made-up authored content")
        generic_warning = classify("results/raw/run/warning.log", 50, b"%Warning: This text mentions a synthesis warning but is not a tool log")
        script = classify("results/raw/run/reproduce.sh", 30, b"#!/bin/sh\necho run")
        generic_verilog = classify("results/raw/run/authored.v", 60, b"module testbench; reg genclock; endmodule")
        generic_json = classify("results/raw/run/authored.json", 40, b'{"creator":"a note about Yosys","message":"not a tool report"}')
        malformed_json_schema = classify("results/raw/run/coverage.json", 50, b'{"seed":"one","random_operations":"many","accepted_reads":0,"accepted_writes":0}')
        junit = classify("results/raw/run/results.xml", 100, b'<testsuites name="results"><testsuite name="all" package="all"><testcase name="smoke" classname="tb.smoke"/></testsuite></testsuites>')
        malformed_xml = classify("results/raw/run/note.xml", 20, b"<testsuite this word appears in authored text")
        generic_xml = classify("results/raw/run/note2.xml", 35, b"<testsuite><testcase>authored prose</testcase></testsuite>")
        structured_jsonl = classify("results/raw/run/events.jsonl", 80, b'{"cycle":1,"epoch":0,"kind":"address_admitted"}\n')
        formal_pass = classify("results/raw/formal/run/PASS", 80, b"Elapsed process time [H:MM:SS (secs)]: 0:00:01 (1)\nengine_0 (smtbmc) returned pass\n")
        generic_pass = classify("results/raw/run/PASS", 30, b"This authored note says returned pass once")
        self.assertEqual(log["origin_classification"], "TOOL_GENERATED")
        self.assertIn("PASS/check count", log["file_specific_evidence"])
        self.assertEqual(generic_log["origin_classification"], "UNKNOWN")
        self.assertEqual(generic_warning["origin_classification"], "UNKNOWN")
        self.assertEqual(generic_verilog["origin_classification"], "UNKNOWN")
        self.assertEqual(generic_json["origin_classification"], "UNKNOWN")
        self.assertEqual(malformed_json_schema["origin_classification"], "UNKNOWN")
        self.assertEqual(junit["origin_classification"], "UNKNOWN")
        self.assertEqual(malformed_xml["origin_classification"], "UNKNOWN")
        self.assertEqual(generic_xml["origin_classification"], "UNKNOWN")
        self.assertEqual(structured_jsonl["origin_classification"], "UNKNOWN")
        self.assertEqual(formal_pass["origin_classification"], "TOOL_GENERATED")
        self.assertEqual(generic_pass["origin_classification"], "UNKNOWN")
        self.assertEqual(script["origin_classification"], "UNKNOWN")
        self.assertIn("directory placement alone", script["file_specific_evidence"])
        self.assertEqual(self.rows["results/raw/ar_target_path/bank_simulation.log"]["origin_classification"], "TOOL_GENERATED")
        self.assertEqual(self.rows["results/raw/ar_target_path/verilator_lint.log"]["origin_classification"], "TOOL_GENERATED")
        self.assertEqual(self.rows["results/raw/gate3_rdata_investigation/run_minimized.sh"]["origin_classification"], "UNKNOWN")

    def test_ppa_comparison_generators_match_actual_writer(self):
        route = classify("results/processed/ab_comparison/ppa_route_comparison.csv", 20)
        resources = classify("results/processed/gate5_reproduction/ab_comparison/ppa_resource_comparison.json", 20)
        self.assertIn("bench/plot_ab_comparison.py", route["file_specific_evidence"])
        self.assertIn("bench/plot_ab_comparison.py", resources["file_specific_evidence"])

    def test_default_generation_is_pinned_and_deterministic(self):
        generator = ROOT / "portfolio_audit/build_ai_provenance_register.py"
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "register.csv"
            context = Path(temp) / "context.json"
            subprocess.run(
                ["python3", str(generator), "--output", str(output), "--context-output", str(context)],
                cwd=ROOT, check=True, capture_output=True, text=True,
            )
            self.assertEqual(output.read_bytes(), REGISTER.read_bytes())
            generated_context = json.loads(context.read_text())
            checked_context = json.loads(CONTEXT.read_text())
            self.assertEqual(generated_context, checked_context)

    def test_generator_defaults_to_pinned_revision_and_refuses_implicit_head(self):
        self.assertEqual(PINNED_REVISION, self.baseline["baseline_revision"])
        generator = ROOT / "portfolio_audit/build_ai_provenance_register.py"
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "register.csv"
            context = Path(temp) / "context.json"
            proc = subprocess.run(
                ["python3", str(generator), "--revision", "HEAD", "--output", str(output), "--context-output", str(context)],
                cwd=ROOT, text=True, capture_output=True,
            )
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("--allow-nonbaseline", proc.stderr)
            self.assertFalse(output.exists())
            self.assertFalse(context.exists())

    def test_nonbaseline_requires_separate_destinations(self):
        generator = ROOT / "portfolio_audit/build_ai_provenance_register.py"
        proc = subprocess.run(
            ["python3", str(generator), "--revision", "HEAD", "--allow-nonbaseline"],
            cwd=ROOT, text=True, capture_output=True,
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("alternate revision inventories require explicit nondefault", proc.stderr)

    def test_output_alias_cannot_overwrite_either_pinned_artifact_for_alternate_revision(self):
        generator = ROOT / "portfolio_audit/build_ai_provenance_register.py"
        protected = (
            "portfolio_audit/generated/ai_provenance_register.csv",
            "portfolio_audit/generated/project_ai_workflow_context.json",
        )
        with tempfile.TemporaryDirectory() as temp:
            for output_path, context_path in (
                ("./" + protected[0], str(Path(temp) / "context.json")),
                (str(Path(temp) / "register.csv"), "./" + protected[1]),
                ("./" + protected[1], str(Path(temp) / "context.json")),
                (str(Path(temp) / "register.csv"), "./" + protected[0]),
            ):
                proc = subprocess.run(
                    ["python3", str(generator), "--revision", "HEAD", "--allow-nonbaseline",
                     "--output", output_path, "--context-output", context_path],
                    cwd=ROOT, text=True, capture_output=True,
                )
                self.assertNotEqual(proc.returncode, 0)
                self.assertIn("alternate revision inventories require explicit nondefault", proc.stderr)


if __name__ == "__main__":
    unittest.main()
