import json
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from axi_reference_model import AxiReferenceModel, RESP_DECERR


def lane(value: int, width: int, index: int) -> int:
    return value << (width * index)


def set_lane(handle, width: int, index: int, value: int) -> None:
    current = int(handle.value)
    mask = ((1 << width) - 1) << (width * index)
    handle.value = (current & ~mask) | lane(value, width, index)


def get_lane(handle, width: int, index: int) -> int:
    return (int(handle.value) >> (width * index)) & ((1 << width) - 1)


async def cycles(dut, count=1):
    for _ in range(count):
        await RisingEdge(dut.ACLK)


def address_for(target: int, offset: int) -> int:
    bases = (0x0000_0000, 0x1000_0000, 0x2000_0000, 0x3000_0000)
    return bases[target] + offset


def endpoint_read(memory, addr: int) -> int:
    raw = bytes(memory[(addr & 0xFFFF):((addr & 0xFFFF) + 8)])
    return int.from_bytes(raw, "little")


def endpoint_write(memory, addr: int, data: int, strobe: int) -> None:
    raw = int(data).to_bytes(8, "little")
    off = addr & 0xFFFF
    for lane in range(8):
        if strobe & (1 << lane):
            memory[off + lane] = raw[lane]


def init_endpoint_memory(salt: int) -> bytearray:
    return bytearray(((i * 37 + salt * 53 + 0x19) & 0xFF) for i in range(64 * 1024))


async def mapped_write(dut, model, memory, manager, ident, target, length, strobes):
    addr = address_for(target, 0x080 + (ident * 8))
    set_lane(dut.manager_awid, 4, manager, ident)
    set_lane(dut.manager_awaddr, 32, manager, addr)
    set_lane(dut.manager_awlen, 8, manager, length)
    set_lane(dut.manager_awsize, 3, manager, 3)
    set_lane(dut.manager_awburst, 2, manager, 1)
    set_lane(dut.manager_awlock, 1, manager, 0)
    set_lane(dut.manager_awvalid, 1, manager, 1)
    while not get_lane(dut.manager_awready, 1, manager):
        await cycles(dut)
    tx = model.admit_aw(manager, ident, addr, length)
    set_lane(dut.manager_awvalid, 1, manager, 0)
    await cycles(dut)
    while not get_lane(dut.target_awvalid, 1, target):
        await cycles(dut)
    observed_id = get_lane(dut.target_awid, 6, target)
    if observed_id != ((manager << 4) | ident):
        raise AssertionError(f"bad target AWID M{manager} ID{ident}: {observed_id:#x}")
    model.observe_target_address("aw", manager, ident, target, addr)
    await cycles(dut)
    for beat in range(length + 1):
        data = (0x1000_0000_0000_0000 | (manager << 48) | (ident << 32) | beat)
        strobe = strobes[beat]
        last = int(beat == length)
        set_lane(dut.manager_wdata, 64, manager, data)
        set_lane(dut.manager_wstrb, 8, manager, strobe)
        set_lane(dut.manager_wlast, 1, manager, last)
        set_lane(dut.manager_wvalid, 1, manager, 1)
        while not get_lane(dut.manager_wready, 1, manager):
            await cycles(dut)
        await cycles(dut)
        set_lane(dut.manager_wvalid, 1, manager, 0)
        while not get_lane(dut.target_wvalid, 1, target):
            await cycles(dut)
        obs_data = get_lane(dut.target_wdata, 64, target)
        obs_strobe = get_lane(dut.target_wstrb, 8, target)
        obs_last = get_lane(dut.target_wlast, 1, target)
        if (obs_data, obs_strobe, obs_last) != (data, strobe, last):
            raise AssertionError("target W payload mismatch")
        model.observe_target_w(manager, target, obs_data, obs_strobe, obs_last)
        if target in (0, 1):
            endpoint_write(memory[target], tx.addr + 8 * beat, obs_data, obs_strobe)
        await cycles(dut)
    set_lane(dut.target_bid, 6, target, (manager << 4) | ident)
    set_lane(dut.target_bresp, 2, target, 0)
    set_lane(dut.target_bvalid, 1, target, 1)
    set_lane(dut.manager_bready, 1, manager, 1)
    while not get_lane(dut.target_bready, 1, target):
        await cycles(dut)
    await cycles(dut)
    set_lane(dut.target_bvalid, 1, target, 0)
    while not get_lane(dut.manager_bvalid, 1, manager):
        await cycles(dut)
    if get_lane(dut.manager_bid, 4, manager) != ident or get_lane(dut.manager_bresp, 2, manager) != 0:
        raise AssertionError("mapped B response mismatch")
    model.observe_b(manager, ident, 0)
    await cycles(dut)
    set_lane(dut.manager_bready, 1, manager, 0)


