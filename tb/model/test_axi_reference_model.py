import unittest
from axi_reference_model import AxiReferenceModel, OracleViolation, ByteMemory
from axi_endpoint_model import EndpointMemory


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
        with self.assertRaises(OracleViolation): self.m.observe_target_address("ar", 0, 1, 0x01, 1, 0)

    def test_bad_ids_data_strobe_resp_last_and_order(self):
        self.m.admit_aw(0, 1, 0, 0)
        self.m.accept_manager_w(0, 1, 0xFF, 1)
        with self.assertRaisesRegex(OracleViolation, "target W mismatch"):
            self.m.observe_target_w(0, 0, 2, 0xFF, 1)
        with self.assertRaises(OracleViolation): self.m.observe_b(0, 1, 2)
        with self.assertRaisesRegex(OracleViolation, "target W mismatch"):
            self.m.observe_target_w(0, 0, 1, 0xFF, 0)
        self.m.observe_target_w(0, 0, 1, 0xFF, 1)
        with self.assertRaises(OracleViolation): self.m.observe_b(1, 1, 0)

    def test_explicit_bad_target_ids(self):
        self.m.admit_aw(0, 3, 0, 0)
        with self.assertRaisesRegex(OracleViolation, "bad target aw ID"):
            self.m.observe_target_address("aw", 0, 3, 0x13, 0, 0)
        self.m.reset()
        self.m.admit_ar(1, 4, 0x100, 0)
        with self.assertRaisesRegex(OracleViolation, "bad target ar ID"):
            self.m.observe_target_address("ar", 1, 4, 0x04, 0, 0x100)

    def test_explicit_bad_returned_ids(self):
        self.m.admit_aw(0, 2, 0, 0)
        with self.assertRaisesRegex(OracleViolation, "duplicate/lost B"):
            self.m.observe_b(0, 3, 0)
        self.m.reset()
        self.m.admit_ar(0, 2, 0, 0)
        with self.assertRaisesRegex(OracleViolation, "duplicate/lost R"):
            self.m.observe_r(0, 3, 0, 0, 0, 1)

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

    def test_reference_endpoint_initialization_contract(self):
        for target, salt in ((0, 0x10), (1, 0x20)):
            reference = ByteMemory(salt=salt)
            endpoint = EndpointMemory(target=target)
            for addr in (0, 7, 0x118, 0xFF8, 0x8000):
                self.assertEqual(reference.read64(addr), endpoint.read64(addr))


if __name__ == "__main__":
    unittest.main()
