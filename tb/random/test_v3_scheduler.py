import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))
from v3_scheduler import Intent, ManagerScheduler


class V3SchedulerTests(unittest.TestCase):
    def test_four_reads_then_d028_reuse(self):
        s = ManagerScheduler()
        for ident in range(4):
            i = Intent(ident, ident, "read")
            self.assertTrue(s.present_ar(i))
            self.assertEqual(s.fire_ar(), i)
        self.assertEqual(set(s.read_live), {0, 1, 2, 3})
        self.assertFalse(s.present_ar(Intent(4, 4, "read")))
        s.fire_r(0, last=True)
        self.assertFalse(s.present_ar(Intent(4, 4, "read")))
        s.step_cycle()
        self.assertTrue(s.present_ar(Intent(4, 4, "read")))

    def test_four_writes_release_owner_without_b(self):
        s = ManagerScheduler()
        for ident in range(4):
            i = Intent(ident, ident, "write")
            self.assertTrue(s.present_aw(i))
            self.assertEqual(s.fire_aw(), i)
            s.fire_manager_w(last=True)
            s.fire_target_w(last=True)
        self.assertEqual(set(s.write_live), {0, 1, 2, 3})
        self.assertIsNone(s.w_owner)
        self.assertFalse(s.present_aw(Intent(4, 4, "write")))
        s.fire_b(0)
        self.assertFalse(s.present_aw(Intent(4, 4, "write")))
        s.step_cycle()
        self.assertTrue(s.present_aw(Intent(4, 4, "write")))

    def test_reset_clears_live_and_owner_state(self):
        s = ManagerScheduler()
        s.present_ar(Intent(1, 1, "read")); s.fire_ar()
        s.present_aw(Intent(2, 2, "write")); s.fire_aw()
        old_epoch = s.epoch
        s.reset()
        self.assertEqual(s.epoch, old_epoch + 1)
        self.assertFalse(s.read_live or s.write_live or s.w_owner)
        self.assertTrue(s.present_ar(Intent(3, 1, "read")))


if __name__ == "__main__":
    unittest.main()
