# Evidence Index

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| G0-E001 | PLAN | repository skeleton and scripts exist | repository tree | COMPLETE |
| G0-E002 | SPEC | AXI4 authority pinned to IHI 0022H.c | `docs/references/AXI_SPEC.md` | COMPLETE |
| G0-E003 | UPSTREAM | required public repository snapshots/licences recorded | `docs/THIRD_PARTY_MANIFEST.md` | COMPLETE as public-source snapshot; local dependency checkout not performed |
| G0-E004 | UPSTREAM | candidate OSS CAD Suite darwin-arm64 asset/digest pinned | `results/processed/gate0/tool_versions.md` | COMPLETE as upstream metadata only |
| G0-E005 | REPRO | qualified host/tool probe | `results/raw/gate0/env/check_env.log` | PASS locally |
| G0-E006 | SIM | Verilator+cocotb smoke | `results/raw/gate0/sim/results.xml`, `run.log` | PASS locally |
| G0-E007 | SIM | cocotbext-axi compatibility | `results/raw/gate0/bfm/results.xml`, `run.log` | PASS locally; verification-only |
| G0-E008 | FORMAL | formal PASS/cover/expected-FAIL harness | `results/raw/gate0/formal/run.log` | PASS locally |
| G0-E009 | SYNTH | ECP5 synthesis smoke | `results/raw/gate0/synth/run.log`, `ecp5_smoke.json` | PASS locally |
| G0-E010 | PNR | ECP5 P&R smoke | `results/raw/gate0/pnr/run.log`, `.config`, `.bit` | PASS locally |
| G0-E011 | SYNTH/PNR | compact wrapper preserves payload cone | `results/raw/gate0/wrapper/run.log`, `check.log`, JSON | PASS locally; generic methodology |

| G0-E012 | REPRO | generated shell/Python smoke harnesses pass static syntax checks | local `bash -n` and `python -m py_compile` run, 2026-09-20 | COMPLETE for syntax only |

| G0-E013 | REPRO | Apple-Silicon CI qualification workflow | `.github/workflows/gate0-macos-arm64.yml`; run 35801448593 artifact under `results/raw/gate0/github-actions/35801448593/`, reviewed report in `results/processed/gate0/ci-run-35801448593.md` | PASS; all workflow steps succeeded |

No AXI functional correctness or performance evidence exists yet.

## Gate-1 specification evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| G1-E001 | SPEC | documented AXI4 subset, exact signal bundle, attributes and exclusions | `docs/REQUIREMENTS.md` | COMPLETE |
| G1-E002 | SPEC | topology, address map, ID widening, ownership, buffering and reset contract | `docs/MICROARCHITECTURE.md` | COMPLETE |
| G1-E003 | SPEC | workload generator, percentages, endpoint model, seeds and sample policy frozen | `bench/workloads.yaml`, SHA-256 `31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4` | COMPLETE |
| G1-E004 | SPEC | metric definitions and fixed P&R/wrapper method | `docs/TIMING_PERFORMANCE.md` | COMPLETE |
| G1-E005 | SPEC | requirement-to-test and formal assumption traceability | `docs/VERIFICATION_PLAN.md`, `docs/FORMAL.md` | COMPLETE |
| G1-E006 | REVIEW | hostile Gate-1 consistency review | authority-file review recorded in Gate-1 commit | PASS; no open BLOCKER/MAJOR issue |

## Decoder primitive evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| D-E001 | SIM | address decoder directed boundary and default tests pass | `results/raw/decoder/simulation.log` | PASS; 19 self-checking cases |
| D-E002 | FORMAL | decoder one-hot/mapped/default properties prove | `results/raw/decoder/formal_prove/logfile.txt` | PASS; Yices via SBY, depth 1 |
| D-E003 | FORMAL | all four target covers reach | `results/raw/decoder/formal_cover/logfile.txt` | PASS; S0, S1, S2 and S3 covers reached at step 0 |
| D-E004 | REPRO | decoder Verilator frontend/lint compatibility passes | `results/raw/decoder/verilator_lint.log` | PASS; reviewed with no warnings |
| D-E005 | SYNTH | decoder completes target-aware Yosys ECP5 synthesis | `results/raw/decoder/yosys_synth.log`, `axi_address_decoder_ecp5.json` | PASS; no P&R or Fabric PPA claim |

