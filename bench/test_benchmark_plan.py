import unittest
import hashlib
from pathlib import Path

from benchmark_plan import (
    GENERATOR_VERSION, SEEDS, WORKLOAD_SHA256, intent_digest,
    make_intents, validate_intents,
)


class BenchmarkPlanTests(unittest.TestCase):
    def test_same_seed_replays_exactly(self):
        a = make_intents("W07", SEEDS[0], per_manager=20)
        b = make_intents("W07", SEEDS[0], per_manager=20)
        self.assertEqual(a, b)
        self.assertEqual(intent_digest(a), intent_digest(b))

    def test_frozen_seed_plans_are_legal_and_diverse(self):
        hashes = set()
        for seed in SEEDS:
            intents = make_intents("W13", seed, per_manager=20)
            validate_intents(intents)
            hashes.add(intent_digest(intents))
            self.assertEqual(len(intents), 60)
            for tx in intents:
                self.assertEqual(tx.target, 1 if tx.manager == 1 else 0)
        self.assertEqual(len(hashes), len(SEEDS))

    def test_w12_offered_read_write_and_release_pattern_is_equal(self):
        intents = make_intents("W12", SEEDS[0], per_manager=40)
        by_manager = [[x for x in intents if x.manager == m] for m in range(3)]
        for rows in zip(*by_manager):
            self.assertEqual(len({x.direction for x in rows}), 1)
            self.assertEqual(len({x.release_cycle for x in rows}), 1)
            self.assertTrue(all(x.target == 0 and x.length == 0 and x.qos == 8
                                for x in rows))

    def test_workload_hash_and_generator_identity_frozen(self):
        actual = hashlib.sha256((Path(__file__).parent / "workloads.yaml").read_bytes()).hexdigest()
        self.assertEqual(actual, WORKLOAD_SHA256)
        self.assertEqual(WORKLOAD_SHA256,
                         "31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4")
        self.assertTrue(GENERATOR_VERSION.startswith("arch-bench-xorshift32-v1"))


if __name__ == "__main__":
    unittest.main()
