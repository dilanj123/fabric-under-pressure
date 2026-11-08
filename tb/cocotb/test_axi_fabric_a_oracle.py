import json
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge, Timer
from cocotb.utils import get_sim_time

from axi_reference_model import AxiReferenceModel, RESP_DECERR
from axi_endpoint_model import EndpointMemory

_ACTIVE_MODEL = None
_LAST_MODEL_TIME = None
_SHADOW_VALUES = {}


def _raw_output_dir():
    return Path(os.environ.get(
        "OUT", Path(os.environ["ROOT"]) / "results/raw/gate2_oracle"))


def _gate3_trace(event):
    path = os.environ.get("GATE3_BOUNDARY_TRACE")
    if not path:
        return
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(event) + "\n")


def lane(value: int, width: int, index: int) -> int:
    return value << (width * index)


def set_lane(handle, width: int, index: int, value: int) -> None:
    key = id(handle)
    current = _SHADOW_VALUES.get(key, int(handle.value))
    mask = ((1 << width) - 1) << (width * index)
    updated = (current & ~mask) | lane(value, width, index)
    _SHADOW_VALUES[key] = updated
    handle.value = updated


def reset_shadow(*handles) -> None:
    """Synchronize packed-lane shadows after a whole-bus assignment."""
    for handle in handles:
        _SHADOW_VALUES[id(handle)] = int(handle.value)


def get_lane(handle, width: int, index: int) -> int:
    return (int(handle.value) >> (width * index)) & ((1 << width) - 1)


async def cycles(dut, count=1):
    global _LAST_MODEL_TIME
    for _ in range(count):
        await RisingEdge(dut.ACLK)
        now = get_sim_time(unit="ns")
        if _ACTIVE_MODEL is not None and now != _LAST_MODEL_TIME:
            _ACTIVE_MODEL.advance()
            _LAST_MODEL_TIME = now


def address_for(target: int, offset: int) -> int:
    bases = (0x0000_0000, 0x1000_0000, 0x2000_0000, 0x3000_0000)
    return bases[target] + offset


def endpoint_read(memory: EndpointMemory, addr: int) -> int:
    return memory.read64(addr)


def endpoint_write(memory: EndpointMemory, addr: int, data: int, strobe: int) -> None:
    memory.write64(addr, data, strobe)


async def mapped_write(dut, model, memory, manager, ident, target, length, strobes,
                      qos_value=0x3, response_delay=0, manager_b_stall=0,
                      addr_override=None):
    addr = address_for(target, 0x080 + (ident * 8)) if addr_override is None else addr_override
    cache, prot, qos, region = 0xA, 0x5, qos_value & 0xF, 0x9
    set_lane(dut.manager_awid, 4, manager, ident)
    set_lane(dut.manager_awaddr, 32, manager, addr)
    set_lane(dut.manager_awlen, 8, manager, length)
    set_lane(dut.manager_awsize, 3, manager, 3)
    set_lane(dut.manager_awburst, 2, manager, 1)
    set_lane(dut.manager_awlock, 1, manager, 0)
    set_lane(dut.manager_awcache, 4, manager, cache)
    set_lane(dut.manager_awprot, 3, manager, prot)
    set_lane(dut.manager_awqos, 4, manager, qos)
    set_lane(dut.manager_awregion, 4, manager, region)
    set_lane(dut.manager_awvalid, 1, manager, 1)
    while not get_lane(dut.manager_awready, 1, manager):
        await cycles(dut)
    tx = model.admit_aw(manager, ident, addr, length, cache=cache, prot=prot,
                        qos=qos, region=region)
    set_lane(dut.manager_awvalid, 1, manager, 0)
    await cycles(dut)
    while not get_lane(dut.target_awvalid, 1, target):
        await cycles(dut)
    observed_id = get_lane(dut.target_awid, 6, target)
    if observed_id != ((manager << 4) | ident):
        raise AssertionError(f"bad target AWID M{manager} ID{ident}: {observed_id:#x}")
    model.observe_target_address("aw", manager, ident, observed_id, target, addr,
                                 length, 3, 1, 0, cache, prot, qos, region)
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
        model.accept_manager_w(manager, data, strobe, last)
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
    await cycles(dut, response_delay)
    set_lane(dut.target_bid, 6, target, (manager << 4) | ident)
    set_lane(dut.target_bresp, 2, target, 0)
    set_lane(dut.target_bvalid, 1, target, 1)
    set_lane(dut.manager_bready, 1, manager, int(manager_b_stall == 0))
    while not get_lane(dut.target_bready, 1, target):
        await cycles(dut)
    await cycles(dut)
    set_lane(dut.target_bvalid, 1, target, 0)
    while not get_lane(dut.manager_bvalid, 1, manager):
        await cycles(dut)
    if manager_b_stall:
        for _ in range(manager_b_stall):
            assert get_lane(dut.manager_bvalid, 1, manager)
            await cycles(dut)
        set_lane(dut.manager_bready, 1, manager, 1)
        await cycles(dut)
    if get_lane(dut.manager_bid, 4, manager) != ident or get_lane(dut.manager_bresp, 2, manager) != 0:
        raise AssertionError("mapped B response mismatch")
    model.observe_b(manager, ident, 0)
    await cycles(dut)
    set_lane(dut.manager_bready, 1, manager, 0)