## Request-legality primitive evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| L-E001 | SIM | supported-request legality directed matrix passes | `results/raw/request_legality/simulation.log` | PASS; 36 self-checking cases |
| L-E002 | FORMAL | legality predicate equivalence and invalid-class properties prove | `results/raw/request_legality/formal_prove/logfile.txt` | PASS; unconstrained inputs, Yices via SBY, depth 1 |
| L-E003 | FORMAL | legal requests preserve decoder target from first byte through last byte | `results/raw/request_legality/formal_prove/logfile.txt` | PASS; composition assertion included |
| L-E004 | FORMAL | legality and target-space covers reach | `results/raw/request_legality/formal_cover/logfile.txt` | PASS; legal lengths, exact boundary, crossing, S0/S1/S2/S3 |
| L-E005 | SYNTH | request-legality primitive completes target-aware Yosys ECP5 synthesis | `results/raw/request_legality/yosys_synth.log`, `axi_request_legal_ecp5.json` | PASS; no P&R or Fabric PPA claim |

## Manager/internal ID mapping evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| I-E001 | SIM | manager/internal ID mapping directed matrix passes | `results/raw/id_mapping/simulation.log` | PASS; 48 valid mappings, 16 reserved returns and collision checks |
| I-E002 | FORMAL | valid manager mapping is bijective and reserved manager code is rejected | `results/raw/id_mapping/formal_prove/logfile.txt` | PASS; unconstrained inputs, Yices via SBY, depth 1 |
| I-E003 | FORMAL | forward exactness, lower-ID preservation and manager-prefix uniqueness prove | `results/raw/id_mapping/formal_prove/logfile.txt` | PASS; no environmental assumptions |
| I-E004 | FORMAL | mapping covers reach valid managers, endpoint IDs, reserved code and shared IDs | `results/raw/id_mapping/formal_cover/logfile.txt` | PASS; all listed cover classes reached |
| I-E005 | SYNTH | ID mapping primitive completes target-aware Yosys ECP5 synthesis | `results/raw/id_mapping/yosys_synth.log`, `axi_id_mapper_ecp5.json` | PASS; no P&R or Fabric PPA claim |

## Outstanding tracker evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| O-E001 | SIM | outstanding tracker directed state-transition suite passes | `results/raw/outstanding_tracker/simulation.log` | PASS; 19 checks including reset, metadata, violations, capacity and read/write independence |
| O-E002 | FORMAL | bounded count/bitmap, busy-ID, invalid-event and metadata properties pass | `results/raw/outstanding_tracker/formal_prove/logfile.txt` | PASS; Yices via SBY, BMC depth 6, initial reset assumption |
| O-E003 | FORMAL | bounded same-cycle pre-state allocation policy properties pass | `results/raw/outstanding_tracker/formal_prove/logfile.txt` | PASS; same-ID and full-count recycling blocked |
| O-E004 | FORMAL | sequential tracker covers reach meaningful states and reset-after-full | `results/raw/outstanding_tracker/formal_cover/logfile.txt` | PASS; cover depth 8 |
| O-E005 | SYNTH | outstanding tracker completes target-aware Yosys ECP5 synthesis | `results/raw/outstanding_tracker/yosys_synth.log`, `axi_outstanding_tracker_ecp5.json` | PASS; no P&R or Fabric PPA claim |

