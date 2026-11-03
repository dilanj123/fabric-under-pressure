"""Small pure-Python checks for canonical endpoint timing and packed lanes."""
import unittest

from benchmark_plan import Intent
from test_axi_fabric_a_benchmark import Endpoint, Transaction, data_for_read, lane, packed


def target_values():
    return {name: [0, 0, 0] for name in (
        "target_awready", "target_arready", "target_wready", "target_bvalid",
        "target_bid", "target_bresp", "target_rvalid", "target_rid",
        "target_rdata", "target_rresp", "target_rlast")}


class BenchmarkDriverTests(unittest.TestCase):
    def test_packed_lane_round_trip(self):
        values = [0xA, 0x3, 0xF]
        bus = packed(values, 4)
        self.assertEqual([lane(bus, 4, i) for i in range(3)], values)

    def test_read_latency_and_r_payload_hold_until_handshake(self):
        tx = Transaction(Intent(9, 1, "read", 3, 0, 0x100, 1, 15, 0))
        endpoint = Endpoint(0)
        endpoint.on_ar(20, tx)

        early = target_values()
        endpoint.drive(21, early)
        self.assertEqual(early["target_rvalid"][0], 0)

        first = target_values()
        endpoint.drive(22, first)
        expected0 = data_for_read(0, 0x100, 0)
        self.assertEqual(first["target_rvalid"][0], 1)
        self.assertEqual(first["target_rdata"][0], expected0)
        self.assertEqual(first["target_rlast"][0], 0)

        held = target_values()
        endpoint.drive(23, held)  # No on_r call means no handshake was sampled.
        for key in ("target_rvalid", "target_rid", "target_rdata", "target_rresp", "target_rlast"):
            self.assertEqual(held[key][0], first[key][0])

        endpoint.on_r(23, held)
        second = target_values()
        endpoint.drive(24, second)
        self.assertEqual(second["target_rdata"][0], data_for_read(0, 0x100, 1))
        self.assertEqual(second["target_rlast"][0], 1)
        endpoint.on_r(24, second)
        self.assertEqual(len(endpoint.reads), 0)

    def test_b_latency_and_pending_response_hold(self):
        tx = Transaction(Intent(12, 2, "write", 4, 1, 0x10000080, 0, 0, 0))
        endpoint = Endpoint(1)
        endpoint.on_aw(tx)
        w = {"target_wdata": [0, 0, 0], "target_wstrb": [0, 0, 0],
             "target_wlast": [0, 0, 0]}
        from test_axi_fabric_a_benchmark import data_for_write
        w["target_wdata"][1] = data_for_write(tx, 0)
        w["target_wstrb"][1] = 0xFF
        w["target_wlast"][1] = 1
        endpoint.on_w(30, w)

        early = target_values()
        endpoint.drive(31, early)
        self.assertEqual(early["target_bvalid"][1], 0)
        response = target_values()
        endpoint.drive(32, response)
        self.assertEqual(response["target_bvalid"][1], 1)
        self.assertEqual(response["target_bid"][1], (2 << 4) | 4)

        held = target_values()
        endpoint.drive(33, held)
        self.assertEqual((held["target_bvalid"][1], held["target_bid"][1],
                          held["target_bresp"][1]),
                         (response["target_bvalid"][1], response["target_bid"][1],
                          response["target_bresp"][1]))
        endpoint.writes.popleft()  # Central engine removes it on sampled B handshake.
        self.assertEqual(len(endpoint.writes), 0)


if __name__ == "__main__":
    unittest.main()