async def mapped_read(dut, model, memory, manager, ident, target, length, addr,
                     qos_value=0x7, response_delay=0, manager_r_stall=0):
    cache, prot, qos, region = 0x6, 0x2, qos_value & 0xF, 0x4
    set_lane(dut.manager_arid, 4, manager, ident)
    set_lane(dut.manager_araddr, 32, manager, addr)
    set_lane(dut.manager_arlen, 8, manager, length)
    set_lane(dut.manager_arsize, 3, manager, 3)
    set_lane(dut.manager_arburst, 2, manager, 1)
    set_lane(dut.manager_arlock, 1, manager, 0)
    set_lane(dut.manager_arcache, 4, manager, cache)
    set_lane(dut.manager_arprot, 3, manager, prot)
    set_lane(dut.manager_arqos, 4, manager, qos)
    set_lane(dut.manager_arregion, 4, manager, region)
    set_lane(dut.manager_arvalid, 1, manager, 1)
    wait_count = 0
    while not get_lane(dut.manager_arready, 1, manager):
        await cycles(dut)
        wait_count += 1
        if wait_count == 100:
            raise AssertionError(f"manager ARREADY timeout M{manager} ID{ident} "
                                 f"ready={int(dut.manager_arready.value):03b}")
    model.admit_ar(manager, ident, addr, length, cache=cache, prot=prot,
                   qos=qos, region=region)
    set_lane(dut.manager_arvalid, 1, manager, 0)
    await cycles(dut)
    while not get_lane(dut.target_arvalid, 1, target):
        await cycles(dut)
    if get_lane(dut.target_arid, 6, target) != ((manager << 4) | ident):
        raise AssertionError("bad target ARID")
    model.observe_target_address("ar", manager, ident, get_lane(dut.target_arid, 6, target), target, addr,
                                 length, 3, 1, 0, cache, prot, qos, region)
    await cycles(dut)
    await cycles(dut, response_delay)
    data = [endpoint_read(memory[target], addr + beat * 8)
            if target in (0, 1) else 0 for beat in range(length + 1)]
    if (os.environ.get("ORACLE_FAULT_MODE") == "bad_rdata" and
            (manager, ident, target) == (0, 13, 0)):
        data[0] ^= 1
    return await _drive_r_burst(
        dut, model, manager, ident, target, data,
        0 if target != 3 else RESP_DECERR, addr,
        manager_ready=manager_r_stall == 0,
        manager_stall_cycles=manager_r_stall,
        source_check=True)


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
                model.observe_target_address("aw", m, ident, get_lane(dut.target_awid, 6, t), t, addresses[m])
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
    for m in range(3):
        model.accept_manager_w(m, 0xABC000 + m, 0xFF, 1)
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
    global _ACTIVE_MODEL
    model = AxiReferenceModel()
    _ACTIVE_MODEL = model
    trace_name = "fault_event_trace.jsonl" if os.environ.get("ORACLE_FAULT_MODE") else "event_trace.jsonl"
    trace_path = _raw_output_dir() / trace_name
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
    cocotb.start_soon(Clock(dut.ACLK, 10, unit="ns").start())
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
    await cycles(dut)
    set_lane(dut.manager_awvalid, 1, manager, 0)

    set_lane(dut.manager_wdata, 64, manager, 0x1122334455667788)
    set_lane(dut.manager_wstrb, 8, manager, 0xAA)
    set_lane(dut.manager_wlast, 1, manager, 1)
    set_lane(dut.manager_wvalid, 1, manager, 1)
    while not get_lane(dut.manager_wready, 1, manager):
        await cycles(dut)
    model.accept_manager_w(manager, 0x1122334455667788, 0xAA, 1)
    await cycles(dut)
    set_lane(dut.manager_wvalid, 1, manager, 0)
    set_lane(dut.manager_bready, 1, manager, 1)
    while not get_lane(dut.manager_bvalid, 1, manager):
        await cycles(dut)
    assert get_lane(dut.manager_bid, 4, manager) == ident
    assert get_lane(dut.manager_bresp, 2, manager) == RESP_DECERR
    model.observe_b(manager, ident, RESP_DECERR)
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
    await cycles(dut)
    set_lane(dut.manager_arvalid, 1, manager, 0)
    set_lane(dut.manager_rready, 1, manager, 1)
    while not get_lane(dut.manager_rvalid, 1, manager):
        await cycles(dut)
    assert get_lane(dut.manager_rid, 4, manager) == 6
    assert get_lane(dut.manager_rdata, 64, manager) == 0
    assert get_lane(dut.manager_rresp, 2, manager) == RESP_DECERR
    assert get_lane(dut.manager_rlast, 1, manager) == 1
    model.observe_r(manager, 6, 0, RESP_DECERR, 1)
    model.assert_drained()

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
    endpoint_memory = {0: EndpointMemory(target=0), 1: EndpointMemory(target=1)}
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
    # S2 is verified with a stateless test endpoint: legal writes consume and
    # discard W beats, while reads return deterministic zero data/OKAY.  This
    # is testbench behavior, not an architectural S2 register-map claim.
    await mapped_write(dut, model, endpoint_memory, 1, 9, 2, 3, [0xFF, 0xAA, 0x55, 0x81])
    await mapped_read(dut, model, endpoint_memory, 1, 10, 2, 3, address_for(2, 0x500))
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
    _ACTIVE_MODEL = None


async def _oracle_reset(dut, model):
    # Reset and packed-input changes are made between active edges. This is
    # also safe when the caller has just returned from ReadOnly.
    await FallingEdge(dut.ACLK)
    for name in ("manager_awvalid", "manager_wvalid", "manager_arvalid",
                 "manager_bready", "manager_rready", "target_bvalid",
                 "target_rvalid"):
        getattr(dut, name).value = 0
    dut.target_awready.value = 0b111
    dut.target_wready.value = 0b111
    dut.target_arready.value = 0b111
    dut.ARESETn.value = 0
    await cycles(dut, 3)
    dut.ARESETn.value = 1
    model.reset()
    await cycles(dut, 2)


