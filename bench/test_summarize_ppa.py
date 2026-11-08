"""Fail-closed tests for the qualified Yosys resource-summary formats."""
from pathlib import Path
import tempfile
import unittest

from bench.summarize_ppa import PPAReportError, direct_synth_counts, wrapped_synth_counts


DIRECT = """=== axi_fabric_a ===

        +----------Local Count, excluding submodules.
        |
     100 wires
      20 wire bits
       10 ports
      100 cells
       12   CCU2C
       20   LUT4
        0   PFUMX
        8   TRELLIS_FF

Warnings: 0 unique messages
"""

WRAPPED = """=== design hierarchy ===

        +----------Count including submodules.
        |
        - arch_fabric_wrapper

        +----------Count including submodules.
        |
      100 wires
       10 ports
        - memories
        - processes
      100 cells
       12   CCU2C
       20   LUT4
        8   TRELLIS_FF
        1 submodules
        1   axi_fabric_a

Warnings: 0 unique messages
"""


class PpaParserTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / "yosys.log"

    def tearDown(self):
        self.temp.cleanup()

    def write(self, text):
        self.path.write_text(text)
        return self.path

    def test_direct_real_format_and_optional_zero(self):
        counts = direct_synth_counts(self.write(DIRECT), "axi_fabric_a")
        self.assertEqual(counts["LUT4"], 20)
        self.assertEqual(counts["TRELLIS_FF"], 8)
        self.assertEqual(counts["PFUMX"], 0)
        self.assertEqual(counts["DP16KD"], 0)

    def test_missing_report_section_fails(self):
        with self.assertRaisesRegex(PPAReportError, "missing Yosys report section"):
            direct_synth_counts(self.write("Warnings: none\n"), "axi_fabric_a")

    def test_wrong_top_fails(self):
        with self.assertRaisesRegex(PPAReportError, "expected DUT top axi_fabric_a"):
            direct_synth_counts(self.write(DIRECT.replace("axi_fabric_a", "axi_fabric_b")),
                                "axi_fabric_a")

    def test_missing_required_resource_fails(self):
        malformed = DIRECT.replace("       20   LUT4\n", "")
        with self.assertRaisesRegex(PPAReportError, "missing required resource counts"):
            direct_synth_counts(self.write(malformed), "axi_fabric_a")

    def test_malformed_required_count_fails(self):
        malformed = DIRECT.replace("       20   LUT4", "   many LUT4")
        with self.assertRaisesRegex(PPAReportError, "malformed resource count"):
            direct_synth_counts(self.write(malformed), "axi_fabric_a")

    def test_wrapped_hierarchy_identifies_dut_and_counts(self):
        counts = wrapped_synth_counts(self.write(WRAPPED), "axi_fabric_a")
        self.assertEqual(counts["LUT4"], 20)
        self.assertEqual(counts["TRELLIS_FF"], 8)
        self.assertEqual(counts["DP16KD"], 0)

    def test_wrapped_wrong_dut_fails(self):
        with self.assertRaisesRegex(PPAReportError, "does not contain expected DUT"):
            wrapped_synth_counts(self.write(WRAPPED.replace("axi_fabric_a", "axi_fabric_b")),
                                 "axi_fabric_a")

    def test_synthesis_failure_is_not_parsed_as_zero(self):
        with self.assertRaisesRegex(PPAReportError, "synthesis log reports failure"):
            direct_synth_counts(self.write("ERROR: synth_ecp5 failed\n"), "axi_fabric_a")


if __name__ == "__main__":
    unittest.main()
