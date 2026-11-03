"""Handshake-timed canonical performance run for Architecture A (and later B).

The coroutine is one cycle engine: it is the sole writer of DUT inputs, samples
all ports once before each active edge, then updates manager and endpoint state
from that immutable snapshot.  No transaction owns a response wait loop.
"""
from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
import hashlib
import json
import os
from pathlib import Path
import sys

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

from benchmark_plan import (
    GENERATOR_VERSION, Intent, WORKLOAD_SHA256, intent_digest,
    make_intents, validate_intents,
)

MASK64 = (1 << 64) - 1
LANE_WIDTHS = {
    "manager_awid": 4, "manager_awaddr": 32, "manager_awlen": 8,
    "manager_awsize": 3, "manager_awburst": 2, "manager_awlock": 1,
    "manager_awcache": 4, "manager_awprot": 3, "manager_awqos": 4,
    "manager_awregion": 4, "manager_awvalid": 1,
    "manager_wdata": 64, "manager_wstrb": 8, "manager_wlast": 1,
    "manager_wvalid": 1, "manager_bready": 1,
    "manager_arid": 4, "manager_araddr": 32, "manager_arlen": 8,
    "manager_arsize": 3, "manager_arburst": 2, "manager_arlock": 1,
    "manager_arcache": 4, "manager_arprot": 3, "manager_arqos": 4,
    "manager_arregion": 4, "manager_arvalid": 1, "manager_rready": 1,
    "target_awready": 1, "target_wready": 1,
    "target_bid": 6, "target_bresp": 2, "target_bvalid": 1,
    "target_arready": 1, "target_rid": 6, "target_rdata": 64,
    "target_rresp": 2, "target_rlast": 1, "target_rvalid": 1,
}


def lane(bus: int, width: int, index: int) -> int:
    return (bus >> (width * index)) & ((1 << width) - 1)


def packed(values: list[int], width: int) -> int:
    return sum((int(v) & ((1 << width) - 1)) << (width * i)
               for i, v in enumerate(values))


def data_for_read(target: int, address: int, beat: int) -> int:
    return ((address * 0x9E3779B185EBCA87) ^ (target << 56) ^
            (beat * 0xD6E8FEB86659FD93) ^ 0xA5A55A5AF00D1234) & MASK64


def data_for_write(tx: "Transaction", beat: int) -> int:
    return (0x5A00000000000000 ^ (tx.intent.sequence << 16) ^
            (tx.intent.manager << 12) ^ (tx.intent.ident << 8) ^ beat) & MASK64


@dataclass
class Transaction:
    intent: Intent
    t_present: int | None = None
    t_addr_accept: int | None = None
    target_addr_accept: int | None = None
    t_wlast_manager: int | None = None
    t_wlast_target: int | None = None
    t_first_resp: int | None = None
    t_complete: int | None = None
    manager_w_cycles: list[int] = field(default_factory=list)
    target_w_cycles: list[int] = field(default_factory=list)
    manager_r_cycles: list[int] = field(default_factory=list)
    target_r_cycles: list[int] = field(default_factory=list)
    manager_wbeat: int = 0
    target_wbeat: int = 0
    manager_rbeat: int = 0
    target_rbeat: int = 0
    opportunity_losses: int = 0
    opportunity_loss_cycles: list[int] = field(default_factory=list)
    target_backpressure_cycles: dict = field(default_factory=lambda: {"aw": 0, "ar": 0, "w": 0})
    target_backpressure_event_cycles: dict = field(
        default_factory=lambda: {"aw": [], "ar": [], "w": []})
    max_pending_cycles: int = 0
    write_owner_blocked_cycles: int = 0
    target_owner_blocked_cycles: int = 0
    sampled: bool = False
    sample_index: int | None = None


@dataclass
class Manager:
    reads: deque
    writes: deque
    ar: Transaction | None = None
    aw: Transaction | None = None
    live_reads: dict = field(default_factory=dict)
    live_writes: dict = field(default_factory=dict)
    w_owner: Transaction | None = None


@dataclass
class EndpointWrite:
    tx: Transaction
    w_done: bool = False
    b_due: int | None = None


@dataclass
class EndpointRead:
    tx: Transaction
    due: int
    beat: int = 0


