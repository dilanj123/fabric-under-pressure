"""Verification-only external endpoint memory model.

It is deliberately separate from the reference model: it consumes observed
target handshakes and owns its own byte memory.
"""
RESP_OKAY = 0b00


class EndpointMemory:
    """Independent verification-endpoint byte memory implementation."""
    def __init__(self, size: int = 64 * 1024, target: int = 0):
        salt = (target + 1) * 0x10
        self.data = bytearray(((i * 37 + salt * 53 + 0x19) & 0xFF)
                              for i in range(size))

    def read64(self, addr: int) -> int:
        off = addr & (len(self.data) - 1)
        return int.from_bytes(self.data[off:off + 8], "little")

    def write64(self, addr: int, value: int, strobe: int) -> None:
        off = addr & (len(self.data) - 1)
        raw = int(value).to_bytes(8, "little")
        for lane in range(8):
            if strobe & (1 << lane):
                self.data[off + lane] = raw[lane]


class ExternalEndpoint:
    def __init__(self, target: int):
        self.target = target
        self.memory = EndpointMemory(target=target)
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