## Architecture-A RR arbiter evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| A-E001 | SIM | standalone 3-way RR scheduling and backpressure suite passes | `results/raw/rr_arbiter/simulation.log` | PASS; 70 checks including 24 pointer/request combinations, ties, rotations, stalls, dynamic arrivals and reset during hold |
| A-E002 | FORMAL | one-hot/no-phantom selection, pointer legality, cyclic selection and hold stability pass | `results/raw/rr_arbiter/formal_prove/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 12 |
| A-E003 | FORMAL | RR covers reach pointer states, all winners, held grants, wrap and skip behavior | `results/raw/rr_arbiter/formal_cover/logfile.txt` | PASS; bounded cover depth 12 |
| A-E004 | FORMAL | persistent-request fairness passes separately for M0, M1 and M2 under watched-request/always-ready assumptions | `results/raw/rr_arbiter/formal_fairness_m0/logfile.txt`, `formal_fairness_m1/logfile.txt`, `formal_fairness_m2/logfile.txt` | PASS for all three; Yices via SBY, bounded BMC depth 12; not an unconditional liveness claim |
| A-E005 | SYNTH | standalone RR arbiter completes target-aware Yosys ECP5 synthesis | `results/raw/rr_arbiter/yosys_synth.log`, `axi_rr_arbiter_3_ecp5.json` | PASS; primitive-only resource evidence, no P&R or Fabric PPA claim |

## Per-manager write-owner evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| W-E001 | SIM | registered owner allocation, metadata capture, beat accounting, stalls, WLAST diagnostics, pre-state recycling and reset pass | `results/raw/write_owner/simulation.log` | PASS; 22 self-checking cases |
| W-E002 | SIM | three independent manager owner contexts can be active and complete independently | `results/raw/write_owner/composition_simulation.log` | PASS; 6 self-checking cases; no target-uniqueness claim |
| W-E003 | FORMAL | owner bounds, context stability, beat accounting, correct WLAST release, no underflow and allocation protection pass | `results/raw/write_owner/formal_prove/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 12; legal allocation assumption `allocate_len <= 15` |
| W-E004 | FORMAL | meaningful owner stalls, malformed W events, completion and following-cycle reallocation are reachable | `results/raw/write_owner/formal_cover/logfile.txt` | PASS; Yices via SBY, bounded cover depth 16 |
| W-E005 | SYNTH | standalone write-owner primitive completes target-aware Yosys ECP5 synthesis | `results/raw/write_owner/yosys_synth.log`, `axi_write_owner_ecp5.json` | PASS; 54 LUT4, 20 TRELLIS_FF, 7 CCU2C, 3 PFUMX, primitive-only evidence |

## Architecture-A target-specific AW scheduler evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| AW-E001 | SIM | one target-specific AW boundary eligibility, owner-gating, READY-stall, D031 suppression, owner-resume and two-target isolation checks pass | `results/raw/aw_target_scheduler/simulation.log` | PASS; 39 self-checking checks |
| AW-E002 | FORMAL | AW eligibility equivalence, target-owner exclusion, accept safety, one-hot grant wiring and D031 request suppression pass | `results/raw/aw_target_scheduler/formal_prove/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 16 |
| AW-E003 | FORMAL | target-boundary covers reach eligible requests, acceptance and owner-busy states | `results/raw/aw_target_scheduler/formal_cover/logfile.txt` | PASS; Yices via SBY, bounded cover depth 16 |
| AW-E004 | FORMAL | focused boundary plus three write-owner composition proves target-owner uniqueness and no second AW while owned | `results/raw/aw_target_scheduler/formal_composition_prove/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 24; owner allocations use the documented legal-length domain |
| AW-E005 | FORMAL | focused composition covers reach accepted AW and registered owner-busy/no-accept states | `results/raw/aw_target_scheduler/formal_composition_cover/logfile.txt` | PASS; Yices via SBY, bounded cover depth 32 |
| AW-E006 | SYNTH | target-specific AW scheduler boundary completes ECP5-targeted Yosys synthesis | `results/raw/aw_target_scheduler/yosys_synth.log`, `axi_aw_target_scheduler_a_ecp5.json` | PASS; 43 LUT4, 6 TRELLIS_FF, 16 PFUMX, 7 L6MUX21; primitive/composed-boundary evidence only |

