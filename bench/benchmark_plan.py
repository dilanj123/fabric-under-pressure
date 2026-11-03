"""Deterministic Architecture-A/B benchmark intent generation.

One global xorshift32 stream is consumed in transaction-round order, with
managers visited M0, M1, M2.  The resulting intents are independent of DUT
handshakes and can be regenerated from workload, seed and this generator.
"""
from __future__ import annotations

from dataclasses import dataclass, asdict
import hashlib
import json
from pathlib import Path

SEEDS = (0xFABC0001, 0xFABC0002, 0xFABC0003, 0xFABC0004, 0xFABC0005)
GENERATOR_VERSION = "arch-bench-xorshift32-v1-round-robin-manager-draws"
WORKLOAD_SHA256 = "31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4"
BASES = (0x00000000, 0x10000000, 0x20000000, 0x30000000)


class XorShift32:
    def __init__(self, seed: int):
        self.state = seed & 0xFFFFFFFF

    def next(self) -> int:
        x = self.state
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        self.state = x & 0xFFFFFFFF
        return self.state


@dataclass(frozen=True)
class Intent:
    sequence: int
    manager: int
    direction: str
    ident: int
    target: int
    address: int
    length: int
    qos: int
    release_cycle: int


@dataclass(frozen=True)
class Profile:
    mode: str
    read_percent: int
    target_mode: str
    secondary_percent: int
    burst_beats: tuple[int, ...]
    qos: int


def scenario_profile(workload: str, manager: int) -> Profile | None:
    """Apply the frozen workload overrides and native traffic-class defaults."""
    if workload == "W00":
        return None
    active = {
        "W01": (0,), "W02": (1,), "W03": (2,),
        "W04": (0, 1, 2), "W05": (0, 1), "W06": (1, 2),
        **{f"W{i:02d}": (0, 1, 2) for i in range(7, 14)},
    }[workload]
    if manager not in active:
        return None
    native = ("sparse", 8, (1,), 8) if manager == 0 else \
             ("saturated", 50, (16,), 0) if manager == 1 else \
             ("bursty", 50, (1, 2), 15)
    mode, read_pct, bursts, qos = native
    target_mode, secondary = "S0", 0
    if workload in ("W01", "W02", "W03"):
        read_pct = 50
    elif workload == "W04":
        mode, read_pct, target_mode, secondary = "native", 50, "S0_OR_S1", 25
    elif workload == "W05":
        mode, read_pct = ("sparse" if manager == 0 else "saturated"), 50
    elif workload == "W06":
        mode, read_pct = ("saturated" if manager == 1 else "bursty"), 50
    elif workload == "W07":
        mode, read_pct = "saturated", 50
    elif workload == "W08":
        mode, read_pct = "saturated", 50
        qos = (12, 0, 15)[manager]
    elif workload == "W09":
        mode, read_pct = "native", 80
    elif workload == "W10":
        mode, read_pct = "native", 20
    elif workload == "W11":
        mode, read_pct = "native", 50
    elif workload == "W12":
        mode, read_pct, bursts, qos = "saturated", 50, (1,), 8
    elif workload == "W13":
        mode, read_pct, target_mode = "native", 50, "PARALLEL_SPLIT"
    if mode == "native":
        mode = native[0]
    return Profile(mode, read_pct, target_mode, secondary, bursts, qos)


def gap_range(mode: str) -> tuple[int, int]:
    return {"sparse": (8, 32), "bursty": (2, 8), "saturated": (0, 0)}[mode]


def make_intents(workload: str, seed: int, per_manager: int = 50_000) -> list[Intent]:
    if workload not in {f"W{i:02d}" for i in range(14)}:
        raise ValueError(f"unknown workload {workload}")
    if seed not in SEEDS:
        raise ValueError(f"seed 0x{seed:08X} is not frozen")
    profiles = [scenario_profile(workload, m) for m in range(3)]
    rng = XorShift32(seed)
    plans: list[Intent] = []
    release = [0, 0, 0]
    sequence = 0
    for n in range(per_manager):
        # W12 deliberately shares each transaction's direction and release gap
        # across all managers to create equal offered demand.
        common_dir = rng.next() % 100 if workload == "W12" else None
        common_gap = rng.next() if workload == "W12" else None
        for m, profile in enumerate(profiles):
            if profile is None:
                continue
            choice = common_dir if common_dir is not None else rng.next() % 100
            direction = "read" if choice < profile.read_percent else "write"
            if profile.target_mode == "PARALLEL_SPLIT":
                target = 1 if m == 1 else 0
            elif profile.target_mode == "S0_OR_S1":
                target = 1 if rng.next() % 100 < profile.secondary_percent else 0
            else:
                target = 0
            length = profile.burst_beats[0] - 1
            if len(profile.burst_beats) > 1:
                length = profile.burst_beats[rng.next() % len(profile.burst_beats)] - 1
            ident = n % 16
            # Uniform over legal 8-byte start positions, excluding only starts
            # that would cross the selected 4-KiB page.
            page = rng.next() % 16
            word = rng.next() % (512 - length)
            address = BASES[target] + page * 4096 + word * 8
            plans.append(Intent(sequence, m, direction, ident, target, address,
                                length, profile.qos, release[m]))
            sequence += 1
            lo, hi = gap_range(profile.mode)
            gap_draw = common_gap if common_gap is not None else rng.next()
            release[m] += lo + (gap_draw % (hi - lo + 1))
    return plans


def intent_digest(intents: list[Intent]) -> str:
    body = "\n".join(json.dumps(asdict(x), sort_keys=True, separators=(",", ":"))
                     for x in intents).encode()
    return hashlib.sha256(body).hexdigest()


def validate_intents(intents: list[Intent]) -> None:
    for tx in intents:
        assert tx.manager in range(3) and tx.direction in ("read", "write")
        assert tx.target in (0, 1) and 0 <= tx.length <= 15
        assert tx.address % 8 == 0 and tx.release_cycle >= 0
        end = tx.address + 8 * (tx.length + 1) - 1
        assert tx.address // 4096 == end // 4096
        if tx.target == 0:
            assert 0 <= tx.address <= end < 0x10000
        else:
            assert 0x10000000 <= tx.address <= end < 0x10010000


def save_manifest(path: Path, workload: str, seed: int, intents: list[Intent]) -> None:
    payload = {
        "workload": workload, "seed": f"0x{seed:08X}",
        "workload_sha256": WORKLOAD_SHA256, "generator_version": GENERATOR_VERSION,
        "intent_count": len(intents), "intent_sha256": intent_digest(intents),
        "release_cycle_max": max((x.release_cycle for x in intents), default=0),
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
