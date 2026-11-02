"""Pure Python state for the central-cycle Gate-3 v3 scheduler."""
from dataclasses import dataclass


@dataclass(frozen=True)
class Intent:
    sequence: int
    ident: int
    direction: str
    target: int = 0
    length: int = 0


class ManagerScheduler:
    def __init__(self, manager=0):
        self.manager = manager
        self.epoch = 0
        self.cycle = 0
        self.read_live = {}
        self.write_live = {}
        self.presented_ar = None
        self.presented_aw = None
        self.w_owner = None
        self._recycle_read = set()
        self._recycle_write = set()
        self._read_capacity_recycled = False
        self._write_capacity_recycled = False

    def step_cycle(self):
        self.cycle += 1
        self._recycle_read.clear()
        self._recycle_write.clear()
        self._read_capacity_recycled = False
        self._write_capacity_recycled = False

    def can_admit_read(self, intent):
        return (intent.ident not in self.read_live
                and intent.ident not in self._recycle_read
                and not self._read_capacity_recycled
                and len(self.read_live) < 4
                and self.presented_ar is None)

    def can_admit_write(self, intent):
        return (intent.ident not in self.write_live
                and intent.ident not in self._recycle_write
                and not self._write_capacity_recycled
                and len(self.write_live) < 4
                and self.presented_aw is None)

    def present_ar(self, intent):
        if not self.can_admit_read(intent):
            return False
        self.presented_ar = intent
        return True

    def fire_ar(self):
        assert self.presented_ar is not None
        intent = self.presented_ar
        self.read_live[intent.ident] = intent
        self.presented_ar = None
        return intent

    def present_aw(self, intent):
        if not self.can_admit_write(intent):
            return False
        self.presented_aw = intent
        return True

    def fire_aw(self):
        assert self.presented_aw is not None
        intent = self.presented_aw
        self.write_live[intent.ident] = intent
        self.presented_aw = None
        self.w_owner = intent
        return intent

    def fire_manager_w(self, last=False):
        assert self.w_owner is not None
        return self.w_owner, bool(last)

    def fire_target_w(self, last=False):
        assert self.w_owner is not None
        owner = self.w_owner
        if last:
            self.w_owner = None
        return owner

    def fire_b(self, ident):
        assert ident in self.write_live
        intent = self.write_live.pop(ident)
        self._recycle_write.add(ident)
        self._write_capacity_recycled = True
        return intent

    def fire_r(self, ident, last=False):
        assert ident in self.read_live
        intent = self.read_live[ident]
        if last:
            self.read_live.pop(ident)
            self._recycle_read.add(ident)
            self._read_capacity_recycled = True
        return intent

    def reset(self):
        self.epoch += 1
        self.read_live.clear()
        self.write_live.clear()
        self.presented_ar = None
        self.presented_aw = None
        self.w_owner = None
        self._recycle_read.clear()
        self._recycle_write.clear()
        self._read_capacity_recycled = False
        self._write_capacity_recycled = False