## Shared per-manager write-state evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| WS-E001 | SIM | shared three-manager write-state bank allocates outstanding and unfinished-W state atomically, enforces four writes and one owner, separates WLAST from B completion, and resets all lanes | `results/raw/write_state_bank/bank_simulation.log` | PASS; 24 self-checking checks |
| WS-E002 | SIM | one-target AW path plus shared bank composition allocates on manager-facing AW admission, preserves state through target stall/consumption, and releases owner/outstanding state at their separate events | `results/raw/write_state_bank/composition_simulation.log` | PASS; 8 self-checking checks |
| WS-E003 | FORMAL | shared-bank count bound and defensive invalid-admission gating pass under documented bounded event assumptions | `results/raw/write_state_bank/formal_bank_prove/logfile.txt` | PASS; Yices via SBY, smtbmc bounded BMC depth 12 |
| WS-E004 | FORMAL | shared AW/path composition proves admission safety, target-side consumption non-allocation and one-target state composition under documented source stability and pre-existing completion assumptions | `results/raw/write_state_bank/formal_comp_prove/logfile.txt` | PASS; Yices via SBY, smtbmc bounded BMC depth 24 |
| WS-E005 | FORMAL | shared-bank and AW/path composition covers reach populated, stalled, consumed and owner/outstanding-lifetime states | `results/raw/write_state_bank/formal_bank_cover/logfile.txt`, `formal_comp_cover/logfile.txt` | PASS; Yices via SBY, bounded cover depths 24 and 32 |
| WS-E006 | SYNTH | shared per-manager write-state bank completes ECP5-targeted Yosys synthesis | `results/raw/write_state_bank/yosys_synth.log`, `axi_write_state_bank_ecp5.json` | PASS; 706 LUT4, 117 TRELLIS_FF, 39 CCU2C, 225 PFUMX, 147 L6MUX21; primitive/composition evidence only, not Fabric PPA |

## Architecture-A one-target AW channel path evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| AWP-E001 | SIM | one-target AW manager admission, payload selection, target stall, D032 no drain/refill, blockers, reset and S3 handling pass | `results/raw/aw_target_path/simulation.log` | PASS; 23 self-checking checks |
| AWP-E002 | FORMAL | AWREADY/fire one-hot, owner exclusion, admission safety, held-slot payload capture and stalled payload stability pass | `results/raw/aw_target_path/formal_prove/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 20 |
| AWP-E003 | FORMAL | D031 request suppression and D032 no-overwrite property pass | `results/raw/aw_target_path/formal_prove/logfile.txt` | PASS; bounded BMC depth 20 |
| AWP-E004 | FORMAL | admissions, S3, stalls, target handshake and following-cycle drain/admit scenarios are reachable | `results/raw/aw_target_path/formal_cover/logfile.txt` | PASS; Yices via SBY, bounded cover depth 24 |
| AWP-E005 | SYNTH | one-target Architecture-A AW path completes ECP5-targeted Yosys synthesis | `results/raw/aw_target_path/yosys_synth.log`, `axi_aw_target_path_a_ecp5.json` | PASS; 210 LUT4, 74 TRELLIS_FF, 29 PFUMX, 11 L6MUX21; path evidence only |

## Registered owner-directed W target path evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| WTP-E001 | SIM | one-target owner-directed W routing, W-before-AW blocking, target stalls, non-final drain/refill, final no-refill and conflict protection pass | `results/raw/w_target_path/standalone_simulation.log` | PASS; 15 self-checking checks |
| WTP-E001a | SIM | parameterized owner routing selects only the matching target for S0, S1, S2 and S3 | `results/raw/w_target_path/route_simulation.log` | PASS; 32 self-checking checks |
| WTP-E002 | SIM | focused AW/state/W composition allocates shared state at AW admission, routes W from the registered owner and keeps outstanding state through WLAST until B | `results/raw/w_target_path/composition_simulation.log` | PASS; 14 self-checking checks |
| WTP-E003 | FORMAL | one-target WREADY ownership, one-hot fire, stalled payload stability, target-only owner events and final-beat no-refill pass | `results/raw/w_target_path/formal_prove/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 20 |
| WTP-E004 | FORMAL | one-target W covers reach pending-before-owner, accepted, stalled, non-final drain/refill, final delivery and conflict states | `results/raw/w_target_path/formal_cover/logfile.txt` | PASS; Yices via SBY, bounded cover depth 24 |
| WTP-E005 | SYNTH | registered W target path completes target-aware Yosys ECP5 synthesis | `results/raw/w_target_path/yosys_synth.log`, `axi_w_target_path_ecp5.json` | PASS; 646 LUT4, 77 TRELLIS_FF, 313 PFUMX, 159 L6MUX21; primitive/path evidence only |
| WTP-E006 | FORMAL | focused AW/state/W composition preserves owner-directed W routing and target-delivery-only owner progression | `results/raw/aw_w_composition/formal_prove/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 24, documented source-stability assumptions |
| WTP-E007 | FORMAL | focused AW/state/W composition covers stalled W, non-final delivery, final delivery and outstanding state retained after WLAST | `results/raw/aw_w_composition/formal_cover/logfile.txt` | PASS; Yices via SBY, bounded cover depth 32 |

## Registered B response routing evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| B-E001 | SIM | standalone four-source RR and focused per-manager B routing pass contention, backpressure, validation, BRESP, S3 and reset checks | `results/raw/b_response_router/rr4_simulation.log`, `router_simulation.log` | PASS; 79 RR4 checks including the exhaustive 4×16 table and 15 router checks |
| B-E002 | SIM | focused B router plus shared write-state composition separates target B admission from manager B completion and preserves same-ID pre-state reuse | `results/raw/b_response_router/composition_simulation.log` | PASS; 8 checks |
| B-E003 | FORMAL | RR4 safety, hold/pointer behavior and four-source covers pass | `results/raw/b_response_router/formal_rr4_prove/logfile.txt`, `formal_rr4_cover/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 16 and cover depth 20 |
| B-E004 | FORMAL | B validation, registered slot gating, completion mapping and manager-valid wiring pass under documented target-source stability assumptions | `results/raw/b_response_router/formal_router_prove/logfile.txt`, `formal_router_cover/logfile.txt` | PASS; Yices via SBY, bounded BMC depth 20 and cover depth 24 |
| B-E005 | SYNTH | RR4 and registered B response router complete ECP5-targeted Yosys synthesis | `results/raw/b_response_router/rr4_yosys_synth.log`, `router_yosys_synth.log`, `results/processed/b_response_router/summary.md` | PASS; primitive/path evidence only, no Fabric PPA claim |

