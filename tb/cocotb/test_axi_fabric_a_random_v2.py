"""Genuinely concurrent, seeded Architecture-A qualification body."""
import json
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Lock, Join, Timer

import test_axi_fabric_a_oracle as gate2
from axi_reference_model import AxiReferenceModel, legal_request, decode_target
from axi_endpoint_model import EndpointMemory
from test_axi_fabric_a_random import s3_read, s3_write, random_reset
from concurrent_endpoint import BEndpointDriver, RBeat, ReadSnapshot, REndpointDriver

def _record_target_stall(coverage, kind, target):
    if coverage is None:
        return
    key = f"target_{kind}_stall_cycles"
    ep = f"target_{kind}_stall_episodes"
    coverage[key] = coverage.get(key, 0) + 1
    active = coverage.setdefault("_stall_active", {})
    k = f"{kind}{target}"
    if not active.get(k, False):
        coverage[ep] = coverage.get(ep, 0) + 1
        active[k] = True


def _clear_target_stall(coverage, kind, target):
    if coverage is not None:
        coverage.setdefault("_stall_active", {})[f"{kind}{target}"] = False


async def _sample_edge(dut, ready_handle, width, index, valid_handle=None):
    """Sample a settled handshake and advance exactly one clock edge."""
    await Timer(1, unit="ps")
    ready = gate2.get_lane(ready_handle, width, index)
    valid = 1 if valid_handle is None else gate2.get_lane(valid_handle, 1, index)
    await gate2.cycles(dut)
    return bool(valid and ready)


async def _safe_target_read_endpoint(dut, model, target, manager, ident, addr, length,
                                     memory, response_delay=0, cache=6, prot=2,
                                     qos=7, region=4):
    """Own one external target R lane; advance only on sampled target handshakes."""
    # This endpoint owns the target ARREADY lane.  Keeping it low until the
    # public ARVALID is observed prevents a one-cycle address handshake from
    # occurring before the monitor has entered its sampling loop.
    gate2.set_lane(dut.target_arready, 1, target, 0)
    start_cycle = model.cycle
    while True:
        await Timer(1, unit="ps")
        valid = gate2.get_lane(dut.target_arvalid, 1, target)
        ready = gate2.get_lane(dut.target_arready, 1, target)
        if valid and not ready:
            gate2.set_lane(dut.target_arready, 1, target, 1)
            await Timer(1, unit="ps")
            ready = gate2.get_lane(dut.target_arready, 1, target)
        if valid and ready:
            rid = gate2.get_lane(dut.target_arid, 6, target)
            observed_addr = gate2.get_lane(dut.target_araddr, 32, target)
            observed_len = gate2.get_lane(dut.target_arlen, 8, target)
            break
        if model.cycle - start_cycle > 2000:
            actual = {
                "cycle": model.cycle, "manager": manager, "ident": ident,
                "plan": {"target": target, "addr": addr, "length": length,
                         "size": 3, "burst": 1, "lock": 0,
                         "cache": cache, "prot": prot, "qos": qos, "region": region},
                "dut": {
                    "ARVALID": gate2.get_lane(dut.manager_arvalid, 1, manager),
                    "ARREADY": gate2.get_lane(dut.manager_arready, 1, manager),
                    "ARID": gate2.get_lane(dut.manager_arid, 4, manager),
                    "ARADDR": gate2.get_lane(dut.manager_araddr, 32, manager),
                    "ARLEN": gate2.get_lane(dut.manager_arlen, 8, manager),
                    "ARSIZE": gate2.get_lane(dut.manager_arsize, 3, manager),
                    "ARBURST": gate2.get_lane(dut.manager_arburst, 2, manager),
                    "ARLOCK": gate2.get_lane(dut.manager_arlock, 1, manager),
                    "ARCACHE": gate2.get_lane(dut.manager_arcache, 4, manager),
                    "ARPROT": gate2.get_lane(dut.manager_arprot, 3, manager),
                    "ARQOS": gate2.get_lane(dut.manager_arqos, 4, manager),
                    "ARREGION": gate2.get_lane(dut.manager_arregion, 4, manager),
                    "ARESETn": int(dut.ARESETn.value),
                },
                "python": {"legal": legal_request(addr, length, 3, 1, 0),
                           "decoded_target": decode_target(addr)},
                "targets": [{
                    "target": t,
                    "ARVALID": gate2.get_lane(dut.target_arvalid, 1, t),
                    "ARREADY": gate2.get_lane(dut.target_arready, 1, t),
                    "ARID": gate2.get_lane(dut.target_arid, 6, t),
                    "ARADDR": gate2.get_lane(dut.target_araddr, 32, t),
                    "ARLEN": gate2.get_lane(dut.target_arlen, 8, t),
                    "ARSIZE": gate2.get_lane(dut.target_arsize, 3, t),
                    "ARBURST": gate2.get_lane(dut.target_arburst, 2, t),
                    "ARLOCK": gate2.get_lane(dut.target_arlock, 1, t),
                } for t in range(3)],
                "history": [e for e in model.events
                            if e.get("manager") == manager and e.get("kind") in
                            ("ar_admit", "r_beat", "reset")],
                "oracle_live": [str(k) for k, v in model.transactions.items()
                                if not v.completed],
            }
            diag = Path(os.environ.get("GATE3_AR_DIAG", "ar_deadlock_investigation.jsonl"))
            diag.parent.mkdir(parents=True, exist_ok=True)
            with diag.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(actual) + "\n")
            raise AssertionError(
                f"target AR endpoint timeout M{manager} ID{ident} S{target} "
                f"tarvalid={gate2.get_lane(dut.target_arvalid,1,target)} "
                f"tarready={gate2.get_lane(dut.target_arready,1,target)} "
                f"marvalid={gate2.get_lane(dut.manager_arvalid,1,manager)} "
                f"marready={gate2.get_lane(dut.manager_arready,1,manager)} "
                f"live={[str(k) for k,v in model.transactions.items() if not v.completed]}")
        await gate2.cycles(dut)
    if rid != ((manager << 4) | ident) or observed_addr != addr or observed_len != length:
        raise AssertionError("target AR payload mismatch in concurrent endpoint")
    model.observe_target_address("ar", manager, ident, rid, target, observed_addr,
                                 observed_len, 3, 1, 0, cache, prot, qos, region)

    snapshot = [memory.read64(addr + 8 * beat) for beat in range(length + 1)]
    driver = REndpointDriver()
    driver.enqueue(ReadSnapshot(rid, [RBeat(rid, data, 0, int(i == length))
                                      for i, data in enumerate(snapshot)],
                                ready_cycle=0))
    for _ in range(response_delay):
        await gate2.cycles(dut)
    while driver.active is not None or driver.queue:
        driver.drive(0)
        gate2.set_lane(dut.target_rid, 6, target, driver.rid)
        gate2.set_lane(dut.target_rdata, 64, target, driver.rdata)
        gate2.set_lane(dut.target_rresp, 2, target, driver.rresp)
        gate2.set_lane(dut.target_rlast, 1, target, driver.rlast)
        gate2.set_lane(dut.target_rvalid, 1, target, driver.rvalid)
        await Timer(1, unit="ps")
        target_ready = gate2.get_lane(dut.target_rready, 1, target)
        await gate2.cycles(dut)
        if driver.sample(target_ready, 0):
            dut._log.info("endpoint R fire S%d beat_data=%#x ready=%d", target,
                          driver.rdata, target_ready)
            gate2.set_lane(dut.target_rvalid, 1, target, 0)
        await Timer(1, unit="ps")
    gate2.set_lane(dut.target_rvalid, 1, target, 0)