async def mapped_read(dut, model, memory, manager, ident, target, length, addr):
    set_lane(dut.manager_arid, 4, manager, ident)
    set_lane(dut.manager_araddr, 32, manager, addr)
    set_lane(dut.manager_arlen, 8, manager, length)
    set_lane(dut.manager_arsize, 3, manager, 3)
    set_lane(dut.manager_arburst, 2, manager, 1)
    set_lane(dut.manager_arlock, 1, manager, 0)
    set_lane(dut.manager_arvalid, 1, manager, 1)
    while not get_lane(dut.manager_arready, 1, manager):
        await cycles(dut)
    model.admit_ar(manager, ident, addr, length)
    set_lane(dut.manager_arvalid, 1, manager, 0)
    await cycles(dut)
    while not get_lane(dut.target_arvalid, 1, target):
        await cycles(dut)
    if get_lane(dut.target_arid, 6, target) != ((manager << 4) | ident):
        raise AssertionError("bad target ARID")
    model.observe_target_address("ar", manager, ident, target, addr)
    await cycles(dut)
    set_lane(dut.manager_rready, 1, manager, 1)
    for beat in range(length + 1):
        data = endpoint_read(memory[target], addr + beat * 8) if target in (0, 1) else 0
        last = int(beat == length)
        set_lane(dut.target_rid, 6, target, (manager << 4) | ident)
        set_lane(dut.target_rdata, 64, target, data)
        set_lane(dut.target_rresp, 2, target, 0)
        set_lane(dut.target_rlast, 1, target, last)
        set_lane(dut.target_rvalid, 1, target, 1)
        while not get_lane(dut.target_rready, 1, target):
            await cycles(dut)
        await cycles(dut)
        set_lane(dut.target_rvalid, 1, target, 0)
        while not get_lane(dut.manager_rvalid, 1, manager):
            await cycles(dut)
        obs_id = get_lane(dut.manager_rid, 4, manager)
        obs_data = get_lane(dut.manager_rdata, 64, manager)
        obs_resp = get_lane(dut.manager_rresp, 2, manager)
        obs_last = get_lane(dut.manager_rlast, 1, manager)
        if (obs_id, obs_data, obs_resp, obs_last) != (ident, data, 0, last):
            raise AssertionError("manager R payload mismatch")
        model.observe_r(manager, ident, beat, obs_data, obs_resp, obs_last,
                        addr + beat * 8 if target in (0, 1) else None)
        await cycles(dut)
    set_lane(dut.manager_rready, 1, manager, 0)


