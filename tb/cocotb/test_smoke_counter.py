import os
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def counter_smoke(dut):
    seed = int(os.getenv("FABRIC_SEED", "0xFABC0001"), 0)
    random.seed(seed)
    dut._log.info("FABRIC_SEED=0x%08x", seed)

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.in_valid.value = 0
    dut.in_data.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    values = [random.randrange(256) for _ in range(8)]
    for value in values:
        dut.in_data.value = value
        dut.in_valid.value = 1
        await RisingEdge(dut.clk)
        assert int(dut.in_ready.value) == 1
    dut.in_valid.value = 0
    await RisingEdge(dut.clk)

    assert int(dut.accepted_count.value) == len(values)
    assert int(dut.last_data.value) == values[-1]
