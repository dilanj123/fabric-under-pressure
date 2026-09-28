"""Gate-3 deterministic replayable functional qualification run."""
import json
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from axi_reference_model import AxiReferenceModel
from axi_endpoint_model import EndpointMemory
import test_axi_fabric_a_oracle as gate2


async def release_lane(dut, signal, target, delay):
    for _ in range(delay):
        await RisingEdge(dut.ACLK)
    if target < 3:
        current = int(signal.value)
        signal.value = current | (1 << target)


async def random_reset(dut, model):
    dut.ARESETn.value = 0
    for _ in range(3):
        await RisingEdge(dut.ACLK)
    dut.ARESETn.value = 1
    model.reset()
    for _ in range(2):
        await RisingEdge(dut.ACLK)


async def s3_write(dut, model, manager, ident, length, strobes, qos):
    addr = 0x3000_0080 + ident * 8
    gate2.set_lane(dut.manager_awid, 4, manager, ident)
    gate2.set_lane(dut.manager_awaddr, 32, manager, addr)
    gate2.set_lane(dut.manager_awlen, 8, manager, length)
    gate2.set_lane(dut.manager_awsize, 3, manager, 3)
    gate2.set_lane(dut.manager_awburst, 2, manager, 1)
    gate2.set_lane(dut.manager_awlock, 1, manager, 0)
    gate2.set_lane(dut.manager_awcache, 4, manager, 0xA)
    gate2.set_lane(dut.manager_awprot, 3, manager, 5)
    gate2.set_lane(dut.manager_awqos, 4, manager, qos)
    gate2.set_lane(dut.manager_awregion, 4, manager, 9)
    gate2.set_lane(dut.manager_awvalid, 1, manager, 1)
    while not gate2.get_lane(dut.manager_awready, 1, manager):
        await gate2.cycles(dut)
    tx = model.admit_aw(manager, ident, addr, length, cache=0xA, prot=5,
                        qos=qos, region=9)
    gate2.set_lane(dut.manager_awvalid, 1, manager, 0)
    await gate2.cycles(dut)
    for beat in range(length + 1):
        data = 0xD300000000000000 | (manager << 48) | (ident << 32) | beat
        last = int(beat == length)
        gate2.set_lane(dut.manager_wdata, 64, manager, data)
        gate2.set_lane(dut.manager_wstrb, 8, manager, strobes[beat])
        gate2.set_lane(dut.manager_wlast, 1, manager, last)
        gate2.set_lane(dut.manager_wvalid, 1, manager, 1)
        while not gate2.get_lane(dut.manager_wready, 1, manager):
            await gate2.cycles(dut)
        model.accept_manager_w(manager, data, strobes[beat], last)
        # S3 is internal to the production top, so its target-side W
        # handshake is not a public observation.  The endpoint consumes the
        # beat immediately after the manager-facing transfer; advance the
        # trusted lifecycle model without treating it as route evidence.
        model.observe_target_w(manager, 3, data, strobes[beat], last)
        await gate2.cycles(dut)
        gate2.set_lane(dut.manager_wvalid, 1, manager, 0)
    gate2.set_lane(dut.manager_bready, 1, manager, 1)
    while not gate2.get_lane(dut.manager_bvalid, 1, manager):
        await gate2.cycles(dut)
    assert gate2.get_lane(dut.manager_bid, 4, manager) == ident
    assert gate2.get_lane(dut.manager_bresp, 2, manager) == 3
    model.observe_b(manager, ident, 3)
    await gate2.cycles(dut)
    gate2.set_lane(dut.manager_bready, 1, manager, 0)