class Endpoint:
    """Canonical one-target FIFO model, stepped only by the central loop."""
    def __init__(self, target: int):
        self.target = target
        self.writes: deque[EndpointWrite] = deque()
        self.reads: deque[EndpointRead] = deque()
        self.max_write_depth = 0
        self.max_read_depth = 0

    def drive(self, cycle: int, values: dict):
        t = self.target
        values["target_awready"][t] = int(len(self.writes) < 8)
        values["target_arready"][t] = int(len(self.reads) < 8)
        active_w = next((x for x in self.writes if not x.w_done), None)
        values["target_wready"][t] = int(active_w is not None)
        if self.writes and self.writes[0].w_done and self.writes[0].b_due <= cycle:
            values["target_bvalid"][t] = 1
            values["target_bid"][t] = widened_id(self.writes[0].tx)
            values["target_bresp"][t] = 0
        head = self.reads[0] if self.reads else None
        if head is not None and head.due <= cycle:
            values["target_rvalid"][t] = 1
            values["target_rid"][t] = widened_id(head.tx)
            values["target_rdata"][t] = data_for_read(t, head.tx.intent.address, head.beat)
            values["target_rresp"][t] = 0
            values["target_rlast"][t] = int(head.beat == head.tx.intent.length)

    def on_aw(self, tx: Transaction):
        self.writes.append(EndpointWrite(tx))
        self.max_write_depth = max(self.max_write_depth, len(self.writes))

    def on_w(self, cycle: int, snap: dict):
        if not self.writes:
            raise AssertionError(f"S{self.target} target W without accepted AW")
        ctx = next((x for x in self.writes if not x.w_done), None)
        if ctx is None:
            raise AssertionError(f"S{self.target} W after final WLAST")
        tx = ctx.tx
        beat = tx.target_wbeat
        expected_last = int(beat == tx.intent.length)
        expected_data = data_for_write(tx, beat)
        got = snap["target_wdata"][self.target]
        strb = snap["target_wstrb"][self.target]
        last = snap["target_wlast"][self.target]
        if (got, strb, last) != (expected_data, 0xFF, expected_last):
            raise AssertionError(
                f"target W mismatch S{self.target} seq={tx.intent.sequence} beat={beat} "
                f"data={got:#x}/{expected_data:#x} strb={strb:#x} last={last}/{expected_last}")
        tx.target_w_cycles.append(cycle)
        tx.target_wbeat += 1
        if expected_last:
            ctx.w_done = True
            ctx.b_due = cycle + 2
            tx.t_wlast_target = cycle
        return tx, bool(expected_last)

    def on_ar(self, cycle: int, tx: Transaction):
        self.reads.append(EndpointRead(tx, cycle + 2))
        self.max_read_depth = max(self.max_read_depth, len(self.reads))

    def on_r(self, cycle: int, snap: dict):
        ctx = self.reads[0]
        tx = ctx.tx
        beat = ctx.beat
        expected = data_for_read(self.target, tx.intent.address, beat)
        got = snap["target_rdata"][self.target]
        last = snap["target_rlast"][self.target]
        expected_last = int(beat == tx.intent.length)
        if (snap["target_rid"][self.target], got,
                snap["target_rresp"][self.target], last) != (
                widened_id(tx), expected, 0, expected_last):
            raise AssertionError(f"target R mismatch S{self.target} seq={tx.intent.sequence} beat={beat}")
        tx.target_r_cycles.append(cycle)
        tx.target_rbeat += 1
        ctx.beat += 1
        if expected_last:
            self.reads.popleft()


def widened_id(tx: Transaction) -> int:
    return (tx.intent.manager << 4) | tx.intent.ident


def due(tx: Transaction, cycle: int) -> bool:
    return tx.intent.release_cycle <= cycle


def tx_record(tx: Transaction, end_cycle: int, warmup: int,
              measure_start: int | None, measure_end: int | None) -> dict:
    i = tx.intent
    record = {
        "sequence": i.sequence, "manager": i.manager,
        "direction": i.direction, "id": i.ident, "target": i.target,
        "address": i.address, "len": i.length, "qos": i.qos,
        "release_cycle": i.release_cycle, "t_present": tx.t_present,
        "t_addr_accept": tx.t_addr_accept,
        "target_addr_accept": tx.target_addr_accept,
        "t_wlast_manager": tx.t_wlast_manager,
        "t_wlast_target": tx.t_wlast_target,
        "t_first_resp": tx.t_first_resp, "t_complete": tx.t_complete,
        "manager_w_cycles": tx.manager_w_cycles,
        "target_w_cycles": tx.target_w_cycles,
        "manager_r_cycles": tx.manager_r_cycles,
        "target_r_cycles": tx.target_r_cycles,
        "opportunity_losses": tx.opportunity_losses,
        "opportunity_loss_cycles": tx.opportunity_loss_cycles,
        "target_backpressure_cycles": tx.target_backpressure_cycles,
        "target_backpressure_event_cycles": tx.target_backpressure_event_cycles,
        "max_pending_cycles": tx.max_pending_cycles,
        "write_owner_blocked_cycles": tx.write_owner_blocked_cycles,
        "target_owner_blocked_cycles": tx.target_owner_blocked_cycles,
        "sampled_latency": tx.sampled, "sample_index": tx.sample_index,
        "warmup_completions_per_manager": warmup,
        "common_window_start": measure_start, "common_window_end": measure_end,
        "complete_cycle": end_cycle,
    }
    return record


