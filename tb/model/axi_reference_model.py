"""Independent Architecture-A Gate-2 reference model.

The model consumes manager-facing handshakes and target observations.  It does
not import RTL constants or inspect DUT state.
"""
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

BEATS_MAX = 16
RESP_OKAY = 0b00
RESP_DECERR = 0b11


class OracleViolation(AssertionError):
    pass


@dataclass(frozen=True)
class TxKey:
    direction: str
    manager: int
    ident: int
    epoch: int


@dataclass
class Transaction:
    key: TxKey
    target: int
    addr: int
    length: int
    size: int
    burst: int
    qos: int
    accept_cycle: int
    expected_beats: int
    lock: int = 0
    cache: int = 0
    prot: int = 0
    region: int = 0
    w_beats: List[Tuple[int, int, int]] = field(default_factory=list)
    manager_w_beats: List[Tuple[int, int, int]] = field(default_factory=list)
    r_beats: int = 0
    completed: bool = False
    target_address_seen: bool = False


def decode_target(addr: int) -> int:
    if 0x0000_0000 <= addr <= 0x0000_FFFF:
        return 0
    if 0x1000_0000 <= addr <= 0x1000_FFFF:
        return 1
    if 0x2000_0000 <= addr <= 0x2000_0FFF:
        return 2
    return 3


def legal_request(addr: int, length: int, size: int, burst: int, lock: int = 0) -> bool:
    beats = length + 1
    return (0 <= length <= 15 and size == 3 and burst == 1 and lock == 0
            and (addr & 7) == 0 and ((addr & 0xFFF) + beats * 8) <= 4096)


class ByteMemory:
    def __init__(self, size: int = 64 * 1024, salt: int = 0):
        self.data = bytearray(((i * 37 + salt * 53 + 0x19) & 0xFF) for i in range(size))

    def read64(self, addr: int) -> int:
        off = addr & (len(self.data) - 1)
        return int.from_bytes(self.data[off:off + 8], "little")

    def write64(self, addr: int, value: int, strobe: int) -> None:
        off = addr & (len(self.data) - 1)
        raw = int(value).to_bytes(8, "little")
        for lane in range(8):
            if strobe & (1 << lane):
                self.data[off + lane] = raw[lane]


