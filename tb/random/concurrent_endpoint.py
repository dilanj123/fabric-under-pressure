"""Handshake-driven verification endpoint primitives for Gate-3."""
from dataclasses import dataclass
from typing import List, Optional, Tuple


@dataclass
class RBeat:
    rid: int
    data: int
    resp: int
    last: int


@dataclass
class ReadSnapshot:
    rid: int
    beats: List[RBeat]
    ready_cycle: int
    index: int = 0
    valid: bool = False


class REndpointDriver:
    """One target R source. State changes only on sampled handshakes."""
    def __init__(self):
        self.queue: List[ReadSnapshot] = []
        self.active: Optional[ReadSnapshot] = None
        self.rvalid = 0
        self.rid = 0
        self.rdata = 0
        self.rresp = 0
        self.rlast = 0
        self.present_cycle = None

    def enqueue(self, snapshot: ReadSnapshot) -> None:
        self.queue.append(snapshot)

    def drive(self, cycle: int) -> None:
        if self.active is None and self.queue:
            if cycle >= self.queue[0].ready_cycle:
                self.active = self.queue.pop(0)
        if self.active is None:
            self.rvalid = 0
            return
        beat = self.active.beats[self.active.index]
        self.rvalid = 1
        self.rid, self.rdata, self.rresp, self.rlast = beat.rid, beat.data, beat.resp, beat.last
        if self.present_cycle is None:
            self.present_cycle = cycle

    def sample(self, target_rready: int, cycle: int) -> bool:
        """Consume one beat only for a sampled RVALID && RREADY event."""
        fire = bool(self.rvalid and target_rready)
        if not fire:
            return False
        assert self.active is not None
        assert self.active.beats[self.active.index] == RBeat(
            self.rid, self.rdata, self.rresp, self.rlast)
        self.active.index += 1
        self.present_cycle = None
        if self.active.index == len(self.active.beats):
            self.active = None
        return True


class BEndpointDriver:
    def __init__(self):
        self.queue: List[Tuple[int, int, int]] = []
        self.active = None
        self.bvalid = 0
        self.bid = 0
        self.bresp = 0

    def enqueue(self, bid: int, bresp: int, ready_cycle: int) -> None:
        self.queue.append((bid, bresp, ready_cycle))

    def drive(self, cycle: int) -> None:
        if self.active is None and self.queue and cycle >= self.queue[0][2]:
            self.active = self.queue.pop(0)[:2]
        if self.active is None:
            self.bvalid = 0
            return
        self.bvalid = 1
        self.bid, self.bresp = self.active

    def sample(self, target_bready: int) -> bool:
        fire = bool(self.bvalid and target_bready)
        if fire:
            self.active = None
        return fire
