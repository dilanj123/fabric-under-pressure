"""Deterministic Gate-3 functional stimulus-plan generator.

The plan is generated before simulation.  No READY, grant, or DUT observation
is used to choose later plan values, so a saved plan is an exact replay input.
"""
from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

SEEDS = [0xA3F30001, 0xA3F30002, 0xA3F30003, 0xA3F30004, 0xA3F30005]
TARGET_BASE = [0x0000_0000, 0x1000_0000, 0x2000_0000, 0x3000_0000]


def make_plan(seed: int, operations: int = 96) -> dict:
    rng = random.Random(seed)
    plan = {
        "seed": seed,
        "architecture": "A",
        "qualification_cycles": 10_000,
        "target_distribution": {"S0": 40, "S1": 30, "S2": 20, "S3": 10},
        "operations": [],
        "resets_after_sequence": [32, 64],
    }
    # Force every manager, target and LEN before using seeded choices.
    forced = [(m, d, l % 4, l) for l in range(16)
              for m in range(3) for d in ("write", "read")]
    for seq in range(operations):
        if seq < len(forced):
            manager, direction, target, length = forced[seq]
        else:
            manager = rng.randrange(3)
            direction = "write" if rng.randrange(2) else "read"
            roll = rng.randrange(100)
            target = 0 if roll < 40 else 1 if roll < 70 else 2 if roll < 90 else 3
            length = rng.randrange(16)
        ident = (seq * 5 + manager * 3 + (1 if direction == "read" else 0)) & 0xF
        addr = TARGET_BASE[target] + 0x080 + (ident * 8)
        strobes = [rng.randrange(256) for _ in range(length + 1)]
        if seq % 5 == 0:
            strobes[0] = 0xFF
        elif seq % 5 == 1:
            strobes[0] = 0x00
        elif seq % 5 == 2:
            strobes[0] = 0xAA
        elif seq % 5 == 3:
            strobes[0] = 0x55
        else:
            strobes[0] = 0x81
        plan["operations"].append({
            "sequence": seq,
            "manager": manager,
            "direction": direction,
            "id": ident,
            "target": target,
            "address": addr,
            "length": length,
            "qos": rng.randrange(16),
            "strobes": strobes,
            "aw_w_style": ("aw_before_w", "w_before_aw", "near_cycle")[seq % 3]
            if direction == "write" else "ar_then_r",
            "target_aw_stall": rng.randrange(4) if seq % 7 == 0 else 0,
            "target_ar_stall": rng.randrange(4) if seq % 7 == 1 else 0,
            "target_w_stall_beat": (rng.randrange(length + 1)
                                     if direction == "write" and seq % 6 == 0 else None),
            "response_delay": rng.randrange(6),
            "manager_b_stall": rng.randrange(4) if direction == "write" else 0,
            "manager_r_stall": rng.randrange(4) if direction == "read" else 0,
        })
    return plan


def write_plan(seed: int, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(make_plan(seed), indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=lambda x: int(x, 0), required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    write_plan(args.seed, args.output)


if __name__ == "__main__":
    main()