The initial B-router functional entries above are retained as historical evidence for the pre-repair implementation. A live audit found that an occupied manager B slot could retain a target grant and that slot capture was not explicitly derived from the target handshake. The repair evidence below is authoritative for current B-router functional claims.

## B response router backpressure repair evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| BR-E001 | SIM | repaired B router rejects occupied-slot overwrite, blocks all same-manager target responses while the manager slot is stalled, preserves slot payload/source and resumes RR after completion | `results/raw/b_response_router_repair/router_simulation.log` | PASS; 36 self-checking checks, including the mandatory two-response and four-pending-target regressions; the same reproducer aborts on the pre-repair `f57b4fd` RTL in a temporary checkout |
| BR-E002 | SIM | RR4 and repaired B-router plus shared write-state regressions pass | `results/raw/b_response_router_repair/rr4_simulation.log`, `composition_simulation.log` | PASS; 79 RR4 checks and 8 write-state composition checks |
| BR-E003 | FORMAL | per-target source stability assumptions, occupied-slot arbitration suppression, target-handshake admission correspondence, completion separation and validation safety pass | `results/raw/b_response_router_repair/formal_router_prove/logfile.txt` | PASS; Yices via SBY smtbmc bounded BMC depth 20 |
| BR-E004 | FORMAL | repaired B-router covers target selection, manager stall and validation states under the repaired registered-slot lifecycle | `results/raw/b_response_router_repair/formal_router_cover/logfile.txt` | PASS; Yices via SBY bounded cover depth 32 |
| BR-E005 | SYNTH | repaired registered B response router completes ECP5-targeted Yosys synthesis | `results/raw/b_response_router_repair/router_yosys_synth.log`, `results/processed/b_response_router_repair/summary.md` | PASS; 598 LUT4, 61 TRELLIS_FF, 128 PFUMX, 48 L6MUX21; primitive/path evidence only, no Fabric PPA claim |

