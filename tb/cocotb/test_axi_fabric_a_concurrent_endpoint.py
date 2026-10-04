"""Focused DUT regression for handshake-safe external R response ownership."""
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer

import test_axi_fabric_a_oracle as gate2
from axi_reference_model import AxiReferenceModel
from axi_endpoint_model import EndpointMemory
from test_axi_fabric_a_random_v2 import _safe_target_read_endpoint


async def _edge(dut):
    await gate2.cycles(dut)
    await Timer(1, unit="ps")


@cocotb.test()
async def endpoint_rvalid_retention(dut):
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
    cocotb.start_soon(Clock(dut.ACLK, 10, unit="ns").start())
    await gate2.cycles(dut, 3)
    dut.ARESETn.value = 1
    model.reset()

    manager, ident, target, addr, length = 1, 6, 0, 0x0000_0740, 3
    cache, prot, qos, region = 6, 2, 7, 4
    memory = EndpointMemory(target=target)
    endpoint = cocotb.start_soon(_safe_target_read_endpoint(
        dut, model, target, manager, ident, addr, length, memory,
        response_delay=0, cache=cache, prot=prot, qos=qos, region=region))

    fields = (("manager_arid", 4, ident), ("manager_araddr", 32, addr),
              ("manager_arlen", 8, length), ("manager_arsize", 3, 3),
              ("manager_arburst", 2, 1), ("manager_arlock", 1, 0),
              ("manager_arcache", 4, cache), ("manager_arprot", 3, prot),
              ("manager_arqos", 4, qos), ("manager_arregion", 4, region))
    for name, width, value in fields:
        gate2.set_lane(getattr(dut, name), width, manager, value)
    gate2.set_lane(dut.manager_arvalid, 1, manager, 1)
    while True:
        await Timer(1, unit="ps")
        ready = gate2.get_lane(dut.manager_arready, 1, manager)
        await gate2.cycles(dut)
        if ready:
            model.admit_ar(manager, ident, addr, length, cache=cache, prot=prot,
                           qos=qos, region=region)
            break
    gate2.set_lane(dut.manager_arvalid, 1, manager, 0)

    # Keep the manager slot occupied. Once the first endpoint beat is active,
    # the fabric must remove target RREADY while preserving the endpoint beat.
    gate2.set_lane(dut.manager_rready, 1, manager, 0)
    while (not gate2.get_lane(dut.target_rvalid, 1, target)
           or gate2.get_lane(dut.target_rready, 1, target)):
        await _edge(dut)
    held = (gate2.get_lane(dut.target_rid, 6, target),
            gate2.get_lane(dut.target_rdata, 64, target),
            gate2.get_lane(dut.target_rresp, 2, target),
            gate2.get_lane(dut.target_rlast, 1, target))
    for _ in range(4):
        assert gate2.get_lane(dut.target_rvalid, 1, target) == 1
        assert (gate2.get_lane(dut.target_rid, 6, target),
                gate2.get_lane(dut.target_rdata, 64, target),
                gate2.get_lane(dut.target_rresp, 2, target),
                gate2.get_lane(dut.target_rlast, 1, target)) == held
        await _edge(dut)

    gate2.set_lane(dut.manager_rready, 1, manager, 1)
    accepted = []
    for beat in range(length + 1):
        while True:
            await Timer(1, unit="ps")
            valid = gate2.get_lane(dut.manager_rvalid, 1, manager)
            ready = gate2.get_lane(dut.manager_rready, 1, manager)
            if valid and ready:
                rid = gate2.get_lane(dut.manager_rid, 4, manager)
                data = gate2.get_lane(dut.manager_rdata, 64, manager)
                resp = gate2.get_lane(dut.manager_rresp, 2, manager)
                last = gate2.get_lane(dut.manager_rlast, 1, manager)
                await gate2.cycles(dut)
                assert rid == ident
                dut._log.info("retention beat=%d data=%#x last=%d", beat, data, last)
                accepted.append((data, last))
                model.observe_r(manager, ident, data, resp, last, None)
                break
            await _edge(dut)
    await endpoint
    assert [d for d, _ in accepted] == [memory.read64(addr + 8 * i) for i in range(length + 1)]
    model.assert_drained()
    gate2.set_lane(dut.manager_rready, 1, manager, 0)
    gate2._ACTIVE_MODEL = None
    dut._log.info("PASS focused DUT RVALID retention: held=%#x, beats=%d", held[1], length + 1)