class AxiReferenceModel:
    def __init__(self):
        self.epoch = 0
        self.cycle = 0
        self.transactions: Dict[TxKey, Transaction] = {}
        self.active_write: Dict[int, TxKey] = {}
        self.memories = {0: ByteMemory(salt=0x10), 1: ByteMemory(salt=0x20)}
        self.events: List[dict] = []
        self.r_source_lock: Dict[int, Tuple[int, int]] = {}

    def reset(self) -> None:
        self.events.append({"kind": "reset", "cycle": self.cycle, "epoch": self.epoch + 1})
        self.epoch += 1
        self.transactions.clear()
        self.active_write.clear()
        self.r_source_lock.clear()

    def _admit(self, direction: str, manager: int, ident: int, addr: int,
               length: int, size: int, burst: int, qos: int = 0,
               lock: int = 0, cache: int = 0, prot: int = 0, region: int = 0) -> Transaction:
        if not legal_request(addr, length, size, burst, lock):
            raise OracleViolation(f"unsupported {direction} request manager={manager} id={ident}")
        key = TxKey(direction, manager, ident, self.epoch)
        if key in self.transactions and not self.transactions[key].completed:
            raise OracleViolation(f"duplicate live {key}")
        tx = Transaction(key, decode_target(addr), addr, length, size, burst, qos,
                         self.cycle, length + 1, lock, cache, prot, region)
        self.transactions[key] = tx
        self.events.append({"kind": direction + "_admit", "cycle": self.cycle,
                            "epoch": self.epoch, "manager": manager, "id": ident,
                            "internal_id": (manager << 4) | ident, "target": tx.target})
        return tx

    def admit_aw(self, manager: int, ident: int, addr: int, length: int,
                 size: int = 3, burst: int = 1, qos: int = 0, lock: int = 0,
                 cache: int = 0, prot: int = 0, region: int = 0) -> Transaction:
        if manager in self.active_write:
            raise OracleViolation(f"manager {manager} has unfinished W owner")
        tx = self._admit("aw", manager, ident, addr, length, size, burst, qos,
                         lock, cache, prot, region)
        self.active_write[manager] = tx.key
        return tx

    def admit_ar(self, manager: int, ident: int, addr: int, length: int,
                 size: int = 3, burst: int = 1, qos: int = 0, lock: int = 0,
                 cache: int = 0, prot: int = 0, region: int = 0) -> Transaction:
        return self._admit("ar", manager, ident, addr, length, size, burst, qos,
                           lock, cache, prot, region)

    def observe_target_address(self, direction: str, manager: int, ident: int,
                               observed_internal_id: int, target: int, addr: int,
                               length: Optional[int] = None, size: Optional[int] = None,
                               burst: Optional[int] = None, lock: Optional[int] = None,
                               cache: Optional[int] = None, prot: Optional[int] = None,
                               qos: Optional[int] = None, region: Optional[int] = None) -> None:
        matches = [tx for tx in self.transactions.values()
                   if tx.key.direction == direction and tx.key.manager == manager
                   and tx.key.ident == ident and tx.key.epoch == self.epoch]
        if len(matches) != 1:
            raise OracleViolation(f"target {direction} without manager admission manager={manager} id={ident}")
        tx = matches[0]
        if tx.target != target:
            raise OracleViolation(f"misroute cycle={self.cycle} expected=S{tx.target} observed=S{target}")
        if tx.addr != addr:
            raise OracleViolation(f"bad {direction} address expected={tx.addr:#x} observed={addr:#x}")
        observed = (length, size, burst, lock, cache, prot, qos, region)
        expected = (tx.length, tx.size, tx.burst, tx.lock, tx.cache, tx.prot, tx.qos, tx.region)
        if all(value is not None for value in observed) and observed != expected:
            raise OracleViolation(f"bad {direction} payload expected={expected} observed={observed}")
        expected_internal = (manager << 4) | ident
        if observed_internal_id != expected_internal:
            raise OracleViolation(
                f"bad target {direction} ID expected={expected_internal:#x} observed={observed_internal_id:#x}")
        if tx.target_address_seen:
            raise OracleViolation(f"duplicate target {direction} delivery manager={manager} id={ident}")
        tx.target_address_seen = True
        self.events.append({"kind": direction + "_target", "cycle": self.cycle,
                            "epoch": self.epoch,
                            "manager": manager, "id": ident, "target": target,
                            "internal_id": observed_internal_id, "addr": addr})

    def accept_manager_w(self, manager: int, data: int, strobe: int, last: int) -> Transaction:
        if manager not in self.active_write:
            raise OracleViolation("manager W without accepted AW")
        tx = self.transactions[self.active_write[manager]]
        beat = len(tx.manager_w_beats)
        expected_last = int(beat == tx.expected_beats - 1)
        if int(last) != expected_last:
            raise OracleViolation(f"bad manager WLAST beat={beat} expected={expected_last} observed={last}")
        if beat >= tx.expected_beats:
            raise OracleViolation("duplicate manager W beat")
        tx.manager_w_beats.append((data, strobe, int(last)))
        self.events.append({"kind": "w_admit", "cycle": self.cycle, "epoch": self.epoch, "manager": manager,
                            "id": tx.key.ident, "target": tx.target, "beat": beat,
                            "data": data, "strobe": strobe, "last": int(last)})
        return tx

    def observe_target_w(self, manager: int, target: int, data: int,
                         strobe: int, last: int) -> Transaction:
        if manager not in self.active_write:
            raise OracleViolation("W without accepted AW")
        tx = self.transactions[self.active_write[manager]]
        beat = len(tx.w_beats)
        if target != tx.target:
            raise OracleViolation(f"W misroute expected=S{tx.target} observed=S{target}")
        if beat >= len(tx.manager_w_beats):
            raise OracleViolation("target W beat has no manager W admission")
        expected_data, expected_strobe, expected_last = tx.manager_w_beats[beat]
        if (data, strobe, int(last)) != (expected_data, expected_strobe, expected_last):
            raise OracleViolation(
                f"target W mismatch manager={manager} beat={beat} "
                f"expected=({expected_data:#x},{expected_strobe:#x},{expected_last}) "
                f"observed=({data:#x},{strobe:#x},{int(last)})")
        tx.w_beats.append((data, strobe, int(last)))
        if target in self.memories:
            self.memories[target].write64(tx.addr + 8 * beat, data, strobe)
        self.events.append({"kind": "w_target", "cycle": self.cycle, "epoch": self.epoch, "manager": manager,
                            "id": tx.key.ident, "target": target, "beat": beat,
                            "data": data, "strobe": strobe, "last": int(last)})
        if expected_last:
            self.active_write.pop(manager)
        return tx

    def observe_b(self, manager: int, ident: int, resp: int) -> Transaction:
        matches = [tx for tx in self.transactions.values()
                   if tx.key.direction == "aw" and tx.key.manager == manager
                   and tx.key.ident == ident and not tx.completed]
        if len(matches) != 1:
            raise OracleViolation(f"duplicate/lost B manager={manager} id={ident}")
        tx = matches[0]
        if len(tx.manager_w_beats) != tx.expected_beats:
            raise OracleViolation(
                f"premature B manager={manager} id={ident}: "
                f"manager W beats={len(tx.manager_w_beats)} expected={tx.expected_beats}")
        if tx.target != 3:
            if not tx.target_address_seen or len(tx.w_beats) != tx.expected_beats:
                raise OracleViolation(
                    f"premature mapped B manager={manager} id={ident}: "
                    f"target AW/W incomplete")
        expected = RESP_DECERR if tx.target == 3 else RESP_OKAY
        if resp != expected:
            raise OracleViolation(f"bad BRESP expected={expected} observed={resp}")
        tx.completed = True
        self.events.append({"kind": "b_complete", "cycle": self.cycle, "epoch": self.epoch,
                            "manager": manager, "id": ident, "target": tx.target})
        return tx

    def observe_r(self, manager: int, ident: int, data: int, resp: int,
                  last: int, addr: Optional[int] = None) -> Transaction:
        matches = [tx for tx in self.transactions.values()
                   if tx.key.direction == "ar" and tx.key.manager == manager
                   and tx.key.ident == ident and not tx.completed]
        if len(matches) != 1:
            raise OracleViolation(f"duplicate/lost R manager={manager} id={ident}")
        tx = matches[0]
        beat = tx.r_beats
        if beat >= tx.expected_beats:
            raise OracleViolation(f"duplicate/extra R manager={manager} id={ident}")
        expected_last = int(beat == tx.expected_beats - 1)
        if int(last) != expected_last:
            raise OracleViolation(f"bad RLAST beat={beat} expected={expected_last} observed={last}")
        expected_resp = RESP_DECERR if tx.target == 3 else RESP_OKAY
        if resp != expected_resp:
            raise OracleViolation(f"bad RRESP expected={expected_resp} observed={resp}")
        if tx.target == 3 and data != 0:
            raise OracleViolation("S3 returned non-zero RDATA")
        if tx.target in self.memories and addr is not None and data != self.memories[tx.target].read64(addr):
            raise OracleViolation(f"bad RDATA manager={manager} id={ident} beat={beat}")
        tx.r_beats += 1
        if expected_last:
            tx.completed = True
        self.events.append({"kind": "r_beat", "cycle": self.cycle, "epoch": self.epoch, "manager": manager,
                            "id": ident, "target": tx.target, "beat": beat,
                            "data": data, "resp": resp, "last": int(last)})
        return tx

    def observe_r_source(self, manager: int, target: int, ident: int, last: int) -> None:
        """Check the frozen contiguous-source rule independently of RTL state."""
        held = self.r_source_lock.get(manager)
        source = (target, ident)
        if held is not None and held != source:
            raise OracleViolation(
                f"R source interleaving manager={manager} held={held} observed={source}")
        if held is None:
            self.r_source_lock[manager] = source
        if last:
            self.r_source_lock.pop(manager, None)

    def advance(self, cycles: int = 1) -> None:
        self.cycle += cycles

    def assert_drained(self) -> None:
        live = [tx.key for tx in self.transactions.values() if not tx.completed]
        if live:
            raise OracleViolation(f"transactions not drained: {live}")
