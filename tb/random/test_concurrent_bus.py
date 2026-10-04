import unittest
from concurrent_bus import ShadowBus


class ShadowBusTests(unittest.TestCase):
    def test_workers_do_not_write_packed_values(self):
        b = ShadowBus()
        b.set_manager('manager_aw', 0, id=5, valid=1)
        b.set_manager('manager_aw', 1, id=9, valid=1)
        self.assertEqual(b.pack('manager_aw', 'id', 4, 3), 0x095)
        self.assertEqual(b.pack('manager_aw', 'valid', 1, 3), 0b011)

    def test_target_ready_packing(self):
        b = ShadowBus()
        b.set_ready('target_rready', 0, 1) if 'target_rready' in b.lanes else None
        b.set_ready('target_awready', 1, 1)
        self.assertEqual(b.packed_ready('target_awready'), 0b010)


if __name__ == '__main__':
    unittest.main()
