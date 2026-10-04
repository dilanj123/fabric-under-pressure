import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).parent))
from concurrent_endpoint import BEndpointDriver, RBeat, ReadSnapshot, REndpointDriver


class EndpointTests(unittest.TestCase):
    def test_r_holds_payload_until_handshake(self):
        d = REndpointDriver()
        d.enqueue(ReadSnapshot(0x12, [RBeat(0x12, 0xAA, 0, 0), RBeat(0x12, 0xBB, 0, 1)], 0))
        d.drive(0)
        first = (d.rid, d.rdata, d.rresp, d.rlast)
        for c in range(1, 4):
            d.drive(c)
            self.assertEqual(first, (d.rid, d.rdata, d.rresp, d.rlast))
            self.assertFalse(d.sample(0, c))
        self.assertTrue(d.sample(1, 4))
        d.drive(5)
        self.assertEqual((d.rdata, d.rlast), (0xBB, 1))
        self.assertTrue(d.sample(1, 5))
        self.assertIsNone(d.active)

    def test_b_holds_until_handshake(self):
        d = BEndpointDriver()
        d.enqueue(0x25, 0, 3)
        for c in range(3):
            d.drive(c)
            self.assertEqual(d.bvalid, 0)
        d.drive(3)
        for _ in range(3):
            self.assertEqual((d.bvalid, d.bid, d.bresp), (1, 0x25, 0))
            self.assertFalse(d.sample(0))
        self.assertTrue(d.sample(1))
        self.assertEqual(d.active, None)

    def test_queued_read_bursts_do_not_interleave(self):
        d = REndpointDriver()
        d.enqueue(ReadSnapshot(1, [RBeat(1, 1, 0, 1)], 0))
        d.enqueue(ReadSnapshot(2, [RBeat(2, 2, 0, 1)], 0))
        d.drive(0); self.assertEqual(d.rid, 1); self.assertTrue(d.sample(1, 0))
        d.drive(1); self.assertEqual(d.rid, 2); self.assertTrue(d.sample(1, 1))


if __name__ == '__main__':
    unittest.main()
