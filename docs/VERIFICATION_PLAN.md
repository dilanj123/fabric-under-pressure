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
| R-003/R-007 IDs and limits | `tb/directed/id_mapper_tb.sv` exhaustively checks 48 valid widen/strip mappings, all 16 reserved return prefixes and collision prevention; `tb/directed/outstanding_tracker_tb.sv` checks busy IDs, four-entry capacity, metadata, violations, same-cycle policy and read/write independence; `tb/directed/axi_write_state_bank_tb.sv` checks shared three-manager write-state allocation, four-write capacity and atomic tracker/owner updates; `tb/directed/axi_read_state_bank_tb.sv` checks shared three-manager read allocation, four-read capacity, same-ID exclusion, completion pre-state and invalid-event gating | `formal/id_mapper_formal.sv` proves mapping properties; `formal/outstanding_tracker_formal.sv` provides bounded depth-6 state/metadata/invariant proof and depth-8 covers; `formal/axi_write_state_bank_formal.sv` provides bounded count safety, invalid-admission gating and state-space covers; `formal/axi_read_state_bank_formal.sv` provides bounded read count/popcount, admission gating and invalid-completion checks; full R completion integration remains future work | `rtl/axi_id_mapper.sv`, `rtl/axi_outstanding_tracker.sv`, `rtl/axi_write_state_bank.sv`, `rtl/axi_read_state_bank.sv`; focused read admission and R routing are evidenced; full four-target integration remains future |
| R-008 write ownership | `tb/directed/axi_write_owner_tb.sv` covers allocation, metadata capture, W-before-owner diagnostics, single/multi/16-beat accounting, stalls, WLAST errors, pre-state recycling and reset; `tb/directed/axi_write_owner_3_tb.sv` covers independent M0/M1/M2 contexts; `tb/directed/axi_aw_target_scheduler_tb.sv` covers target-owner gating and the target boundary composition; `tb/directed/axi_aw_write_state_composition_tb.sv` composes one AW target path with the shared bank; `tb/directed/axi_w_target_path_tb.sv` and `tb/directed/axi_aw_w_state_composition_tb.sv` cover owner-directed W admission, W-before-AW, AW-before-W and target delivery; `tb/directed/axi_b_response_router_tb.sv` and `tb/directed/axi_b_write_state_composition_tb.sv` cover focused B arbitration, validation, slot transport and manager completion | `formal/axi_write_owner_formal.sv` checks registered context stability, beat accounting, bounds, WLAST release, malformed-event diagnostics, no underflow and next-cycle reallocation; `formal/aw_target_scheduler_composition_formal.sv` checks focused target-owner uniqueness and no second AW while owned with bounded B; `formal/axi_aw_write_state_composition_formal.sv` checks shared-bank admission safety, target-fire non-allocation and registered composition covers under documented source/completion assumptions; `formal/axi_w_target_path_formal.sv` checks one-target WREADY ownership, stalled payload stability, target-only owner events and final no-refill; `formal/rr_arbiter_4_formal.sv` and `formal/axi_b_response_router_formal.sv` check four-source RR safety, B validation, slot gating and completion-event mapping under bounded assumptions | `rtl/axi_write_owner.sv`, `rtl/axi_write_state_bank.sv`, `rtl/axi_w_target_path.sv`, `rtl/axi_rr_arbiter_4.sv`, `rtl/axi_b_response_router.sv`; focused B response transport and write completion are evidenced, while four-target production write composition, S3 response generation and full read/write integration remain future work |
| R-009 reset | idle reset and reset with pending AW/W/B/AR/R | stale response exclusion under reset epoch assumption | coordinated reset/flush |
| R-010 Architecture A | `tb/directed/rr_arbiter_tb.sv` covers the 24 pointer/request combinations, ties, rotations, dynamic arrivals, stalls and reset during hold; `tb/directed/axi_aw_target_scheduler_tb.sv` covers one composed AW target boundary, eligibility blockers, owner gating, READY stall, D031 suppression and two-target non-global serialization; `tb/directed/axi_ar_target_path_tb.sv`, `tb/directed/axi_ar_read_state_composition_tb.sv` and `tb/directed/axi_ar_s3_tb.sv` cover one AR target boundary, shared read admission, D032 slot behavior, D036 suppression, blockers, payload stability and S3 transport; `tb/directed/axi_r_response_router_tb.sv`, `tb/directed/axi_r_burst_lengths_tb.sv` and `tb/directed/axi_ar_r_read_lifecycle_tb.sv` cover focused R arbitration, burst locking, stalls, drain/refill, RLAST completion and AR/R lifecycle | `formal/rr_arbiter_formal.sv` covers one-hot/no-phantom selection, held stability, pointer updates and cyclic selection; `formal/rr_arbiter_fairness.sv` checks bounded competing grants for M0, M1 and M2 with the watched request continuously asserted and READY continuously high, using bounded depth 12; `formal/aw_target_scheduler_formal.sv` and `formal/aw_target_scheduler_composition_formal.sv` provide bounded AW boundary/composition properties; `formal/axi_ar_target_path_formal.sv` provides bounded AR one-hot, D032 slot, payload stability and D036 properties; `formal/axi_r_response_router_formal.sv` provides bounded R validation, target-handshake admission, lock persistence, no interleaving, final no-refill, completion mapping and per-target source stability | `rtl/axi_rr_arbiter_3.sv`, `rtl/axi_aw_target_scheduler_a.sv`, `rtl/axi_ar_target_scheduler_a.sv`, `rtl/axi_ar_target_path_a.sv`, `rtl/axi_r_response_router.sv`; S3 response generation and complete four-target production integration remain future work |
| R-011 Architecture B | QoS priority, age threshold 64 and escape rotation | age saturation, monotonicity and escape cover under service-opportunity assumptions | QoS/age arbiters |
| R-012 workloads/metrics | replay each W00–W13 seed | deterministic generator checksum and identical A/B configuration | traffic generator, counters |
| R-013/R-014/R-015 implementation contract | interface/reset/CDC negative checks | wrapper preservation and parameter assertions | top-level fabric/wrapper |