def _set_aw(dut, manager, ident, target, length):
    addr = address_for(target, 0x180 + ident * 8)
    fields = (0xA, 0x5, 0x3, 0x9)
    set_lane(dut.manager_awid, 4, manager, ident)
    set_lane(dut.manager_awaddr, 32, manager, addr)
    set_lane(dut.manager_awlen, 8, manager, length)
    set_lane(dut.manager_awsize, 3, manager, 3)
    set_lane(dut.manager_awburst, 2, manager, 1)
    set_lane(dut.manager_awlock, 1, manager, 0)
    set_lane(dut.manager_awcache, 4, manager, fields[0])
    set_lane(dut.manager_awprot, 3, manager, fields[1])
    set_lane(dut.manager_awqos, 4, manager, fields[2])
    set_lane(dut.manager_awregion, 4, manager, fields[3])
    set_lane(dut.manager_awvalid, 1, manager, 1)
    return addr, fields


async def _admit_write_no_b(dut, model, manager, ident, target, length=0,
                            target_aw_stall=0):
    if target_aw_stall:
        dut.target_awready.value = int(dut.target_awready.value) & ~(1 << target)
    addr, fields = _set_aw(dut, manager, ident, target, length)
    while not get_lane(dut.manager_awready, 1, manager):
        await cycles(dut)
    tx = model.admit_aw(manager, ident, addr, length, cache=fields[0], prot=fields[1],
                        qos=fields[2], region=fields[3])
    await cycles(dut)
    set_lane(dut.manager_awvalid, 1, manager, 0)
    if target_aw_stall:
        while not get_lane(dut.target_awvalid, 1, target):
            await cycles(dut)
        for _ in range(target_aw_stall):
            assert get_lane(dut.target_awvalid, 1, target)
            await cycles(dut)
        dut.target_awready.value = int(dut.target_awready.value) | (1 << target)
    while not (get_lane(dut.target_awvalid, 1, target) and
               get_lane(dut.target_awready, 1, target)):
        await cycles(dut)
    observed = (get_lane(dut.target_awid, 6, target),
                get_lane(dut.target_awaddr, 32, target),
                get_lane(dut.target_awlen, 8, target),
                get_lane(dut.target_awsize, 3, target),
                get_lane(dut.target_awburst, 2, target),
                get_lane(dut.target_awlock, 1, target),
                get_lane(dut.target_awcache, 4, target),
                get_lane(dut.target_awprot, 3, target),
                get_lane(dut.target_awqos, 4, target),
                get_lane(dut.target_awregion, 4, target))
    model.observe_target_address("aw", manager, ident, observed[0], target, addr,
                                 *observed[2:])
    await cycles(dut)
    return tx, addr


async def _write_data_only(dut, model, tx, manager, target, strobes,
                           stall_target_beat=None):
    for beat in range(tx.expected_beats):
        data = 0x5500000000000000 | (manager << 48) | (tx.key.ident << 32) | beat
        strobe = strobes[beat]
        last = int(beat == tx.expected_beats - 1)
        if stall_target_beat == beat:
            dut.target_wready.value = int(dut.target_wready.value) & ~(1 << target)
        set_lane(dut.manager_wdata, 64, manager, data)
        set_lane(dut.manager_wstrb, 8, manager, strobe)
        set_lane(dut.manager_wlast, 1, manager, last)
        set_lane(dut.manager_wvalid, 1, manager, 1)
        while not get_lane(dut.manager_wready, 1, manager):
            await cycles(dut)
        model.accept_manager_w(manager, data, strobe, last)
        await cycles(dut)
        set_lane(dut.manager_wvalid, 1, manager, 0)
        if stall_target_beat == beat:
            while not get_lane(dut.target_wvalid, 1, target):
                await cycles(dut)
            for _ in range(3):
                assert get_lane(dut.target_wvalid, 1, target)
                assert get_lane(dut.target_wdata, 64, target) == data
                assert get_lane(dut.target_wstrb, 8, target) == strobe
                assert get_lane(dut.target_wlast, 1, target) == last
                await cycles(dut)
            dut.target_wready.value = int(dut.target_wready.value) | (1 << target)
        while not (get_lane(dut.target_wvalid, 1, target) and
                   get_lane(dut.target_wready, 1, target)):
            await cycles(dut)
        obs_data = get_lane(dut.target_wdata, 64, target)
        obs_strobe = get_lane(dut.target_wstrb, 8, target)
        obs_last = get_lane(dut.target_wlast, 1, target)
        model.observe_target_w(manager, target, obs_data, obs_strobe, obs_last)
        await cycles(dut)
    return tx