## Architecture-A one-target AR path and shared read-state evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| AR-E001 | SIM | one-target Architecture-A AR eligibility, three-manager payload selection, target stall, D032 no drain/refill and reset checks pass | `results/raw/ar_target_path/path_simulation.log` | PASS; 42 self-checking checks |
| AR-E002 | SIM | legal S3 AR transport and widened internal ID are exercised at the parameterized target path | `results/raw/ar_target_path/s3_simulation.log` | PASS; 1 self-checking check; no S3 response-generation claim |
| AR-E003 | SIM | shared three-manager read-state bank enforces allocation, same-ID exclusion, four-entry capacity, completion pre-state and invalid-event gating | `results/raw/ar_target_path/bank_simulation.log` | PASS; 14 self-checking checks |
| AR-E004 | SIM | one-target AR path plus shared read-state composition allocates on manager-facing admission, does not allocate on target consumption and permits following-cycle ID reuse after completion | `results/raw/ar_target_path/composition_simulation.log` | PASS; 7 self-checking checks |
| AR-E009 | SIM | read and write ordering domains permit the same numeric ID to coexist independently for one manager | `results/raw/ar_target_path/independence_simulation.log` | PASS; 2 self-checking checks |
| AR-E005 | FORMAL | AR one-hot READY/fire, D032 slot capture/stability and D036 same-edge successor suppression pass | `results/raw/ar_target_path/formal_ar_prove/logfile.txt` | PASS; Yices via SBY `smtbmc`, bounded BMC depth 20; cover depth 24 |
| AR-E006 | FORMAL | shared read-state count/popcount, four-entry bound, admission gating and reset/manager-state covers pass | `results/raw/ar_target_path/formal_bank_prove/logfile.txt`, `formal_bank_cover/logfile.txt` | PASS; Yices via SBY `smtbmc`, bounded BMC depth 8; cover depth 24 |
| AR-E007 | FORMAL | one-target AR path plus shared read-state composition commits manager-facing AR admission, separates target consumption and read-state allocation, and preserves bounded count safety | `results/raw/ar_target_path/formal_comp_prove/logfile.txt`, `formal_comp_cover/logfile.txt` | PASS; Yices via SBY `smtbmc`, bounded BMC depth 12; cover depth 20 with per-manager source-stability and busy-completion assumptions |
| AR-E008 | SYNTH | one-target AR path and shared read-state bank complete ECP5-targeted Yosys synthesis | `results/raw/ar_target_path/yosys_ar_path_synth.log`, `yosys_read_bank_synth.log`, `results/processed/ar_target_path/summary.md` | PASS; 198 LUT4/74 TRELLIS_FF path and 550 LUT4/57 TRELLIS_FF bank; primitive/composition evidence only |

## Architecture-A R response routing and read completion evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| R-E001 | SIM | focused per-manager four-target R routing passes contention, burst locking, stalls/gaps, non-final drain/refill, final no-refill, validation diagnostics, same visible IDs across managers, out-of-order IDs, S3 transport and reset | `results/raw/r_response_router/router_simulation.log`, `burst_simulation.log` | PASS; 34 standalone checks and 50 burst-length checks |
| R-E002 | SIM | focused AR/R lifecycle allocates read state on AR admission, preserves it through target R transport and clears it only on manager accepted RLAST | `results/raw/r_response_router/lifecycle_simulation.log` | PASS; 9 self-checking checks |
| R-E003 | FORMAL | per-target source stability assumptions, target-handshake admission, validation safety, occupied-slot blocking, lock persistence, no interleaving, final no-refill and completion separation pass | `results/raw/r_response_router/formal_prove/logfile.txt` | PASS; Yices via SBY smtbmc bounded BMC depth 24 |
| R-E004 | FORMAL | focused R lifecycle covers first admission, locked slot, locked-target gap, manager completion and concurrent manager admissions | `results/raw/r_response_router/formal_cover/logfile.txt` | PASS; Yices via SBY bounded cover depth 32 |
| R-E005 | SYNTH | focused registered R response router completes ECP5-targeted Yosys synthesis | `results/raw/r_response_router/yosys_r_router_synth.log`, `results/processed/r_response_router/summary.md` | PASS; 1,786 LUT4, 284 TRELLIS_FF, 353 PFUMX, 102 L6MUX21; primitive/path evidence only, no Fabric PPA claim |