Every regression prints the seed and exact commit. A project-owned reference model remains the oracle; external BFMs only generate legal channel activity.

### Shared per-manager write-state integration

`tb/directed/axi_write_state_bank_tb.sv` checks 24 state-transition conditions including atomic AW allocation, WLAST/B separation, four-write capacity, same-cycle pre-state recycling, invalid-admission protection, manager independence and reset. `tb/directed/axi_aw_write_state_composition_tb.sv` checks the one-target AW path feeding the shared bank, target stall/consumption and owner/outstanding lifetime. `formal/axi_write_state_bank_formal.sv` provides bounded count-safety, invalid-admission gating and state-space covers; `formal/axi_aw_write_state_composition_formal.sv` provides bounded composition safety and covers with AXI source stability and legal pre-existing W/B completion assumptions. `rtl/axi_write_state_bank.sv` is the shared production bank. Production W routing, B routing and multi-target integration remain future work.

### Architecture-A one-target AW channel path

The first address-channel boundary is covered separately from full Fabric integration. `tb/directed/axi_aw_target_path_tb.sv` checks three-manager admission, complete AW payload muxing, ID widening, target stall stability, D032 no drain/refill, S3 admission, reset and eligibility blockers. `formal/axi_aw_target_path_formal.sv` checks one-hot manager READY/fire, admission safety, D031 suppression, one-entry slot capture, stalled payload stability and target-slot conservation using bounded depth 20 prove and depth 24 cover. `rtl/axi_aw_target_path_a.sv` is the production boundary. Shared write-state allocation and owner-directed W transport are separately evidenced; B response transport is now covered by the focused B entries above. Four-target production integration, AR/R and S3 response generation remain future work.


### Architecture-A one-target AR path and shared read state