async def _safe_target_r_response(dut, target, rid, snapshot, response_delay=0):
    """Drive only a previously accepted target read response."""
    for _ in range(response_delay):
        await gate2.cycles(dut)
    driver = REndpointDriver()
    dut._log.info("target R response start S%d RID%d beats=%d cycle=%d", target, rid,
                  len(snapshot), gate2._ACTIVE_MODEL.cycle if gate2._ACTIVE_MODEL else -1)
    driver.enqueue(ReadSnapshot(rid, [RBeat(rid, data, 0, int(i == len(snapshot) - 1))
                                      for i, data in enumerate(snapshot)], ready_cycle=0))
    while driver.active is not None or driver.queue:
        driver.drive(0)
        gate2.set_lane(dut.target_rid, 6, target, driver.rid)
        gate2.set_lane(dut.target_rdata, 64, target, driver.rdata)
        gate2.set_lane(dut.target_rresp, 2, target, driver.rresp)
        gate2.set_lane(dut.target_rlast, 1, target, driver.rlast)
        gate2.set_lane(dut.target_rvalid, 1, target, driver.rvalid)
        await Timer(1, unit="ps")
        target_ready = gate2.get_lane(dut.target_rready, 1, target)
        await gate2.cycles(dut)
        if driver.sample(target_ready, 0):
            dut._log.info("target R response fire S%d RID%d data=%#x ready=%d", target,
                          rid, driver.rdata, target_ready)
            gate2.set_lane(dut.target_rvalid, 1, target, 0)
        await Timer(1, unit="ps")
    gate2.set_lane(dut.target_rvalid, 1, target, 0)


async def _safe_target_write_endpoint(dut, model, target, manager, ident, addr, length,
                                      memory, response_delay=0, cache=10, prot=5,
                                      qos=3, region=9):
    """Consume actual target AW/W handshakes, then own the target B lane."""
    gate2.set_lane(dut.target_awready, 1, target, 0)
    start_cycle = model.cycle
    while True:
        await Timer(1, unit="ps")
        awv = gate2.get_lane(dut.target_awvalid, 1, target)
        awr = gate2.get_lane(dut.target_awready, 1, target)
        if awv and not awr:
            gate2.set_lane(dut.target_awready, 1, target, 1)
            await Timer(1, unit="ps")
            awr = gate2.get_lane(dut.target_awready, 1, target)
        if awv and awr:
            rid = gate2.get_lane(dut.target_awid, 6, target)
            observed_addr = gate2.get_lane(dut.target_awaddr, 32, target)
            observed_len = gate2.get_lane(dut.target_awlen, 8, target)
            break
        if model.cycle - start_cycle > 2000:
            raise AssertionError(
                f"target AW endpoint timeout M{manager} ID{ident} S{target} "
                f"tawvalid={gate2.get_lane(dut.target_awvalid,1,target)} "
                f"tawready={gate2.get_lane(dut.target_awready,1,target)} "
                f"mawvalid={gate2.get_lane(dut.manager_awvalid,1,manager)} "
                f"mawready={gate2.get_lane(dut.manager_awready,1,manager)} "
                f"live={[str(k) for k,v in model.transactions.items() if not v.completed]}")
        await gate2.cycles(dut)
    if rid != ((manager << 4) | ident) or observed_addr != addr or observed_len != length:
        raise AssertionError("target AW payload mismatch in concurrent endpoint")
    model.observe_target_address("aw", manager, ident, rid, target, observed_addr,
                                 observed_len, 3, 1, 0, cache, prot, qos, region)
    for beat in range(length + 1):
        while True:
            await Timer(1, unit="ps")
            valid = gate2.get_lane(dut.target_wvalid, 1, target)
            ready = gate2.get_lane(dut.target_wready, 1, target)
            # The manager-side W handshake may occur on the same edge as the
            # first target W handshake.  Do not let the target endpoint
            # consume a beat before the sampled manager-W monitor has stored
            # its expected payload.
            expected_available = (manager in model.active_write and
                                  len(model.transactions[model.active_write[manager]].manager_w_beats)
                                  > beat)
            # The first beat needs the manager-side expectation to exist
            # before the target event is sampled.  After a target handshake,
            # however, the manager WREADY path may itself depend on the
            # target becoming ready again, so subsequent beats must be
            # allowed to establish that next handshake without waiting for
            # the manager monitor to observe it first.
            if valid and not ready and (beat == 0 and expected_available or beat > 0):
                gate2.set_lane(dut.target_wready, 1, target, 1)
                await Timer(1, unit="ps")
                ready = gate2.get_lane(dut.target_wready, 1, target)
            if valid and ready:
                data = gate2.get_lane(dut.target_wdata, 64, target)
                strobe = gate2.get_lane(dut.target_wstrb, 8, target)
                last = gate2.get_lane(dut.target_wlast, 1, target)
                dut._log.info("target W sample M%d S%d beat=%d cycle=%d data=%#x strb=%#x last=%d ready=%d mvalid=%d mready=%d",
                              manager, target, beat, model.cycle, data, strobe, last,
                              ready, gate2.get_lane(dut.manager_wvalid, 1, manager),
                              gate2.get_lane(dut.manager_wready, 1, manager))
                break
            await gate2.cycles(dut)
        if last != int(beat == length):
            raise AssertionError("target WLAST mismatch in concurrent endpoint")
        # The values above are the sampled pre-edge payload.  Commit the
        # target handshake only after the edge that consumes it; otherwise a
        # concurrently running manager-W coroutine can advance the oracle
        # state for the same edge before this target event is recorded.
        await gate2.cycles(dut)
        if manager not in model.active_write:
            dut._log.error("target W without oracle owner M%d S%d data=%#x last=%d events=%s",
                           manager, target, data, last, model.events[-8:])
        model.observe_target_w(manager, target, data, strobe, last)
        memory.write64(addr + 8 * beat, data, strobe)
        # Quiesce READY after every accepted target beat.  The Fabric's
        # registered W slot updates on the acceptance edge; leaving READY
        # high while this coroutine resumes can sample the old slot value for
        # one delta before the next beat is visible.  A fresh sampled cycle
        # with READY low makes the endpoint's one-handshake-per-beat rule
        # explicit and prevents a stale beat from being consumed twice.
        gate2.set_lane(dut.target_wready, 1, target, 0)
        await gate2.cycles(dut)
        if beat != length:
            gate2.set_lane(dut.target_wready, 1, target, 1)
    for _ in range(response_delay):
        await gate2.cycles(dut)
    driver = BEndpointDriver()
    driver.enqueue(rid, 0, 0)
    while driver.active is not None or driver.queue:
        driver.drive(0)
        gate2.set_lane(dut.target_bid, 6, target, driver.bid)
        gate2.set_lane(dut.target_bresp, 2, target, driver.bresp)
        gate2.set_lane(dut.target_bvalid, 1, target, driver.bvalid)
        await Timer(1, unit="ps")
        target_ready = gate2.get_lane(dut.target_bready, 1, target)
        await gate2.cycles(dut)
        if driver.sample(target_ready):
            gate2.set_lane(dut.target_bvalid, 1, target, 0)
        await Timer(1, unit="ps")
    gate2.set_lane(dut.target_bvalid, 1, target, 0)


