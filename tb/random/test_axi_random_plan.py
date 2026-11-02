import json
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))
from axi_random_plan import make_plan, validate_plan
sys.path.insert(0, str(Path(__file__).parents[1] / "model"))
from axi_reference_model import legal_request


class RandomPlanTests(unittest.TestCase):
    def test_same_seed_is_identical(self):
        self.assertEqual(make_plan(0xA3F30001), make_plan(0xA3F30001))

    def test_different_seeds_change_random_body(self):
        a = make_plan(0xA3F30001)
        b = make_plan(0xA3F30002)
        self.assertNotEqual(a["random_operations"], b["random_operations"])

    def test_random_body_and_legal_fields(self):
        plan = make_plan(0xA3F30003)
        self.assertGreaterEqual(len(plan["random_operations"]), 512)
        for op in plan["random_operations"]:
            self.assertIn(op["manager"], range(3))
            self.assertIn(op["direction"], ("read", "write"))
            self.assertIn(op["id"], range(16))
            self.assertIn(op["length"], range(16))
            self.assertIn(op["qos"], range(16))
            self.assertTrue(legal_request(op["address"], op["length"], 3, 1, 0))
            if op["direction"] == "write":
                self.assertEqual(len(op["strobes"]), op["length"] + 1)
            self.assertGreaterEqual(op["launch_cycle"], 0)

    def test_saved_plan_round_trip(self):
        plan = make_plan(0xA3F30004)
        encoded = json.dumps(plan, sort_keys=True)
        self.assertEqual(plan, json.loads(encoded))

    def test_all_frozen_seeds_and_lengths_validate(self):
        for seed in (0xA3F30001, 0xA3F30002, 0xA3F30003, 0xA3F30004, 0xA3F30005):
            for count in (512, 2048):
                plan = make_plan(seed, count)
                validate_plan(plan)
                self.assertEqual(len(plan["random_operations"]), count)

    def test_rejects_original_s0_s3_mismatch(self):
        plan = make_plan(0xA3F30001, 512)
        plan["random_operations"][0].update(target=0, address=0x00010040)
        with self.assertRaisesRegex(ValueError, "decodes to S3"):
            validate_plan(plan)

    def test_rejects_mapped_burst_crossing_region(self):
        plan = make_plan(0xA3F30001, 512)
        op = plan["random_operations"][0]
        op.update(target=0, address=0x0000FFC0, length=15)
        with self.assertRaisesRegex(ValueError, "4-KiB crossing|leaves mapped"):
            validate_plan(plan)


if __name__ == "__main__":
    unittest.main()