async def _admit_read_no_response(dut, model, manager, ident, target, length=0,
                                  target_ar_stall=0):
    if target_ar_stall:
        dut.target_arready.value = int(dut.target_arready.value) & ~(1 << target)
    addr = address_for(target, 0x980 + ident * 8)
    cache, prot, qos, region = 0x6, 0x2, 0x7, 0x4
    set_lane(dut.manager_arid, 4, manager, ident)
    set_lane(dut.manager_araddr, 32, manager, addr)
    set_lane(dut.manager_arlen, 8, manager, length)
    set_lane(dut.manager_arsize, 3, manager, 3)
    set_lane(dut.manager_arburst, 2, manager, 1)
    set_lane(dut.manager_arlock, 1, manager, 0)
    set_lane(dut.manager_arcache, 4, manager, cache)
    set_lane(dut.manager_arprot, 3, manager, prot)
    set_lane(dut.manager_arqos, 4, manager, qos)
    set_lane(dut.manager_arregion, 4, manager, region)
    set_lane(dut.manager_arvalid, 1, manager, 1)
    wait_count = 0
    while not get_lane(dut.manager_arready, 1, manager):
        await cycles(dut)
    tx = model.admit_ar(manager, ident, addr, length, cache=cache, prot=prot,
                        qos=qos, region=region)
    await cycles(dut)
    set_lane(dut.manager_arvalid, 1, manager, 0)
    if target_ar_stall:
        while not get_lane(dut.target_arvalid, 1, target):
            await cycles(dut)
        for _ in range(target_ar_stall):
            assert get_lane(dut.target_arvalid, 1, target)
            await cycles(dut)
        dut.target_arready.value = int(dut.target_arready.value) | (1 << target)
    while not (get_lane(dut.target_arvalid, 1, target) and
               get_lane(dut.target_arready, 1, target)):
        await cycles(dut)
        wait_count += 1
        if wait_count == 200:
            raise AssertionError(f"target AR timeout M{manager} ID{ident} S{target} "
                                 f"valid={int(dut.target_arvalid.value):04b} "
                                 f"ready={int(dut.target_arready.value):03b}")
    observed_id = get_lane(dut.target_arid, 6, target)
    observed_addr = get_lane(dut.target_araddr, 32, target)
    observed_fields = (get_lane(dut.target_arlen, 8, target),
                       get_lane(dut.target_arsize, 3, target),
                       get_lane(dut.target_arburst, 2, target),
                       get_lane(dut.target_arlock, 1, target),
                       get_lane(dut.target_arcache, 4, target),
                       get_lane(dut.target_arprot, 3, target),
                       get_lane(dut.target_arqos, 4, target),
                       get_lane(dut.target_arregion, 4, target))
    model.observe_target_address("ar", manager, ident, observed_id, target,
                                 observed_addr, *observed_fields)
    await cycles(dut)
    return tx


async def _return_b(dut, model, manager, ident, target, ready=True):
    set_lane(dut.target_bid, 6, target, (manager << 4) | ident)
    set_lane(dut.target_bresp, 2, target, 0)
    set_lane(dut.target_bvalid, 1, target, 1)
    set_lane(dut.manager_bready, 1, manager, int(ready))
    while not get_lane(dut.target_bready, 1, target):
        await cycles(dut)
    await cycles(dut)
    set_lane(dut.target_bvalid, 1, target, 0)
    while not get_lane(dut.manager_bvalid, 1, manager):
        await cycles(dut)
    if not ready:
        for _ in range(3):
            assert get_lane(dut.manager_bvalid, 1, manager)
            await cycles(dut)
        set_lane(dut.manager_bready, 1, manager, 1)
        await cycles(dut)
    assert get_lane(dut.manager_bid, 4, manager) == ident
    model.observe_b(manager, ident, get_lane(dut.manager_bresp, 2, manager))
    await cycles(dut)
    set_lane(dut.manager_bready, 1, manager, 0)


async def _return_r(dut, model, manager, ident, target, length=0,
                    ready=True, source_check=True, pending_ar=None):
    data = [0 if target == 3 else
            0x9000000000000000 | (target << 40) | (ident << 8) | beat
            for beat in range(length + 1)]
    return await _drive_r_burst(dut, model, manager, ident, target, data,
                                0 if target != 3 else RESP_DECERR, None,
                                manager_ready=ready,
                                manager_stall_cycles=0 if ready else 3,
                                source_check=source_check, pending_ar=pending_ar)


def _r_snapshot(dut, manager, target):
    target_values = tuple(get_lane(getattr(dut, f"target_r{name}"), width, target)
                          for name, width in (("valid", 1), ("ready", 1), ("id", 6),
                                              ("data", 64), ("resp", 2), ("last", 1)))
    manager_values = tuple(get_lane(getattr(dut, f"manager_r{name}"), width, manager)
                           for name, width in (("valid", 1), ("ready", 1), ("id", 4),
                                               ("data", 64), ("resp", 2), ("last", 1)))
    manager_ar = (get_lane(dut.manager_arvalid, 1, manager),
                  get_lane(dut.manager_arready, 1, manager),
                  get_lane(dut.manager_arid, 4, manager),
                  get_lane(dut.manager_araddr, 32, manager),
                  get_lane(dut.manager_arlen, 8, manager))
    target_ar = (get_lane(dut.target_arvalid, 1, target),
                 get_lane(dut.target_arready, 1, target),
                 get_lane(dut.target_arid, 6, target),
                 get_lane(dut.target_araddr, 32, target),
                 get_lane(dut.target_arlen, 8, target))
    return {"target": target_values, "manager": manager_values,
            "manager_ar": manager_ar, "target_ar": target_ar}