async def concurrent_same_id(dut, model, memory):
    """Overlap one same-visible-ID transaction per manager."""
    ident = 5
    targets = (0, 1, 2)
    addresses = [address_for(t, 0x700 + 8 * m) for m, t in enumerate(targets)]
    awid = awaddr = awlen = awsize = awburst = awvalid = 0
    for m, t in enumerate(targets):
        awid |= ident << (4 * m)
        awaddr |= addresses[m] << (32 * m)
        awsize |= 3 << (3 * m)
        awburst |= 1 << (2 * m)
        awvalid |= 1 << m
    dut.manager_awid.value = awid
    dut.manager_awaddr.value = awaddr
    dut.manager_awlen.value = awlen
    dut.manager_awsize.value = awsize
    dut.manager_awburst.value = awburst
    dut.manager_awvalid.value = awvalid
    admitted = [False] * 3
    wait_cycles = 0
    while not all(admitted):
        await cycles(dut)
        wait_cycles += 1
        if wait_cycles > 100:
            raise AssertionError(
                f"concurrent AW admission timeout ready={int(dut.manager_awready.value):03b} "
                f"addr={int(dut.manager_awaddr.value):024x} len={int(dut.manager_awlen.value):06x} "
                f"size={int(dut.manager_awsize.value):09x} burst={int(dut.manager_awburst.value):06x} "
                f"lock={int(dut.manager_awlock.value):03b}")
        for m in range(3):
            if not admitted[m] and get_lane(dut.manager_awready, 1, m):
                model.admit_aw(m, ident, addresses[m], 0)
                admitted[m] = True
                set_lane(dut.manager_awvalid, 1, m, 0)
    seen_aw = [False] * 3
    while not all(seen_aw):
        for m, t in enumerate(targets):
            if not seen_aw[m] and get_lane(dut.target_awvalid, 1, t):
                if get_lane(dut.target_awid, 6, t) != ((m << 4) | ident):
                    raise AssertionError("same-ID widened AWID collision")
                model.observe_target_address("aw", m, ident, t, addresses[m])
                seen_aw[m] = True
        if not all(seen_aw):
            await cycles(dut)
    dut._log.info("oracle concurrent AW target handshakes PASS")
    await cycles(dut)
    wdata = wstrb = wlast = wvalid = 0
    for m in range(3):
        wdata |= (0xABC000 + m) << (64 * m)
        wstrb |= 0xFF << (8 * m)
        wlast |= 1 << m
        wvalid |= 1 << m
    dut.manager_wdata.value = wdata
    dut.manager_wstrb.value = wstrb
    dut.manager_wlast.value = wlast
    dut.manager_wvalid.value = wvalid
    delivered = [False] * 3
    while not all(delivered):
        await cycles(dut)
        for m, t in enumerate(targets):
            if not delivered[m] and get_lane(dut.target_wvalid, 1, t):
                data = get_lane(dut.target_wdata, 64, t)
                model.observe_target_w(m, t, data, get_lane(dut.target_wstrb, 8, t),
                                       get_lane(dut.target_wlast, 1, t))
                delivered[m] = True
                set_lane(dut.manager_wvalid, 1, m, 0)
    dut._log.info("oracle concurrent W target handshakes PASS")
    bid = bresp = bvalid = bready = 0
    for m, t in enumerate(targets):
        bid |= ((m << 4) | ident) << (6 * t)
        bvalid |= 1 << t
        bready |= 1 << m
    dut.target_bid.value = bid
    dut.target_bresp.value = bresp
    dut.target_bvalid.value = bvalid
    dut.manager_bready.value = bready
    completed = [False] * 3
    while not all(completed):
        await cycles(dut)
        for m in range(3):
            if not completed[m] and get_lane(dut.manager_bvalid, 1, m):
                if get_lane(dut.manager_bid, 4, m) != ident:
                    raise AssertionError("same-ID returned BID mismatch")
                model.observe_b(m, ident, 0)
                completed[m] = True
    dut.manager_bready.value = 0
    dut._log.info("oracle concurrent B completions PASS")
    dut.target_bvalid.value = 0
    await cycles(dut, 2)


