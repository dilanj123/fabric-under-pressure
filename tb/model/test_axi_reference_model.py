import unittest
from axi_reference_model import AxiReferenceModel, OracleViolation, ByteMemory


class OracleNegativeTests(unittest.TestCase):
    def setUp(self):
        self.m = AxiReferenceModel()

    def test_loss(self):
        self.m.admit_ar(0, 1, 0, 0)
        with self.assertRaises(OracleViolation): self.m.assert_drained()

    def test_duplication(self):
        self.m.admit_ar(0, 1, 0, 0)
        self.m.observe_r(0, 1, 0, 0, 0, 1)
        with self.assertRaises(OracleViolation): self.m.observe_r(0, 1, 0, 0, 0, 1)

    def test_misroute(self):
        self.m.admit_ar(0, 1, 0, 0)
        with self.assertRaises(OracleViolation): self.m.observe_target_address("ar", 0, 1, 1, 0)

    def test_bad_ids_data_strobe_resp_last_and_order(self):
        self.m.admit_aw(0, 1, 0, 0)
        with self.assertRaises(OracleViolation): self.m.observe_target_w(0, 1, 1, 0xFF, 1)
        with self.assertRaises(OracleViolation): self.m.observe_b(0, 1, 2)
        with self.assertRaises(OracleViolation): self.m.observe_target_w(0, 0, 1, 0xFF, 0)
        self.m.observe_target_w(0, 0, 0xAA, 0x55, 1)
        with self.assertRaises(OracleViolation): self.m.observe_b(1, 1, 0)

    def test_stale_epoch(self):
        self.m.admit_ar(0, 2, 0, 0)
        self.m.reset()
        with self.assertRaises(OracleViolation): self.m.observe_r(0, 2, 0, 0, 0, 1)

    def test_r_source_interleaving(self):
        self.m.admit_ar(0, 2, 0, 1)
        self.m.observe_r_source(0, 0, 2, 0)
        with self.assertRaises(OracleViolation):
            self.m.observe_r_source(0, 1, 3, 0)
        self.m.observe_r_source(0, 0, 2, 1)

    def test_corruption_sensitivity(self):
        self.m.admit_ar(0, 3, 0, 0)
        with self.assertRaises(OracleViolation):
            self.m.observe_r(0, 3, 0, 0xDEAD, 0, 1, addr=0)

    def test_memory_strobes(self):
        mem = ByteMemory(salt=1)
        before = mem.read64(0x20)
        mem.write64(0x20, 0x1122334455667788, 0xAA)
        after = mem.read64(0x20)
        self.assertNotEqual(before, after)
        before_b = before.to_bytes(8, "little")
        after_b = after.to_bytes(8, "little")
        for lane in range(8):
            if 0xAA & (1 << lane):
                self.assertEqual(after_b[lane], (0x1122334455667788 >> (8 * lane)) & 0xFF)
            else:
                self.assertEqual(after_b[lane], before_b[lane])


if __name__ == "__main__":
    unittest.main()