async def _r_sample_cycle(dut, model, manager, target, target_payload=None,
                          target_valid=0, manager_ready=1):
    """Drive on falling edges and return pre-edge and settled observations.

    The pre-edge sample is taken after a Timer has allowed the falling-edge
    writes and combinational READY paths to settle, but before ACLK rises.
    Handshake decisions use this sample, which is the value presented to the
    active edge. ReadOnly is used only afterward to capture settled outputs.
    """
    global _LAST_MODEL_TIME
    await FallingEdge(dut.ACLK)
    if target_payload is not None:
        rid, data, resp, last = target_payload
        set_lane(dut.target_rid, 6, target, rid)
        set_lane(dut.target_rdata, 64, target, data)
        set_lane(dut.target_rresp, 2, target, resp)
        set_lane(dut.target_rlast, 1, target, last)
    set_lane(dut.target_rvalid, 1, target, target_valid)
    set_lane(dut.manager_rready, 1, manager, manager_ready)
    await Timer(1, unit="ns")
    pre_edge = _r_snapshot(dut, manager, target)
    await RisingEdge(dut.ACLK)
    active_edge = _r_snapshot(dut, manager, target)
    await ReadOnly()
    settled = _r_snapshot(dut, manager, target)
    now = get_sim_time(unit="ns")
    if _ACTIVE_MODEL is model and now != _LAST_MODEL_TIME:
        model.advance()
        _LAST_MODEL_TIME = now
    trace = {"time_ns": int(now), "pre_edge": pre_edge,
             "active_edge_trigger": active_edge, "read_only_settled": settled}
    _gate3_trace({"boundary": "r_edge_sample", **trace})
    return trace