The R evidence is scoped to the common response router and focused AR/R lifecycle composition. Recorded-target versus returned-target matching is not implemented because the current shared read-state bank does not expose the required table. S3 response generation and full four-target production integration remain future work.

## S3 error-target evidence

| S3-E001 | SIM | Standalone S3 legal unmapped write/read behavior passes 1/2/4/16-beat bursts, WLAST diagnostics, response backpressure, simultaneous read/write activity and reset | `results/raw/s3_error_target/standalone_simulation.log` | PASS; 72 self-checking checks |
| S3-E002 | SIM | Focused Architecture-A manager-to-S3-to-manager write lifecycle allocates shared write state on AW admission, consumes W through S3 and returns manager-visible DECERR B before clearing the busy ID | `results/raw/s3_error_target/write_lifecycle_simulation.log` | PASS; 5 self-checking checks |
| S3-E003 | SIM | Focused Architecture-A manager-to-S3-to-manager read lifecycle allocates shared read state, transports a two-beat DECERR burst and clears the ID only on accepted manager RLAST | `results/raw/s3_error_target/read_lifecycle_simulation.log` | PASS; 6 self-checking checks |
| S3-E004 | FORMAL | Standalone S3 write/read state, DECERR payload, beat bounds and backpressure-stability properties pass | `results/raw/s3_error_target/formal_write_run.log`, `formal_read_run.log` | PASS; Yices via SBY smtbmc, bounded BMC depth 24; legal AWLEN/ARLEN <= 15 assumptions |
| S3-E005 | FORMAL | Standalone S3 write/read covers reach one-beat, 16-beat, stalled-response and final-response states | `results/raw/s3_error_target/formal_write_run.log`, `formal_read_run.log` | PASS; Yices via SBY bounded cover depth 24 |
| S3-E006 | SYNTH | S3 error target completes ECP5-targeted Yosys synthesis | `results/raw/s3_error_target/synthesis.log`, `axi_s3_error_target_ecp5.json` | PASS; 52 LUT4, 29 TRELLIS_FF, 12 CCU2C, 13 PFUMX, 7 L6MUX21; primitive evidence only, no Fabric PPA claim |

## S3 W-before-AW repair evidence

| S3R-E001 | SIM | Legal WVALID-before-local-AW is backpressured without a diagnostic; the held beat completes after AW acceptance and produces DECERR B | `results/raw/s3_error_target_repair/standalone_simulation.log` | PASS; 77 checks |
| S3R-E002 | SIM | Focused AW/state/W/S3 composition delays target AW acceptance while W is presented through the registered owner path, then completes normally without a false diagnostic | `results/raw/s3_error_target_repair/write_lifecycle_simulation.log` | PASS; 7 checks |
| S3R-E003 | FORMAL | `!write_active -> !wready` and no-W-handshake-without-context safety pass; W-before-AW followed by later AW is covered | `results/raw/s3_error_target_repair/formal_write_run.log` | PASS; Yices via SBY smtbmc, bounded prove/cover depth 24 |
| S3R-E004 | SIM/FORMAL | Existing S3 read lifecycle and read endpoint checks remain passing after the diagnostic repair | `results/raw/s3_error_target_repair/read_lifecycle_simulation.log`, `formal_read_run.log` | PASS; 6 simulation checks and bounded prove/cover |
| S3R-E005 | SYNTH | Repaired S3 endpoint completes fresh ECP5-targeted synthesis | `results/raw/s3_error_target_repair/synthesis.log`, `axi_s3_error_target_ecp5.json` | PASS; 52 LUT4, 29 TRELLIS_FF, 12 CCU2C, 13 PFUMX, 7 L6MUX21 |

