"""Verification-only external endpoint memory model.

It is deliberately separate from the reference model: it consumes observed
target handshakes and owns its own byte memory.
"""
from axi_reference_model import ByteMemory, RESP_OKAY


class ExternalEndpoint:
    def __init__(self, target: int):
        self.target = target
        self.memory = ByteMemory(salt=target + 1)
        self.aw = None
        self.w_beats = []

    def observe_aw(self, internal_id: int, addr: int, length: int) -> None:
        self.aw = (internal_id, addr, length + 1)
        self.w_beats.clear()

    def observe_w(self, data: int, strobe: int, last: int) -> None:
        if self.aw is None:
            raise AssertionError("endpoint W without AW")
        _, addr, _ = self.aw
        self.memory.write64(addr + 8 * len(self.w_beats), data, strobe)
        self.w_beats.append((data, strobe, last))

    def write_response(self):
        if self.aw is None or not self.w_beats or not self.w_beats[-1][2]:
            return None
        return self.aw[0], RESP_OKAY