async def _drive_r_burst(dut, model, manager, ident, target, data_beats, resp,
                         addr, manager_ready=True, manager_stall_cycles=0,
                         source_check=True, fault_mode=None, post_cycles=2,
                         pending_ar=None):
    """Drive an R burst until sampled target and manager handshakes complete."""
    fault = fault_mode or os.environ.get("ORACLE_R_FAULT_MODE")
    expected_count = len(data_beats)
    if expected_count == 0 or expected_count > 16:
        raise AssertionError(f"invalid expected R beat count {expected_count}")
    internal_id = (manager << 4) | ident
    target_handshakes = []
    manager_handshakes = []
    prior_manager_data = None
    oracle_updates_before = sum(1 for event in model.events
                                if event.get("kind") == "r_beat" and
                                event.get("manager") == manager and event.get("id") == ident and
                                event.get("epoch") == model.epoch)
    manager_stall_seen = 0
    pending_ar_admitted = False
    pending_ar_target_seen = False
    pending_ar_event = None
    if pending_ar is not None:
        # The registered AR slot accepts the manager request one cycle before
        # its target-facing handshake. Observe both edges after RLAST.
        post_cycles = max(post_cycles, 4)

    for beat in range(expected_count):
        source_beat = beat
        if fault == "duplicate" and beat == 2:
            source_beat = 1
        elif fault == "missing" and beat == 1:
            source_beat = 2
        payload_data = data_beats[source_beat]
        if fault == "bad_rdata" and beat == 0:
            payload_data ^= 1
        payload_id = internal_id - 1 if fault == "wrong_rid" and beat == 0 else internal_id
        payload_last = int(beat == expected_count - 1)
        if fault == "early_rlast" and beat == 1:
            payload_last = 1
        if fault == "missing_rlast" and beat == expected_count - 1:
            payload_last = 0
        expected_payload = (ident, data_beats[beat], resp, int(beat == expected_count - 1))
        target_seen = False
        manager_seen = False
        waited = 0
        manager_stalled = 0
        while not manager_seen:
            first_drive = waited == 0
            drive_payload = (payload_id, payload_data, resp, payload_last) if first_drive else None
            trace = await _r_sample_cycle(
                dut, model, manager, target, drive_payload,
                target_valid=int(not target_seen),
                manager_ready=int(manager_ready or
                                  manager_stall_seen >= manager_stall_cycles))
            sample = trace["pre_edge"]
            tv, tr, trid, td, tresp, tlast = sample["target"]
            mv, mr, mid, md, mresp, mlast = sample["manager"]
            arv, arr, arid, araddr, arlen = sample["manager_ar"]
            tarv, tarr, tarid, taraddr, tarlen = sample["target_ar"]
            if sample != trace["active_edge_trigger"]:
                raise AssertionError(
                    f"R pre-edge/active-edge snapshot mismatch at {trace['time_ns']}ns: "
                    f"pre={sample} edge={trace['active_edge_trigger']}")
            if tv and not tr:
                if (trid, td, tresp, tlast) != (payload_id, payload_data, resp, payload_last):
                    raise AssertionError("target R payload changed while stalled")
            if mv and not mr:
                manager_stall_seen += 1
                held = (mid, md, mresp, mlast)
                if getattr(_drive_r_burst, "held_manager_payload", None) not in (None, held):
                    raise AssertionError("manager R payload changed while stalled")
                _drive_r_burst.held_manager_payload = held
            else:
                _drive_r_burst.held_manager_payload = None

            if tv and tr:
                target_seen = True
                target_handshakes.append({"time_ns": trace["time_ns"], "beat": beat,
                                          "rid": trid, "data": td, "resp": tresp,
                                          "last": tlast})
                if (trid, td, tresp, tlast) != (payload_id, payload_data, resp, payload_last):
                    raise AssertionError(f"target R handshake payload differs from driven beat {beat}")
            if pending_ar is not None and arv and arr:
                if mv and mr and mlast:
                    raise AssertionError("D028 violation: AR admission shared the RLAST completion edge")
                if pending_ar_admitted:
                    raise AssertionError("duplicate pending AR handshake")
                expected_ar_payload = (pending_ar["id"], pending_ar["addr"], pending_ar["len"])
                if (arid, araddr, arlen) != expected_ar_payload:
                    raise AssertionError(f"pending AR payload mismatch: {(arid, araddr, arlen)} "
                                         f"!= {expected_ar_payload}")
                model.admit_ar(manager, pending_ar["id"], pending_ar["addr"], pending_ar["len"],
                               cache=pending_ar["cache"], prot=pending_ar["prot"],
                               qos=pending_ar["qos"], region=pending_ar["region"])
                pending_ar_admitted = True
                pending_ar_event = {"time_ns": trace["time_ns"], "id": arid, "addr": araddr}
            if pending_ar is not None and pending_ar_admitted and not pending_ar_target_seen and tarv and tarr:
                expected_internal = (manager << 4) | pending_ar["id"]
                if tarid == expected_internal:
                    if (taraddr, tarlen) != (pending_ar["addr"], pending_ar["len"]):
                        raise AssertionError("pending target AR payload mismatch")
                    model.observe_target_address(
                        "ar", manager, pending_ar["id"], tarid, target, taraddr, tarlen, 3, 1, 0,
                        pending_ar["cache"], pending_ar["prot"], pending_ar["qos"], pending_ar["region"])
                    pending_ar_target_seen = True
            if mv and mr:
                manager_handshakes.append({"time_ns": trace["time_ns"], "beat": beat,
                                           "rid": mid, "data": md, "resp": mresp,
                                           "last": mlast})
                if mid != ident:
                    raise AssertionError(f"wrong RID at manager R handshake: expected={ident} got={mid}")
                if md != expected_payload[1]:
                    if prior_manager_data == md:
                        raise AssertionError(f"duplicate accepted R beat: M{manager} ID{ident} beat={beat}")
                    if beat + 1 < expected_count and md == data_beats[beat + 1]:
                        raise AssertionError(f"missing accepted R beat: M{manager} ID{ident} expected beat={beat}")
                    raise AssertionError(f"bad RDATA manager={manager} id={ident} beat={beat}")
                if mresp != expected_payload[2]:
                    raise AssertionError(f"bad RRESP beat={beat}: expected={resp} observed={mresp}")
                if mlast != expected_payload[3]:
                    if mlast:
                        raise AssertionError(f"early RLAST at beat={beat}")
                    raise AssertionError(f"missing final RLAST at beat={beat}")
                if not target_seen:
                    raise AssertionError(f"manager R beat {beat} accepted before target R handshake")
                if source_check:
                    model.observe_r_source(manager, target, ident, mlast)
                model.observe_r(manager, ident, md, mresp, mlast,
                                addr + beat * 8 if addr is not None and target in (0, 1) else None)
                prior_manager_data = md
                manager_seen = True
            waited += 1
            if fault == "wrong_rid" and waited >= 8 and not target_seen:
                raise AssertionError("wrong RID blocked: target RVALID had no accepting target RREADY")
            if waited >= 100 and not manager_seen:
                raise AssertionError(
                    f"R transfer timeout M{manager} ID{ident} beat={beat} "
                    f"target_seen={target_seen} manager_valid={mv} manager_ready={mr}")

    oracle_updates_after = sum(1 for event in model.events
                               if event.get("kind") == "r_beat" and
                               event.get("manager") == manager and event.get("id") == ident and
                               event.get("epoch") == model.epoch)
    require_counts = {"expected_beats": expected_count,
                      "target_handshakes": len(target_handshakes),
                      "manager_handshakes": len(manager_handshakes),
                      "oracle_updates": oracle_updates_after - oracle_updates_before}
    if require_counts["target_handshakes"] != expected_count or \
            require_counts["manager_handshakes"] != expected_count:
        raise AssertionError(f"R handshake count mismatch: {require_counts}")

    # Keep RREADY asserted and target RVALID low for a short observation
    # window. Any extra accepted transfer is reported by the same monitor.
    for _ in range(post_cycles):
        trace = await _r_sample_cycle(dut, model, manager, target, None, 0, 1)
        tv, tr, trid, td, tresp, tlast = trace["pre_edge"]["target"]
        mv, mr, mid, md, mresp, mlast = trace["pre_edge"]["manager"]
        arv, arr, arid, araddr, arlen = trace["pre_edge"]["manager_ar"]
        tarv, tarr, tarid, taraddr, tarlen = trace["pre_edge"]["target_ar"]
        if tv and tr:
            raise AssertionError("extra target R handshake after expected RLAST")
        if mv and mr:
            model.observe_r(manager, mid, md, mresp, mlast)
            raise AssertionError("extra manager R handshake after expected RLAST")
        if pending_ar is not None and arv and arr:
            if pending_ar_admitted:
                raise AssertionError("duplicate pending AR handshake")
            expected_ar_payload = (pending_ar["id"], pending_ar["addr"], pending_ar["len"])
            if (arid, araddr, arlen) != expected_ar_payload:
                raise AssertionError(f"pending AR payload mismatch: {(arid, araddr, arlen)} "
                                     f"!= {expected_ar_payload}")
            pending_ar_event = {"time_ns": trace["time_ns"], "id": arid, "addr": araddr}
            model.admit_ar(manager, pending_ar["id"], pending_ar["addr"], pending_ar["len"],
                           cache=pending_ar["cache"], prot=pending_ar["prot"],
                           qos=pending_ar["qos"], region=pending_ar["region"])
            pending_ar_admitted = True
        if pending_ar is not None and pending_ar_admitted and not pending_ar_target_seen and tarv and tarr:
            expected_internal = (manager << 4) | pending_ar["id"]
            if tarid == expected_internal:
                if (taraddr, tarlen) != (pending_ar["addr"], pending_ar["len"]):
                    raise AssertionError("pending target AR payload mismatch")
                model.observe_target_address(
                    "ar", manager, pending_ar["id"], tarid, target, taraddr, tarlen, 3, 1, 0,
                    pending_ar["cache"], pending_ar["prot"], pending_ar["qos"], pending_ar["region"])
                pending_ar_target_seen = True
    await FallingEdge(dut.ACLK)
    set_lane(dut.target_rvalid, 1, target, 0)
    set_lane(dut.manager_rready, 1, manager, 0)
    if pending_ar is not None and pending_ar_admitted:
        set_lane(dut.manager_arvalid, 1, manager, 0)
    await Timer(1, unit="ns")
    _gate3_trace({"boundary": "r_burst_complete", "manager": manager, "id": ident,
                  "target": target, **require_counts,
                  "target_payloads": target_handshakes,
                  "manager_payloads": manager_handshakes,
                  "pending_ar_admission": pending_ar_event,
                  "pending_ar_target_seen": pending_ar_target_seen})
    if pending_ar is not None and (not pending_ar_admitted or not pending_ar_target_seen):
        raise AssertionError(f"pending AR did not fully progress: admitted={pending_ar_admitted} "
                             f"target_seen={pending_ar_target_seen}")
    return require_counts


