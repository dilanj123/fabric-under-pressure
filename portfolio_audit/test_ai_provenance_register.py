import csv
import json
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REGISTER = ROOT / "portfolio_audit/generated/ai_provenance_register.csv"
BASELINE = ROOT / "portfolio_audit/generated/authorship_baseline.json"
ALLOWED = {
    "HUMAN_CONFIRMED", "AI_GENERATED_CONFIRMED", "AI_ASSISTED_CONFIRMED",
    "MIXED_CONFIRMED", "TOOL_GENERATED", "THIRD_PARTY", "UNKNOWN",
}


class ProvenanceRegisterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline = json.loads(BASELINE.read_text())
        with REGISTER.open(newline="", encoding="utf-8") as stream:
            cls.rows = list(csv.DictReader(stream))

    def test_paths_and_blobs_match_recorded_git_tree(self):
        revision = self.baseline["baseline_revision"]
        tree = subprocess.check_output(
            ["git", "ls-tree", "-rz", "--full-tree", revision], cwd=ROOT
        ).split(b"\0")
        expected = {}
        for item in tree:
            if not item:
                continue
            meta, path = item.split(b"\t", 1)
            mode, kind, oid = meta.decode().split()
            if kind == "blob":
                expected[path.decode("utf-8", "surrogateescape")] = oid
        actual = {row["path"]: row["git_blob_sha"] for row in self.rows}
        self.assertEqual(len(self.rows), len(actual))
        self.assertEqual(actual, expected)

    def test_classifications_are_explicit_and_cautious(self):
        self.assertEqual(len(self.rows), self.baseline["tracked_path_count"])
        for row in self.rows:
            self.assertIn(row["origin_classification"], ALLOWED)
            self.assertTrue(row["evidence_type"])
            self.assertTrue(row["limitations"])
        self.assertFalse(any(r["origin_classification"] == "HUMAN_CONFIRMED" for r in self.rows))
        self.assertFalse(any(r["origin_classification"] == "AI_GENERATED_CONFIRMED" for r in self.rows))


if __name__ == "__main__":
    unittest.main()
