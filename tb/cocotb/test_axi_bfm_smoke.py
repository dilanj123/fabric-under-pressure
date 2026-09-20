import itertools
import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam


def cycle_pause():
    return itertools.cycle([1, 1, 0, 1, 0])


async def reset_dut(dut):
    dut.rst.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    for _ in range(2):
        await RisingEdge(dut.clk)


@cocotb.test()
async def axi_bfm_qualification(dut):
    seed = int(os.getenv("FABRIC_SEED", "0xFABC0001"), 0)
    dut._log.info("FABRIC_SEED=0x%08x", seed)
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    bus = AxiBus.from_prefix(dut, "axi")
    master = AxiMaster(bus, dut.clk, dut.rst, max_burst_len=16)
    ram = AxiRam(bus, dut.clk, dut.rst, size=2**16)

    # Finite, deterministic subordinate-side backpressure.
    ram.write_if.aw_channel.set_pause_generator(cycle_pause())
    ram.write_if.w_channel.set_pause_generator(cycle_pause())
    ram.read_if.ar_channel.set_pause_generator(cycle_pause())
    ram.write_if.b_channel.set_pause_generator(cycle_pause())
    ram.read_if.r_channel.set_pause_generator(cycle_pause())

    await reset_dut(dut)

    # One aligned 64-bit write and read with explicit IDs.
    word = bytes.fromhex("8877665544332211")
    w = await master.write(0x1000, word, awid=0x3, size=3, qos=8)
    assert int(w.resp) == 0
    r = await master.read(0x1000, 8, arid=0x5, size=3, qos=8)
    assert int(r.resp) == 0
    assert bytes(r.data) == word

    # Multi-beat aligned INCR transaction: 32 bytes = four 64-bit beats.
    burst = bytes(range(32))
    w2 = await master.write(0x1080, burst, awid=0x6, size=3, qos=4)
    assert int(w2.resp) == 0
    r2 = await master.read(0x1080, len(burst), arid=0x9, size=3, qos=4)
    assert int(r2.resp) == 0
    assert bytes(r2.data) == burst

    assert ram.read(0x1000, 8) == word
    assert ram.read(0x1080, 32) == burst
