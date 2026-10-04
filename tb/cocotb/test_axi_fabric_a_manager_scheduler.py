"""Focused request/response-separated multi-outstanding manager regression."""
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock

from axi_reference_model import AxiReferenceModel
import test_axi_fabric_a_oracle as oracle


async def reset(dut, model):
    for name in ("manager_awvalid", "manager_wvalid", "manager_arvalid",
                 "manager_bready", "manager_rready", "target_bvalid",
                 "target_rvalid"):
        getattr(dut, name).value = 0
    dut.target_awready.value = 0b111
    dut.target_wready.value = 0b111
    dut.target_arready.value = 0b111
    dut.ARESETn.value = 0
    cocotb.start_soon(Clock(dut.ACLK, 10, unit="ns").start())
    await oracle.cycles(dut, 3)
    dut.ARESETn.value = 1
    model.reset()
    await oracle.cycles(dut, 2)


async def issue_four_reads(dut, model, manager):
    """Issue all four read requests before any response is returned."""
    for ident in range(4):
        await oracle._admit_read_no_response(dut, model, manager, ident, 0, 0)


async def drain_four_reads(dut, model, manager):
    """Return responses only after the request phase has reached depth four."""
    for ident in range(4):
        await oracle._return_r(dut, model, manager, ident, 0, 0)


async def issue_four_writes(dut, model, manager):
    """Issue AW/W for four writes, retaining all B responses."""
    for ident in range(4, 8):
        tx, _ = await oracle._admit_write_no_b(dut, model, manager, ident, 0, 0)
        await oracle._write_data_only(dut, model, tx, manager, 0, [0xFF])


async def drain_four_writes(dut, model, manager):
    """Return B responses only after the write request phase reaches depth four."""
    for ident in range(4, 8):
        await oracle._return_b(dut, model, manager, ident, 0)


@cocotb.test()
async def request_response_separated_manager_scheduler(dut):
    model = AxiReferenceModel()
    oracle._ACTIVE_MODEL = model
    oracle._LAST_MODEL_TIME = None
    await reset(dut, model)

    # Request and response are intentionally separate phases.  This is the
    # scheduling contract the random qualification body must exercise: a
    # manager may fill four distinct IDs before any response is consumed.
    await issue_four_reads(dut, model, 0)
    live_reads = [tx for tx in model.transactions.values()
                  if tx.key.direction == "ar" and not tx.completed]
    assert len(live_reads) == 4
    assert model.events[-1]["kind"] == "ar_target"
    await drain_four_reads(dut, model, 0)

    await issue_four_writes(dut, model, 0)
    live_writes = [tx for tx in model.transactions.values()
                  if tx.key.direction == "aw" and not tx.completed]
    assert len(live_writes) == 4
    assert model.events[-1]["kind"] == "w_target"
    await drain_four_writes(dut, model, 0)

    model.assert_drained()
    oracle._ACTIVE_MODEL = None
    dut._log.info("PASS request/response-separated manager scheduler: reads=4 writes=4")