@cocotb.test()
async def fabric_a_oracle_closure_matrix(dut):
    global _ACTIVE_MODEL
    model = AxiReferenceModel()
    _ACTIVE_MODEL = model
    trace_path = _raw_output_dir() / "closure_event_trace.jsonl"
    trace_path.parent.mkdir(parents=True, exist_ok=True)
    cocotb.start_soon(Clock(dut.ACLK, 10, unit="ns").start())
    await _oracle_reset(dut, model)
    endpoint_memory = {0: EndpointMemory(target=0), 1: EndpointMemory(target=1)}

    # A/F/G: target AW/AR/W and manager B/R backpressure, with public handshakes.
    tx, _ = await _admit_write_no_b(dut, model, 0, 10, 0, 3, target_aw_stall=3)
    await _write_data_only(dut, model, tx, 0, 0, [0xFF, 0xAA, 0x55, 0x81], stall_target_beat=1)
    await _return_b(dut, model, 0, 10, 0, ready=False)
    txr = await _admit_read_no_response(dut, model, 0, 11, 1, 3, target_ar_stall=3)
    await _return_r(dut, model, 0, 11, 1, 3, ready=False)
    dut._log.info("oracle deterministic AW/AR/W/B/R backpressure PASS")

    # A: four writes live after complete data phases, then fifth-ID blocking.
    live_w = []
    for ident in range(1, 5):
        tx, _ = await _admit_write_no_b(dut, model, 0, ident, 0, 0)
        await _write_data_only(dut, model, tx, 0, 0, [0xFF])
        live_w.append(ident)
    _set_aw(dut, 0, 5, 0, 0)
    for _ in range(3):
        assert not get_lane(dut.manager_awready, 1, 0)
        await cycles(dut)
    await _return_b(dut, model, 0, 1, 0)
    assert not get_lane(dut.manager_awready, 1, 0)
    await cycles(dut)
    assert get_lane(dut.manager_awready, 1, 0)
    model.admit_aw(0, 5, address_for(0, 0x180 + 5 * 8), 0, cache=0xA, prot=0x5, qos=0x3, region=0x9)
    await cycles(dut)
    set_lane(dut.manager_awvalid, 1, 0, 0)
    # deliver ID5 and drain it, then the remaining four responses
    while not get_lane(dut.target_awvalid, 1, 0): await cycles(dut)
    model.observe_target_address("aw", 0, 5, get_lane(dut.target_awid, 6, 0), 0,
                                 address_for(0, 0x180 + 5 * 8), 0, 3, 1, 0, 0xA, 0x5, 0x3, 0x9)
    await cycles(dut)
    await _write_data_only(dut, model, model.transactions[[k for k in model.transactions if k.ident == 5 and k.direction == "aw"][0]], 0, 0, [0xFF])
    await _return_b(dut, model, 0, 5, 0)
    for ident in (2, 3, 4): await _return_b(dut, model, 0, ident, 0)
    dut._log.info("oracle four-write capacity and D028 recovery PASS")

    # B: four reads live, fifth blocked, then following-cycle recovery.
    for ident in range(1, 5): await _admit_read_no_response(dut, model, 0, ident, 0, 0)
    _set_aw(dut, 0, 99, 0, 0)  # clear AW inputs; AR is tested below
    set_lane(dut.manager_awvalid, 1, 0, 0)
    addr5 = address_for(0, 0x980 + 5 * 8)
    for ident in (5,):
        set_lane(dut.manager_arid, 4, 0, ident); set_lane(dut.manager_araddr, 32, 0, addr5)
        set_lane(dut.manager_arlen, 8, 0, 0); set_lane(dut.manager_arsize, 3, 0, 3)
        set_lane(dut.manager_arburst, 2, 0, 1); set_lane(dut.manager_arlock, 1, 0, 0)
        set_lane(dut.manager_arcache, 4, 0, 6); set_lane(dut.manager_arprot, 3, 0, 2)
        set_lane(dut.manager_arqos, 4, 0, 7); set_lane(dut.manager_arregion, 4, 0, 4)
        await FallingEdge(dut.ACLK)
        set_lane(dut.manager_arvalid, 1, 0, 1)
    for _ in range(3):
        await FallingEdge(dut.ACLK)
        await Timer(1, unit="ns")
        assert get_lane(dut.manager_arvalid, 1, 0)
        assert not get_lane(dut.manager_arready, 1, 0), "fifth AR was admitted at full capacity"
        await RisingEdge(dut.ACLK)
    pending_ar = {"id": 5, "addr": addr5, "len": 0,
                  "cache": 6, "prot": 2, "qos": 7, "region": 4}
    r_counts = await _return_r(dut, model, 0, 1, 0, 0, pending_ar=pending_ar)
    assert r_counts == {"expected_beats": 1, "target_handshakes": 1,
                        "manager_handshakes": 1, "oracle_updates": 1}
    assert not get_lane(dut.manager_arvalid, 1, 0), "accepted fifth AR was not withdrawn"
    _gate3_trace({"boundary": "d028_ar_recovery", "cycle": model.cycle,
                  "manager": 0, "id": 5, "address": addr5,
                  "r_completion_count": 1, "next_cycle_ar_admission": True})
    for ident in (2, 3, 4, 5): await _return_r(dut, model, 0, ident, 0, 0)
    dut._log.info("oracle four-read capacity and D028 recovery PASS")

    # C: same visible read ID overlaps across all managers with distinct widened IDs.
    for manager, target in enumerate((0, 1, 2)):
        await _admit_read_no_response(dut, model, manager, 5, target, 0)
    for manager, target in enumerate((0, 1, 2)):
        await _return_r(dut, model, manager, 5, target, 0)
    dut._log.info("oracle same-visible-ID read concurrency PASS")

    # D/E: legal different-ID out-of-order completion.
    for ident, target in ((6, 0), (7, 1)):
        tx, _ = await _admit_write_no_b(dut, model, 0, ident, target, 0)
        await _write_data_only(dut, model, tx, 0, target, [0xFF])
    await _return_b(dut, model, 0, 7, 1)
    await _return_b(dut, model, 0, 6, 0)
    for ident, target in ((8, 0), (9, 1)):
        await _admit_read_no_response(dut, model, 0, ident, target, 0)
    await _return_r(dut, model, 0, 9, 1, 0)
    await _return_r(dut, model, 0, 8, 0, 0)
    dut._log.info("oracle distinct-ID out-of-order B/R PASS")

    # H: live work is abandoned at a coordinated reset; same IDs are fresh after it.
    tx, _ = await _admit_write_no_b(dut, model, 0, 12, 0, 0)
    await _write_data_only(dut, model, tx, 0, 0, [0xFF])
    await _admit_read_no_response(dut, model, 0, 13, 1, 1)
    assert any(not tx.completed for tx in model.transactions.values())
    await _oracle_reset(dut, model)
    await mapped_write(dut, model, endpoint_memory, 0, 12, 0, 0, [0xFF])
    await mapped_read(dut, model, endpoint_memory, 0, 13, 0, 0, address_for(0, 0x080 + 13 * 8))
    model.assert_drained()
    with trace_path.open("w", encoding="utf-8") as trace:
        for event in model.events:
            trace.write(json.dumps(event) + "\n")
    dut._log.info("oracle live-work reset epoch and fresh same-ID reuse PASS")
    _ACTIVE_MODEL = None