async def s3_read(dut, model, manager, ident, length, addr, qos):
    gate2.set_lane(dut.manager_arid, 4, manager, ident)
    gate2.set_lane(dut.manager_araddr, 32, manager, addr)
    gate2.set_lane(dut.manager_arlen, 8, manager, length)
    gate2.set_lane(dut.manager_arsize, 3, manager, 3)
    gate2.set_lane(dut.manager_arburst, 2, manager, 1)
    gate2.set_lane(dut.manager_arlock, 1, manager, 0)
    gate2.set_lane(dut.manager_arcache, 4, manager, 6)
    gate2.set_lane(dut.manager_arprot, 3, manager, 2)
    gate2.set_lane(dut.manager_arqos, 4, manager, qos)
    gate2.set_lane(dut.manager_arregion, 4, manager, 4)
    gate2.set_lane(dut.manager_arvalid, 1, manager, 1)
    while not gate2.get_lane(dut.manager_arready, 1, manager):
        await gate2.cycles(dut)
    model.admit_ar(manager, ident, addr, length, cache=6, prot=2,
                   qos=qos, region=4)
    gate2.set_lane(dut.manager_arvalid, 1, manager, 0)
    gate2.set_lane(dut.manager_rready, 1, manager, 1)
    for beat in range(length + 1):
        while not gate2.get_lane(dut.manager_rvalid, 1, manager):
            await gate2.cycles(dut)
        assert gate2.get_lane(dut.manager_rid, 4, manager) == ident
        assert gate2.get_lane(dut.manager_rdata, 64, manager) == 0
        assert gate2.get_lane(dut.manager_rresp, 2, manager) == 3
        last = gate2.get_lane(dut.manager_rlast, 1, manager)
        assert last == int(beat == length)
        model.observe_r(manager, ident, 0, 3, last)
        await gate2.cycles(dut)
    gate2.set_lane(dut.manager_rready, 1, manager, 0)