@cocotb.test()
async def fabric_a_s3_oracle(dut):
    model = AxiReferenceModel()
    trace_path = Path(os.environ["ROOT"]) / "results/raw/gate2_oracle/event_trace.jsonl"
    trace_path.parent.mkdir(parents=True, exist_ok=True)
    trace = trace_path.open("w", encoding="utf-8")

    # Initialize all packed manager-side inputs and external target channels.
    for name in ("manager_awid", "manager_awaddr", "manager_awlen", "manager_awsize",
                 "manager_awburst", "manager_awlock", "manager_awcache", "manager_awprot",
                 "manager_awqos", "manager_awregion", "manager_awvalid", "manager_wdata",
                 "manager_wstrb", "manager_wlast", "manager_wvalid", "manager_bready",
                 "manager_arid", "manager_araddr", "manager_arlen", "manager_arsize",
                 "manager_arburst", "manager_arlock", "manager_arcache", "manager_arprot",
                 "manager_arqos", "manager_arregion", "manager_arvalid", "manager_rready",
                 "target_awready", "target_wready", "target_bvalid", "target_bid",
                 "target_bresp", "target_arready", "target_rvalid", "target_rid",
                 "target_rdata", "target_rresp", "target_rlast"):
        getattr(dut, name).value = 0
    dut.target_awready.value = 0b111
    dut.target_wready.value = 0b111
    dut.target_arready.value = 0b111
    dut.ARESETn.value = 0
    cocotb.start_soon(Clock(dut.ACLK, 10, units="ns").start())
    await cycles(dut, 3)
    dut.ARESETn.value = 1
    model.reset()

    # Legal unmapped write: the independent model predicts S3/DECERR.
    manager, ident, addr = 0, 5, 0x3000_0000
    set_lane(dut.manager_awid, 4, manager, ident)
    set_lane(dut.manager_awaddr, 32, manager, addr)
    set_lane(dut.manager_awlen, 8, manager, 0)
    set_lane(dut.manager_awsize, 3, manager, 3)
    set_lane(dut.manager_awburst, 2, manager, 1)
    set_lane(dut.manager_awvalid, 1, manager, 1)
    while not (get_lane(dut.manager_awready, 1, manager)):
        await cycles(dut)
    tx = model.admit_aw(manager, ident, addr, 0)
    trace.write(json.dumps({"cycle": model.cycle, "kind": "aw_admit", "target": tx.target, "id": ident}) + "\n")
    await cycles(dut)
    set_lane(dut.manager_awvalid, 1, manager, 0)

    set_lane(dut.manager_wdata, 64, manager, 0x1122334455667788)
    set_lane(dut.manager_wstrb, 8, manager, 0xAA)
    set_lane(dut.manager_wlast, 1, manager, 1)
    set_lane(dut.manager_wvalid, 1, manager, 1)
    while not get_lane(dut.manager_wready, 1, manager):
        await cycles(dut)
    model.observe_target_w(manager, 3, 0x1122334455667788, 0xAA, 1)
    trace.write(json.dumps({"cycle": model.cycle, "kind": "w_target", "target": 3, "id": ident}) + "\n")
    await cycles(dut)
    set_lane(dut.manager_wvalid, 1, manager, 0)
    set_lane(dut.manager_bready, 1, manager, 1)
    while not get_lane(dut.manager_bvalid, 1, manager):
        await cycles(dut)
    assert get_lane(dut.manager_bid, 4, manager) == ident
    assert get_lane(dut.manager_bresp, 2, manager) == RESP_DECERR
    model.observe_b(manager, ident, RESP_DECERR)
    trace.write(json.dumps({"cycle": model.cycle, "kind": "b_complete", "target": 3, "id": ident}) + "\n")
    await cycles(dut)
    set_lane(dut.manager_bready, 1, manager, 0)

    # Legal unmapped read: exact zero-data DECERR beat and restored RID.
    set_lane(dut.manager_arid, 4, manager, 6)
    set_lane(dut.manager_araddr, 32, manager, 0x4000_0000)
    set_lane(dut.manager_arlen, 8, manager, 0)
    set_lane(dut.manager_arsize, 3, manager, 3)
    set_lane(dut.manager_arburst, 2, manager, 1)
    set_lane(dut.manager_arvalid, 1, manager, 1)
    while not get_lane(dut.manager_arready, 1, manager):
        await cycles(dut)
    tx = model.admit_ar(manager, 6, 0x4000_0000, 0)
    trace.write(json.dumps({"cycle": model.cycle, "kind": "ar_admit", "target": tx.target, "id": 6}) + "\n")
    await cycles(dut)
    set_lane(dut.manager_arvalid, 1, manager, 0)
    set_lane(dut.manager_rready, 1, manager, 1)
    while not get_lane(dut.manager_rvalid, 1, manager):
        await cycles(dut)
    assert get_lane(dut.manager_rid, 4, manager) == 6
    assert get_lane(dut.manager_rdata, 64, manager) == 0
    assert get_lane(dut.manager_rresp, 2, manager) == RESP_DECERR
    assert get_lane(dut.manager_rlast, 1, manager) == 1
    model.observe_r(manager, 6, 0, 0, RESP_DECERR, 1)
    model.assert_drained()
    trace.write(json.dumps({"cycle": model.cycle, "kind": "r_complete", "target": 3, "id": 6}) + "\n")

    # Start an independent mapped-memory phase.  The endpoint memories are a
    # separate implementation from the oracle memories; only observations at
    # the DUT pins connect the two models.
    for name in ("manager_awvalid", "manager_wvalid", "manager_arvalid",
                 "manager_bready", "manager_rready", "target_bvalid",
                 "target_rvalid"):
        getattr(dut, name).value = 0
    dut.ARESETn.value = 0
    await cycles(dut, 3)
    dut.ARESETn.value = 1
    model.reset()
    endpoint_memory = {0: init_endpoint_memory(0x10), 1: init_endpoint_memory(0x20)}
    # All legal lengths exercise target routing, WLAST/RLAST position and
    # independent byte-strobe memory updates on both mapped banks.
    for length in range(16):
        target = length & 1
        ident = length
        strobes = [0xFF, 0xAA, 0x55, 0x81, 0x00][length % 5:]
        strobes = (strobes + [0xFF] * 16)[:length + 1]
        await mapped_write(dut, model, endpoint_memory, 0, ident, target, length, strobes)
        await mapped_read(dut, model, endpoint_memory, 0, ident, target, length,
                          address_for(target, 0x080 + ident * 8))
    dut._log.info("oracle mapped lengths PASS")
    # A coordinated epoch boundary also verifies that the same visible IDs
    # can be reused as fresh transactions after outstanding state is flushed.
    dut.ARESETn.value = 0
    await cycles(dut, 3)
    dut.ARESETn.value = 1
    model.reset()
    await concurrent_same_id(dut, model, endpoint_memory)
    dut._log.info("oracle concurrent same-ID PASS")
    model.assert_drained()
    for event in model.events:
        trace.write(json.dumps(event) + "\n")
    trace.close()
    dut._log.info("oracle S3 end-to-end PASS epoch=%d", model.epoch)