## Architecture-A four-target production integration evidence

| FAB-E001 | LINT/ELAB | `axi_fabric_a` composes the four target paths, shared state banks, common response routers and internal S3 endpoint with no Verilator lint warnings | `results/raw/fabric_a_integration/lint.log` | PASS; Verilator 5.053 |
| FAB-E002 | SIM | Whole-top directed responder checks route every manager through S0-S3 for AW/W/B and AR/R, including S3 DECERR traffic and 16-beat mapped/unmapped transactions | `results/raw/fabric_a_integration/simulation.log`, `tb/directed/axi_fabric_a_tb.sv` | PASS; 260 self-checking checks |
| FAB-E003 | SYNTH | Complete `axi_fabric_a` production composition completes ECP5-targeted Yosys synthesis | `results/raw/fabric_a_integration/synthesis.log`, `results/raw/fabric_a_integration/axi_fabric_a_ecp5.json` | PASS; 5,046 LUT4, 1,219 TRELLIS_FF, 288 CCU2C, 807 PFUMX, 270 L6MUX21; no PPA/timing claim |

The whole-top directed environment uses verification-only external responders for S0-S2 and the real S3 endpoint. It is focused integration evidence, not a complete correctness proof. Recorded-target versus returned-target response-source matching remains unproven. A project-owned Python oracle now exists with scoped S0/S1/S3 DUT evidence; the complete Gate-2 oracle matrix remains outstanding.

## Architecture-A Gate-2 directed integration regression

| FAB-G2-E001 | LINT/ELAB | Production top lint/elaboration remains clean during the expanded Gate-2 directed run | `results/raw/fabric_a_gate2_directed/lint.log` | PASS; Verilator 5.053 |
| FAB-G2-E002 | SIM | Expanded whole-top directed closure regression covers retained route smoke plus timing permutations, shared read/write capacity, unsupported shapes, target/manager backpressure, contention, parallel progress, cross-manager ID disambiguation, distinct-ID out-of-order completion, locked-source gaps, target-W stalls and reset recovery | `results/raw/fabric_a_gate2_directed/simulation.log`, `results/processed/fabric_a_gate2_directed/summary.md` | PASS; 348 self-checking checks |

This closes the hand-written directed integration pass only. The independent Python oracle and Gate-2 closure decision remain outstanding.

## Independent Python oracle — scoped evidence

| ORACLE-E001 | SIM/UNIT | Project-owned Python reference model detector self-tests reject loss, duplication, address/W misrouting, bad target/returned IDs, bad data/WSTRB/RESP/LAST, R-source interleaving, stale epochs and memory initialization mismatch | `results/raw/gate2_oracle/pytest_oracle_model.log`, `tb/model/test_axi_reference_model.py` | PASS; 11 tests |
| ORACLE-E002 | SIM | DUT-facing cocotb oracle checks S3 DECERR lifecycle, S0/S1 mapped read/write data, all legal LEN values 0..15, manager-W versus target-W payload comparison, WSTRB readback, target address/ID routing and three-manager same-visible-ID write overlap | `results/raw/gate2_oracle/cocotb_build.log`, `results/raw/gate2_oracle/event_trace.jsonl` | PASS; scoped single-test run |
| ORACLE-E003 | SIM | Fixed-cycle event trace is monotonic across multiple reset epochs; endpoint memory is independently implemented and sampled against the reference initialization contract | `results/raw/gate2_oracle/event_trace.jsonl`, `tb/model/axi_endpoint_model.py` | PASS |
| ORACLE-E004 | SIM/EXPECTED-FAIL | Deliberate DUT-facing read-data corruption fails with the specific `bad RDATA` oracle mismatch; the closure driver requires this failure | `results/raw/gate2_oracle/fault_sensitivity.log`, `fault_sensitivity_result.log` | PASS sensitivity |
| ORACLE-E005 | BOOKKEEPING | Closure summary records the implemented scope and remaining independent-oracle gaps; no Gate-2 tag is created | `results/processed/gate2_oracle/summary.md` | Gate 2 remains open |
