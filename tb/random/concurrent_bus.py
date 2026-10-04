"""Single-owner shadow bus for packed cocotb AXI inputs.

Workers mutate lane dictionaries. Only ``commit`` writes DUT handles. The
class is simulator-agnostic so unit tests can validate packing without a DUT.
"""
from dataclasses import dataclass, field


@dataclass
class ShadowBus:
    managers: int = 3
    targets: int = 3
    lanes: dict = field(default_factory=dict)

    def __post_init__(self):
        self.lanes = {
            "manager_aw": [{} for _ in range(self.managers)],
            "manager_w": [{} for _ in range(self.managers)],
            "manager_ar": [{} for _ in range(self.managers)],
            "manager_bready": [0] * self.managers,
            "manager_rready": [0] * self.managers,
            "target_awready": [0] * self.targets,
            "target_wready": [0] * self.targets,
            "target_arready": [0] * self.targets,
            "target_b": [{} for _ in range(self.targets)],
            "target_r": [{} for _ in range(self.targets)],
        }

    def set_manager(self, channel, manager, **fields):
        self.lanes[channel][manager].update(fields)

    def set_ready(self, channel, index, value):
        self.lanes[channel][index] = int(bool(value))

    def set_target(self, channel, target, **fields):
        self.lanes[channel][target].update(fields)

    def pack(self, channel, field, width, count):
        value = 0
        for i in range(count):
            value |= (int(self.lanes[channel][i].get(field, 0)) & ((1 << width) - 1)) << (i * width)
        return value

    def packed_ready(self, channel):
        value = 0
        for i, bit in enumerate(self.lanes[channel]):
            value |= (int(bit) & 1) << i
        return value