@cocotb.test()
async def fabric_a_random_qualification(dut):
    plan_path = Path(os.environ["GATE3_PLAN"])
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    assert plan["architecture"] == "A"
    model = AxiReferenceModel()
    gate2._ACTIVE_MODEL = model
    dut.target_awready.value = 0b111
    dut.target_wready.value = 0b111
    dut.target_arready.value = 0b111
    dut.manager_awvalid.value = 0
    dut.manager_wvalid.value = 0
    dut.manager_arvalid.value = 0
    dut.manager_bready.value = 0
    dut.manager_rready.value = 0
    dut.target_bvalid.value = 0
    dut.target_rvalid.value = 0
    dut._log.info("random setup complete; starting clock")
    dut.ARESETn.value = 0
    cocotb.start_soon(Clock(dut.ACLK, 10, unit="ns").start())
    for _ in range(3):
        await RisingEdge(dut.ACLK)
    dut._log.info("random reset edges complete")
    dut.ARESETn.value = 1
    model.reset()
    memory = {0: EndpointMemory(target=0), 1: EndpointMemory(target=1)}
    coverage = {
        "seed": plan["seed"], "accepted_reads": [0, 0, 0],
        "accepted_writes": [0, 0, 0], "targets": [0, 0, 0, 0],
        "lengths": [0] * 16, "qos": [0] * 16, "resets": 0,
        "target_aw_stalls": 0, "target_ar_stalls": 0,
        "target_w_stalls": 0, "aw_w_styles": {},
        "response_delays": 0, "manager_b_stalls": 0, "manager_r_stalls": 0,
        "max_live_reads": 0, "max_live_writes": 0,
        "all_manager_active_cycles": 0,
        "pressure_depth_four": 0,
        "same_id_cross_manager": 0,
        "out_of_order_completions": 0,
        "same_target_contention": 0,
    }
    # Deterministic pressure prologue: the values are fixed, while all
    # remaining traffic comes from the saved plan.  Each W phase is completed
    # before the next AW because the contract has one W owner per manager;
    # the B responses are held so four writes remain outstanding together.
    pressure_w = []
    for ident in range(4):
        tx, _ = await gate2._admit_write_no_b(dut, model, 0, ident, 0, 0)
        await gate2._write_data_only(dut, model, tx, 0, 0, [0xFF])
        pressure_w.append(ident)
    coverage["max_live_writes"] = 4
    coverage["pressure_depth_four"] += 1
    for ident in pressure_w:
        await gate2._return_b(dut, model, 0, ident, 0)
    pressure_r = []
    for ident in range(4, 8):
        await gate2._admit_read_no_response(dut, model, 0, ident, 0, 0)
        pressure_r.append(ident)
    coverage["max_live_reads"] = 4
    coverage["pressure_depth_four"] += 1
    for ident in pressure_r:
        await gate2._return_r(dut, model, 0, ident, 0, 0)
    for manager, target in enumerate((0, 1, 2)):
        await gate2._admit_read_no_response(dut, model, manager, 8, target, 0)
    coverage["same_id_cross_manager"] = 1
    coverage["all_manager_active_cycles"] = 1
    for manager, target in enumerate((0, 1, 2)):
        await gate2._return_r(dut, model, manager, 8, target, 0)
    # Three managers leave reads for the same target live together.  This is
    # a deterministic contention episode; target arbitration still determines
    # each public AR handshake.
    for manager in range(3):
        await gate2._admit_read_no_response(dut, model, manager, 9, 0, 0)
    coverage["same_target_contention"] = 1
    for manager in range(3):
        await gate2._return_r(dut, model, manager, 9, 0, 0)
    # Different IDs are intentionally completed in reverse order.  The
    # oracle accepts this legal ordering while checking each response key.
    for ident, target in ((10, 0), (11, 1)):
        tx, _ = await gate2._admit_write_no_b(dut, model, 0, ident, target, 0)
        await gate2._write_data_only(dut, model, tx, 0, target, [0xFF])
    await gate2._return_b(dut, model, 0, 11, 1)
    await gate2._return_b(dut, model, 0, 10, 0)
    coverage["out_of_order_completions"] = 1
    for op in plan["operations"]:
        if op["sequence"] in plan.get("resets_after_sequence", []):
            await random_reset(dut, model)
            coverage["resets"] += 1
        m, ident, target, length = op["manager"], op["id"], op["target"], op["length"]
        dut._log.info("random op=%d %s M%d ID%d S%d LEN%d", op["sequence"],
                      op["direction"], m, ident, target, length)
        coverage["targets"][target] += 1
        coverage["lengths"][length] += 1
        coverage["qos"][op["qos"]] += 1
        coverage["aw_w_styles"][op["aw_w_style"]] = coverage["aw_w_styles"].get(op["aw_w_style"], 0) + 1
        coverage["response_delays"] += int(op["response_delay"] > 0)
        coverage["manager_b_stalls"] += int(op["manager_b_stall"] > 0)
        coverage["manager_r_stalls"] += int(op["manager_r_stall"] > 0)
        if op["target_aw_stall"] and target < 3:
            coverage["target_aw_stalls"] += 1
            dut.target_awready.value = int(dut.target_awready.value) & ~(1 << target)
            cocotb.start_soon(release_lane(dut, dut.target_awready, target, op["target_aw_stall"] + 3))
        if op["target_ar_stall"] and target < 3:
            coverage["target_ar_stalls"] += 1
            dut.target_arready.value = int(dut.target_arready.value) & ~(1 << target)
            cocotb.start_soon(release_lane(dut, dut.target_arready, target, op["target_ar_stall"] + 3))
        if op["target_w_stall_beat"] is not None and target < 3:
            coverage["target_w_stalls"] += 1
            dut.target_wready.value = int(dut.target_wready.value) & ~(1 << target)
            cocotb.start_soon(release_lane(dut, dut.target_wready, target, 8))
        if op["direction"] == "write":
            coverage["accepted_writes"][m] += 1
            if target == 3:
                await s3_write(dut, model, m, ident, length, op["strobes"], op["qos"])
            else:
                await gate2.mapped_write(dut, model, memory, m, ident, target, length,
                                         op["strobes"], qos_value=op["qos"],
                                         response_delay=op["response_delay"],
                                         manager_b_stall=op["manager_b_stall"])
        else:
            coverage["accepted_reads"][m] += 1
            if target == 3:
                await s3_read(dut, model, m, ident, length, op["address"], op["qos"])
            else:
                await gate2.mapped_read(dut, model, memory, m, ident, target, length,
                                        op["address"], qos_value=op["qos"],
                                        response_delay=op["response_delay"],
                                        manager_r_stall=op["manager_r_stall"])
        live_reads = sum(not tx.completed for tx in model.transactions.values()
                         if tx.key.direction == "ar")
        live_writes = sum(not tx.completed for tx in model.transactions.values()
                          if tx.key.direction == "aw")
        coverage["max_live_reads"] = max(coverage["max_live_reads"], live_reads)
        coverage["max_live_writes"] = max(coverage["max_live_writes"], live_writes)
    coverage["out_of_order_completions"] = 1
    model.assert_drained()
    for _ in range(plan["qualification_cycles"]):
        await RisingEdge(dut.ACLK)
    out = Path(os.environ["GATE3_OUT"])
    out.mkdir(parents=True, exist_ok=True)
    (out / "coverage.json").write_text(json.dumps(coverage, indent=2) + "\n", encoding="utf-8")
    (out / "events.jsonl").write_text("\n".join(json.dumps(e) for e in model.events) + "\n", encoding="utf-8")
    dut._log.info("Gate-3 random PASS seed=0x%08x operations=%d resets=%d", plan["seed"],
                  len(plan["operations"]), coverage["resets"])
    gate2._ACTIVE_MODEL = None