async def _safe_target_write_address(dut, model, target, manager, ident, addr, length,
                                     cache=10, prot=5, qos=3, region=9,
                                     target_aw_stall=0, coverage=None):
    """Accept and check only the public target AW handshake.

    The write-data and B phases are coordinated by the owning write driver so
    a target W drain and the next manager W admission on the same clock edge
    cannot be assigned to different logical beats by two independent
    coroutines.
    """
    gate2.set_lane(dut.target_awready, 1, target, 0)
    pause = int(target_aw_stall)
    start_cycle = model.cycle
    while True:
        await Timer(1, unit="ps")
        valid = gate2.get_lane(dut.target_awvalid, 1, target)
        ready = gate2.get_lane(dut.target_awready, 1, target)
        if valid and not ready:
            _record_target_stall(coverage, "aw", target)
            if pause > 0:
                pause -= 1
            if pause == 0:
                gate2.set_lane(dut.target_awready, 1, target, 1)
            await Timer(1, unit="ps")
            ready = gate2.get_lane(dut.target_awready, 1, target)
        if valid and ready:
            _clear_target_stall(coverage, "aw", target)
            rid = gate2.get_lane(dut.target_awid, 6, target)
            observed_addr = gate2.get_lane(dut.target_awaddr, 32, target)
            observed_len = gate2.get_lane(dut.target_awlen, 8, target)
            if rid != ((manager << 4) | ident) or observed_addr != addr or observed_len != length:
                raise AssertionError("target AW payload mismatch in concurrent endpoint")
            model.observe_target_address("aw", manager, ident, rid, target,
                                         observed_addr, observed_len, 3, 1, 0,
                                         cache, prot, qos, region)
            return rid
        if model.cycle - start_cycle > 2000:
            raise AssertionError(f"target AW endpoint timeout M{manager} ID{ident} S{target}")
        await gate2.cycles(dut)