@cocotb.test()
async def fabric_a_oracle_r_edge_safe(dut):
    """Check one four-beat mapped response from active-edge bus samples."""
    global _ACTIVE_MODEL, _LAST_MODEL_TIME
    _LAST_MODEL_TIME = None
    model = AxiReferenceModel()
    _ACTIVE_MODEL = model
    cocotb.start_soon(Clock(dut.ACLK, 10, unit="ns").start())
    await _oracle_reset(dut, model)
    manager, ident, target, length = 0, 11, 1, 3
    addr = address_for(target, 0x980 + ident * 8)
    fault = os.environ.get("ORACLE_R_FAULT_MODE")
    await _admit_read_no_response(dut, model, manager, ident, target, length)
    expected = [model.memories[target].read64(addr + 8 * beat)
                for beat in range(length + 1)]
    if fault:
        expected_message = {
            "duplicate": "duplicate accepted R beat",
            "missing": "missing accepted R beat",
            "bad_rdata": "bad RDATA",
            "early_rlast": "early RLAST",
            "missing_rlast": "missing final RLAST",
            "wrong_rid": "wrong RID",
        }.get(fault)
        if expected_message is None:
            raise AssertionError(f"unsupported ORACLE_R_FAULT_MODE={fault}")
        try:
            await _drive_r_burst(dut, model, manager, ident, target, expected, 0, addr,
                                 source_check=True, fault_mode=fault)
        except AssertionError as exc:
            if expected_message not in str(exc):
                raise AssertionError(
                    f"fault {fault} failed for an unexpected reason: {exc}") from exc
            raise AssertionError(f"ORACLE_EXPECTED_FAULT:{fault}:{exc}") from exc
        raise AssertionError(f"R fault injection went undetected: {fault}")

    unstalled = await _drive_r_burst(dut, model, manager, ident, target, expected,
                                     0, addr, manager_ready=True)
    assert unstalled == {"expected_beats": 4, "target_handshakes": 4,
                         "manager_handshakes": 4, "oracle_updates": 4}
    model.assert_drained()

    await _oracle_reset(dut, model)
    await _admit_read_no_response(dut, model, manager, ident, target, length)
    expected = [model.memories[target].read64(addr + 8 * beat)
                for beat in range(length + 1)]
    backpressured = await _drive_r_burst(dut, model, manager, ident, target, expected,
                                         0, addr, manager_ready=False,
                                         manager_stall_cycles=3)
    assert backpressured == {"expected_beats": 4, "target_handshakes": 4,
                             "manager_handshakes": 4, "oracle_updates": 4}
    model.assert_drained()
    dut._log.info("oracle R active-edge regression PASS unstalled=%s backpressured=%s",
                  unstalled, backpressured)
    _ACTIVE_MODEL = None
