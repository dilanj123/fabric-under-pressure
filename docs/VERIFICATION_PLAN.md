# Verification Plan

**Status:** Gate-1 verification contract frozen; no AXI verification has run.

## Independent checking
A project-owned Python transaction/reference model records manager, target, ID, address, length, size, data/strobes, acceptance cycle, expected route and expected response. It models the architectural contract, not RTL internals.

## Required detection
Loss, duplication, misrouting, bad ID, bad data, bad RESP, bad LAST, ordering violations and stale responses after reset.

## Directed suites
1. primitive/decoder tests;
2. AW/W decoupling including W presented before matching AW is accepted;
3. B path and backpressure;
4. AR/R path and backpressure;
5. 1–16 beat INCR bursts and 4-KiB boundary rejection/generation discipline;
6. multiple distinct IDs and legal out-of-order completion;
7. simultaneous managers/targets;
8. random subordinate response latency;
9. every channel backpressured;
10. default/error target;
11. idle reset and reset with partially accepted traffic;
12. long randomized contention;
13. adversarial fairness/starvation;
14. architecture A/B against identical frozen workload vectors.

## Regression rule
Every discovered functional bug gains a regression test before the fix is considered complete.

## Phase-0 note
`cocotbext-axi` may be used as verification-only stimulus after the compatibility smoke passes; it is never the sole oracle.

## Gate-1 traceability matrix

| Requirement | Directed checks | Random/formal checks | Planned implementation block |
|---|---|---|---|
| R-001/R-005 subset and attributes | `tb/directed/request_legality_tb.sv` covers supported lengths, INCR, full-width size, alignment, lock and 4-KiB boundaries; attributes remain pass-through and are not interpreted | `formal/request_legality_formal.sv` proves legality equivalence, invalid-shape rejection and endpoint safety; no end-to-end unsupported-request response is claimed | `rtl/axi_request_legal.sv`; later request admission/protocol integration remains future work |
| R-002/R-004 topology and decode | `tb/directed/address_decoder_tb.sv` covers mapped boundaries, adjacent addresses and representative unmapped values | `formal/address_decoder_formal.sv` proves one-hot target selection, mapped routing and default routing; covers S0/S1/S2/S3 | `rtl/fabric_addr_map_pkg.sv`, `rtl/axi_address_decoder.sv`; S3 endpoint remains future integration |
| R-003/R-007 IDs and limits | `tb/directed/id_mapper_tb.sv` exhaustively checks 48 valid widen/strip mappings, all 16 reserved return prefixes and collision prevention; `tb/directed/outstanding_tracker_tb.sv` checks busy IDs, four-entry capacity, metadata, violations, same-cycle policy and read/write independence | `formal/id_mapper_formal.sv` proves mapping properties; `formal/outstanding_tracker_formal.sv` provides bounded depth-6 state/metadata/invariant proof and depth-8 covers; actual AW/AR/B/R integration remains future work | `rtl/axi_id_mapper.sv`, `rtl/axi_outstanding_tracker.sv`; response routing and end-to-end admission remain future integration |
| R-008 write ownership | `tb/directed/axi_write_owner_tb.sv` covers allocation, metadata capture, W-before-owner diagnostics, single/multi/16-beat accounting, stalls, WLAST errors, pre-state recycling and reset; `tb/directed/axi_write_owner_3_tb.sv` covers independent M0/M1/M2 contexts; `tb/directed/axi_aw_target_scheduler_tb.sv` covers target-owner gating and the target boundary composition | `formal/axi_write_owner_formal.sv` checks registered context stability, beat accounting, bounds, WLAST release, malformed-event diagnostics, no underflow and next-cycle reallocation; `formal/aw_target_scheduler_composition_formal.sv` checks focused target-owner uniqueness and no second AW while owned with bounded BMC/cover | `rtl/axi_write_owner.sv`, `rtl/axi_aw_target_scheduler_a.sv`; target-specific W routing, AW/W channel integration and response paths remain future work |
| R-009 reset | idle reset and reset with pending AW/W/B/AR/R | stale response exclusion under reset epoch assumption | coordinated reset/flush |
| R-010 Architecture A | `tb/directed/rr_arbiter_tb.sv` covers the 24 pointer/request combinations, ties, rotations, dynamic arrivals, stalls and reset during hold; `tb/directed/axi_aw_target_scheduler_tb.sv` covers one composed AW target boundary, eligibility blockers, owner gating, READY stall, D031 suppression and two-target non-global serialization | `formal/rr_arbiter_formal.sv` covers one-hot/no-phantom selection, held stability, pointer updates and cyclic selection; `formal/rr_arbiter_fairness.sv` checks bounded competing grants for M0, M1 and M2 with the watched request continuously asserted and READY continuously high, using bounded depth 12; `formal/aw_target_scheduler_formal.sv` and `formal/aw_target_scheduler_composition_formal.sv` provide bounded boundary/composition properties | `rtl/axi_rr_arbiter_3.sv`, `rtl/axi_aw_target_scheduler_a.sv`; four-target production instantiation, AR and AXI channel integration remain future work |
| R-011 Architecture B | QoS priority, age threshold 64 and escape rotation | age saturation, monotonicity and escape cover under service-opportunity assumptions | QoS/age arbiters |
| R-012 workloads/metrics | replay each W00–W13 seed | deterministic generator checksum and identical A/B configuration | traffic generator, counters |
| R-013/R-014/R-015 implementation contract | interface/reset/CDC negative checks | wrapper preservation and parameter assertions | top-level fabric/wrapper |

Every regression prints the seed and exact commit. A project-owned reference model remains the oracle; external BFMs only generate legal channel activity.