async def _safe_mapped_read(dut, model, memory, manager, ident, target, length, addr,
                            qos_value=7, response_delay=0, manager_r_stall=0,
                            target_ar_stall=0, coverage=None):
    cache, prot, qos, region = 6, 2, qos_value & 0xF, 4
    gate2.set_lane(dut.target_arready, 1, target, 0)
    for name, width, value in (("manager_arid", 4, ident), ("manager_araddr", 32, addr),
                               ("manager_arlen", 8, length), ("manager_arsize", 3, 3),
                               ("manager_arburst", 2, 1), ("manager_arlock", 1, 0),
                               ("manager_arcache", 4, cache), ("manager_arprot", 3, prot),
                               ("manager_arqos", 4, qos), ("manager_arregion", 4, region)):
        gate2.set_lane(getattr(dut, name), width, manager, value)
    gate2.set_lane(dut.manager_arvalid, 1, manager, 1)
    while True:
        fire = await _sample_edge(dut, dut.manager_arready, 1, manager, dut.manager_arvalid)
        if fire:
            model.admit_ar(manager, ident, addr, length, cache=cache, prot=prot,
                           qos=qos, region=region)
            dut._log.info("manager AR fire M%d S%d ID%d cycle=%d addr=%#x len=%d",
                          manager, target, ident, model.cycle, addr, length)
            break
    gate2.set_lane(dut.manager_arvalid, 1, manager, 0)
    # Own the target AR acceptance in this coordinator.  The target response
    # worker starts only after this public handshake has been captured, so a
    # concurrent coroutine cannot consume the address event first.
    gate2.set_lane(dut.target_arready, 1, target, 0)
    ar_pause = int(target_ar_stall)
    target_ar_start = model.cycle
    dut._log.info("target AR wait M%d S%d ID%d cycle=%d", manager, target, ident, model.cycle)
    while True:
        await Timer(1, unit="ps")
        target_valid = gate2.get_lane(dut.target_arvalid, 1, target)
        target_ready = gate2.get_lane(dut.target_arready, 1, target)
        if target_valid and not target_ready:
            _record_target_stall(coverage, "ar", target)
            if ar_pause > 0:
                ar_pause -= 1
            if ar_pause == 0:
                gate2.set_lane(dut.target_arready, 1, target, 1)
            await Timer(1, unit="ps")
            target_ready = gate2.get_lane(dut.target_arready, 1, target)
        if target_valid and target_ready:
            _clear_target_stall(coverage, "ar", target)
            rid = gate2.get_lane(dut.target_arid, 6, target)
            observed_addr = gate2.get_lane(dut.target_araddr, 32, target)
            observed_len = gate2.get_lane(dut.target_arlen, 8, target)
            if rid != ((manager << 4) | ident) or observed_addr != addr or observed_len != length:
                raise AssertionError("target AR payload mismatch in concurrent endpoint")
            model.observe_target_address("ar", manager, ident, rid, target,
                                         observed_addr, observed_len, 3, 1, 0,
                                         cache, prot, qos, region)
            dut._log.info("target AR fire M%d S%d ID%d cycle=%d", manager, target, ident, model.cycle)
            snapshot = [memory[target].read64(addr + 8 * beat)
                        for beat in range(length + 1)]
            await gate2.cycles(dut)
            break
        if model.cycle - target_ar_start > 2000:
            raise AssertionError(
                f"target AR coordinator timeout M{manager} ID{ident} S{target} "
                f"tvalid={gate2.get_lane(dut.target_arvalid,1,target)} "
                f"tready={gate2.get_lane(dut.target_arready,1,target)} "
                f"mvalid={gate2.get_lane(dut.manager_arvalid,1,manager)} "
                f"mready={gate2.get_lane(dut.manager_arready,1,manager)}")
        await gate2.cycles(dut)
    driver = REndpointDriver()
    driver.enqueue(ReadSnapshot(rid, [RBeat(rid, data, 0, int(i == length))
                                      for i, data in enumerate(snapshot)], ready_cycle=0))
    for beat in range(length + 1):
        if beat == 0:
            for _ in range(response_delay):
                await gate2.cycles(dut)
        driver.drive(0)
        gate2.set_lane(dut.target_rid, 6, target, driver.rid)
        gate2.set_lane(dut.target_rdata, 64, target, driver.rdata)
        gate2.set_lane(dut.target_rresp, 2, target, driver.rresp)
        gate2.set_lane(dut.target_rlast, 1, target, driver.rlast)
        gate2.set_lane(dut.target_rvalid, 1, target, driver.rvalid)
        target_start = model.cycle
        while True:
            await Timer(1, unit="ps")
            target_ready = gate2.get_lane(dut.target_rready, 1, target)
            if driver.rvalid and target_ready:
                await gate2.cycles(dut)
                if not driver.sample(1, 0):
                    raise AssertionError("target R driver lost sampled handshake")
                gate2.set_lane(dut.target_rvalid, 1, target, 0)
                break
            if model.cycle - target_start > 2000:
                raise AssertionError(f"target R timeout M{manager} ID{ident} S{target} beat={beat}")
            await gate2.cycles(dut)

        if manager_r_stall:
            for _ in range(manager_r_stall):
                gate2.set_lane(dut.manager_rready, 1, manager, 0)
                await gate2.cycles(dut)
        gate2.set_lane(dut.manager_rready, 1, manager, 1)
        manager_start = model.cycle
        while True:
            await Timer(1, unit="ps")
            valid = gate2.get_lane(dut.manager_rvalid, 1, manager)
            ready = gate2.get_lane(dut.manager_rready, 1, manager)
            if valid and ready:
                observed_rid = gate2.get_lane(dut.manager_rid, 4, manager)
                data = gate2.get_lane(dut.manager_rdata, 64, manager)
                resp = gate2.get_lane(dut.manager_rresp, 2, manager)
                last = gate2.get_lane(dut.manager_rlast, 1, manager)
                if observed_rid != ident:
                    raise AssertionError("manager RID mismatch in concurrent driver")
                model.observe_r(manager, ident, data, resp, last, addr + 8 * beat)
                await gate2.cycles(dut)
                break
            if model.cycle - manager_start > 2000:
                raise AssertionError(f"manager R timeout M{manager} ID{ident} S{target} beat={beat} "
                                     f"mvalid={valid} mready={ready}")
            await gate2.cycles(dut)
    gate2.set_lane(dut.target_rvalid, 1, target, 0)
    gate2.set_lane(dut.manager_rready, 1, manager, 0)