@cocotb.test()
async def architecture_a_canonical_benchmark(dut):
    workload = os.environ["ARCH_BENCH_WORKLOAD"]
    seed = int(os.environ["ARCH_BENCH_SEED"], 0)
    qualification = os.environ.get("ARCH_BENCH_QUALIFICATION", "0") == "1"
    warmup = int(os.environ.get("ARCH_BENCH_WARMUP", "500"))
    samples = int(os.environ.get("ARCH_BENCH_SAMPLES", "5000"))
    intent_limit = int(os.environ.get("ARCH_BENCH_INTENTS_PER_MANAGER", "50000"))
    out = Path(os.environ["ARCH_BENCH_OUT"])
    out.mkdir(parents=True, exist_ok=True)
    intents = make_intents(workload, seed, per_manager=intent_limit)
    validate_intents(intents)
    active = sorted({x.manager for x in intents})
    managers = [Manager(deque(), deque()) for _ in range(3)]
    all_tx: dict[tuple[int, int, str], Transaction] = {}
    for intent in intents:
        tx = Transaction(intent)
        all_tx[(intent.manager, intent.sequence, intent.direction)] = tx
        (managers[intent.manager].reads if intent.direction == "read"
         else managers[intent.manager].writes).append(tx)
    endpoints = [Endpoint(t) for t in range(3)]
    target_w_owner: list[Transaction | None] = [None, None, None]
    completion_count = [0, 0, 0]
    measured_count = [0, 0, 0]
    measure_start: int | None = None
    measure_end: int | None = None
    premeasurement_completions = None
    measure_cycles = 0
    max_wait = {m: {"read": 0, "write": 0} for m in range(3)}
    grant_counts = {"aw": [0, 0, 0], "ar": [0, 0, 0]}
    contention_opportunities = {"aw": 0, "ar": 0}
    max_live_reads = [0, 0, 0]
    max_live_writes = [0, 0, 0]
    target_stall_cycles = {name: [0, 0, 0] for name in ("aw", "ar", "w")}
    target_stall_episodes = {name: [0, 0, 0] for name in ("aw", "ar", "w")}
    previous_target_stall = {name: [False, False, False] for name in ("aw", "ar", "w")}
    manager_stall_cycles = {name: [0, 0, 0] for name in ("b", "r")}
    manager_stall_episodes = {name: [0, 0, 0] for name in ("b", "r")}
    previous_manager_stall = {name: [False, False, False] for name in ("b", "r")}
    previous_snapshot = None
    parallel_target_cycles = 0
    all_manager_active_cycles = 0
    event_path = out / "transactions.jsonl"
    event_file = event_path.open("w", encoding="utf-8")
    event_file.write(json.dumps({"kind": "run_start", "seed": f"0x{seed:08X}",
                                 "workload": workload,
                                 "generator": GENERATOR_VERSION,
                                 "intent_sha256": intent_digest(intents),
                                 "intent_count": len(intents)}) + "\n")

    def choose_presentations(cycle: int, allow_new: bool):
        for m, state in enumerate(managers):
            if state.ar is None and allow_new and state.reads:
                candidate = state.reads[0]
                if due(candidate, cycle) and len(state.live_reads) < 4 and \
                        candidate.intent.ident not in state.live_reads:
                    state.ar = state.reads.popleft()
                    state.ar.t_present = cycle
            if state.aw is None and allow_new and state.writes:
                candidate = state.writes[0]
                if due(candidate, cycle) and len(state.live_writes) < 4 and \
                        candidate.intent.ident not in state.live_writes:
                    state.aw = state.writes.popleft()
                    state.aw.t_present = cycle

    def make_inputs(cycle: int):
        values = {name: [0] * 3
                  for name in LANE_WIDTHS}
        choose_presentations(cycle, measure_end is None)
        for m, state in enumerate(managers):
            values["manager_bready"][m] = 1
            values["manager_rready"][m] = 1
            if state.aw is not None:
                tx = state.aw
                values["manager_awvalid"][m] = 1
                for name, value in (
                    ("manager_awid", tx.intent.ident), ("manager_awaddr", tx.intent.address),
                    ("manager_awlen", tx.intent.length), ("manager_awsize", 3),
                    ("manager_awburst", 1), ("manager_awlock", 0),
                    ("manager_awcache", 0), ("manager_awprot", 0),
                    ("manager_awqos", tx.intent.qos), ("manager_awregion", 0)):
                    values[name][m] = value
            if state.ar is not None:
                tx = state.ar
                values["manager_arvalid"][m] = 1
                for name, value in (
                    ("manager_arid", tx.intent.ident), ("manager_araddr", tx.intent.address),
                    ("manager_arlen", tx.intent.length), ("manager_arsize", 3),
                    ("manager_arburst", 1), ("manager_arlock", 0),
                    ("manager_arcache", 0), ("manager_arprot", 0),
                    ("manager_arqos", tx.intent.qos), ("manager_arregion", 0)):
                    values[name][m] = value
            if state.w_owner is not None and state.w_owner.manager_wbeat <= state.w_owner.intent.length:
                tx = state.w_owner
                beat = tx.manager_wbeat
                values["manager_wvalid"][m] = 1
                values["manager_wdata"][m] = data_for_write(tx, beat)
                values["manager_wstrb"][m] = 0xFF
                values["manager_wlast"][m] = int(beat == tx.intent.length)
        for ep in endpoints:
            ep.drive(cycle, values)
        return values

    def snapshot():
        snap = {}
        for name, width in LANE_WIDTHS.items():
            handle = getattr(dut, name)
            snap[name] = [lane(int(handle.value), width, i) for i in range(3)]
        # Public DUT outputs not driven by the environment.
        outputs = {
            "manager_awready": 1, "manager_wready": 1,
            "manager_bvalid": 1, "manager_bid": 4, "manager_bresp": 2,
            "manager_arready": 1, "manager_rvalid": 1, "manager_rid": 4,
            "manager_rdata": 64, "manager_rresp": 2, "manager_rlast": 1,
            "target_awvalid": 1, "target_awid": 6, "target_awaddr": 32,
            "target_awlen": 8, "target_awsize": 3, "target_awburst": 2,
            "target_awlock": 1, "target_awcache": 4, "target_awprot": 3,
            "target_awqos": 4, "target_awregion": 4,
            "target_wvalid": 1, "target_wdata": 64,
            "target_wstrb": 8, "target_wlast": 1, "target_bready": 1,
            "target_arvalid": 1, "target_arid": 6, "target_araddr": 32,
            "target_arlen": 8, "target_arsize": 3, "target_arburst": 2,
            "target_arlock": 1, "target_arcache": 4, "target_arprot": 3,
            "target_arqos": 4, "target_arregion": 4, "target_rready": 1,
        }
        for name, width in outputs.items():
            handle = getattr(dut, name)
            snap[name] = [lane(int(handle.value), width, i) for i in range(3)]
        snap["resetn"] = int(dut.ARESETn.value)
        return snap

    def fire(s, valid, ready, i):
        return bool(s[valid][i] and s[ready][i])

    def find_live(manager: int, direction: str, ident: int) -> Transaction:
        live = managers[manager].live_reads if direction == "read" else managers[manager].live_writes
        if ident not in live:
            state = managers[manager]
            raise AssertionError(
                f"completion for non-live M{manager} {direction} ID{ident}; "
                f"live_reads={list(state.live_reads)} live_writes={list(state.live_writes)} "
                f"present_aw={state.aw.intent.sequence if state.aw else None} "
                f"present_ar={state.ar.intent.sequence if state.ar else None} "
                f"w_owner={state.w_owner.intent.sequence if state.w_owner else None} "
                f"cycle={cycle}")
        return live[ident]

    def finish(tx: Transaction, cycle: int):
        nonlocal measure_start, measure_end
        m = tx.intent.manager
        completion_count[m] += 1
        if measure_start is not None and cycle >= measure_start and measured_count[m] < samples:
            measured_count[m] += 1
            tx.sampled = True
            tx.sample_index = measured_count[m]
        event_file.write(json.dumps(tx_record(tx, cycle, warmup, measure_start, measure_end),
                                    separators=(",", ":")) + "\n")

    def process(cycle: int, s: dict, driven: dict):
        nonlocal measure_start, measure_end, parallel_target_cycles, all_manager_active_cycles
        nonlocal previous_snapshot, premeasurement_completions
        if not s["resetn"]:
            raise AssertionError("unexpected reset during canonical benchmark")

        held_channels = (
            ("manager AW", "manager_awvalid", "manager_awready",
             ("manager_awid", "manager_awaddr", "manager_awlen", "manager_awsize",
              "manager_awburst", "manager_awlock", "manager_awcache", "manager_awprot",
              "manager_awqos", "manager_awregion")),
            ("manager W", "manager_wvalid", "manager_wready",
             ("manager_wdata", "manager_wstrb", "manager_wlast")),
            ("manager AR", "manager_arvalid", "manager_arready",
             ("manager_arid", "manager_araddr", "manager_arlen", "manager_arsize",
              "manager_arburst", "manager_arlock", "manager_arcache", "manager_arprot",
              "manager_arqos", "manager_arregion")),
            ("manager B", "manager_bvalid", "manager_bready", ("manager_bid", "manager_bresp")),
            ("manager R", "manager_rvalid", "manager_rready",
             ("manager_rid", "manager_rdata", "manager_rresp", "manager_rlast")),
            ("target AW", "target_awvalid", "target_awready",
             ("target_awid", "target_awaddr", "target_awlen", "target_awsize",
              "target_awburst", "target_awlock", "target_awcache", "target_awprot",
              "target_awqos", "target_awregion")),
            ("target W", "target_wvalid", "target_wready",
             ("target_wdata", "target_wstrb", "target_wlast")),
            ("target B", "target_bvalid", "target_bready", ("target_bid", "target_bresp")),
            ("target AR", "target_arvalid", "target_arready",
             ("target_arid", "target_araddr", "target_arlen", "target_arsize",
              "target_arburst", "target_arlock", "target_arcache", "target_arprot",
              "target_arqos", "target_arregion")),
            ("target R", "target_rvalid", "target_rready",
             ("target_rid", "target_rdata", "target_rresp", "target_rlast")),
        )
        if previous_snapshot is not None:
            for label, valid, ready, payload in held_channels:
                for lane_index in range(3):
                    if (previous_snapshot[valid][lane_index] and
                            not previous_snapshot[ready][lane_index]):
                        old = tuple(previous_snapshot[name][lane_index] for name in payload)
                        new = tuple(s[name][lane_index] for name in payload)
                        if not s[valid][lane_index] or old != new:
                            raise AssertionError(
                                f"{label} payload/VALID changed while stalled lane={lane_index} "
                                f"cycle={cycle} old={old} new={new}")
        previous_snapshot = s

        m_aw = [fire(s, "manager_awvalid", "manager_awready", m) for m in range(3)]
        m_ar = [fire(s, "manager_arvalid", "manager_arready", m) for m in range(3)]
        m_w = [fire(s, "manager_wvalid", "manager_wready", m) for m in range(3)]
        m_b = [fire(s, "manager_bvalid", "manager_bready", m) for m in range(3)]
        m_r = [fire(s, "manager_rvalid", "manager_rready", m) for m in range(3)]
        t_aw = [fire(s, "target_awvalid", "target_awready", t) for t in range(3)]
        t_ar = [fire(s, "target_arvalid", "target_arready", t) for t in range(3)]
        t_w = [fire(s, "target_wvalid", "target_wready", t) for t in range(3)]
        t_b = [fire(s, "target_bvalid", "target_bready", t) for t in range(3)]
        t_r = [fire(s, "target_rvalid", "target_rready", t) for t in range(3)]

        for direction, fires, valid_name, ready_name in (
            ("aw", m_aw, "manager_awvalid", "manager_awready"),
            ("ar", m_ar, "manager_arvalid", "manager_arready")):
            winners = [m for m, value in enumerate(fires) if value]
            presented = [state.aw if direction == "aw" else state.ar
                         for state in managers]
            if len({presented[m].intent.target for m in winners}) != len(winners):
                raise AssertionError(f"multiple {direction.upper()} grants to one target in a cycle")
            for winner in winners:
                win_tx = presented[winner]
                if win_tx is None:
                    raise AssertionError(f"{direction.upper()} fire without presented request")
                grant_counts[direction][winner] += 1
                for m, losing in enumerate(presented):
                    state = managers[m]
                    if (m == winner or fires[m] or losing is None or
                            losing.intent.target != win_tx.intent.target):
                        continue
                    if direction == "aw" and state.w_owner is not None:
                        continue
                    if direction == "aw" and target_w_owner[win_tx.intent.target] is not None:
                        continue
                    live = state.live_writes if direction == "aw" else state.live_reads
                    if len(live) < 4 and losing.intent.ident not in live:
                        losing.opportunity_losses += 1
                        losing.opportunity_loss_cycles.append(cycle)
                        contention_opportunities[direction] += 1
                if direction == "aw":
                    tx = win_tx
                    mid = s["manager_awid"][winner]
                    if (mid, s["manager_awaddr"][winner], s["manager_awlen"][winner],
                        s["manager_awqos"][winner], s["manager_awsize"][winner],
                        s["manager_awburst"][winner]) != (
                        tx.intent.ident, tx.intent.address, tx.intent.length,
                        tx.intent.qos, 3, 1):
                        raise AssertionError("manager AW payload changed before handshake")
                    max_wait[winner]["write"] = max(
                        max_wait[winner]["write"], cycle -
                        (cycle if tx.t_present is None else tx.t_present))
                    tx.t_addr_accept = cycle
                    tx.max_pending_cycles = max(
                        0, cycle - (cycle if tx.t_present is None else tx.t_present))
                    managers[winner].live_writes[mid] = tx
                    max_live_writes[winner] = max(max_live_writes[winner],
                                                  len(managers[winner].live_writes))
                    managers[winner].aw = None
                    managers[winner].w_owner = tx
                    tx.manager_wbeat = 0
                else:
                    tx = win_tx
                    mid = s["manager_arid"][winner]
                    if (mid, s["manager_araddr"][winner], s["manager_arlen"][winner],
                        s["manager_arqos"][winner], s["manager_arsize"][winner],
                        s["manager_arburst"][winner]) != (
                        tx.intent.ident, tx.intent.address, tx.intent.length,
                        tx.intent.qos, 3, 1):
                        raise AssertionError("manager AR payload changed before handshake")
                    max_wait[winner]["read"] = max(
                        max_wait[winner]["read"], cycle -
                        (cycle if tx.t_present is None else tx.t_present))
                    tx.t_addr_accept = cycle
                    tx.max_pending_cycles = max(
                        0, cycle - (cycle if tx.t_present is None else tx.t_present))
                    managers[winner].live_reads[mid] = tx
                    max_live_reads[winner] = max(max_live_reads[winner],
                                                 len(managers[winner].live_reads))
                    managers[winner].ar = None

        for m, state in enumerate(managers):
            if state.aw is not None:
                if state.w_owner is not None:
                    state.aw.write_owner_blocked_cycles += 1
            for direction, fires, valid_name, ready_name in (
                ("write", m_aw, "manager_awvalid", "manager_awready"),
                ("read", m_ar, "manager_arvalid", "manager_arready")):
                tx = state.aw if direction == "write" else state.ar
                if tx is not None and not fires[m] and tx.t_present is not None:
                    pending = cycle - tx.t_present
                    tx.max_pending_cycles = max(tx.max_pending_cycles, pending)
                    max_wait[m][direction] = max(max_wait[m][direction], pending)

        # Count only observed public target VALID&&!READY stalls.
        for t in range(3):
            stalled = {
                "aw": bool(s["target_awvalid"][t] and not s["target_awready"][t]),
                "ar": bool(s["target_arvalid"][t] and not s["target_arready"][t]),
                "w": bool(s["target_wvalid"][t] and not s["target_wready"][t]),
            }
            for name, active_stall in stalled.items():
                if active_stall:
                    target_stall_cycles[name][t] += 1
                    if not previous_target_stall[name][t]:
                        target_stall_episodes[name][t] += 1
                previous_target_stall[name][t] = active_stall
            if stalled["aw"]:
                iid = s["target_awid"][t]
                tx = find_live(iid >> 4, "write", iid & 0xF)
                tx.target_backpressure_cycles["aw"] += 1
                tx.target_backpressure_event_cycles["aw"].append(cycle)
            if stalled["ar"]:
                iid = s["target_arid"][t]
                tx = find_live(iid >> 4, "read", iid & 0xF)
                tx.target_backpressure_cycles["ar"] += 1
                tx.target_backpressure_event_cycles["ar"].append(cycle)
            if stalled["w"]:
                tx = target_w_owner[t]
                if tx is None:
                    raise AssertionError(f"target S{t} W stalled without an owner")
                tx.target_backpressure_cycles["w"] += 1
                tx.target_backpressure_event_cycles["w"].append(cycle)

        for m in range(3):
            stalled = {
                "b": bool(s["manager_bvalid"][m] and not s["manager_bready"][m]),
                "r": bool(s["manager_rvalid"][m] and not s["manager_rready"][m]),
            }
            for name, active_stall in stalled.items():
                if active_stall:
                    manager_stall_cycles[name][m] += 1
                    if not previous_manager_stall[name][m]:
                        manager_stall_episodes[name][m] += 1
                previous_manager_stall[name][m] = active_stall

        for m, state in enumerate(managers):
            if m_w[m]:
                tx = state.w_owner
                if tx is None or tx.manager_wbeat > tx.intent.length:
                    raise AssertionError(f"manager W fire without active owner M{m}")
                beat = tx.manager_wbeat
                expected = data_for_write(tx, beat)
                got = s["manager_wdata"][m]
                last = s["manager_wlast"][m]
                if (got, s["manager_wstrb"][m], last) != (
                        expected, 0xFF, int(beat == tx.intent.length)):
                    raise AssertionError(f"manager W payload mismatch M{m} seq={tx.intent.sequence}")
                tx.manager_w_cycles.append(cycle)
                tx.manager_wbeat += 1
                if last:
                    tx.t_wlast_manager = cycle

        for t in range(3):
            if t_aw[t]:
                iid = s["target_awid"][t]
                m, ident = iid >> 4, iid & 0xF
                tx = find_live(m, "write", ident)
                if (tx.intent.target, tx.intent.address, tx.intent.length) != (
                        t, s["target_awaddr"][t], s["target_awlen"][t]):
                    raise AssertionError(f"target AW routing/payload mismatch S{t} ID{iid}")
                tx.target_addr_accept = cycle
                if target_w_owner[t] is not None:
                    raise AssertionError(f"S{t} accepted AW while prior target W owner active")
                target_w_owner[t] = tx
                endpoints[t].on_aw(tx)
            if t_w[t]:
                tx, final_wlast = endpoints[t].on_w(cycle, s)
                if final_wlast:
                    if target_w_owner[t] is not tx:
                        raise AssertionError("target WLAST did not release matching target owner")
                    target_w_owner[t] = None
                    owner = managers[tx.intent.manager].w_owner
                    if owner is not tx:
                        raise AssertionError("target WLAST did not match manager write owner")
                    managers[tx.intent.manager].w_owner = None
            if t_ar[t]:
                iid = s["target_arid"][t]
                m, ident = iid >> 4, iid & 0xF
                tx = find_live(m, "read", ident)
                if (tx.intent.target, tx.intent.address, tx.intent.length) != (
                        t, s["target_araddr"][t], s["target_arlen"][t]):
                    raise AssertionError(f"target AR routing/payload mismatch S{t} ID{iid}")
                tx.target_addr_accept = cycle
                endpoints[t].on_ar(cycle, tx)
            if t_r[t]:
                endpoints[t].on_r(cycle, s)
            if t_b[t]:
                if not endpoints[t].writes or not endpoints[t].writes[0].w_done:
                    raise AssertionError(f"target B without completed target W S{t}")
                tx = endpoints[t].writes.popleft().tx
                if s["target_bid"][t] != widened_id(tx) or s["target_bresp"][t] != 0:
                    raise AssertionError(f"target B payload mismatch S{t}")

        for m, state in enumerate(managers):
            if m_r[m]:
                ident = s["manager_rid"][m]
                tx = find_live(m, "read", ident)
                beat = tx.manager_rbeat
                expected = data_for_read(tx.intent.target, tx.intent.address, beat)
                last = int(beat == tx.intent.length)
                if (s["manager_rdata"][m], s["manager_rresp"][m], s["manager_rlast"][m]) != (
                        expected, 0, last):
                    raise AssertionError(f"manager R mismatch M{m} seq={tx.intent.sequence} beat={beat}")
                tx.manager_r_cycles.append(cycle)
                if tx.t_first_resp is None:
                    tx.t_first_resp = cycle
                tx.manager_rbeat += 1
                if last:
                    tx.t_complete = cycle
                    del state.live_reads[ident]
                    finish(tx, cycle)
            if m_b[m]:
                ident = s["manager_bid"][m]
                tx = find_live(m, "write", ident)
                if s["manager_bresp"][m] != 0 or tx.t_wlast_manager is None:
                    raise AssertionError(f"manager B before WLAST or bad BRESP M{m} ID{ident}")
                tx.t_first_resp = cycle
                tx.t_complete = cycle
                del state.live_writes[ident]
                finish(tx, cycle)

        target_address_fires = [t for t in range(3) if t_aw[t] or t_ar[t]]
        if workload == "W13" and len(set(target_address_fires)) >= 2:
            parallel_target_cycles += 1
        if all(any((state.ar is not None, state.aw is not None, state.w_owner is not None,
                    bool(state.live_reads), bool(state.live_writes)))
               for state in managers):
            all_manager_active_cycles += 1

        if measure_start is None and active and all(completion_count[m] >= warmup for m in active):
            measure_start = cycle + 1
            premeasurement_completions = list(completion_count)
            event_file.write(json.dumps({"kind": "measurement_start", "cycle": measure_start}) + "\n")
        if measure_end is None and active and measure_start is not None and \
                all(measured_count[m] >= samples for m in active):
            measure_end = cycle
            event_file.write(json.dumps({"kind": "measurement_end", "cycle": cycle}) + "\n")

    clk = Clock(dut.ACLK, 10, unit="ns")
    cocotb.start_soon(clk.start(start_high=False))
    dut.ARESETn.value = 0
    zero = {name: 0 for name in LANE_WIDTHS}
    for name, width in LANE_WIDTHS.items():
        getattr(dut, name).value = 0
    for _ in range(4):
        await RisingEdge(dut.ACLK)
    await FallingEdge(dut.ACLK)
    dut.ARESETn.value = 1

    cycle = 0
    timeout = int(os.environ.get("ARCH_BENCH_TIMEOUT_CYCLES", "1000000"))
    while cycle < timeout:
        await FallingEdge(dut.ACLK)
        values = make_inputs(cycle)
        for name, width in LANE_WIDTHS.items():
            getattr(dut, name).value = packed(values[name], width)
        # At the falling edge inputs are committed; this delay lets all
        # combinational READY/VALID paths settle before the next rising edge.
        await Timer(4, unit="ns")
        s = snapshot()
        await RisingEdge(dut.ACLK)
        process(cycle, s, values)
        cycle += 1

        if workload == "W00" and cycle >= int(os.environ.get("ARCH_BENCH_IDLE_CYCLES", "1000")):
            measure_start, measure_end = 0, cycle
            break
        if measure_end is not None:
            any_held = any(x.ar is not None or x.aw is not None or x.w_owner is not None or
                           x.live_reads or x.live_writes for x in managers)
            any_endpoint = any(ep.writes or ep.reads for ep in endpoints)
            if not any_held and not any_endpoint:
                break
    else:
        live = [{"manager": m, "reads": list(x.live_reads), "writes": list(x.live_writes),
                 "aw": x.aw.intent.sequence if x.aw else None,
                 "ar": x.ar.intent.sequence if x.ar else None,
                 "w_owner": x.w_owner.intent.sequence if x.w_owner else None}
                for m, x in enumerate(managers)]
        raise AssertionError(f"benchmark timeout cycle={cycle} live={live} endpoints="
                             f"{[(len(e.writes), len(e.reads)) for e in endpoints]}")

    drain_end_cycle = cycle
    for m in active:
        if measured_count[m] != samples:
            raise AssertionError(f"M{m} measured {measured_count[m]} samples, expected {samples}")
        if completion_count[m] < warmup + samples:
            raise AssertionError(f"M{m} did not complete warmup plus measured transactions")
    event_file.flush()
    event_file.close()
    metadata = {
        "architecture": "A", "workload": workload, "seed": f"0x{seed:08X}",
        "workload_sha256": WORKLOAD_SHA256, "generator_version": GENERATOR_VERSION,
        "intent_sha256": intent_digest(intents), "intent_count": len(intents),
        "benchmark_driver_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "generator_sha256": hashlib.sha256(
            (Path(os.environ["ROOT"]) / "bench/benchmark_plan.py").read_bytes()).hexdigest(),
        "simulator_python": sys.version.split()[0],
        "active_managers": active, "warmup_per_manager": warmup,
        "retained_completions_per_manager": samples,
        "completion_count_by_manager": completion_count,
        "premeasurement_completions_by_manager": premeasurement_completions or [0, 0, 0],
        "measured_count_by_manager": measured_count,
        "measurement_start_cycle": measure_start, "measurement_end_cycle": measure_end,
        "measurement_cycles": (0 if measure_start is None else (measure_end - measure_start + 1)),
        "drain_end_cycle": drain_end_cycle, "max_pending_wait_cycles": max_wait,
        "address_grants": grant_counts, "lost_service_opportunities": contention_opportunities,
        "max_live_reads_by_manager": max_live_reads,
        "max_live_writes_by_manager": max_live_writes,
        "target_stall_cycles_by_target": target_stall_cycles,
        "target_stall_episodes_by_target": target_stall_episodes,
        "manager_stall_cycles_by_manager": manager_stall_cycles,
        "manager_stall_episodes_by_manager": manager_stall_episodes,
        "parallel_target_address_cycles": parallel_target_cycles,
        "all_manager_active_cycles": all_manager_active_cycles,
        "endpoint_max_write_depth": [ep.max_write_depth for ep in endpoints],
        "endpoint_max_read_depth": [ep.max_read_depth for ep in endpoints],
        "qualification_only": qualification,
    }
    (out / "run_meta.json").write_text(json.dumps(metadata, indent=2) + "\n")
    dut._log.info("ARCH_BENCH_PASS workload=%s seed=0x%08X completed=%s measured=%s cycles=%d..%d drain=%d",
                  workload, seed, completion_count, measured_count, measure_start or 0,
                  measure_end or 0, drain_end_cycle)