The focused AR evidence is scoped to one parameterized target and a shared three-manager read-state bank. `tb/directed/axi_ar_target_path_tb.sv` checks all three manager payload paths, eligibility blockers, D032 slot behavior, target stalls and reset; `tb/directed/axi_ar_s3_tb.sv` checks legal S3 transport; `tb/directed/axi_ar_read_state_composition_tb.sv` checks manager-facing admission allocation, target-side consumption without allocation, completion pre-state and following-cycle reuse. `formal/axi_ar_target_path_formal.sv` checks one-hot READY/fire, D036 suppression, one-entry slot capture and stalled payload stability at bounded depth 20/24. `formal/axi_read_state_bank_formal.sv` checks count/popcount, four-entry bounds, admission gating and reset/cover states at bounded depth 8/24. R routing and accepted-RLAST completion are covered separately by the focused R section below.

### Focused B response routing and write completion

`tb/directed/axi_rr_arbiter_4_tb.sv` covers the standalone S0-S3 round-robin primitive; `tb/directed/axi_b_response_router_tb.sv` covers all-four same-manager contention, different-manager concurrency, same visible IDs across managers, manager backpressure, the occupied-slot overwrite regression, invalid prefix/nonbusy rejection, BRESP propagation, S3 transport and reset; `tb/directed/axi_b_write_state_composition_tb.sv` covers target admission versus manager completion, WLAST/outstanding separation and same-ID following-cycle reuse. `formal/rr_arbiter_4_formal.sv` provides bounded depth-16 safety/hold/pointer checks with depth-20 covers. `formal/axi_b_response_router_formal.sv` provides bounded depth-20 validation, occupied-slot arbitration suppression, actual target-handshake admission correspondence, completion mapping and per-target source-stability assumptions with depth-32 covers. `rtl/axi_b_response_router.sv` is the repaired focused registered B path; the pre-repair router evidence is retained as historical traceability. Returned-target versus recorded-target metadata matching is not implemented because the current shared-bank interface does not expose that requirement; S3 DECERR generation and full four-target production write composition remain future work.

### Focused R response routing and read completion

`tb/directed/axi_r_response_router_tb.sv` covers four-target initial contention, RR rotation, manager backpressure, locked-target gaps, non-final drain/refill, final no-refill, invalid prefix/non-busy RID, locked-RID changes, same visible IDs across managers, different-ID out-of-order completion, BRESP-equivalent RRESP propagation, S3 transport and reset. `tb/directed/axi_r_burst_lengths_tb.sv` covers 2-, 4- and 16-beat bursts at full rate; `tb/directed/axi_ar_r_read_lifecycle_tb.sv` composes AR admission, shared read state, target R transport and manager RLAST completion. `formal/axi_r_response_router_formal.sv` uses per-target source-stability assumptions and checks target-handshake slot admission, validation safety, no response acceptance while a manager slot is stalled, lock establishment/persistence, no interleaving, final no-refill, completion separation and focused covers. The prove is bounded BMC depth 24 and cover depth 32 with Yices via SBY smtbmc. `rtl/axi_r_response_router.sv` is the focused common return path. Recorded-target matching, S3 response generation and full four-target production integration remain future work.


## S3 default/error target evidence

`tb/directed/axi_s3_error_target_tb.sv` checks standalone legal unmapped write/read behavior for 1/2/4/16-beat bursts, WLAST diagnostics, B/R backpressure, simultaneous independent read/write contexts and reset. `tb/directed/axi_s3_write_lifecycle_tb.sv` composes the TARGET_INDEX=3 AW path, shared write-state bank, W path, S3 endpoint and B router. `tb/directed/axi_s3_read_lifecycle_tb.sv` composes the TARGET_INDEX=3 AR path, shared read-state bank, S3 endpoint and R router. `formal/axi_s3_error_target_write_formal.sv` and `formal/axi_s3_error_target_read_formal.sv` provide bounded S3 state, payload, counter and stability checks with Yices via SBY at depth 24. The endpoint synthesises through ECP5-targeted Yosys. Recorded-target response-source matching and full four-target production integration remain future work.

The S3 W-before-AW repair is covered by `tb/directed/axi_s3_error_target_tb.sv` and `tb/directed/axi_s3_write_lifecycle_tb.sv`: WVALID may precede local AW acceptance, WREADY remains low, no state or response changes occur, and the held beat completes after AW. `formal/axi_s3_error_target_write_formal.sv` checks no W handshake without context and covers later AW availability.