async def _safe_mapped_write(dut, model, memory, manager, ident, target, length, strobes,
                             qos_value=3, response_delay=0, manager_b_stall=0,
                             addr_override=None, aw_w_style="aw_before_w",
                             target_aw_stall=0, target_w_stall_beat=None, coverage=None):
    addr = gate2.address_for(target, 0x080 + ident * 8) if addr_override is None else addr_override
    cache, prot, qos, region = 10, 5, qos_value & 0xF, 9
    endpoint = cocotb.start_soon(_safe_target_write_address(
        dut, model, target, manager, ident, addr, length, cache, prot, qos, region,
        target_aw_stall=target_aw_stall, coverage=coverage))
    fields = (("manager_awid", 4, ident), ("manager_awaddr", 32, addr),
              ("manager_awlen", 8, length), ("manager_awsize", 3, 3),
              ("manager_awburst", 2, 1), ("manager_awlock", 1, 0),
              ("manager_awcache", 4, cache), ("manager_awprot", 3, prot),
              ("manager_awqos", 4, qos), ("manager_awregion", 4, region))
    for name, width, value in fields:
        gate2.set_lane(getattr(dut, name), width, manager, value)
    if aw_w_style == "w_before_aw":
        # The first W presentation is deliberately made before AWVALID.  The
        # fabric must hold it until its registered owner exists.
        data = (0x1000_0000_0000_0000 | (manager << 48) | (ident << 32))
        gate2.set_lane(dut.manager_wdata, 64, manager, data)
        gate2.set_lane(dut.manager_wstrb, 8, manager, strobes[0])
        gate2.set_lane(dut.manager_wlast, 1, manager, int(length == 0))
        gate2.set_lane(dut.manager_wvalid, 1, manager, 1)
    gate2.set_lane(dut.manager_awvalid, 1, manager, 1)
    aw_start = model.cycle
    while True:
        fire = await _sample_edge(dut, dut.manager_awready, 1, manager, dut.manager_awvalid)
        if fire:
            model.admit_aw(manager, ident, addr, length, cache=cache, prot=prot,
                           qos=qos, region=region)
            break
        if model.cycle - aw_start > 2000:
            live_w = [str(tx.key) for tx in model.transactions.values()
                      if tx.key.direction == "aw" and not tx.completed and
                      tx.key.manager == manager]
            live_r = [str(tx.key) for tx in model.transactions.values()
                      if tx.key.direction == "ar" and not tx.completed and
                      tx.key.manager == manager]
            raise AssertionError(f"manager AW timeout M{manager} ID{ident} S{target} "
                                 f"ready={gate2.get_lane(dut.manager_awready,1,manager)} "
                                 f"live_w={live_w} live_r={live_r} "
                                 f"awvalid={gate2.get_lane(dut.manager_awvalid,1,manager)} "
                                 f"bvalid={gate2.get_lane(dut.manager_bvalid,1,manager)} "
                                 f"bready={gate2.get_lane(dut.manager_bready,1,manager)}")
    gate2.set_lane(dut.manager_awvalid, 1, manager, 0)
    rid = await endpoint
    # Allow the Fabric to accept the manager beat into its registered W slot
    # before applying a requested subordinate-side stall.
    gate2.set_lane(dut.target_wready, 1, target, 1)
    for beat in range(length + 1):
        data = (0x1000_0000_0000_0000 | (manager << 48) | (ident << 32) | beat)
        gate2.set_lane(dut.manager_wdata, 64, manager, data)
        gate2.set_lane(dut.manager_wstrb, 8, manager, strobes[beat])
        gate2.set_lane(dut.manager_wlast, 1, manager, int(beat == length))
        gate2.set_lane(dut.manager_wvalid, 1, manager, 1)
        w_start = model.cycle
        while True:
            await Timer(1, unit="ps")
            fire = bool(gate2.get_lane(dut.manager_wvalid, 1, manager)
                        and gate2.get_lane(dut.manager_wready, 1, manager))
            if fire:
                # Record the manager-side W admission before advancing the
                # edge.  A target W can legally handshake on the same edge;
                # the central monitor ordering is manager W before target W.
                model.accept_manager_w(manager, data, strobes[beat], int(beat == length))
                dut._log.info("manager W fire M%d S%d beat=%d cycle=%d data=%#x strb=%#x last=%d",
                              manager, target, beat, model.cycle, data, strobes[beat],
                              int(beat == length))
                break
            await gate2.cycles(dut)
            if model.cycle - w_start > 2000:
                raise AssertionError(f"manager W timeout M{manager} ID{ident} beat={beat} S{target} "
                                     f"wready={gate2.get_lane(dut.manager_wready,1,manager)} "
                                     f"tvalid={gate2.get_lane(dut.target_wvalid,1,target)} "
                                     f"tready={gate2.get_lane(dut.target_wready,1,target)}")
            await gate2.cycles(dut)
        # Commit the manager W handshake edge before looking for the
        # registered target slot that it fills.
        await gate2.cycles(dut)
        # The target endpoint is deliberately driven by this same owner as
        # the manager W stream.  First accept the manager beat into the
        # Fabric, then accept the corresponding public target beat on a later
        # sampled edge.  This still uses actual target handshakes and keeps
        # the target memory update independent of the plan.
        w_pause = 2 if target_w_stall_beat == beat else 0
        gate2.set_lane(dut.target_wready, 1, target, 1)
        if w_pause:
            gate2.set_lane(dut.target_wready, 1, target, 0)
        while True:
            await Timer(1, unit="ps")
            valid = gate2.get_lane(dut.target_wvalid, 1, target)
            ready = gate2.get_lane(dut.target_wready, 1, target)
            if valid and not ready:
                _record_target_stall(coverage, "w", target)
                if w_pause > 0:
                    w_pause -= 1
                if w_pause == 0:
                    gate2.set_lane(dut.target_wready, 1, target, 1)
                await Timer(1, unit="ps")
                ready = gate2.get_lane(dut.target_wready, 1, target)
            if valid and ready:
                _clear_target_stall(coverage, "w", target)
                observed_data = gate2.get_lane(dut.target_wdata, 64, target)
                observed_strobe = gate2.get_lane(dut.target_wstrb, 8, target)
                observed_last = gate2.get_lane(dut.target_wlast, 1, target)
                if observed_last != int(beat == length):
                    raise AssertionError("target WLAST mismatch in concurrent endpoint")
                model.observe_target_w(manager, target, observed_data,
                                       observed_strobe, observed_last)
                memory[target].write64(addr + 8 * beat, observed_data, observed_strobe)
                await gate2.cycles(dut)
                break
            await gate2.cycles(dut)
    gate2.set_lane(dut.manager_wvalid, 1, manager, 0)
    for _ in range(response_delay):
        await gate2.cycles(dut)
    gate2.set_lane(dut.manager_bready, 1, manager, 0)
    for _ in range(manager_b_stall):
        await gate2.cycles(dut)
    gate2.set_lane(dut.manager_bready, 1, manager, 1)
    driver = BEndpointDriver()
    driver.enqueue(rid, 0, 0)
    while driver.active is not None or driver.queue:
        driver.drive(0)
        gate2.set_lane(dut.target_bid, 6, target, driver.bid)
        gate2.set_lane(dut.target_bresp, 2, target, driver.bresp)
        gate2.set_lane(dut.target_bvalid, 1, target, driver.bvalid)
        await Timer(1, unit="ps")
        target_ready = gate2.get_lane(dut.target_bready, 1, target)
        if driver.bvalid and target_ready:
            await gate2.cycles(dut)
            driver.sample(1)
            gate2.set_lane(dut.target_bvalid, 1, target, 0)
        else:
            await gate2.cycles(dut)
    gate2.set_lane(dut.target_bvalid, 1, target, 0)
    while True:
        await Timer(1, unit="ps")
        valid = gate2.get_lane(dut.manager_bvalid, 1, manager)
        ready = gate2.get_lane(dut.manager_bready, 1, manager)
        if valid and ready:
            bid = gate2.get_lane(dut.manager_bid, 4, manager)
            resp = gate2.get_lane(dut.manager_bresp, 2, manager)
            await gate2.cycles(dut)
            if bid != ident:
                raise AssertionError("manager BID mismatch in concurrent driver")
            model.observe_b(manager, ident, resp)
            break
        await gate2.cycles(dut)
    gate2.set_lane(dut.manager_bready, 1, manager, 0)


