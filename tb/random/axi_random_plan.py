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
MAPPED_LIMIT = [0x0001_0000, 0x1001_0000, 0x2000_1000]


def validate_plan(plan: dict) -> None:
    """Validate every planned address against the frozen map and AXI subset."""
    from axi_reference_model import decode_target, legal_request

    if plan.get("architecture") != "A":
        raise ValueError("architecture must be A")
    for section in ("coverage_anchors", "random_operations"):
        for op in plan.get(section, []):
            seed = plan.get("seed")
            seq = op.get("sequence")
            target = op.get("target")
            addr = op.get("address")
            length = op.get("length")

            def fail(reason):
                raise ValueError(
                    f"seed=0x{seed:08X} sequence={seq} target={target} "
                    f"address={addr:#010x} violation={reason}")

            if not isinstance(op.get("manager"), int) or op["manager"] not in range(3):
                fail("manager outside 0..2")
            if op.get("direction") not in ("read", "write"):
                fail("invalid direction")
            if not isinstance(op.get("id"), int) or op["id"] not in range(16):
                fail("ID outside 0..15")
            if not isinstance(target, int) or target not in range(4):
                fail("target outside S0..S3")
            if not isinstance(addr, int) or not isinstance(length, int):
                fail("address/LEN missing or not integer")
            if length not in range(16):
                fail("LEN outside 0..15")
            if addr & 7:
                fail("address is not 8-byte aligned")
            if not legal_request(addr, length, 3, 1, 0):
                fail("unsupported SIZE/BURST/LOCK or 4-KiB crossing")
            actual = decode_target(addr)
            if actual != target:
                fail(f"claimed target S{target} decodes to S{actual}")
            end = addr + (length + 1) * 8 - 1
            if target < 3 and not (TARGET_BASE[target] <= addr <= end < MAPPED_LIMIT[target]):
                fail(f"burst leaves mapped S{target} region")
            if target == 3 and actual != 3:
                fail("S3 address is mapped")
            if not isinstance(op.get("qos"), int) or op["qos"] not in range(16):
                fail("QOS outside 0..15")
            if not isinstance(op.get("launch_cycle"), int) or op["launch_cycle"] < 0:
                fail("invalid launch_cycle")
            if op["direction"] == "write":
                strobes = op.get("strobes")
                if not isinstance(strobes, list) or len(strobes) != length + 1:
                    fail("WSTRB count must equal LEN+1")
                if any(not isinstance(x, int) or x not in range(256) for x in strobes):
                    fail("WSTRB outside 0..255")
            for field in ("response_delay", "manager_b_stall", "manager_r_stall",
                          "target_aw_stall", "target_ar_stall"):
                if field in op and (not isinstance(op[field], int) or op[field] < 0):
                    fail(f"invalid {field}")
            if op["direction"] == "write" and op.get("aw_w_style") not in (
                    "aw_before_w", "w_before_aw", "near_cycle"):
                fail("invalid write AW/W style")


def make_plan(seed: int, operations: int = 512) -> dict:
    rng = random.Random(seed)
    plan = {
        "seed": seed,
        "architecture": "A",
        "qualification_cycles": 10_000,
        "target_distribution": {"S0": 40, "S1": 30, "S2": 20, "S3": 10},
        "coverage_anchors": [],
        "random_operations": [],
        "resets": sorted(rng.sample(range(256, 5000), 3)),
        "resets_after_sequence": [],
    }
    # Anchors are deliberately separate from random-body coverage.
    for seq, (manager, direction, target, length) in enumerate(
            [(m, d, t, 0) for m in range(3) for d in ("write", "read")
             for t in range(4)]):
        ident = (seq + manager * 5 + (1 if direction == "read" else 0)) & 0xF
        plan["coverage_anchors"].append({"kind": "anchor", "sequence": seq,
                                         "manager": manager, "direction": direction,
                                         "id": ident, "target": target, "length": length,
                                         "address": TARGET_BASE[target] + 0x080 + ident * 8,
                                         "qos": seq & 0xF,
                                         "strobes": [0xFF], "launch_cycle": seq * 4,
                                         "aw_w_style": "aw_before_w"})
    for seq in range(operations):
        manager = rng.randrange(3)
        direction = "write" if rng.randrange(2) else "read"
        roll = rng.randrange(100)
        target = 0 if roll < 40 else 1 if roll < 70 else 2 if roll < 90 else 3
        length = rng.randrange(16)
        ident = rng.randrange(16)
        # Keep random manager/sequence locations distinct within the 4-KiB
        # legal-burst window so concurrent functional traffic has no
        # accidental read/write ordering dependency.
        if target in (0, 1):
            # Keep all generated operations inside the selected 64-KiB
            # mapped window.  Thirty 128-byte-safe slots fit per 4-KiB page;
            # wrap the page index before crossing the target boundary.
            page_count = 16 if target in (0, 1) else 1
            page = ((seq // 30) % page_count) * 0x1000
            slot = (seq % 30) * 0x80 + 0x40
            addr = TARGET_BASE[target] + page + slot
        else:
            addr = TARGET_BASE[target] + 0x080 + ((seq % 24) * 0x40)
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
        plan["random_operations"].append({
            "kind": "random", "sequence": seq,
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
            "launch_cycle": rng.randrange(64, 5000),
        })
    plan["operations"] = plan["random_operations"]
    validate_plan(plan)
    return plan


def write_plan(seed: int, path: Path, operations: int = 512) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(make_plan(seed, operations=operations), indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=lambda x: int(x, 0), required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--operations", type=int, default=512)
    args = parser.parse_args()
    if args.operations <= 0:
        parser.error("--operations must be positive")
    write_plan(args.seed, args.output, operations=args.operations)


if __name__ == "__main__":
    main()