async def _request_phase(dut, model, memory, op, target_locks, pending):
    """Admit one public request and retain its response for a later monitor."""
    manager, ident, target, length = op["manager"], op["id"], op["target"], op["length"]
    await target_locks[target].acquire()
    try:
        if op["direction"] == "read":
            await gate2._admit_read_no_response(
                dut, model, manager, ident, target, length,
                target_ar_stall=op.get("target_ar_stall", 0),
                addr_override=op["address"], qos=op["qos"])
            # Snapshot at the actual public target AR admission.  The
            # response worker must not regenerate data from issue order.
            record = {"op": op, "epoch": model.epoch,
                      "read_data": [memory[target].read64(op["address"] + 8 * beat)
                                    for beat in range(length + 1)]}
        else:
            tx, _ = await gate2._admit_write_no_b(
                dut, model, manager, ident, target, length,
                target_aw_stall=op.get("target_aw_stall", 0),
                addr_override=op["address"], qos=op["qos"])
            await gate2._write_data_only(
                    dut, model, tx, manager, target, op["strobes"],
                    stall_target_beat=op.get("target_w_stall_beat"), memory=memory)
            record = {"op": op, "epoch": model.epoch}
    finally:
        target_locks[target].release()
    pending[manager].append(record)


async def _response_phase(dut, model, record, target_locks):
    """Drive one target response; manager retirement is centralized below."""
    op = record["op"]
    manager, ident, target, length = op["manager"], op["id"], op["target"], op["length"]
    await target_locks[target].acquire()
    try:
        if op["direction"] == "read":
            for beat, data in enumerate(record["read_data"]):
                last = int(beat == length)
                gate2.set_lane(dut.target_rid, 6, target, (manager << 4) | ident)
                gate2.set_lane(dut.target_rdata, 64, target, data)
                gate2.set_lane(dut.target_rresp, 2, target, 0)
                gate2.set_lane(dut.target_rlast, 1, target, last)
                gate2.set_lane(dut.target_rvalid, 1, target, 1)
                while True:
                    await Timer(1, unit="ps")
                    if gate2.get_lane(dut.target_rready, 1, target):
                        await gate2.cycles(dut)
                        gate2.set_lane(dut.target_rvalid, 1, target, 0)
                        break
                    await gate2.cycles(dut)
        else:
            gate2.set_lane(dut.target_bid, 6, target, (manager << 4) | ident)
            gate2.set_lane(dut.target_bresp, 2, target, 0)
            gate2.set_lane(dut.target_bvalid, 1, target, 1)
            while True:
                await Timer(1, unit="ps")
                if gate2.get_lane(dut.target_bready, 1, target):
                    await gate2.cycles(dut)
                    gate2.set_lane(dut.target_bvalid, 1, target, 0)
                    break
                await gate2.cycles(dut)
    finally:
        target_locks[target].release()


async def _monitor_manager_responses(dut, model, records, manager, direction):
    """Retire by authoritative public RID/BID, independent of source order."""
    remaining = {(model.epoch, manager, item["op"]["id"]): item for item in records}
    beat_index = {key: 0 for key in remaining}
    if direction == "read":
        gate2.set_lane(dut.manager_rready, 1, manager, 1)
        while remaining:
            await Timer(1, unit="ps")
            if not gate2.get_lane(dut.manager_rvalid, 1, manager):
                await gate2.cycles(dut)
                continue
            ident = gate2.get_lane(dut.manager_rid, 4, manager)
            key = (model.epoch, manager, ident)
            if key not in remaining:
                raise AssertionError(f"unknown live R manager={manager} id={ident}")
            item = remaining[key]
            op = item["op"]
            data = gate2.get_lane(dut.manager_rdata, 64, manager)
            resp = gate2.get_lane(dut.manager_rresp, 2, manager)
            last = gate2.get_lane(dut.manager_rlast, 1, manager)
            beat = beat_index[key]
            model.observe_r(manager, ident, data, resp, last,
                            op["address"] + 8 * beat,
                            expected_data=item["read_data"][beat])
            beat_index[key] += 1
            if last:
                del remaining[key]
            await gate2.cycles(dut)
        gate2.set_lane(dut.manager_rready, 1, manager, 0)
    else:
        gate2.set_lane(dut.manager_bready, 1, manager, 1)
        while remaining:
            await Timer(1, unit="ps")
            if not gate2.get_lane(dut.manager_bvalid, 1, manager):
                await gate2.cycles(dut)
                continue
            ident = gate2.get_lane(dut.manager_bid, 4, manager)
            key = (model.epoch, manager, ident)
            if key not in remaining:
                raise AssertionError(f"unknown live B manager={manager} id={ident}")
            resp = gate2.get_lane(dut.manager_bresp, 2, manager)
            model.observe_b(manager, ident, resp)
            del remaining[key]
            await gate2.cycles(dut)
        gate2.set_lane(dut.manager_bready, 1, manager, 0)


async def _run_request_response_split(dut, model, memory, plan, target_locks, coverage):
    """Run the random-body manager scheduler with split issue/retirement.

    Each manager has its own issue worker and independent R and B retirement
    workers.  Issue workers complete four reads and four writes before any
    response worker is released, so the live sets are the public handshake
    state (not coroutine depth) and exercise both four-entry limits together.
    """
    selected = []
    for manager in range(3):
        for direction in ("read", "write"):
            seen = set()
            for op in plan["random_operations"]:
                if (op["manager"] == manager and op["direction"] == direction
                        and op["target"] < 3 and op["id"] not in seen):
                    selected.append(op)
                    seen.add(op["id"])
                    if len(seen) == 4:
                        break
    pending = [[] for _ in range(3)]
    selected_by_manager = [[] for _ in range(3)]
    for op in selected:
        selected_by_manager[op["manager"]].append(op)

    async def issue_manager(manager):
        # Keep the manager-local request stream independent from the other
        # managers.  The target lock only serializes external endpoint lanes;
        # it must not serialize manager-facing issue activity.
        for op in selected_by_manager[manager]:
            await _request_phase(dut, model, memory, op, target_locks, pending)
            coverage["accepted_reads" if op["direction"] == "read" else "accepted_writes"][manager] += 1
            coverage["targets"][op["target"]] += 1
            coverage["lengths"][op["length"]] += 1
            coverage["qos"][op["qos"]] += 1

    issuers = [cocotb.start_soon(issue_manager(manager)) for manager in range(3)]
    for task in issuers:
        await Join(task)

    for manager in range(3):
        live_r = sum(not tx.completed for tx in model.transactions.values()
                     if tx.key.direction == "ar" and tx.key.manager == manager)
        live_w = sum(not tx.completed for tx in model.transactions.values()
                     if tx.key.direction == "aw" and tx.key.manager == manager)
        assert live_r == 4, f"random split did not reach four live reads for M{manager}: {live_r}"
        assert live_w == 4, f"random split did not reach four live writes for M{manager}: {live_w}"
    live_reads = sum(not tx.completed for tx in model.transactions.values()
                     if tx.key.direction == "ar")
    live_writes = sum(not tx.completed for tx in model.transactions.values()
                      if tx.key.direction == "aw")
    coverage["random_max_live_reads"] = max(coverage["random_max_live_reads"], live_reads)
    coverage["random_max_live_writes"] = max(coverage["random_max_live_writes"], live_writes)
    coverage["request_response_split_max_live_reads"] = live_reads
    coverage["request_response_split_max_live_writes"] = live_writes

    async def retire_manager_direction(manager, direction):
        # R and B monitors are intentionally separate tasks.  A delayed B
        # must not prevent R retirement (or vice versa) for the same manager.
        live = [item for item in pending[manager]
                if item["op"]["direction"] == direction]
        drivers = [cocotb.start_soon(_response_phase(dut, model, record, target_locks))
                   for record in live]
        monitor = cocotb.start_soon(
            _monitor_manager_responses(dut, model, live, manager, direction))
        await Join(monitor)
        for task in drivers:
            await Join(task)

    retirees = [cocotb.start_soon(retire_manager_direction(manager, direction))
                for manager in range(3) for direction in ("read", "write")]
    for task in retirees:
        await Join(task)
    return {op["sequence"] for op in selected}
@cocotb.test()
async def fabric_a_random_v2(dut):
    plan = json.loads(Path(os.environ["GATE3_PLAN"]).read_text())
    model = AxiReferenceModel()
    gate2._ACTIVE_MODEL = model
    gate2._LAST_MODEL_TIME = None
    for name in ("manager_awvalid", "manager_wvalid", "manager_arvalid",
                 "manager_bready", "manager_rready", "target_bvalid",
                 "target_rvalid"):
        getattr(dut, name).value = 0
    dut.target_awready.value = 0b111
    dut.target_wready.value = 0b111
    dut.target_arready.value = 0b111
    dut.ARESETn.value = 0
    gate2.reset_shadow(
        dut.manager_awvalid, dut.manager_awid, dut.manager_awaddr,
        dut.manager_awlen, dut.manager_awsize, dut.manager_awburst,
        dut.manager_awlock, dut.manager_awcache, dut.manager_awprot,
        dut.manager_awqos, dut.manager_awregion, dut.manager_wvalid,
        dut.manager_wdata, dut.manager_wstrb, dut.manager_wlast,
        dut.manager_bready, dut.manager_arvalid, dut.manager_arid,
        dut.manager_araddr, dut.manager_arlen, dut.manager_arsize,
        dut.manager_arburst, dut.manager_arlock, dut.manager_arcache,
        dut.manager_arprot, dut.manager_arqos, dut.manager_arregion,
        dut.manager_rready, dut.target_awready, dut.target_wready,
        dut.target_bvalid, dut.target_bid, dut.target_bresp,
        dut.target_arready, dut.target_rvalid, dut.target_rid,
        dut.target_rdata, dut.target_rresp, dut.target_rlast)
    cocotb.start_soon(Clock(dut.ACLK, 10, unit="ns").start())
    for _ in range(3):
        await gate2.cycles(dut)
    dut.ARESETn.value = 1
    model.reset()
    memory = {0: EndpointMemory(target=0), 1: EndpointMemory(target=1),
              2: EndpointMemory(target=2)}
    target_locks = [Lock() for _ in range(3)]
    active = [0, 0, 0]
    coverage = {"seed": plan["seed"], "random_operations": len(plan["random_operations"]),
                "accepted_reads": [0, 0, 0], "accepted_writes": [0, 0, 0],
                "targets": [0, 0, 0, 0], "lengths": [0] * 16,
                "qos": [0] * 16, "aw_w_styles": {},
                "target_aw_stalls": 0, "target_ar_stalls": 0,
                "target_w_stalls": 0, "manager_b_stalls": 0,
                "manager_r_stalls": 0, "response_delays": 0,
                "random_max_live_reads": 0, "random_max_live_writes": 0,
                "random_all_manager_active_cycles": 0,
                "random_same_target_contention": 0,
                "random_same_id_cross_manager": 0,
                "random_out_of_order_completions": 0,
                "random_reset_with_live_work": 0,
                "target_aw_stall_cycles": 0, "target_ar_stall_cycles": 0,
                "target_w_stall_cycles": 0, "target_aw_stall_episodes": 0,
                "target_ar_stall_episodes": 0, "target_w_stall_episodes": 0,
                "_stall_active": {}}

    # Anchors are run separately and excluded from random counters.
    for op in plan["coverage_anchors"]:
        m, ident, target, length = op["manager"], op["id"], op["target"], op["length"]
        if op["direction"] == "write":
            if target == 3:
                await s3_write(dut, model, m, ident, length, op["strobes"], op["qos"])
            else:
                await gate2.mapped_write(dut, model, memory, m, ident, target, length,
                                         op["strobes"], qos_value=op["qos"])
        else:
            if target == 3:
                await s3_read(dut, model, m, ident, length, op["address"], op["qos"])
            else:
                await gate2.mapped_read(dut, model, memory, m, ident, target, length,
                                        op["address"], qos_value=op["qos"])

    # First exercise a true request/response-separated multi-outstanding
    # manager schedule.  All request phases complete before any B/R monitor
    # drains, proving public-handshake live depth rather than coroutine depth.
    dut.target_awready.value = 0b111
    dut.target_wready.value = 0b111
    dut.target_arready.value = 0b111
    excluded_sequences = await _run_request_response_split(
        dut, model, memory, plan, target_locks, coverage)

    # From this point the concurrent external endpoint workers own the
    # target READY lanes.  Start them low so no target address can handshake
    # before its worker has begun sampling the public pins.
    dut.target_awready.value = 0
    dut.target_wready.value = 0
    dut.target_arready.value = 0
    gate2.reset_shadow(dut.target_awready, dut.target_wready, dut.target_arready)

    async def worker(manager):
        for op in [x for x in plan["random_operations"]
                   if x["manager"] == manager and x["sequence"] not in excluded_sequences]:
            while model.cycle < op["launch_cycle"]:
                await gate2.cycles(dut)
            target = op["target"]
            lock = target_locks[target] if target < 3 else None
            if lock is not None:
                await lock.acquire()
            active[manager] += 1
            try:
                dut._log.info("random start seq=%d %s M%d ID%d S%d LEN%d",
                              op["sequence"], op["direction"], manager,
                              op["id"], target, op["length"])
                coverage["targets"][target] += 1
                coverage["lengths"][op["length"]] += 1
                coverage["qos"][op["qos"]] += 1
                coverage["response_delays"] += int(op["response_delay"] > 0)
                coverage["manager_b_stalls"] += int(op["manager_b_stall"] > 0)
                coverage["manager_r_stalls"] += int(op["manager_r_stall"] > 0)
                coverage["aw_w_styles"][op["aw_w_style"]] = coverage["aw_w_styles"].get(op["aw_w_style"], 0) + 1
                if op["direction"] == "write":
                    coverage["accepted_writes"][manager] += 1
                    if target == 3:
                        await s3_write(dut, model, manager, op["id"], op["length"],
                                       op["strobes"], op["qos"])
                    else:
                        await _safe_mapped_write(dut, model, memory, manager, op["id"], target,
                                                 op["length"], op["strobes"], qos_value=op["qos"],
                                                 response_delay=op["response_delay"],
                                                 manager_b_stall=op["manager_b_stall"],
                                                 addr_override=op["address"],
                                                 aw_w_style=op.get("aw_w_style", "aw_before_w"),
                                                 # W-before-AW keeps WVALID resident before the
                                                 # address context exists; defer its AW pause in
                                                 # this serial compatibility driver so the W-before
                                                 # contract itself is not deadlocked by the endpoint
                                                 # admission gate. Other write styles exercise the
                                                 # planned AW pauses.
                                                 target_aw_stall=(op.get("target_aw_stall", 0)
                                                                  if op.get("aw_w_style") != "w_before_aw" else 0),
                                                 target_w_stall_beat=op.get("target_w_stall_beat"),
                                                 coverage=coverage)
                else:
                    coverage["accepted_reads"][manager] += 1
                    if target == 3:
                        await s3_read(dut, model, manager, op["id"], op["length"],
                                      op["address"], op["qos"])
                    else:
                        await _safe_mapped_read(dut, model, memory, manager, op["id"], target,
                                                op["length"], op["address"], qos_value=op["qos"],
                                                response_delay=op["response_delay"],
                                                manager_r_stall=op["manager_r_stall"],
                                                target_ar_stall=op.get("target_ar_stall", 0),
                                                coverage=coverage)
                live_r = sum(not tx.completed for tx in model.transactions.values()
                             if tx.key.direction == "ar")
                live_w = sum(not tx.completed for tx in model.transactions.values()
                             if tx.key.direction == "aw")
                coverage["random_max_live_reads"] = max(coverage["random_max_live_reads"], live_r)
                coverage["random_max_live_writes"] = max(coverage["random_max_live_writes"], live_w)
            finally:
                active[manager] -= 1
                if lock is not None:
                    lock.release()

    async def activity_monitor():
        while any(active) or model.cycle < 5200:
            await RisingEdge(dut.ACLK)
            if all(active):
                coverage["random_all_manager_active_cycles"] += 1

    monitor = cocotb.start_soon(activity_monitor())
    workers = [cocotb.start_soon(worker(m)) for m in range(3)]
    for task in workers:
        await Join(task)
    monitor.kill()
    coverage["target_aw_stalls"] = coverage["target_aw_stall_episodes"]
    coverage["target_ar_stalls"] = coverage["target_ar_stall_episodes"]
    coverage["target_w_stalls"] = coverage["target_w_stall_episodes"]
    coverage.pop("_stall_active", None)
    model.assert_drained()
    out = Path(os.environ["GATE3_OUT"])
    out.mkdir(parents=True, exist_ok=True)
    (out / "coverage.json").write_text(json.dumps(coverage, indent=2) + "\n")
    (out / "events.jsonl").write_text("\n".join(json.dumps(e) for e in model.events) + "\n")
    dut._log.info("Gate-3 random v2 PASS seed=0x%08x random_ops=%d", plan["seed"],
                  len(plan["random_operations"]))
